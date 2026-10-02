# MACE-MP-0 Foundation Potential Microservice

FastAPI compute service for the **MACE-MP-0** (Molecular Atomic Cluster Expansion for Materials Project) neural network potential, providing energy, force, and geometry relaxation endpoints for Quantum Forge.

## Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check & model status |
| `POST` | `/predict` | Predict potential energy (eV) and forces (eV/Å) |
| `POST` | `/relax` | Geometry optimization / relaxation via ASE BFGS |
| `GET` | `/docs` | Interactive Swagger API documentation |

## Environment & API Keys

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `PORT` | Service port (default `8001`) |
| `MACE_API_KEY` | Optional security key. If set, clients must pass `X-API-Key: <key>` or `Authorization: Bearer <key>` |
| `HF_TOKEN` | Hugging Face user access token (get from [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)) |
| `MACE_MODEL_SIZE` | `small`, `medium` (default), or `large` |

## Quick Start

```bash
cd mace-backend
pip install -r requirements.txt
uvicorn main:app --port 8001 --reload
```

## Docker

```bash
docker build -t quantum-forge-mace .
docker run -p 8001:8001 -e HF_TOKEN="your_token" quantum-forge-mace
```
