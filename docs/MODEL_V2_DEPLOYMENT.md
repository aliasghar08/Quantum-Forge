# Quantum Forge — Transition1x GNN Model v2 Deployment Runbook

**Target Audience:** DevOps, Machine Learning Engineers, Platform Operators  
**Cloud Run Service:** `quantom-forge-gnn` (`us-central1`)  
**Production URL:** `https://quantom-forge-gnn-227207155336.us-central1.run.app`  
**Web Frontend:** `https://quantom-forge.web.app`  
**Previous Stable Revision:** `quantom-forge-gnn-00007-cjg`

---

## 1. Overview & Architectural Progression

Transition1x GNN Model v2 advances the production potential from the legacy distance-only baseline to an equivariant PaiNN-lite architecture equipped with calibrated uncertainty quantification (UQ).

| Metric / Dimension | Baseline v1 (`tx1-fastapi`) | Architecture v1 (`tx1-v2a`) | Equivariant v2b (`tx1-v2b`) | Calibrated Ensemble (`tx1-v2`) |
|---|---|---|---|---|
| **Architecture** | Distance-only MLP | Gaussian RBF + Cosine Cutoff | PaiNN-lite Equivariant | 5-Member PaiNN Ensemble |
| **Parameters** | 186,113 | 186,113 | 473,089 | 473,089 × 5 (with temp scaling) |
| **Barrier MAE** | 315.00 kcal/mol | 11.44 kcal/mol (27× improvement) | 2.26 kcal/mol (139× improvement) | < 2.0 kcal/mol |
| **Uncertainty** | None (N/A) | None (N/A) | None (N/A) | Calibrated 1σ & 2σ Gaussian coverage |
| **Storage / Memory** | 2.26 MB | 2.26 MB | 2.03 MB | ~10.2 MB total (< 30 MB target) |
| **Inference CPU (20-atom)** | ~50 ms | ~50 ms | ~90 ms | ~340 ms (< 500 ms target) |

All strategies coexist behind the versioned `strategy` parameter and `mlip_registry`, ensuring zero breaking changes for existing API consumers and frontends.

---

## 2. Pre-Deployment Verification Checklist

Before pushing to Google Cloud Build, ensure all local tests pass:

```bash
cd tx1-fastapi-backend

# 1. Run full test suite
./venv/bin/python -m pytest tests/ -v

# 2. Verify all models and metadata exist
ls -lh models/ensemble_v2/
test -f models/ensemble_metadata.json
test -f t1x_model_checkpoint.pt
test -f t1x_model_checkpoint_v2a.pt
test -f t1x_model_checkpoint_v2b.pt
```

---

## 3. Step-by-Step Deployment Sequence

### Step 1 — Build & Container Image Submission
Submit the Docker build to Google Cloud Artifact Registry / Container Registry:

```bash
cd tx1-fastapi-backend

gcloud builds submit \
  --project quantom-forge \
  --tag us-central1-docker.pkg.dev/quantom-forge/quantom-forge-repo/quantom-forge-gnn:v2 .
```

*Note: Ensure `.dockerignore` permits `models/ensemble_v2` and `t1x_model_checkpoint*.pt` so checkpoints are bundled directly into the container image.*

### Step 2 — Deploy to Cloud Run (Canary / Dry-Run)
Deploy the container with 0% or initial traffic, keeping default strategy as `tx1-fastapi`:

```bash
gcloud run deploy quantom-forge-gnn \
  --project quantom-forge \
  --image us-central1-docker.pkg.dev/quantom-forge/quantom-forge-repo/quantom-forge-gnn:v2 \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --concurrency 40
```

### Step 3 — Verify `/health` Endpoint
Check that all strategies are loaded and digests are reported:

```bash
curl -s https://quantom-forge-gnn-227207155336.us-central1.run.app/health | jq .
```

Expected response structure:
```json
{
  "status": "ok",
  "strategies_loaded": [
    "tx1-fastapi",
    "tx1-v2a",
    "tx1-v2b",
    "tx1-v2"
  ],
  "checkpoint_digests": {
    "tx1-fastapi": "sha256:...",
    "tx1-v2a": "sha256:...",
    "tx1-v2b": "sha256:...",
    "tx1-v2": "ensemble: [sha256:..., ...]"
  }
}
```

### Step 4 — Smoke Test Single & Batch Predictions
Verify `/predict` returns calibrated uncertainty when `mlip_model="tx1-v2"`:

```bash
curl -s -X POST https://quantom-forge-gnn-227207155336.us-central1.run.app/predict \
  -H "Content-Type: application/json" \
  -d '{
    "atomic_numbers": [8, 1, 1],
    "positions": [[0.0, 0.0, 0.0], [0.0, 0.75, 0.58], [0.0, -0.75, 0.58]],
    "mlip_model": "tx1-v2"
  }' | jq .
```

Verify `/predict/batch`:
```bash
curl -s -X POST https://quantom-forge-gnn-227207155336.us-central1.run.app/predict/batch \
  -H "Content-Type: application/json" \
  -d '{
    "molecules": [
      {
        "atomic_numbers": [8, 1, 1],
        "positions": [[0.0, 0.0, 0.0], [0.0, 0.75, 0.58], [0.0, -0.75, 0.58]]
      }
    ],
    "strategy": "tx1-v2"
  }' | jq .
```

### Step 5 — Frontend Validation & Web Deployment
1. Test frontend with strategy set to `tx1-v2` in the Compute settings dropdown.
2. Verify uncertainty badge (`±X.X kcal/mol`) renders next to the energy profile (amber styling if > 5 kcal/mol).
3. Deploy frontend to Firebase Hosting:
```bash
cd quantum_forge
flutter build web --release
firebase deploy --only hosting --project quantom-forge
```

### Step 6 — 48-Hour Monitoring
Monitor Cloud Run metrics for:
- Request error rate (HTTP 5xx should be < 0.1%).
- Latency (p95 CPU latency < 500 ms for molecules ≤ 20 atoms).
- Memory utilization (< 1.2 GB of the 2.0 GB ceiling).

---

## 4. Rollback Plan

If anomaly or regression occurs post-deployment:

### Level 1: Frontend Fallback (Immediate, < 2 min)
Switch frontend default strategy back to `tx1-fastapi`:
1. In `app_settings_provider.dart`, default `modelStrategy = 'tx1-fastapi'`.
2. Redeploy hosting: `firebase deploy --only hosting`.
3. Backend continues serving existing endpoints without modification.

### Level 2: Cloud Run Traffic Shift (Instant, < 30 sec)
Shift 100% of Cloud Run traffic back to the known good revision:

```bash
gcloud run services update-traffic quantom-forge-gnn \
  --project quantom-forge \
  --region us-central1 \
  --to-revisions=quantom-forge-gnn-00007-cjg=100
```

Verify previous revision is serving:
```bash
curl -s https://quantom-forge-gnn-227207155336.us-central1.run.app/health
```

### Level 3: Checkpoint Retention
Never delete `t1x_model_checkpoint.pt`, `t1x_model_checkpoint_v2a.pt`, or `models/ensemble_v2/*.pt` from local disk or storage. Checkpoint retention guarantees immediate roll-forward and reproducible offline auditing.
