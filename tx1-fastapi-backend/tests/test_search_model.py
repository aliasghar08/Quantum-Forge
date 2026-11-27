"""
Unit tests for PharmaChemSearchNet & /api/search/semantic endpoint
------------------------------------------------------------------
Validates:
1. Severe typo recovery (e.g. 'ketiapine' -> 'Quetiapine').
2. Clinical intent recovery (e.g. 'loop diuretic heart failure' -> 'Furosemide').
3. Sub-35ms search execution latency.
4. FastAPI /api/search/semantic endpoint schema & status codes.
"""

import time
import pytest
from fastapi.testclient import TestClient

from main import app, search_engine


@pytest.fixture(scope="module", autouse=True)
def client():
    # Trigger lifespan to load models and catalog
    search_engine.load()
    with TestClient(app) as test_client:
        yield test_client


def test_search_engine_loaded():
    assert search_engine.loaded is True
    assert search_engine.catalog_embeddings is not None
    assert len(search_engine.catalog_ids) > 1000


def test_typo_recovery():
    """Verify severe typo 'ketiapine' ranks 'Quetiapine' in top 3."""
    results = search_engine.search(query="ketiapine", top_k=3)
    assert len(results) > 0
    top_names = [r["name"].lower() for r in results]
    assert any("quetiapine" in name or "seroquel" in name for name in top_names), (
        f"Expected quetiapine in top 3, got: {top_names}"
    )


def test_clinical_intent_recovery():
    """Verify 'loop diuretic heart failure' ranks 'Furosemide' in top 3."""
    results = search_engine.search(query="loop diuretic heart failure", top_k=3)
    assert len(results) > 0
    top_names = [r["name"].lower() for r in results]
    assert any("furosemide" in name or "lasix" in name for name in top_names), (
        f"Expected furosemide in top 3, got: {top_names}"
    )


def test_search_latency_budget():
    """Verify neural search execution takes < 35 ms."""
    start = time.perf_counter()
    _ = search_engine.search(query="paracetamol synthesis", top_k=20)
    elapsed_ms = (time.perf_counter() - start) * 1000.0
    assert elapsed_ms < 35.0, f"Search took {elapsed_ms:.2f} ms (budget is 35 ms)"


def test_semantic_search_api_endpoint(client):
    """Test POST /api/search/semantic HTTP status, schema, and filtering."""
    resp = client.post(
        "/api/search/semantic",
        json={"query": "ketiapine", "top_k": 5}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["query"] == "ketiapine"
    assert "results" in data
    assert len(data["results"]) <= 5
    assert len(data["results"]) > 0
    first = data["results"][0]
    assert "id" in first
    assert "name" in first
    assert "category" in first
    assert "score" in first
    assert first["score"] > 0.0
