"""Unit tests for CHGNet FastAPI microservice."""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "CHGNet"
    assert "endpoints" in data


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "CHGNet"
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
    print("All CHGNet backend standalone tests passed!")
