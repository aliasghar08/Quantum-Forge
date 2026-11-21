# Multi-Backend External MLIPs & Quantum Chemistry Surrogates

Quantum Forge integrates multiple foundation machine learning potentials and semi-empirical quantum methods to provide multi-model cross-validation.

## Supported Engines

1. **`mace/` (MACE-MP-0)**
   * Higher-order equivariant message-passing neural potential.
   * YAML configs: `mace_gcp_production.yaml`, `mace_local_dev.yaml`, `mace_local_smoke.yaml`.
   * Microservice: `mace-backend/`.

2. **`ani2x/` (ANI-2x)**
   * Deep neural network potential for organic molecules (H, C, N, O, S, F, Cl).
   * Microservice: `ani2x-backend/`.

3. **`chgnet/` (CHGNet)**
   * Crystal Hamiltonian Graph Neural Network for inorganic crystal lattices and battery materials.
   * Microservice: `chgnet-backend/`.

4. **`gfn2_xtb/` (GFN2-xTB)**
   * Semi-empirical tight-binding quantum chemistry surrogate for geometry optimization and electronic properties.
   * Microservice: `gfn2-xtb-backend/`.
