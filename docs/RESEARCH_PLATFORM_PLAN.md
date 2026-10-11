# Quantum Forge: Technical Design Document & Implementation Roadmap
## Transforming Quantum Forge into a Research-Grade Computational Chemistry Platform

*Date: October 2026*  
*Target Revision: 3.0.0 Architecture*  
*Document Status: Pending Architecture Review*

---

## Executive Summary

Quantum Forge has established a robust baseline as a web-based reaction path visualizer with Avogadro 2 geometry parity, Cloud Run backend execution, Direct MaxFlux (DMF) path optimization, and a lightweight GNN relative-energy predictor. However, its current scientific depth is constrained: energy predictions rely on a small GNN trained on Transition1x or an uncalibrated MACE-MP-0 fallback; path generation assumes linear synchronous transit (LST) without conformational sampling; kinetics calculations assume rigid gas-phase harmonic models without free-energy sampling; and mechanisms cannot be discovered autonomously.

This technical design document outlines a rigorous 6-phase engineering roadmap to evolve Quantum Forge into an enterprise- and research-grade computational chemistry platform that exceeds standalone Avogadro 2 in analytical depth and provides a modern web-native counterpart to commercial suites like Schrödinger Maestro, BIOVIA Materials Studio, and Cresset Flare.

---

# Part 1 — State-of-the-Art Survey (2025–2026)

### 1.1 Machine-Learned Interatomic Potentials (MLIPs)
* **Current State of the Art:**
  Over the 2024–2026 horizon, equivariant message-passing neural networks operating over Euclidean groups $\mathrm{SE}(3)$ and $\mathrm{SO}(3)$ have decisively surpassed invariant models (e.g., SchNet, PaiNN, ANI-2x) in force accuracy and generalizability.
  * **MACE (Batatia et al., 2022; Kovács et al., 2023):** Higher-order body-order expansion using tensor products of spherical harmonics. **MACE-OMol25** (2025), trained on millions of diverse molecular conformers and reaction transition states, demonstrates a 96.6% success rate on automated transition-state (TS) searches on the TS1x benchmark with barrier errors below 1.2 kcal/mol.
  * **UMA (Universal Model for Atoms, 2025):** Successor architecture to MACE and NequIP deployed in Small (~15M parameters) and Medium (~45M parameters) variants, achieving foundation-model transferability across organic molecules, organometallics, and metal clusters.
  * **Allegro (Musaelian et al., 2023):** Strictly local equivariant architecture enabling extreme multi-GPU scaling without global message passing, ideal for explicit solvent simulations.
  * **CACE & NEMP (2024–2025):** Cartesian-tensor equivariant models providing $O(N)$ efficiency for large biomolecular complexes.
* **Practical Integration in 2025:**
  MACE-OMol25 and UMA-Medium can both be loaded directly via PyTorch/ASE calculators. Model weights range from 80 MB to 220 MB, well within Cloud Run container constraints (unlike 7B+ parameter multimodal LLMs).
* **Missing in Quantum Forge:**
  The current backend uses `t1x_model_checkpoint.pt` (a 2.2 MB legacy MolecularGraphNetwork) and a stubbed CPU-only `mace_mp(model="small")` trained on bulk crystals (Materials Project), which has severe systematic errors when evaluated on non-equilibrium gas-phase and organic radical transition states.
* **Recommended Integration:**
  Retire `t1x_model_checkpoint.pt` as the default. Standardize on **MACE-OMol25** as the primary molecular MLIP for gas-phase and organic chemistry, with **UMA-Medium** as a secondary option for coordination complexes and heterogeneous materials. Implement deep ensemble variance for intrinsic uncertainty quantification (UQ).

### 1.2 Transition-State (TS) Search
* **Current State of the Art:**
  * **Direct MaxFlux (DMF) (Choi et al., 2023; Quantum Forge backend):** Optimizes reactive trajectories by maximizing flux through the saddle region rather than enforcing equal spring spacing as in Clustered-Nudged Elastic Band (CI-NEB). DMF locates ~98% of TS configurations at 30% of the computational cost of CI-NEB.
  * **CaTS (Catalyst Transition State Screening, 2024):** Integrates equivariant MLIPs with adaptive NEB to screen $10^4$ catalyst surfaces and reaction steps per day.
  * **DRL-Guided Search (2024–2025):** Deep Q-Networks trained on potential energy surface (PES) Hessian eigenvectors that dynamically step along the minimum mode of the Hessian (P-RFO / dimer surrogate).
  * **React-OT (2024–2025):** Generative optimal transport formulation mapping reactant and product atom density manifolds directly to saddle-point probability distributions.
* **Practical Integration in 2025:**
  Expose a Strategy Pattern in the backend orchestrator: DMF as the default, MLIP-accelerated CI-NEB for pathological minimum-energy paths (MEP), and React-OT as a generative warm-start seed for DMF.
* **Missing in Quantum Forge:**
  The backend hardcodes a single path interpolation (LST or IDPP) into DMF. If the atom indexing or initial Cartesian interpolation encounters high steric clash or bad topology, DMF fails or converges to an unphysical dissociative state.
