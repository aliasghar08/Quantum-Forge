"""Unit tests for GFN2-xTB FastAPI microservice."""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["method"] == "GFN2-xTB"
    assert "endpoints" in data


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["method"] == "GFN2-xTB"
    assert "status" in data


def test_predict_validation():
    # Empty positions should return 422
    response = client.post(
        "/predict",
        json={"atomic_numbers": [], "positions": []},
    )
    assert response.status_code == 422


if __name__ == "__main__":
    test_root()
    test_health()
    test_predict_validation()
    print("All GFN2-xTB backend standalone tests passed!")
