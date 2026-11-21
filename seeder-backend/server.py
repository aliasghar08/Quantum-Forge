#!/usr/bin/env python3
"""
Quantum Forge 24/7 Cloud Reaction Seeder Service
-------------------------------------------------
Continuous, high-throughput background worker and live monitoring service for Google Cloud Run.
Streams combinatorial 3D reaction datasets directly into Firestore /library 24/7.
"""

import os
import sys
import time
import json
import logging
import threading
import datetime
from typing import Optional
from fastapi import FastAPI, BackgroundTasks, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("QuantumForgeSeeder")

# Import continuous upload core
import seed_massive_firebase as seeder

app = FastAPI(title="Quantum Forge 24/7 Continuous Reaction Seeder", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SeederState:
    def __init__(self):
        self.lock = threading.Lock()
        self.is_running = True
        self.is_paused = False
        self.start_time = time.time()
        self.total_uploaded = 0
        self.initial_count = 0
        self.current_live_count = 0
        self.speed_rxns_sec = 0.0
        self.last_batch_time = time.time()
        self.last_error: Optional[str] = None
        self.batch_size = int(os.environ.get("SEEDER_BATCH_SIZE", "200"))
        self.workers = int(os.environ.get("SEEDER_WORKERS", "4"))
        self.category_mode = os.environ.get("SEEDER_CATEGORY_MODE", "all")
        self.status = "INITIALIZING"

state = SeederState()

def background_seeder_worker():
    """Continuously streams batches of reactions into Cloud Firestore /library."""
    logger.info("Starting background seeder worker thread...")
    try:
        token = seeder.get_auth_token_threadsafe()
        initial = seeder.get_total_count(token)
        with state.lock:
            state.initial_count = initial
            state.current_live_count = initial
            state.status = "STREAMING"
        logger.info("Connected to Firestore. Baseline live count: %d reactions", initial)
    except Exception as e:
        logger.error("Failed to connect to Firestore on startup: %s", e)
        with state.lock:
            state.last_error = str(e)
            state.status = "AUTH_RETRYING"

    offset = state.initial_count
    
    while state.is_running:
        if state.is_paused:
            with state.lock:
                state.status = "PAUSED"
            time.sleep(2.0)
            continue

        try:
            token = seeder.get_auth_token_threadsafe()
            chunk_size = state.batch_size
            chunk = seeder.generate_combinatorial_reactions(
                offset, 
                chunk_size, 
                category_mode=state.category_mode
            )

            commit_start = time.time()
            success = seeder.commit_batch(token, chunk)
            commit_duration = time.time() - commit_start

            if success:
                offset += chunk_size
                with state.lock:
                    state.total_uploaded += chunk_size
                    state.current_live_count = state.initial_count + state.total_uploaded
                    state.last_batch_time = time.time()
                    elapsed = time.time() - state.start_time
                    state.speed_rxns_sec = round(state.total_uploaded / elapsed, 1) if elapsed > 0 else 0.0
                    state.status = "STREAMING"
                    state.last_error = None
                
                # Log progress every 5 batches (1,000 reactions)
                if (state.total_uploaded // chunk_size) % 5 == 0:
                    logger.info("⚡ Cloud Seeder Progress: +%d uploaded this session | Live Firestore: %d | Speed: %.1f rxns/sec",
                                state.total_uploaded, state.current_live_count, state.speed_rxns_sec)

                # Modest pacing: 50ms between batches to maintain healthy throughput while preventing 429
                time.sleep(0.05)
            else:
                with state.lock:
                    state.status = "RETRYING"
                time.sleep(1.0)

        except Exception as e:
            err_msg = str(e)
            logger.warning("Upload cycle notice: %s", err_msg)
            with state.lock:
                state.last_error = err_msg
                if "429" in err_msg or "RESOURCE_EXHAUSTED" in err_msg:
                    state.status = "QUOTA_BACKOFF"
                else:
                    state.status = "ERROR_BACKOFF"
            
            # Backoff before retrying
            time.sleep(5.0)

@app.on_event("startup")
def start_seeder():
    t = threading.Thread(target=background_seeder_worker, daemon=True)
    t.start()
    logger.info("Worker thread spawned successfully.")

@app.get("/health")
@app.get("/status")
@app.get("/api/seeder/health")
@app.get("/api/seeder/status")
def get_status():
    with state.lock:
        elapsed_sec = int(time.time() - state.start_time)
        return {
            "status": state.status,
            "is_paused": state.is_paused,
            "total_uploaded_this_container": state.total_uploaded,
            "current_firestore_live_count": state.current_live_count,
            "speed_reactions_per_sec": state.speed_rxns_sec,
            "speed_reactions_per_hour": round(state.speed_rxns_sec * 3600),
            "batch_size": state.batch_size,
            "category_mode": state.category_mode,
            "uptime_seconds": elapsed_sec,
            "last_error": state.last_error,
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
        }

@app.post("/pause")
@app.post("/api/seeder/pause")
def pause_seeder():
    with state.lock:
        state.is_paused = True
        state.status = "PAUSED"
    return {"message": "Continuous seeder paused.", "status": "PAUSED"}

@app.post("/resume")
@app.post("/api/seeder/resume")
def resume_seeder():
    with state.lock:
        state.is_paused = False
        state.status = "STREAMING"
    return {"message": "Continuous seeder resumed.", "status": "STREAMING"}

@app.get("/", response_class=HTMLResponse)
@app.get("/api/seeder", response_class=HTMLResponse)
@app.get("/api/seeder/", response_class=HTMLResponse)
def index_dashboard():
    with state.lock:
        status = state.status
        uploaded = state.total_uploaded
        live_count = state.current_live_count
        speed = state.speed_rxns_sec
        hourly_rate = round(speed * 3600)
        uptime = int(time.time() - state.start_time)
        hrs = uptime // 3600
        mins = (uptime % 3600) // 60
        secs = uptime % 60
        err = state.last_error or "None (Healthy)"

    badge_color = "#10B981" if status == "STREAMING" else ("#F59E0B" if status in ("PAUSED", "QUOTA_BACKOFF") else "#EF4444")

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Quantum Forge | 24/7 Cloud Reaction Seeder</title>
  <meta http-equiv="refresh" content="3">
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #0b0f17;
      color: #e2e8f0;
      margin: 0;
      padding: 2rem;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
    }}
    .card {{
      background: #151d2a;
      border: 1px solid #1e293b;
      border-radius: 16px;
      padding: 2.5rem;
      max-width: 640px;
      width: 100%;
      box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }}
    .header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2rem;
      border-bottom: 1px solid #1e293b;
      padding-bottom: 1.5rem;
    }}
    .title {{
      font-size: 1.5rem;
      font-weight: 700;
      color: #38bdf8;
      margin: 0;
    }}
    .subtitle {{
      font-size: 0.85rem;
      color: #94a3b8;
      margin-top: 0.25rem;
    }}
    .status-badge {{
      background: {badge_color}22;
      color: {badge_color};
      border: 1px solid {badge_color}88;
      padding: 6px 14px;
      border-radius: 9999px;
      font-weight: 600;
      font-size: 0.85rem;
      letter-spacing: 0.05em;
    }}
    .grid {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1.25rem;
      margin-bottom: 2rem;
    }}
    .metric {{
      background: #0f172a;
      border: 1px solid #1e293b;
      border-radius: 12px;
      padding: 1.25rem;
    }}
    .metric-label {{
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #64748b;
      margin-bottom: 0.5rem;
    }}
    .metric-value {{
      font-size: 1.75rem;
      font-weight: 700;
      color: #f8fafc;
    }}
    .metric-sub {{
      font-size: 0.75rem;
      color: #38bdf8;
      margin-top: 0.25rem;
    }}
    .footer {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 0.8rem;
      color: #64748b;
      border-top: 1px solid #1e293b;
      padding-top: 1.25rem;
    }}
    .pulse {{
      display: inline-block;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: {badge_color};
      margin-right: 6px;
      animation: pulse-animation 2s infinite;
    }}
    @keyframes pulse-animation {{
      0% {{ opacity: 1; transform: scale(1); }}
      50% {{ opacity: 0.4; transform: scale(1.2); }}
      100% {{ opacity: 1; transform: scale(1); }}
    }}
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div>
        <h1 class="title">Quantum Forge 24/7 Seeder</h1>
        <div class="subtitle">Cloud Run Autonomous Database Scaling Engine</div>
      </div>
      <div class="status-badge"><span class="pulse"></span>{status}</div>
    </div>
    
    <div class="grid">
      <div class="metric">
        <div class="metric-label">Firestore Total Reactions</div>
        <div class="metric-value">{live_count:,}</div>
        <div class="metric-sub">Live in /library</div>
      </div>
      <div class="metric">
        <div class="metric-label">Uploaded This Container</div>
        <div class="metric-value">+{uploaded:,}</div>
        <div class="metric-sub">Session batches</div>
      </div>
      <div class="metric">
        <div class="metric-label">Upload Speed</div>
        <div class="metric-value">{speed} <span style="font-size: 1rem; font-weight: 400; color: #94a3b8;">rxns/sec</span></div>
        <div class="metric-sub">~{hourly_rate:,} rxns / hour</div>
      </div>
      <div class="metric">
        <div class="metric-label">Container Uptime</div>
        <div class="metric-value">{hrs:02d}:{mins:02d}:{secs:02d}</div>
        <div class="metric-sub">Auto-refreshes every 3s</div>
      </div>
    </div>

    <div class="footer">
      <div>Host: Google Cloud Run (us-central1)</div>
      <div>Notice: {err}</div>
    </div>
  </div>
</body>
</html>
"""
    return html

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port)