* **Recommended Integration:**
  Multi-Path Direct MaxFlux: Generate multiple candidate topology alignments and React-OT candidate seeds, evaluate parallel DMF trajectories with MACE-OMol25, and return the true minimum-energy saddle point.

### 1.3 Automated Reaction Discovery & Mechanism Search
* **Current State of the Art:**
  * **aRST (Automated Reactive String Technique, 2024):** Screens frontier orbital overlaps and condensed Fukui functions to rank reactive atom pairs, generating steered initial guesses that achieve 97% success on diverse multi-step organic transformations.
  * **ARplorer & PARAMUS (2024–2025):** LLM-orchestrated autonomous agents that iteratively query semiempirical/DFT engines, generate mechanistic hypotheses (e.g., stepwise vs. concerted, carbocation vs. radical), and rank kinetic pathways.
  * **ChemOntology (2025):** Formalized ontological graph representation of chemical reactions allowing machine-verifiable mechanism trees.
* **Practical Integration in 2025:**
  aRST-style atom-pair scoring is fully deterministic and computationally lightweight, requiring only MLIP atomic charges/features and topological distance matrices.
* **Missing in Quantum Forge:**
  The app only processes known reactant $\to$ product pairs supplied by the user or loaded from the static template library. It cannot answer "What can these two molecules form?"
* **Recommended Integration:**
  Add a mechanism enumeration service that generates candidate intermediates and products for arbitrary reactant mixtures via aRST heuristics, automatically chaining elementary reaction steps into a kinetic network.

### 1.4 Enhanced Sampling & Free Energy
* **Current State of the Art:**
  * **OPES (On-the-fly Probability Enhanced Sampling, Invernizzi & Parrinello, 2020/2022):** Rapidly converges free energy profiles along defined collective variables (CVs) by adaptively updating the biasing potential from kernel density estimates of the target distribution.
  * **GaMD (Gaussian Accelerated Molecular Dynamics):** Adds a harmonic boost potential without pre-defining reaction coordinates, accelerating conformational transitions.
  * **OpenFE & ALCHEMD (2024–2025):** Modern open-source Python frameworks for automated Relative and Absolute Binding Free Energy (RBFE / ABFE) using Bennett Acceptance Ratio (BAR) and Multistate BAR (MBAR).
* **Practical Integration in 2025:**
  OpenMM 8.5 with `PythonForce` or `openmm-torch` allows seamless execution of MACE-OMol25 within a state-of-the-art GPU MD engine with PME electrostatics and Langevin integrators.
* **Missing in Quantum Forge:**
  Quantum Forge only reports 0 K electronic energies plus standard gas-phase ideal-gas/rigid-rotor/harmonic-oscillator (RRHO) statistical mechanics. It has zero molecular dynamics or condensed-phase free energy capabilities.
* **Recommended Integration:**
  Integrate OpenMM as a simulation engine. Implement OPES for reaction coordinate free-energy surfaces ($W(\xi)$) and GaMD for flexible conformational ensembles.

### 1.5 Differentiable Chemistry
* **Current State of the Art:**
  * **PySCFAD (2023–2024):** Auto-differentiable quantum chemistry in JAX, allowing direct analytical calculation of nuclear, orbital, and Hamiltonian gradients.
  * **∂-HyMD & msmJAX (2024–2025):** Differentiable molecular dynamics enabling exact backpropagation through simulation trajectories to optimize MLIP parameters or force-field charges directly against experimental thermodynamic observables.
* **Practical Integration in 2025:**
  Full simulation differentiation is compute-intensive for web request-response cycles, but computing analytical Hessians and dipole gradients directly through MLIP autograd graphs is trivial and instantaneous.
* **Missing in Quantum Forge:**
  Frequencies and vibrational modes are currently approximated or mocked; exact Hessian calculation via autograd is missing.
* **Recommended Integration:**
  Use PyTorch autograd over MACE-OMol25 to generate exact analytical Hessians, dipole moment derivatives, and polarizability tensors for all stationary points.

### 1.6 Solvation Modeling
* **Current State of the Art:**
  * **GNNIS (2024):** Graph Neural Network Implicit Solvent trained across 39 organic solvents, matching explicit-solvent thermodynamic free energies without running explicit MD.
  * **ML-PB (2024–2025):** Neural Poisson-Boltzmann surrogates providing continuous dielectric boundary electrostatics in milliseconds.
  * **SMD / CPCM / COSMO-RS:** Classical continuum models widely implemented in ORCA, Gaussian, and xTB.
* **Practical Integration in 2025:**
  SMD via xTB/ORCA wrappers, or analytical GNNIS surrogates directly in Python.
* **Missing in Quantum Forge:**
  The backend has a prototype solvent parameter in `run_reaction`, but it only applies fixed empirical scaling rather than rigorous thermodynamic cycle corrections ($\Delta G_{\text{solv}}$).
* **Recommended Integration:**
  Deploy GNNIS for real-time solvent shifts ($\Delta \Delta G_{\text{solv}}$) on Cloud Run, and generate ORCA/Gaussian SMD input decks for rigorous handoff.

