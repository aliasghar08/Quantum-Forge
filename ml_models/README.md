# Quantum Forge Centralized Machine Learning Models Repository (`ml_models/`)

This directory houses all neural potentials, machine learning surrogate models, and training pipelines utilized across Quantum Forge's clinical simulation and quantum chemistry ecosystems.

## Directory Structure Overview

* **[`tx1_painn_ensemble/`](./tx1_painn_ensemble/)**: 5-member rotation-equivariant PaiNN-Lite MLIP ensemble for reaction potential energy surfaces, activation energies, and atomic forces.
* **[`pharma_bionet/`](./pharma_bionet/)**: Multi-task neural pharmacology network for mechanism of action (MoA), cross-species bioavailability, and curriculum routing.
* **[`continual_learning/`](./continual_learning/)**: Replay buffer pipelines and fine-tuned checkpoints from autonomous continuous literature harvesting.
* **[`external_mlips/`](./external_mlips/)**: Configurations and model loaders for foundation MLIPs (MACE-MP-0, ANI-2x, CHGNet, GFN2-xTB).
* **[`cardio_electrophysiology/`](./cardio_electrophysiology/)**: CardioCath 3D Lab AI suite (CardioPINN, CardioElectrophys, CardioNephroGNN, CardioFNO, CardioRotor).
* **[`neurology_ai/`](./neurology_ai/)**: NeuroLab 3D AI suite (WholeNeuro-Connectome, SynapseNet-Axon, NeuroSpikeNet, NeuroFNO-Perfusion, NeuroBBB-GNN).
* **[`nephrology_ai/`](./nephrology_ai/)**: NephroLab 3D AI suite (NephroPINN-Glomerular, NephroTox-GNN, DialysisKineticsNet).
* **[`client_algorithms/`](./client_algorithms/)**: On-device Dart neural trajectory compression and multi-head geometric self-attention algorithms.

Refer to [`docs/ML_MODELS_INVENTORY.md`](../docs/ML_MODELS_INVENTORY.md) for full mathematical profiles and calibration metrics.
