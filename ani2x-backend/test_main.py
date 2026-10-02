"""Unit tests for ANI-2x FastAPI microservice."""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "ANI-2x"
    assert "endpoints" in data


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "ANI-2x"
    assert "status" in data


def test_predict_validation():
    # Empty positions should return 422
    response = client.post(
        "/predict",
        json={"atomic_numbers": [], "positions": []},
    )
    assert response.status_code == 422


def test_unsupported_elements():
    # Iron (atomic number 26) is unsupported by ANI-2x
    response = client.post(
        "/predict",
        json={"atomic_numbers": [26], "positions": [[0.0, 0.0, 0.0]]},
    )
    assert response.status_code == 422


if __name__ == "__main__":
    test_root()
    test_health()
    test_predict_validation()
    test_unsupported_elements()
    print("All ANI-2x backend standalone tests passed!")
