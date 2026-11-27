"""
Unit Tests for Dedicated search-backend Microservice
---------------------------------------------------
Verifies:
1. Health endpoint and vector catalog loading.
2. Typo recovery ('ketiapine' -> 'Quetiapine').
3. Clinical intent recovery ('loop diuretic heart failure' -> 'Furosemide').
4. Neural inference latency < 35 ms.
5. Hybrid retrieval and self-healing endpoints.
"""

import time
import pytest
from fastapi.testclient import TestClient

from main import app, search_engine


@pytest.fixture(scope="module", autouse=True)
def client():
    search_engine.load()
    with TestClient(app) as test_client:
        yield test_client


def test_health_check(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert data["service"] == "quantum-forge-search"
    assert data["catalog_vectors"] >= 20000
    assert data["embedding_dim"] == 128


def test_typo_recovery(client):
    """Verify severe typo 'ketiapine' returns 'Quetiapine' in top 3."""
    resp = client.post(
        "/api/search/semantic",
        json={"query": "ketiapine", "top_k": 3}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["query"] == "ketiapine"
    assert len(data["results"]) > 0
    top_names = [r["name"].lower() for r in data["results"]]
    assert any("quetiapine" in name or "seroquel" in name for name in top_names), (
        f"Expected quetiapine in top 3, got: {top_names}"
    )


def test_clinical_intent_recovery(client):
    """Verify clinical intent 'loop diuretic heart failure' returns 'Furosemide' in top 3."""
    resp = client.post(
        "/api/search/semantic",
        json={"query": "loop diuretic heart failure", "top_k": 3}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["results"]) > 0
    top_names = [r["name"].lower() for r in data["results"]]
    assert any("furosemide" in name or "lasix" in name for name in top_names), (
        f"Expected furosemide in top 3, got: {top_names}"
    )


def test_neural_latency_budget(client):
    """Verify search execution latency takes < 35 ms."""
    start = time.perf_counter()
    resp = client.post(
        "/api/search/semantic",
        json={"query": "paracetamol toxicology", "top_k": 20}
    )
    elapsed_ms = (time.perf_counter() - start) * 1000.0
    assert resp.status_code == 200
    assert elapsed_ms < 35.0, f"Search took {elapsed_ms:.2f} ms (budget is 35 ms)"


def test_hybrid_search_endpoint(client):
    resp = client.post(
        "/api/search/hybrid",
        json={"query": "aspirin cox acetylation", "top_k": 5}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["results"]) > 0
    assert data["results"][0]["score"] > 0.0


def test_self_heal_endpoint(client):
    resp = client.post(
        "/api/search/self-heal",
        json={"document_ids": ["rx_sample_1", "rx_sample_2"]}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "enqueued"
    assert data["enqueued"] == 2
