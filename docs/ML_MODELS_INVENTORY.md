# Quantum Forge Machine Learning Models Inventory & Architectural Registry

**Document Version:** 2.0.0  
**Repository Status:** Production / Clinical & Quantum Simulation Workstation  
**Hardware Targets:** Apple Silicon Metal Performance Shaders (`mps`), CUDA (`cuda:0`), Cloud Run Multi-Core CPU (`cpu`)  
**Parent Laboratory:** Dart Nexus Lab  

---

## 1. Master Model Registry

| Model Identifier | Architecture Family | Parameters | Checkpoint Size | Device Target | Active Service / Endpoint | Primary Function |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`tx1-v2` (Ensemble)** | PaiNN-Lite (5-Member Ensemble) | 165,473 × 5 = **827,365** | 0.66 MB × 5 = **3.30 MB** | `mps`, `cuda`, `cpu` | `tx1-fastapi-backend` (`/predict`, `/predict/batch`) | Equivariant PES, activation barrier $E_a$, atomic forces, and ensemble epistemic uncertainty $\sigma_E$ |
| **`tx1-v2b` (Single)** | PaiNN-Lite (Rot-Invariant + Equivariant) | **165,473** | **1.94 MB** | `mps`, `cpu` | `tx1-fastapi-backend` (`/predict`) | Calibrated single-model barrier prediction (Val MAE: 1.63 kcal/mol) |
| **`tx1-v2a` (Single)** | MolecularGraphNetwork (Legacy GNN) | **196,929** | **2.15 MB** | `cpu`, `mps` | `tx1-fastapi-backend` (`/predict`) | Legacy fallback distance-based molecular GNN |
| **`pharma-bionet-v1`** | Multi-Task Deep Neural Network | **64,343** | **0.26 MB** | `mps`, `cpu` | `tx1-fastapi-backend` (`/api/pharma/predict`, `/api/pharma/dossiers`) | Multi-task MoA classification, bioavailability across species, and medical specialty routing |
| **`cardio-pinn-best`** | Physics-Informed Neural Network (PINN) | **144,651** | **0.57 MB** | `mps`, `cpu` | `cardiocath-backend` (`/api/cardio/simulate`) | Navier-Stokes 1D hemodynamics, FFR, iFR, and microvascular resistance |
| **`cardio-electrophys`** | Action Potential Conduction Net | **209,893** | **0.82 MB** | `mps`, `cpu` | `cardiocath-backend` (`/api/cardio/ep-study`) | Transmembrane voltage $V_m$, APD90, and CiPA ion channel cardiotoxicity |
| **`cardio-nephro-gnn`** | 5-Member Molecular Graph Ensemble | **354,699** | **1.39 MB** | `mps`, `cpu` | `cardiocath-backend` (`/api/cardio/cardio-nephro-predict`) | ChEMBL hERG IC50, Nav1.5, Cav1.2, and renal clearance risk scoring |
| **`cardio-fno-3d`** | 3D Fourier Neural Operator | **254,405** | **1.35 MB** | `mps`, `cpu` | `cardiocath-backend` (`/api/cardio/fno-strain`) | Myocardial contractility, regional strain bullseye, and Global Longitudinal Strain (GLS) |
| **`cardio-rotor-3d`** | Phase Singularity & Re-entry Tracker | **68,588** | **0.28 MB** | `mps`, `cpu` | `cardiocath-backend` (`/api/cardio/rotor-mapping`) | 3D spiral re-entrant wave rotors, dominant frequency, and ablation targets |
| **`whole-neuro-connectome`**| 10-Axis Neuro-Anatomical Classifier | **28,624** | **0.12 MB** | `mps`, `cpu` | `neurolab-backend` (`/api/neuro/whole-system-localize`) | 16-feature clinical deficit vector to 10 anatomical neuro-axes lesion localization |
| **`synapse-net-axon`** | Saltatory Conduction Biophysical Surrogate | **9,607** | **0.04 MB** | `mps`, `cpu` | `neurolab-backend` (`/api/neuro/synapse-axon`) | Node of Ranvier saltatory conduction velocity, compound muscle action potential (CMAP), and NMJ safety margin |
| **`neuro-spike-net`** | Cortical Action Potential Train Surrogate| **19,816** | **0.09 MB** | `mps`, `cpu` | `neurolab-backend` (`/api/neuro/ionm-telemetry`) | Intraoperative neurophysiological monitoring (IONM) SSEP and MEP signal generation |
| **`neuro-fno-perfusion`** | 2D/3D Cerebral Hemodynamics Operator | **170,280** | **0.80 MB** | `mps`, `cpu` | `neurolab-backend` (`/api/neuro/tcd-vasospasm`) | Dynamic susceptibility contrast (DSC) perfusion: CBF, CBV, MTT, and Tmax ischemic core/penumbra |
| **`neuro-bbb-gnn`** | Blood-Brain Barrier Permeability Net | **15,684** | **0.07 MB** | `mps`, `cpu` | `neurolab-backend` (`/api/neuro/bbb-predict`) | logBB, CNS MPO, and passive brain penetration descriptor scoring |
| **`nephro-pinn-glomerular`**| Glomerular Ultrafiltration PINN | **15,561** | **0.07 MB** | `mps`, `cpu` | `nephrolab-backend` (`/api/nephro/simulate`) | Starling microvascular forces ($\Delta P - \Delta \Pi$), single-nephron GFR, and podocyte slit shear stress |
| **`nephro-tox-gnn`** | Tubular Necrosis & Nephrotoxicity Net | **15,718** | **0.07 MB** | `mps`, `cpu` | `nephrolab-backend` (`/api/nephro/nephrotox-predict`) | Proximal tubule toxicity (KIM-1, NGAL) and cisplatin/aminoglycoside damage probability |
| **`dialysis-kinetics-net`** | Multi-Compartment Solute Kinetic Net | **13,543** | **0.06 MB** | `mps`, `cpu` | `nephrolab-backend` (`/api/nephro/dialysis-kinetics`) | Urea/creatinine two-pool distribution, dialyzer clearance ($K_d$), and single-pool $Kt/V$ |
| **`mace-mp-0`** | Foundation Equivariant Graph Potential | External / Cache | Pre-cached | `cuda`, `cpu` | `mace-backend` (`/predict`, `/md`) | Higher-order body-order equivariant graph potential for foundation molecular dynamics |
| **`ani-2x`** | Atomic Neural Network Potential | External / Cache | Pre-cached | `cuda`, `mps`, `cpu` | `ani2x-backend` (`/predict`, `/md`) | Organic chemical potential trained on HCNO-S-Cl systems |
| **`chgnet`** | Crystal Hamiltonian Graph Neural Network | External / Cache | Pre-cached | `cuda`, `cpu` | `chgnet-backend` (`/predict`, `/relax`) | Inorganic solids, crystal structures, and battery electrode potentials |
| **`gfn2-xtb`** | Semi-Empirical Quantum Chemical Surrogate | Compiled Binary | Executable | Native CPU | `gfn2-xtb-backend` (`/calculate`, `/opt`) | Tight-binding quantum chemistry surrogate for total energy, dipole, and HOMO-LUMO gap |
| **`TransformerReactionCompressor`** | Client-Side Multi-Head Self-Attention | On-Device Algorithmic | Inline Dart | Web / Mobile / Desktop | `quantum_forge` (Flutter Client) | Dynamic NEB path interpolation, 21-frame collision-free reconstruction, and harmonic vibration modes |

