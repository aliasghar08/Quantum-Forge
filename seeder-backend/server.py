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
import multiprocessing
import collections
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, BackgroundTasks, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

try:
    multiprocessing.set_start_method("spawn", force=True)
except (RuntimeError, ValueError):
    pass

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
        self.rolling_history = collections.deque(maxlen=20)  # (timestamp, batch_count)
        self.last_batch_time = time.time()
        self.last_error: Optional[str] = None
        self.batch_size = int(os.environ.get("SEEDER_BATCH_SIZE", "500"))
        self.cpu_workers = int(os.environ.get("SEEDER_CPU_WORKERS", str(max(1, min(4, (os.cpu_count() or 2))))))
        self.io_workers = int(os.environ.get("SEEDER_IO_WORKERS", os.environ.get("SEEDER_WORKERS", "8")))
        self.category_mode = os.environ.get("SEEDER_CATEGORY_MODE", "all")
        self.status = "INITIALIZING"

state = SeederState()

def background_seeder_worker():
    """Continuously streams batches of reactions into Cloud Firestore /library using hybrid multiprocessing and connection-pooled multithreading."""
    logger.info("Starting background hybrid seeder worker thread (CPU: %d, IO: %d)...", state.cpu_workers, state.io_workers)
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

    try:
        process_pool = ProcessPoolExecutor(max_workers=state.cpu_workers)
    except Exception as exc:
        logger.warning("Could not initialize ProcessPoolExecutor (%s). Falling back to direct generation.", exc)
        process_pool = None

    io_pool = ThreadPoolExecutor(max_workers=state.io_workers)

    while state.is_running:
        if state.is_paused:
            with state.lock:
                state.status = "PAUSED"
            time.sleep(2.0)
            continue

        try:
            token = seeder.get_auth_token_threadsafe()
            chunk_size = state.batch_size
            dispatch_n = max(2, min(state.io_workers, 8))

            # Dispatch chunk_size slices across ProcessPool / direct generation
            gen_futures = []
            if process_pool:
                for i in range(dispatch_n):
                    gen_futures.append(process_pool.submit(
                        seeder.generate_and_validate_reaction_slice,
                        (offset + (i * chunk_size), chunk_size, state.category_mode)
                    ))
            else:
                for i in range(dispatch_n):
                    batch = seeder.generate_combinatorial_reactions(
                        offset + (i * chunk_size), chunk_size, category_mode=state.category_mode
                    )
                    gen_futures.append(batch)

            generated_batches = []
            if process_pool:
                for fut in as_completed(gen_futures):
                    try:
                        res = fut.result()
                        if res:
                            generated_batches.append(res)
                    except Exception as ge:
                        logger.warning("Generation error in process worker: %s", ge)
            else:
                generated_batches = [b for b in gen_futures if b]

            if not generated_batches:
                time.sleep(1.0)
                continue

            # Stream generated batches in parallel across ThreadPool
            commit_futures = {
                io_pool.submit(seeder.commit_batch, token, b): len(b)
                for b in generated_batches
            }

            successful_count = 0
            for cf in as_completed(commit_futures):
                b_size = commit_futures[cf]
                try:
                    if cf.result():
                        successful_count += b_size
                except Exception as ce:
                    logger.warning("Commit batch error: %s", ce)

            now = time.time()
            if successful_count > 0:
                offset += successful_count
                with state.lock:
                    state.total_uploaded += successful_count
                    state.current_live_count = state.initial_count + state.total_uploaded
                    state.last_batch_time = now
                    state.rolling_history.append((now, successful_count))

                    # Compute accurate rolling rate over sliding window
                    if len(state.rolling_history) > 1:
                        oldest_t, _ = state.rolling_history[0]
                        total_window = sum(cnt for _, cnt in state.rolling_history)
                        dt = now - oldest_t
                        state.speed_rxns_sec = round(total_window / dt, 1) if dt > 0 else 0.0
                    else:
                        elapsed = now - state.start_time
                        state.speed_rxns_sec = round(state.total_uploaded / elapsed, 1) if elapsed > 0 else 0.0

                    state.status = "STREAMING"
                    state.last_error = None

                logger.info("⚡ Cloud Seeder Progress: +%d uploaded (Session: +%d) | Live Firestore: %d | Speed: %.1f rxns/sec",
                            successful_count, state.total_uploaded, state.current_live_count, state.speed_rxns_sec)

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
            time.sleep(5.0)

@app.on_event("startup")
def start_seeder():
    t = threading.Thread(target=background_seeder_worker, daemon=True)
    t.start()
    logger.info("Hybrid multi-worker background thread spawned successfully.")

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
            "cpu_workers": state.cpu_workers,
            "io_workers": state.io_workers,
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
        cpu_w = state.cpu_workers
        io_w = state.io_workers
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
        <div class="subtitle">Cloud Run Hybrid Multi-Worker Database Scaling Engine</div>
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
        <div class="metric-sub">~{hourly_rate:,} rxns / hour (Rolling)</div>
      </div>
      <div class="metric">
        <div class="metric-label">Workers & Uptime</div>
        <div class="metric-value">{hrs:02d}:{mins:02d}:{secs:02d}</div>
        <div class="metric-sub">CPU: {cpu_w} processes | IO: {io_w} threads</div>
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

