# Quantum Forge: Cloud Infrastructure & Deployment

This directory consolidates all cloud deployment specifications, container build definitions, and cloud orchestration scripts for Quantum Forge on Google Cloud Platform (GCP).

## Directory Structure

```
infrastructure/
├── cloudbuild/                  # Google Cloud Build trigger specifications
│   └── cloudbuild_harvester.yaml
└── gcp/                         # Google Cloud Platform provisioning scripts
    ├── create_spot_vm.sh        # Compute Engine Spot VM creation
    ├── sweep_on_vm.sh           # Hyperparameter sweeps on remote instances
    ├── sync_from_gcs.sh         # Pull artifacts from Google Cloud Storage
    ├── sync_to_gcs.sh           # Push checkpoints to Google Cloud Storage
    ├── train_ensemble_on_vm.sh  # Distributed ensemble training launcher
    └── train_on_vm.sh           # Single-node VM training launcher
```

## Cloud Microservices Summary

| Service Name | Platform | Region | Description |
| --- | --- | --- | --- |
| `quantum-forge-seeder` | Cloud Run | `us-central1` | 24/7 background streamer continuously growing the 2.85M+ reaction library in Firestore. |
| `neurolab-backend` | Cloud Run | `us-central1` | Hodgkin-Huxley & PyTorch neuro-electrophysiology solver. |
| `nephrolab-backend` | Cloud Run | `us-central1` | Stewart Stewart-Hamilton acid-base, GFR, & nephron transport solver. |
| `cardiocath-backend` | Cloud Run | `us-central1` | Wiggers diagram & cardiac hemodynamics solver. |
| `tx1-fastapi-backend` | Cloud Run | `us-central1` | TX1 PaiNN-Lite MLIP ensemble & molecular potential backend. |
| `quantum-forge-harvester`| Cloud Build / Run | `us-central1` | Autonomous academic literature harvester & ingester. |