---

## 2. Deep-Dive Technical Profiles

### 2.1 TX1 PaiNN-Lite MLIP Ensemble (`tx1-v2`)
* **Architecture:** Polarizable Atom Interaction Neural Network carrying scalar features $s_i \in \mathbb{R}^{64}$ and equivariant 3D vector features $\vec{v}_i \in \mathbb{R}^{64 \times 3}$.
* **Mathematical Invariant:** Guarantees rotation and translation equivariance for vector messages ($\mathbf{R}\vec{v} = \vec{v}'$) and strict rotation invariance for scalar energies.
* **Radial Basis Functions:** 32 Gaussian RBF centers spanning $r_{\min} = 0.5\text{ \AA}$ to $r_{\max} = 6.0\text{ \AA}$ with smooth cosine cutoff:
  $$f_{\text{cut}}(r) = \frac{1}{2}\left[\cos\left(\frac{\pi r}{r_{\text{cut}}}\right) + 1\right] \quad (r < r_{\text{cut}})$$
* **Ensemble Epistemic Uncertainty:**
  $$E_{\text{ens}} = \frac{1}{M}\sum_{m=1}^M E_m, \quad \sigma_E = \sqrt{\frac{1}{M-1}\sum_{m=1}^M (E_m - E_{\text{ens}})^2}$$
* **Calibrated Temperature Scaling:** $T = 1.0$, scaling parameter $\sigma_{\text{cal}} = T \cdot \sigma_E$.
* **Training Pipeline:** Trained on Apple Silicon M1 Pro (`mps`) across Transition1x (909 elementary reaction profiles, 10,000+ DFT configurations).

### 2.2 PharmaBioNet (`pharma_bionet_v1`)
* **Input Layer:** 32-dimensional invariant molecular and physicochemical descriptor vector (heteroatom counts, molecular weight, estimated H-bond donors/acceptors, aromaticity proxy, logP proxy, topological polar surface area proxy).
* **Network Structure:** Fully connected multi-head backbone:
  * Backbone: $\text{Linear}(32 \to 64) \to \text{GELU} \to \text{Linear}(64 \to 64) \to \text{LayerNorm}$
  * Head 1 (Mechanism of Action): Multi-class Softmax over 8 core therapeutic mechanisms.
  * Head 2 (Cross-Species Bioavailability): Multi-output Sigmoid over 5 veterinary/human species.
  * Head 3 (Medical Curriculum Routing): Multi-class Softmax across MBBS, Pharm-D, and DVM curricula.
* **Loss Function:** Joint multi-task cross-entropy + binary cross-entropy:
  $$\mathcal{L} = \mathcal{L}_{\text{MoA}} + 0.5\,\mathcal{L}_{\text{species}} + 0.5\,\mathcal{L}_{\text{curriculum}}$$

### 2.3 CardioCath & Electrophysiology AI Suite
* **`cardio-pinn-best`:** Embeds the 1D Navier-Stokes momentum and continuity equations for pulsatile coronary blood flow:
  $$\frac{\partial A}{\partial t} + \frac{\partial Q}{\partial z} = 0, \quad \frac{\partial Q}{\partial t} + \frac{\partial}{\partial z}\left(\alpha \frac{Q^2}{A}\right) + \frac{A}{\rho}\frac{\partial P}{\partial z} + K_R \frac{Q}{A} = 0$$
* **`cardio-electrophys`:** Aliev-Panfilov 2-variable cardiac action potential surrogate calculating wave propagation across 14 rhythm patterns.
* **`cardio-nephro-gnn`:** 5-member GNN ensemble trained on curated ChEMBL bioactivity assays, evaluating off-target cardiotoxicity ($hERG$, $Na_v1.5$, $Ca_v1.2$) and renal tubular clearance.
* **`cardio-fno-3d`:** Fourier Neural Operator learning mapping between 3D mechanical pressure fields and myocardial fiber strain tensors in the frequency domain.

### 2.4 NeuroLab 3D AI Suite
* **`whole-neuro-connectome`:** Linear classifier mapping a 16-feature deficit vector (cranial nerve palsies, limb weakness, sensory levels, visual deficits) to 10 anatomical lesion sites with 100% test accuracy.
* **`synapse-net-axon`:** Hodgkin-Huxley saltatory conduction surrogate parameterizing myelin thickness, nodal sodium channel conductance ($g_{Na}$), and neuromuscular junction quantal content.
* **`neuro-fno-perfusion`:** Maps arterial input functions (AIF) and tissue residue functions to voxel-wise cerebral perfusion parameters ($CBF, CBV, MTT$).

### 2.5 NephroLab 3D AI Suite
* **`nephro-pinn-glomerular`:** Solves microvascular Starling equilibrium across fenestrated glomerular capillaries:
  $$GFR = K_f \cdot \left[(P_{GC} - P_{BS}) - \sigma(\Pi_{GC} - \Pi_{BS})\right]$$
* **`nephro-tox-gnn`:** GNN trained on nephrotoxin chemical graphs predicting proximal tubular brush border injury risk.
* **`dialysis-kinetics-net`:** Two-pool variable-volume mathematical model for urea kinetic modeling ($Kt/V$).

### 2.6 Client-Side Trajectory Engine (`TransformerReactionCompressor`)
* **Algorithm:** Embedded directly in `quantum_forge/lib/core/algorithms/transformer_reaction_compressor.dart`.
* **Mechanism:** 2-head geometric self-attention with latent feature max-pooling, allowing client-side interpolation of reaction intermediate frames without requiring continuous server round-trips.

---

## 3. Reorganized `ml_models/` Directory Structure

```text
ml_models/
├── README.md
├── tx1_painn_ensemble/
│   ├── README.md
│   ├── checkpoints/
│   │   ├── member_0.pt                          # 165,473 params (0.66 MB)
│   │   ├── member_1.pt                          # 165,473 params (0.66 MB)
│   │   ├── member_2.pt                          # 165,473 params (0.66 MB)
│   │   ├── member_3.pt                          # 165,473 params (0.66 MB)
│   │   ├── member_4.pt                          # 165,473 params (0.66 MB)
│   │   ├── ensemble_metadata.json               # Calibration & temperature metadata
│   │   ├── t1x_model_checkpoint_v2b.pt          # PaiNN-Lite single model (1.94 MB)
│   │   └── t1x_model_checkpoint_v2a.pt          # Legacy GNN single model (2.15 MB)
│   ├── backups/                                 # Historical epoch checkpoints (.epoch20.pt)
│   ├── architecture/
│   │   ├── painn.py                             # PaiNN-Lite equivariant network implementation
│   │   └── legacy_gnn.py                        # MolecularGraphNetwork implementation
│   └── training/
│       ├── mps_trainer.py                       # Apple Silicon MPS fine-tuning trainer
│       ├── train_ensemble.py                    # Multi-member ensemble training orchestrator
│       └── calibrate_uncertainty.py             # Temperature and variance calibration script
├── pharma_bionet/
│   ├── README.md
│   ├── checkpoints/
│   │   └── pharma_bionet_v1.pt                  # 64,343 params (0.26 MB)
│   ├── architecture/
│   │   └── pharma_intelligence_model.py         # PharmaBioNet network architecture
│   └── training/
│       └── train_pharma_model.py                # MPS-accelerated multi-task training script
├── continual_learning/
│   ├── README.md
│   ├── checkpoints/
│   │   ├── model_continual_latest.pt            # Active production continual model (0.68 MB)
│   │   └── model_continual_*.pt                 # Historical training checkpoint chain
│   └── pipelines/
│       └── README.md                            # Documentation on replay buffers & .extxyz queues
├── external_mlips/
│   ├── README.md
│   ├── mace/
│   │   ├── README.md
│   │   ├── mace_gcp_production.yaml             # MACE production training configuration
│   │   ├── mace_local_dev.yaml                  # Local development config
│   │   └── mace_calculator.py                   # ASE MACE calculator loader
│   ├── ani2x/
│   │   ├── README.md
│   │   └── ani2x_calculator.py                  # TorchANI model loader
│   ├── chgnet/
│   │   ├── README.md
│   │   └── chgnet_calculator.py                 # Crystal CHGNet loader
│   └── gfn2_xtb/
│       ├── README.md
│       └── xtb_calculator.py                    # GFN2-xTB binary wrapper
├── cardio_electrophysiology/
│   ├── README.md
│   ├── cardio_pinn/                             # Navier-Stokes coronary hemodynamic PINN
│   ├── cardio_electrophys/                      # Action potential & CiPA electrophysiology model
│   ├── cardio_nephro_gnn/                       # 5-member hERG / Nav1.5 / Cav1.2 toxicity ensemble
│   ├── cardio_fno_3d/                           # 3D Fourier Neural Operator for myocardial strain
│   └── cardio_rotor_3d/                         # Spiral wave re-entry rotor tracker
├── neurology_ai/
│   ├── README.md
│   ├── whole_neuro_connectome/                  # 10-axis clinical deficit lesion localizer
│   ├── synapse_net_axon/                        # Saltatory conduction & NMJ biophysical model
│   ├── neuro_spike_net/                         # Cortical action potential spiking model
│   ├── neuro_fno_perfusion/                     # DSC perfusion CT/MRI neural operator
│   └── neuro_bbb_gnn/                           # Blood-brain barrier permeability GNN
├── nephrology_ai/
│   ├── README.md
│   ├── nephro_pinn_glomerular/                  # Glomerular Starling forces ultrafiltration PINN
│   ├── nephro_tox_gnn/                          # Drug-induced proximal tubular necrosis GNN
│   └── dialysis_kinetics_net/                   # Urea kinetic modeling (Kt/V) network
└── client_algorithms/
    ├── README.md
    └── dart_algorithms/
        └── README.md                            # Trajectory compression & self-attention spec
```

---

## 4. Verification & Validation Status

* **`tx1-fastapi-backend` Unit Tests:** 14/14 passed
* **`tx1-fastapi-backend` Integration Tests (`test_main.py`):** 23/23 passed
* **`cardiocath-backend` Tests (`test_hemodynamics.py`):** 30/30 passed
* **`neurolab-backend` Tests (`test_neuro_solver.py`):** 18/18 passed
* **`nephrolab-backend` Tests (`test_nephro.py`):** 8/8 passed
* **Total Automated Tests Passing:** **93 / 93** (100% Pass Rate)
