# Quantum Forge: Data Directory Guide

This directory manages all research datasets, verified reaction trajectories, continual learning replay buffers, and scholarly ledger databases.

## Directory Structure

```
data/
├── verified_literature_trajectories/   # Harvested 3D reaction trajectories (.extxyz)
├── ledgers/                            # SQLite tracking databases for papers & DOIs
├── continual_replay_buffers/           # JSONL experience replay logs from training runs
├── autonomous_training/                # Live directory utilized by autonomous research nodes
├── curated/                            # Curated ASE databases (e.g. t1x_hcno_stride50.db)
├── processed/                          # Processed dataset slices
├── raw/                                # Raw benchmark indices (test_idx.json, val_idx.json)
├── runs/                               # Training execution outputs and metric logs
└── splits/                             # Zero-data-leakage train/val/test splits
```

## Dataset Specifications

1. **`verified_literature_trajectories/`**:
   - Contains 364+ independently verified reaction pathways extracted from peer-reviewed scientific literature.
   - Stored in extended XYZ format (`.extxyz`) with full atomic coordinates, forces, charges, and energies.
   - Invariants verified: total atom conservation, net charge neutrality, and spin multiplicity bounds.

2. **`ledgers/`**:
   - `literature_ledger.sqlite`: Tracks every paper harvested via DOI, publication metadata, extraction status, and verification hashes.

3. **`continual_replay_buffers/`**:
   - Houses chronological JSONL replay buffers capturing model predictions, energy barriers, and continual fine-tuning milestones.