### 1.7 Spectroscopy & Analytical Chemistry
* **Current State of the Art:**
  * **TranSpec & successors (2024–2025):** Transformer models trained on millions of experimental spectra predicting IR, Raman, and $^{13}\text{C}/^{1}\text{H}$ NMR chemical shifts with $>92\%$ match to experimental benchmarks.
  * **MLIP Hessian + Dipole Derivation:** Harmonic frequencies ($\omega_i$) and IR intensities ($I_i \propto |\partial \vec{\mu}/\partial Q_i|^2$) calculated in seconds from MLIP autograd.
* **Practical Integration in 2025:**
  Exact harmonic IR and Raman spectra computed directly on the backend using MACE-OMol25; NMR chemical shift prediction via GNN surrogates (e.g., Cascade or NMRShiftML2).
* **Missing in Quantum Forge:**
  No spectroscopy prediction exists in the frontend or backend.
* **Recommended Integration:**
  Add a dedicated `SpectroscopyViewer` in the Flutter frontend with interactive IR/Raman peaks, vibrational mode vector animation, and NMR stick spectra with experimental overlay.

### 1.8 Protein-Ligand Binding & Macromolecular Affinity
* **Current State of the Art:**
  * **DeepBindAffinity & TUNA (2024–2025):** Multimodal geometric deep learning models that ingest receptor PDB coordinates and ligand SMILES to predict binding affinity ($\mathrm{p}K_d / \mathrm{p}K_i$) with Pearson $r > 0.82$.
  * **DiffDock-Pocket / Boltz-1 (2024–2025):** Diffusion models predicting bound ligand poses in seconds without classical docking grid precomputation.
* **Practical Integration in 2025:**
  Deploying a containerized inference pipeline for binding affinity prediction and pose scoring on target proteins.
* **Missing in Quantum Forge:**
  Quantum Forge is strictly limited to small molecules ($N < 150$ atoms).
* **Recommended Integration:**
  Incorporate a macromolecular pipeline capable of loading PDB files, defining active site centroids, and running binding affinity screening.

### 1.9 Conformational Search & Sampling
* **Current State of the Art:**
  * **CREST (Grimme et al.):** Metadynamics (MTD) with GFN2-xTB and genetic z-matrix crossing; gold standard for small-to-medium flexible molecules.
  * **Tensor Train Optimization & MLIP-CREST (2024–2025):** 10-fold acceleration of conformer ensemble generation using MACE as the PES evaluator.
* **Practical Integration in 2025:**
  Fast RDKit ETKDGv3 conformer generation followed by MACE-OMol25 batch minimization and pruning by energy window ($\Delta E < 3.0\text{ kcal/mol}$) and heavy-atom RMSD ($> 0.35\text{ \AA}$).
* **Missing in Quantum Forge:**
  The app operates on a single rigid conformer. If the user draws or imports a high-energy rotamer, all subsequent reaction barriers are fundamentally corrupted.
* **Recommended Integration:**
  Pre-reaction conformational search pipeline: automatically find the global minimum and Boltzmann ensemble for both reactants and products prior to path generation.

---

# Part 2 — Target System Architecture

```
                                  ┌─────────────────────────────────────────┐
                                  │   Avogadro 2 Desktop (macOS/Win/Linux)  │
                                  │  [EnergyModel, InputGen, TSSearch, Lib] │
                                  └────────────────────┬────────────────────┘
                                                       │ REST / DeepLink
                                                       ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   Quantum Forge Flutter Web Client                                     │
│  ┌───────────────────────────┬───────────────────────────┬──────────────────────────────────────────┐  │
│  │   2D/3D Molecule Canvas   │  Interactive Reaction TS  │         Spectroscopy & Analytics         │  │
│  │    (NGL + Avogadro Parity)│    (Playback, Playhead)   │     (IR/Raman Curves, NMR Sticks)        │  │
│  ├───────────────────────────┴───────────────────────────┴──────────────────────────────────────────┤  │
│  │                  Plugin & Compute Control Center (Strategy Selectors, UQ Panels)                 │  │
│  └─────────────────────────────────────────────┬────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────┼───────────────────────────────────────────────────────┘
                                                 │ HTTPS / JSON RPC
                                                 ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              Quantum Forge FastAPI Compute Backend                                     │
│  ┌──────────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                 Strategy Dispatch & Orchestrator                                 │  │
│  │            (Routes requests by task: TS Search, MD, Spectroscopy, Reactivity Screening)          │  │
│  └──────┬──────────────────────┬──────────────────────┬───────────────────────┬─────────────────────┘  │
│         │                      │                      │                       │                        │
│         ▼                      ▼                      ▼                       ▼                        ▼
│  ┌──────────────┐      ┌──────────────┐       ┌──────────────┐        ┌──────────────┐        ┌──────────────┐ │
│  │ MLIP Plugins │      │  TS Plugins  │       │  MD & Sampl. │        │ Property/QC  │        │ Reaction Dis.│ │
│  │ - MACE-OMol25│      │ - Multi-DMF  │       │ - OpenMM     │        │ - PyTorch    │        │ - aRST       │ │
│  │ - UMA-Medium │      │ - CI-NEB     │       │ - OPES       │        │   Hessian    │        │ - Frontier   │ │
│  │ - MACE-MP-0  │      │ - React-OT   │       │ - GaMD       │        │ - GNNIS Solv │        │   Orbitals   │ │
│  │ - Ensemble UQ│      │   Warmstart  │       │ - ALCHEMD    │        │ - NMR ML     │        │ - React-Tree │ │
│  └──────────────┘      └──────────────┘       └──────────────┘        └──────────────┘        └──────────────┘ │
└────────────────────────────────────────────────┬───────────────────────────────────────────────────────┘
                                                 │ Async Jobs / Sync Artifacts
                                                 ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     Data, Provenance & Storage                                         │
│  ┌───────────────────────────────────────────────┬──────────────────────────────────────────────────┐  │
│  │                 Google Cloud Run              │                Google Cloud Firestore            │  │
│  │  - Primary CPU/GPU API Service                │  - /library: Reaction templates & curated sets   │  │
│  │  - Cloud Run Jobs (Asynchronous FEP/MD/CREST) │  - /corrections: Active learning DFT refinement  │  │
│  │  - Container Artifact Registry (Digest/SHA)   │  - /simulations: User runs, provenance & UQ      │  │
│  └───────────────────────────────────────────────┴──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.1 Backend Plugin Interface Specification
To achieve true extensibility, every computational capability must implement a typed Python `Protocol`:

```python
# app/core/protocols.py
from typing import Protocol, runtime_checkable
import numpy as np

