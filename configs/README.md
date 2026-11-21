# Quantum Forge: Configuration Management

This directory organizes all environment-specific configurations, hyperparameters, and infrastructure profiles for Quantum Forge.

## Directory Layout

```
configs/
├── production/          # Production deployment profiles
│   └── mace_gcp_production.yaml
├── local_dev/            # Local workstation development settings
│   └── mace_local_dev.yaml
└── testing/              # Continuous integration & smoke test profiles
    └── mace_local_smoke.yaml
```

## Profiles

### 1. `production/mace_gcp_production.yaml`
- Target: Google Cloud Platform (Compute Engine Spot VMs & Cloud Run)
- Optimizations: Multi-GPU distributed training, full batch size, FP32/BF16 mixed precision, automated checkpoint upload to GCS buckets.

### 2. `local_dev/mace_local_dev.yaml`
- Target: Local Developer Workstations (macOS Apple Silicon / Linux CUDA)
- Optimizations: Metal Performance Shaders (MPS) or single-device CUDA, medium batch sizes, periodic local checkpointing.

### 3. `testing/mace_local_smoke.yaml`
- Target: CI/CD Pipelines & Unit Test Suites
- Optimizations: Minimal synthetic dataset slices, 1-2 epochs, instant execution for rapid regression testing.

> **Backward Compatibility**: Root-level aliases are preserved to ensure legacy deployment scripts resolve without errors.
