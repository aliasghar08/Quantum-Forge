# Quantum Forge Search Microservice (`quantum-forge-search`)

Standalone high-throughput neural and hybrid search microservice for Quantum Forge.
Completely isolated from `tx1-fastapi-backend` (Equivariant PaiNN physics inference) to support massive public concurrent search queries.

## Architecture

- **Engine**: FastAPI + Uvicorn + PyTorch + NumPy BLAS.
- **Neural Model**: `PharmaChemSearchNet` (128-d Bi-Encoder + 6-feature Cross-Reranker).
- **Catalog**: In-memory vector matrix over 25,000+ verified literature records, clinical medicines, and curriculum templates (`models/semantic_catalog.npz`).
- **Endpoints**:
  - `GET /health`: Healthcheck, catalog vector count, and thread pool metrics.
  - `POST /api/search/semantic`: Vectorized BLAS dot-product neural retrieval in < 35 ms.
  - `POST /api/search/hybrid`: Server-side parallel multi-leg search combining neural retrieval, Firestore tokens, and legacy prefix scans.
  - `POST /api/search/self-heal`: Asynchronous background patching for unindexed legacy documents.

## Local Execution

```bash
uvicorn main:app --host 0.0.0.0 --port 8006
```

## Cloud Run Deployment

```bash
gcloud run deploy quantum-forge-search \
  --image us-central1-docker.pkg.dev/quantom-forge/quantom-forge-repo/quantum-forge-search:latest \
  --platform managed \
  --region us-central1 \
  --cpu 2 --memory 2Gi \
  --min-instances 1 --max-instances 10 \
  --concurrency 32 \
  --no-invoker-iam-check
```
