# ANI-2x Neural Network Potential Microservice

FastAPI compute service for **ANI-2x** (Accurate Neural Network Potential for Organic Molecules), parameterized across 7 elemental species: **H, C, N, O, S, F, Cl**, providing high-accuracy DFT-level potential energies and analytical forces for Quantum Forge.

## Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check & model status |
| `POST` | `/predict` | Predict potential energy (eV) and forces (eV/Å) |
| `POST` | `/optimize` | Geometry optimization via ASE BFGS |
| `GET` | `/docs` | Interactive Swagger API documentation |

## Supported Elements

`H` (1), `C` (6), `N` (7), `O` (8), `F` (9), `S` (16), `Cl` (17).
Inputs containing other elements will be rejected with HTTP 422.

## Environment & API Keys

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `PORT` | Service port (default `8002`) |
| `ANI_API_KEY` | Optional security key. If set, clients must pass `X-API-Key: <key>` or `Authorization: Bearer <key>` |

## Quick Start

```bash
cd ani2x-backend
pip install -r requirements.txt
uvicorn main:app --port 8002
```

## Docker

```bash
docker build -t quantum-forge-ani2x .
docker run -p 8002:8002 quantum-forge-ani2x
```