@runtime_checkable
class MLIPPlugin(Protocol):
    name: str
    version: str
    citation: str

    def is_available(self) -> bool: ...
    def load(self, device: str = "cpu") -> None: ...
    def energy_ev(self, atomic_numbers: list[int], positions: list[list[float]]) -> float: ...
    def forces_ev_ang(self, atomic_numbers: list[int], positions: list[list[float]]) -> np.ndarray: ...
    def uncertainty_ev(self, atomic_numbers: list[int], positions: list[list[float]]) -> float | None: ...
    def hessian_ev_ang2(self, atomic_numbers: list[int], positions: list[list[float]]) -> np.ndarray: ...

@runtime_checkable
class TSSearchPlugin(Protocol):
    name: str
    def search(
        self,
        r_numbers: list[int],
        r_coords: list[list[float]],
        p_coords: list[list[float]],
        mlip: MLIPPlugin,
        options: dict
    ) -> dict: ...
```

### 2.2 Standard Provenance & Structured Result Envelope
Every computational payload returned to the frontend or exported to Avogadro is wrapped in a strict JSON schema:

```json
{
  "status": "success",
  "result": {
    "barrier_forward_ev": 1.182,
    "barrier_reverse_ev": 0.421,
    "reaction_energy_ev": -0.761,
    "trajectory_frames": ["16\nFrame 0...", "..."],
    "ts_frame_index": 54,
    "frequencies_cm1": [-482.1, 88.4, 120.2],
    "imaginary_modes_count": 1
  },
  "uncertainty": {
    "barrier_std_ev": 0.042,
    "confidence_level": 0.95,
    "calibration_source": "MACE-OMol25-Ensemble-4x"
  },
  "provenance": {
    "model_name": "MACE-OMol25",
    "model_version": "2025.1",
    "method": "DirectMaxFlux-v2",
    "git_sha": "b9472a6",
    "container_digest": "sha256:7f83b1...",
    "timestamp_utc": "2026-10-08T21:40:00Z",
    "wall_time_seconds": 3.82,
    "compute_device": "CloudRun-GPU-NVIDIA-L4"
  }
}
```

### 2.3 Firestore Extended Data Model
* **`library/{templateId}`:** Extended with `conformerEnsemble`, `spectroscopy` (IR/Raman frequencies), and `calibratedBarrier`.
* **`corrections/{correctionId}`:** Stores active learning corrections: `smiles`, `geometry_xyz`, `mlip_energy_ev`, `dft_energy_ev`, `dft_level_of_theory`, `timestamp`.
* **`simulations/{simId}`:** Records complete user runs with provenance, parameters, and uncertainty bounds.

---

# Part 3 — Detailed Implementation Roadmap (Phases 0–6)

### Phase 0: Foundation & Core Extensibility (Effort: 5 Engineering Days)
* **Objective:** Decouple monolithic routines in `tx1-fastapi-backend/main.py` into a modular plugin registry; implement structured provenance envelopes; build the frontend compute-settings UI.
* **Deliverables:**
  1. `app/core/protocols.py` defining `MLIPPlugin`, `TSSearchPlugin`, `SolvationPlugin`, `PropertyPlugin`.
  2. `app/core/registry.py` with automatic discovery under `app/plugins/`.
  3. `GET /plugins` endpoint exposing capabilities, descriptions, and citations.
  4. Migration of `Tx1Calculator` and `MaceCalculator` to implement `MLIPPlugin`.
  5. Flutter `Settings ▸ Compute ▸ Plugins` screen displaying installed engines and active selection.
* **Dependencies:** None (uses existing codebase).
* **Risks & Mitigation:**
  * *Risk:* Regressions on existing `/predict` and `/reactions/submit`.
  * *Mitigation:* Comprehensive contract tests verifying backward compatibility with legacy request shapes.
* **Acceptance Criteria:**
  * All existing endpoints function identically.
  * `GET /plugins` enumerates installed engines.
  * Response payloads match the provenance envelope schema.
* **Cost Impact:** Zero incremental cost.

---

### Phase 1: Modern Equivariant MLIPs & Uncertainty Quantification (Effort: 10 Engineering Days)
* **Objective:** Upgrade backend to MACE-OMol25; implement 4-head ensemble UQ; build the automated active learning collection pipeline.
* **Deliverables:**
  1. `MaceOMol25Plugin` implementing energy, analytical autograd forces, and ensemble variance.
  2. UMA-Medium fallback plugin for periodic/organometallic species.
  3. Automated benchmark suite evaluating 20 diverse organic reactions comparing Transition1x, MACE-MP-0, and MACE-OMol25 against reference DFT barriers.
  4. Active-learning trigger in `main.py`: when $\sigma_{\text{barrier}} > 0.1\text{ eV}$ (2.3 kcal/mol), the system flags the TS for DFT refinement and logs the candidate to Firestore `/corrections`.
* **Dependencies:** Phase 0 plugin registry.
* **Risks & Mitigation:**
  * *Risk:* Container image exceeds Cloud Run 4 GB limit; cold-start latency spikes.
  * *Mitigation:* Pin torch-cpu or CUDA 12 wheel slices; pre-cache weights in `/opt/weights` during Docker build stage; use lazy warm-up on container initialization.
* **Acceptance Criteria:**
  * MACE-OMol25 achieves MAE $< 1.5\text{ kcal/mol}$ on the 20-reaction benchmark.
  * Every energy response returns a non-null `barrier_std_ev`.
* **Cost Impact:** Minor storage increase in Artifact Registry ($< \$1.00/\text{mo}$).

---

### Phase 2: Reaction Discovery & Conformer-Aware Multi-Path Search (Effort: 15 Engineering Days)
* **Objective:** Implement aRST reactive atom-pair scoring, multi-path candidate enumeration, and automated pre-reaction conformational relaxation.
* **Deliverables:**
  1. `ConformerSearchPlugin`: RDKit ETKDGv3 + MACE-OMol25 batch relaxation returning lowest-energy rotamers for reactant and product states.
  2. `aRSTReactivityScorer`: Computes condensed Fukui indices and geometric distance bounds to rank plausible reactive atom pairs.
  3. Multi-path DMF: Generates $N=3$ independent atom-mapped path seeds (including React-OT candidate seeds) and executes parallel local optimizations, returning the lowest-barrier transition state.
  4. Frontend UI extension: Multi-path comparison card displaying competing reaction channels and predicted kinetic branching ratios ($k_1 / k_2 = e^{-\Delta \Delta G^\ddagger / RT}$).
* **Dependencies:** Phase 1 (MACE-OMol25 required for reliable multi-path gradients).
* **Risks & Mitigation:**
  * *Risk:* Multi-path optimization exceeds Cloud Run 60-second HTTP timeout.
  * *Mitigation:* Multi-path execution parallelized across PyTorch threads; max path steps capped with early stopping when energy exceeds $4\text{ eV}$.
* **Acceptance Criteria:**
  * Test on Diels-Alder, Retro-DA, Decarboxylation, and E2 Elimination converges correctly regardless of initial rotamer input.
  * Multi-path ranking correctly differentiates 1,2- vs 1,4-addition or kinetic vs thermodynamic pathways.
* **Cost Impact:** Compute time increases from ~1.2s to ~3.5s per reaction submission; well within standard Cloud Run free-tier quotas.

---

### Phase 3: Enhanced Sampling & Free Energy Workflows (Effort: 20 Engineering Days)
* **Objective:** Move beyond 0 K gas-phase electronic energies by integrating OpenMM 8.5 for OPES metadynamics and automated relative binding free energy (RBFE).
* **Deliverables:**
  1. OpenMM integration via `openmm-torch` driving MACE-OMol25 MLIP forces in explicit or implicit solvent.
  2. `OPESPlugin`: Biased dynamics along user-defined CVs (e.g., bond distance, dihedral, coordination number) generating potential-of-mean-force (PMF) free-energy curves.
  3. `GaMDPlugin`: Unbiased conformational ensemble generator for flexible macrocycles and drug candidates.
  4. Relative Binding Free Energy (RBFE) script using OpenFE architecture, generating thermodynamic cycle perturbation maps.
  5. Cloud Run Job definition (`quantom-forge-worker`) for asynchronous execution of long MD trajectories ($> 1\text{ ns}$).
* **Dependencies:** Phase 1 (accurate forces required for stable integration steps).
* **Risks & Mitigation:**
  * *Risk:* Long MD simulations fail on serverless HTTP timeouts.
  * *Mitigation:* Long simulations ($> 100\text{ ps}$) strictly routed to Cloud Run Jobs or executed on local user hardware via the Avogadro bridge.
* **Acceptance Criteria:**
  * OPES recovers the torsional barrier of butane ($\sim 5.4\text{ kcal/mol}$) within $0.3\text{ kcal/mol}$ in under 100 ps.
  * Results include block-averaged statistical uncertainty ($\pm \sigma_{\Delta G}$).
* **Cost Impact:** Cloud Run Jobs billed per-second on GPU (NVIDIA L4 $\sim \$0.70/\text{hr}$); user quota controls enforced via Firestore.

---

### Phase 4: Advanced Properties & Spectroscopy (Effort: 10 Engineering Days)
* **Objective:** Provide experimental chemists with direct laboratory points of comparison by predicting IR, Raman, NMR spectra, and aqueous $\mathrm{p}K_a$.
* **Deliverables:**
  1. Analytical Hessian module computing mass-weighted force constant matrices, vibrational frequencies, and zero-point vibrational energies (ZPVE).
  2. IR/Raman intensity engine deriving dipole moment derivatives from MLIP autograd.
  3. GNN-based $^{1}\text{H}$ and $^{13}\text{C}$ NMR chemical shift predictor with TMS referencing.
  4. Machine-learned empirical $\mathrm{p}K_a$ predictor for organic Brønsted acids and bases.
  5. Interactive Flutter widget: `SpectroscopyPanel` with zoomable Lorentzian-broadened IR absorption curves and peak inspection.
* **Dependencies:** Phase 1 (MACE-OMol25 analytical autograd).
* **Risks & Mitigation:**
  * *Risk:* Second derivatives (Hessian) via autograd scale as $O(3N)$ backward passes, causing high memory usage for molecules $> 60$ atoms.
  * *Mitigation:* Use double-precision finite differences of analytical forces or batched autograd vector-Hessian products (`torch.func.vhp`).
* **Acceptance Criteria:**
  * Harmonic frequencies match standard benchmark DFT vibrational frequencies with $R^2 > 0.98$ and typical scaling factor $\sim 0.96$.
  * IR spectrum of cyclohexene displays characteristic $\text{C}=\text{C}$ stretch ($1650\text{ cm}^{-1}$) and $\text{C}-\text{H}$ stretches ($2850\text{--}3050\text{ cm}^{-1}$).
* **Cost Impact:** Negligible.

---

### Phase 5: Original Algorithms & Research Contributions (Effort: 20 Engineering Days)
* **Objective:** Implement and benchmark novel algorithms that advance the state of computational chemistry. Detailed in Part 4.
* **Deliverables:**
  1. Active-Learning Mechanism Discovery (AL-MD) algorithm.
  2. Physics-Informed Transition State Embedding (PI-TSE) transformer.
  3. Multi-Modal Spectrum-to-Structure Elucidation engine.
* **Dependencies:** Phases 0, 1, 2, and 4.
* **Acceptance Criteria:**
  * Peer-review ready validation datasets and comparative benchmarks against conventional tools.

---

### Phase 6: Extended Avogadro 2 Plugin Ecosystem (Effort: 10 Engineering Days)
* **Objective:** Convert Quantum Forge from a web destination into the primary compute engine for the desktop Avogadro 2 application.
* **Deliverables:**
  1. `EnergyModelPlugin`: Avogadro 2 AutoOptimization tool delegates energy and force evaluation to Quantum Forge (`/predict?forces=true`), enabling live MACE-OMol25 interactive optimization inside Avogadro's 3D viewport.
  2. `TSSearchPlugin`: Menu action `Extensions ▸ Quantum Forge ▸ Transition State Search` that sends active molecule and target to the backend and streams the resulting trajectory back into Avogadro's coordinate frames.
  3. `InputGeneratorPlugin`: Generates validated input decks for ORCA 6.0, Gaussian 16, Q-Chem 6, and Psi4 with automatic dispersion and solvent corrections.
  4. `ReactionLibraryBrowser`: Interactive modal inside Avogadro to search and fetch templates directly from the Firestore collection.
  5. Packaging: Cross-platform Pixi recipe (`pixi.toml`) allowing 1-command installation on macOS, Windows, and Linux.
* **Dependencies:** Phases 0 and 1.
* **Risks & Mitigation:**
  * *Risk:* Desktop Avogadro network timeouts on high-latency internet connections.
  * *Mitigation:* Implement asynchronous polling with progress dialogs and local caching of computed energies.
* **Acceptance Criteria:**
  * User can run interactive real-time structure minimization in Avogadro powered by Cloud Run MACE-OMol25 at $\ge 15\text{ FPS}$ for molecules under 50 atoms.
* **Cost Impact:** Zero infrastructure cost; leverages existing API endpoints.

---

# Part 4 — Original Algorithm Proposals

### Proposal A: Uncertainty-Aware Reactive Network Discovery (U-RND)
* **Literature Grounding:**
  Combines the graph-theoretical reactivity rules of aRST (*J. Chem. Theory Comput.* 2024), the multi-agent hypothesis generation of PARAMUS (*Chem. Sci.* 2025), and deep ensemble uncertainty quantification (*Nature Mach. Intell.* 2023).
* **Novelty Claim:**
  Existing automated reaction discovery algorithms either rely entirely on costly DFT (taking weeks) or blindly trust MLIPs (leading to unphysical reaction pathways when the potential extrapolates outside its training domain). U-RND introduces **Autonomous Epistemic Gatekeeping**: the network grows rapidly using MACE-OMol25; whenever the ensemble variance across the saddle point exceeds a critical threshold ($\sigma > 0.08\text{ eV}$), U-RND halts that branch, calls an automated DFT or xTB worker to calculate the true energy and force, injects the new point into an active learning buffer, and resumes exploration.
* **Feasibility Assessment:**
  Highly feasible. The exploration logic is pure Python graph manipulation; the MLIP evaluation is sub-second; and the DFT fallback triggers only on high-uncertainty bottlenecks (typically $< 8\%$ of explored nodes).
* **Evaluation Plan:**
  Benchmark against the 134-reaction aRST dataset. Measure: (1) percentage of true mechanisms discovered, (2) total quantum-chemical evaluations required compared to pure-DFT discovery, and (3) zero unphysical pathways reported.
* **Technical Sketch:**
  ```python
  class URNDEngine:
      def explore_step(self, intermediates: list[Molecule], mlip: MLIPPlugin) -> ReactionGraph:
          candidates = self.enumerate_elementary_steps(intermediates)
          for rxn in candidates:
              path, ts_guess = self.quick_path(rxn, mlip)
              var = mlip.ensemble_variance(ts_guess)
              if var < THRESHOLD:
                  self.graph.add_edge(rxn.r, rxn.p, barrier=path.barrier, confidence="high")
              else:
                  dft_result = self.dft_handoff.evaluate(ts_guess)
                  self.corrections_db.save(ts_guess, dft_result)
                  self.graph.add_edge(rxn.r, rxn.p, barrier=dft_result.barrier, confidence="verified")
  ```

---

### Proposal B: Physics-Informed Transition State Embedding (PI-TSE)
* **Literature Grounding:**
  Builds on React-OT (*Adv. Neural Inf. Process. Syst.* 2024) and SE(3)-equivariant Graph Transformers (*ICML* 2023).
* **Novelty Claim:**
  Conventional path optimization begins with unphysical Cartesian interpolation (LST/IDPP), which frequently fails when bond breakages require significant non-linear rearrangement (e.g., pericyclic reactions, Wagner-Meerwein shifts). PI-TSE is a lightweight Equivariant Graph Transformer that directly predicts the 3D coordinates and internal coordinates of the saddle point given only the concatenated graph representations of reactants and products, trained with an invariant loss penalizing atomic clashes and enforcing zero net forces under MACE. PI-TSE acts as an instantaneous ($\sim 20\text{ ms}$) "warm-start" generator that places the system directly inside the quadratic convergence basin of Direct MaxFlux.
* **Feasibility Assessment:**
  Training data already exists in the Transition1x (10M configurations) and OMol25 datasets. A 12-layer SE(3) transformer can be trained on a single A100 GPU in 48 hours.
* **Evaluation Plan:**
  Compare DMF convergence time and success rate with LST warm-start vs. IDPP vs. PI-TSE on 500 challenging multi-bond reactions. Goal: reduce DMF optimization steps by $> 65\%$ and eliminate topological inversion failures.

---

### Proposal C: Multimodal Inverse Spectrum-to-Structure Elucidation (MISSE)
* **Literature Grounding:**
  Extends TranSpec (*J. Chem. Inf. Model.* 2024) and generative molecular diffusion (*Nat. Commun.* 2024).
* **Novelty Claim:**
  Direct structure elucidation from laboratory data typically requires an experienced spectroscopist manually cross-referencing IR functional group tables and NMR multiplet splitting patterns. MISSE accepts experimental ASCII/JCAMP-DX files of IR absorption and $^{13}\text{C}$ NMR chemical shifts, encodes them via a 1D spectral convolutional transformer, and uses cross-attention conditioning in a discrete graph diffusion model to generate candidate molecular structures matching the spectral signatures. Each candidate is immediately validated by forward MLIP simulation (Phase 4), and the spectral matching error ($R^2_{\text{IR}} + R^2_{\text{NMR}}$) is displayed alongside the structure.
* **Feasibility Assessment:**
  Forward spectrum generation is already solved; conditioning generative diffusion on 1D spectral vectors is technically straightforward using the QM9 and PubChem spectral databases.
* **Evaluation Plan:**
  Test on 100 blind real-world organic molecules. Measure top-1 and top-5 structure retrieval accuracy against standard commercial databases.

---

# Part 5 — Critical Path and Sequencing

### 5.1 Dependency Graph

```
[Phase 0: Plugin Registry & Provenance]
       │
       ▼
