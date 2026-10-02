"""Unit tests for MACE-MP-0 FastAPI microservice."""

import pytest
from fastapi.testclient import TestClient
from main import app, MACE_API_KEY

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "MACE-MP-0"
    assert "endpoints" in data


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "MACE-MP-0"
    assert "status" in data


def test_predict_validation():
    # Mismatched lengths should return 422
    response = client.post(
        "/predict",
        json={"atomic_numbers": [6, 1], "positions": [[0.0, 0.0, 0.0]]},
    )
    assert response.status_code == 422


if __name__ == "__main__":
    test_root()
    test_health()
    test_predict_validation()
    print("All MACE backend standalone tests passed!")
