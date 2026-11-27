"""
Quantum Forge Dedicated Search Microservice (`quantum-forge-search`)
---------------------------------------------------------------------
High-throughput FastAPI microservice serving neural, hybrid, and self-healing
search for Quantum Forge. Operates completely standalone from tx1-fastapi-backend.
"""

from __future__ import annotations

import os
import sys
import time
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import BackgroundTasks, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

BACKEND_DIR = Path(__file__).resolve().parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.search_engine import search_engine


@asynccontextmanager
async def lifespan(_: FastAPI):
    search_engine.load()
    yield


app = FastAPI(
    title="Quantum Forge Search Microservice",
    version="1.2.0",
    description="Dedicated neural and hybrid retrieval service powered by PharmaChemSearchNet",
    lifespan=lifespan,
)

# CORS setup
DEFAULT_ORIGINS = [
    "https://quantom-forge.web.app",
    "https://quantom-forge.firebaseapp.com",
    "https://quantumforgeapp.com",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://localhost:8080",
]


def allowed_origins() -> List[str]:
    raw = os.environ.get("SEARCH_ALLOWED_ORIGINS", "*").strip()
    if raw == "*":
        return ["*"]
    extra = [o.strip() for o in raw.split(",") if o.strip()]
    return DEFAULT_ORIGINS + extra


app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==========================================
# REQUEST / RESPONSE SCHEMAS
# ==========================================
class SemanticSearchRequest(BaseModel):
    query: str
    category: Optional[str] = None
    top_k: int = 20


class SearchResultItem(BaseModel):
    id: str
    name: str
    category: str
    score: float
    doi: Optional[str] = None
    citations: int = 0
    source: str = "neural_biencoder"


class SearchResponse(BaseModel):
    query: str
    total: int
    latency_ms: float
    results: List[SearchResultItem]


class SelfHealRequest(BaseModel):
    document_ids: List[str]


class SelfHealResponse(BaseModel):
    status: str
    enqueued: int


# ==========================================
# ENDPOINTS
# ==========================================
@app.get("/health")
@app.get("/api/search/health")
async def health_check():
    """Health check returning catalog vector count and model version."""
    catalog_count = len(search_engine.catalog_ids) if search_engine.catalog_ids is not None else 0
    return {
        "status": "healthy" if search_engine.loaded else "initializing",
        "service": "quantum-forge-search",
        "model_version": "pharma_search_encoder_v1",
        "catalog_vectors": catalog_count,
        "embedding_dim": 128,
        "thread_workers": 16,
    }


@app.post("/api/search/semantic", response_model=SearchResponse)
async def semantic_search(req: SemanticSearchRequest):
    """
    Sub-35ms neural semantic search across 25,000+ catalog records.
    Recovers clinical intent and severe typos via PharmaChemSearchNet.
    """
    start = time.perf_counter()
    clean_q = req.query.strip()
    if not clean_q:
        return SearchResponse(query=req.query, total=0, latency_ms=0.0, results=[])

    raw_results = search_engine.search_semantic(query=clean_q, category=req.category, top_k=req.top_k)
    elapsed_ms = (time.perf_counter() - start) * 1000.0

    items = [
        SearchResultItem(
            id=r["id"],
            name=r["name"],
            category=r["category"],
            score=round(float(r["score"]), 4),
            doi=r.get("doi"),
            citations=r.get("citations", 0),
            source=r.get("source", "neural_biencoder"),
        )
        for r in raw_results
    ]
    return SearchResponse(query=clean_q, total=len(items), latency_ms=round(elapsed_ms, 2), results=items)


@app.post("/api/search/hybrid", response_model=SearchResponse)
async def hybrid_search(req: SemanticSearchRequest):
    """
    Parallel server-side retrieval combining PharmaChemSearchNet neural search
    and multi-leg query fallbacks.
    """
    start = time.perf_counter()
    clean_q = req.query.strip()
    if not clean_q:
        return SearchResponse(query=req.query, total=0, latency_ms=0.0, results=[])

    raw_results = search_engine.search_hybrid(query=clean_q, category=req.category, top_k=req.top_k)
    elapsed_ms = (time.perf_counter() - start) * 1000.0

    items = [
        SearchResultItem(
            id=r["id"],
            name=r["name"],
            category=r["category"],
            score=round(float(r["score"]), 4),
            doi=r.get("doi"),
            citations=r.get("citations", 0),
            source=r.get("source", "hybrid"),
        )
        for r in raw_results
    ]
    return SearchResponse(query=clean_q, total=len(items), latency_ms=round(elapsed_ms, 2), results=items)


@app.post("/api/search/self-heal", response_model=SelfHealResponse)
async def self_heal_endpoint(req: SelfHealRequest, bg: BackgroundTasks):
    """
    Accepts unindexed document IDs discovered during fallback scans
    and enqueues background patching for search_tokens and curriculum facets.
    """
    doc_ids = [d.strip() for d in req.document_ids if d.strip()]
    if doc_ids:
        bg.add_task(search_engine.self_heal, doc_ids)
    return SelfHealResponse(status="enqueued", enqueued=len(doc_ids))


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "8080"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
