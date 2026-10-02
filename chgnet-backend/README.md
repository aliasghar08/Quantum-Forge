# CHGNet Universal Potential Microservice

FastAPI compute service for **CHGNet** (Crystal Hamiltonian Graph Neural Network), a pretrained universal neural network potential with charge and magnetic moment information for molecules, materials, and crystal structures.

## Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check & model status |
| `POST` | `/predict` | Predict potential energy (eV), forces (eV/Å), stress, and magnetic moments |
| `POST` | `/relax` | Structure relaxation via `StructOptimizer` |
| `GET` | `/docs` | Interactive Swagger API documentation |

## Environment & API Keys

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `PORT` | Service port (default `8003`) |
| `CHGNET_API_KEY` | Optional security key. If set, clients must pass `X-API-Key: <key>` or `Authorization: Bearer <key>` |
| `MP_API_KEY` | Optional Materials Project API key from [next-gen.materialsproject.org/api](https://next-gen.materialsproject.org/api) |

## Quick Start

```bash
cd chgnet-backend
pip install -r requirements.txt
uvicorn main:app --port 8003
```

## Docker

```bash
docker build -t quantum-forge-chgnet .
docker run -p 8003:8003 quantum-forge-chgnet
```
