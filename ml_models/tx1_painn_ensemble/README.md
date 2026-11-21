# TX1 PaiNN-Lite MLIP Ensemble

The `tx1_painn_ensemble` is the flagship machine-learning interatomic potential (MLIP) powering Quantum Forge's 3D reaction simulation engine.

## Subdirectories

* **`checkpoints/`**: Contains the active 5-member ensemble weights (`member_0.pt` through `member_4.pt`), calibration metadata (`ensemble_metadata.json`), and standalone checkpoints (`t1x_model_checkpoint_v2b.pt`, `t1x_model_checkpoint_v2a.pt`).
* **`backups/`**: Historical training epoch checkpoints (`*.epoch20.pt`, etc.).
* **`architecture/`**: Complete model architectures including `painn.py` (PaiNN-Lite equivariant network) and `legacy_gnn.py` (distance-based molecular graph network).
* **`training/`**: `mps_trainer.py` (Apple Silicon M1 Pro MPS trainer), `train_ensemble.py`, and `calibrate_uncertainty.py`.

## Architecture Specifications

* **Parameter Count per Member:** 165,473 parameters (Total: 827,365 parameters across 5 members)
* **Invariant & Equivariant Features:** 64-dimensional scalar channel, $64 \times 3$ equivariant vector channel
* **Radial Basis Functions:** 32 Gaussian RBFs from $0.5\text{ \AA}$ to $6.0\text{ \AA}$ with cosine cutoff
* **Ensemble Epistemic Uncertainty:** $\sigma_E = \text{std}(E_1, \dots, E_5)$