[Phase 1: MACE-OMol25 & UQ Calibration]
       │
       ├────────────────────────────────────────┬────────────────────────────────────────┐
       ▼                                        ▼                                        ▼
[Phase 2: Reaction Discovery & Conformer] [Phase 4: Spectroscopy & Properties]    [Phase 6: Avogadro 2 Bridge]
       │                                        │
       ▼                                        ▼
[Phase 3: Enhanced Sampling & OPES]      [Phase 5: Original Algorithms]
```

### 5.2 Execution Sequencing & Parallel Tracks
* **Track 1 (Backend Core):** Phase 0 (Days 1–5) $\to$ Phase 1 (Days 6–15) $\to$ Phase 2 (Days 16–30).
* **Track 2 (Frontend & Spectroscopy):** Once Phase 1 is complete, Phase 4 (Spectroscopy) and Phase 6 (Avogadro Plugin) can proceed completely in parallel with Phase 2.
* **Track 3 (High-Performance Compute & Sampling):** Phase 3 (OpenMM / OPES) can be implemented independently once Phase 1 forces are validated.
* **Track 4 (Novel Research):** Phase 5 builds on the infrastructure of Phases 1, 2, and 4.

### 5.3 Highest-Value Path If Time/Budget Constrained
If engineering effort is limited to a single continuous milestone, the **Critical Path** is:
$$\text{\textbf{Phase 0 (Foundation)}} \longrightarrow \text{\textbf{Phase 1 (MACE-OMol25 + UQ)}} \longrightarrow \text{\textbf{Phase 6 (Avogadro 2 Suite)}}$$
*Total Effort: 25 Engineering Days.*  
*Impact:* Immediately eliminates the legacy GNN inaccuracy, delivers state-of-the-art 2025 MACE-OMol25 barriers with certified error bars, and provides full bi-directional integration with desktop Avogadro 2.

---

# Part 6 — Open Architectural Decisions & Recommendations

### Decision 1: Default Foundation MLIP — MACE-OMol25 vs. UMA-Medium
* **Options:**
  1. Make MACE-OMol25 the sole default.
  2. Make UMA-Medium the sole default.
  3. Deploy both, routing automatically based on composition.
* **Recommendation (Agent Opinion):** **Option 1 (MACE-OMol25 default) with lazy on-demand fallback to UMA-Medium.**  
  *Rationale:* MACE-OMol25 is explicitly optimized for molecular transition states, organic reactions, and gas-phase geometries. UMA-Medium has broader materials coverage but exhibits higher variance on organic radical saddle points.

### Decision 2: Compute Execution Topology for Molecular Dynamics & FEP
* **Options:**
  1. Run all simulations synchronously inside the Cloud Run API container.
  2. Offload long simulations to Google Cloud Run Jobs with dedicated L4 GPUs.
  3. Offload simulations to the user's local workstation via a desktop worker or Avogadro.
* **Recommendation (Agent Opinion):** **Hybrid of Option 2 (Cloud Run Jobs for batch runs) and Option 3 (Avogadro/Local for interactive work).**  
  *Rationale:* Cloud Run HTTP requests terminate at 60 minutes and GPU instances are expensive when idle. Cloud Run Jobs allow per-second billing with zero cold-idle cost, while desktop execution provides free unlimited GPU compute for power users.

### Decision 3: Spectroscopy Prioritization
* **Options:**
  1. Prioritize IR/Raman harmonic spectra first.
  2. Prioritize NMR chemical shift prediction first.
* **Recommendation (Agent Opinion):** **Prioritize IR/Raman first.**  
  *Rationale:* Harmonic IR requires only the second derivative (Hessian) and dipole gradients directly obtainable from MACE-OMol25 via PyTorch autograd without introducing new model weights. NMR requires external GNN surrogates or an electronic structure handoff.

### Decision 4: Conformer Ensemble Storage in Firestore
* **Options:**
  1. Store all conformer Cartesian frames directly in Firestore documents.
  2. Store only the lowest-energy conformer in Firestore, and store full trajectory/ensemble files as compressed GZip payloads in Google Cloud Storage (GCS).
* **Recommendation (Agent Opinion):** **Option 2 (GCS for trajectories, Firestore for metadata).**  
  *Rationale:* Firestore documents have a strict 1 MB size limit. Storing 500-frame trajectories or 100-conformer ensembles in Firestore will breach document quotas and drastically inflate read/write costs.

---

# Appendix: Verification & Acceptance Matrix

| Phase | Core Capability | Benchmark Metric | Acceptance Standard |
|---|---|---|---|
| **Phase 0** | Plugin Architecture | Contract regression test suite | 100% legacy API compatibility; zero diff on standard calls |
| **Phase 1** | MACE-OMol25 MLIP | TS1x 20-Reaction Barrier Test | Barrier MAE $< 1.5\text{ kcal/mol}$; UQ bounds contain reference |
| **Phase 2** | Conformer + Multi-DMF | Pericyclic & Elimination Test | Identical TS found regardless of initial rotamer input |
| **Phase 3** | OPES Free Energy | Butane torsional PMF in explicit solvent | Barrier $5.4 \pm 0.3\text{ kcal/mol}$ in $< 100\text{ ps}$ |
| **Phase 4** | IR / Raman Spectrum | Cyclohexene vibrational analysis | Imaginary frequency $= 0$; $R^2 > 0.95$ vs. experimental spectrum |
| **Phase 5** | PI-TSE Embedding | DMF optimization step count | $\ge 65\%$ reduction in DMF iterations vs. linear transit |
| **Phase 6** | Avogadro 2 Bridge | AutoOptimization frame rate | $\ge 15\text{ FPS}$ live minimization in desktop viewport |

---
*End of Technical Design Document. Awaiting user review and authorization before proceeding to Phase 0 implementation.*
