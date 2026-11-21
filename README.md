# Quantum Forge 🧪⚛️🫀🧠

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/WebGL-Three.js-black?style=for-the-badge&logo=three.js&logoColor=white" alt="WebGL Three.js" />
  <img src="https://img.shields.io/badge/Google_Cloud-Cloud_Run-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Cloud Run" />
  <img src="https://img.shields.io/badge/Firebase-Hosting_%26_Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/PyTorch-Apple_Silicon_MPS-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white" alt="PyTorch" />
  <img src="https://img.shields.io/badge/Tests-564%20Passing%20(100%25)-brightgreen?style=for-the-badge" alt="Tests" />
  <img src="https://img.shields.io/badge/SaMD-7--Pillar%20Legal%20Shield-orange?style=for-the-badge" alt="SaMD 7-Pillar Shield" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="License" />
</p>

**Quantum Forge** is an AI-accelerated quantum chemistry, computational pharmacology, and multi-organ clinical simulation workstation built **for the web** with Flutter and WebGL (Three.js & NGL). It gives researchers, computational chemists, pharmacologists, cardiologists, nephrologists, neurologists, and medical students a single high-performance browser dashboard for building molecules, modeling atomic transition states, evaluating neural interatomic potentials (MLIPs), simulating multi-organ pathophysiology, and conducting real-time bedside hemodynamics.

🌐 **Production Website**: [https://quantumforgeapp.com](https://quantumforgeapp.com)  
🌐 **Firebase Web Mirror**: [https://quantom-forge.web.app](https://quantom-forge.web.app)  
📖 **Repository Directory Guide**: [docs/PROJECT_DIRECTORY_GUIDE.md](docs/PROJECT_DIRECTORY_GUIDE.md)  
🧠 **Centralized AI Models Guide**: [ai_models/README.md](ai_models/README.md)  
🔒 **Security Policy**: [SECURITY.md](SECURITY.md)  
⚖️ **License & Intellectual Property**: [LICENSE.md](LICENSE.md) · [COPYRIGHT.md](COPYRIGHT.md)  

---

## 🗺️ Multi-Disciplinary Workstations

Quantum Forge unites 7 major scientific and medical simulation workstations inside one seamless browser interface:

```
                               ┌─────────────────────────────────────────────────────────────┐
                               │                    QUANTUM FORGE PLATFORM                   │
                               │                https://quantumforgeapp.com                  │
                               └──────────────────────────────┬──────────────────────────────┘
                                                              │
         ┌─────────────────────┬──────────────────────┬───────┴──────────────┬─────────────────────┬─────────────────────┐
         ▼                     ▼                      ▼                      ▼                     ▼                     ▼
 ⚛️ Quantum Chemistry   🫀 CardioCath 3D       🧠 NeuroLab 3D         🫘 NephroLab 3D       🫁 PulmoLab 3D        🦷 DentoLab 3D
  • 25-Param Solver      • Interventional Cath  • Whole CNS/PNS/ANS    • Starling GFR        • Ventilator Loops    • 32-Tooth Anatomy
  • NGL 3D Player        • Wiggers Diagram      • 84-Parcel Connectome • Stewart Acid-Base   • Dynamic Compliance  • TMJ Kinematics
  • Avogadro 2 Parity    • C-Arm 3D Twin        • Patch-Clamp Ionic    • CRRT / Dialysis     • Airway Resistance   • Endodontic Pulp
  • Equivariant PaiNN    • 5-Ch Oscilloscope    • EEG Frequency Power  • Nephrotox GNN       • Alveolar Gas P-V    • CBCT Volumetrics
```

---

### 1. ⚛️ Quantum Chemistry & Transition State Reaction Dynamics
* **Avogadro 2 Desktop Parity**: Native CJSON, CML, Multi-XYZ, and SDF read/write support; discrete NEB trajectory playback with dynamic valence-aware bond perception.
* **NGL 3D Molecular Engine**: Orthographic camera, 4× MSAA antialiasing, Ball & Stick, Licorice, and Van der Waals space-filling representations.
* **25-Parameter Researcher Control Panel**: Direct user configuration of Temperature ($T$), Pressure ($P$), Implicit Solvent screening ($\varepsilon_r$ 2.38 to 80.1), Spin Multiplicity ($2S+1$), Charge ($q$), Catalyst Barrier Reduction ($\Delta E_{cat}$), CI-NEB spring constants, and vibrational Zero-Point Energy (ZPE) corrections.
* **Foundation MLIP Ensembles**: Continuous spatial convolutions via 5-member rotation-equivariant **TX1 PaiNN-Lite** ensemble, alongside containerized **MACE-MP-0**, **ANI-2x**, **CHGNet**, and **GFN2-xTB** semi-empirical quantum backends.

---

### 2. 🫀 CardioCath 3D Lab (`/cardiac`)
* **Interventional Catheterization Suite**: 3 synchronized viewports: Procedural 3D Beating Heart, Synchronized X-ray Fluoroscopy, and 3D C-Arm Gantry Digital Twin with radiation dosimetry badges.
* **Hemodynamics & Wiggers Diagram**: Pulsatile Navier-Stokes fluid mechanics, Murray's Law coronary bifurcation branching, and endothelial wall shear stress modeling for DK-Crush, Culotte, and TAP stenting.
* **5-Channel ICU Bedside Oscilloscope**: High-resolution Lead II & V1 ECG, invasive arterial blood pressure (ABP Pa/Pd with dicrotic notch), central venous pressure (CVP), SpO2 plethysmograph, and EtCO2 capnogram. Includes 14 arrhythmias, 200J defibrillation, and hospital thermal paper export.
* **Cardiorenal Multi-Organ Coupling**: Bidirectional integration with NephroLab 3D computing Cardiorenal Syndromes (Types 1–5), RAAS activation, and glomerular-perfusion crosstalk.

---

### 3. 🧠 NeuroLab 3D (`/neuro`)
* **Whole Human Nervous System Coverage**: 3D interactive WebGL visualization spanning the Central Nervous System (CNS: Brain & Spinal Cord), Peripheral Nervous System (PNS: Cranial Nerves I–XII, Brachial/Lumbosacral Plexuses, Named Nerves, Dermatome/Myotome maps), Autonomic Nervous System (Sympathetic chain & Craniosacral Parasympathetic), and Microscopic Synaptic Cleft.
* **Desikan-Killiany Connectome GNN**: 84-parcel cortical and subcortical graph network computing tractography streamlines, graph Laplacian centrality, and functional clustering.
* **Biophysical Ionic & Cable Theory**: Solves Goldman-Hodgkin-Katz (GHK) membrane potentials, Hodgkin-Huxley ($Na_V$, $K_V$) action potentials, and Rall's dendritic cable attenuation equations.
* **Cerebral Hemodynamics & Perfusion**: Monro-Kellie intracranial pressure (ICP) compliance curve, Lassen autoregulation ($MAP\text{ 50–150 mmHg}$), and cerebral perfusion pressure ($CPP = MAP - ICP$).

---

### 4. 🫘 NephroLab 3D (`/nephro`)
* **Biophysical Glomerular & Tubular Engine**: Solves Starling capillary-Bowman dynamics, myogenic autoregulation, tubuloglomerular feedback, and countercurrent electrolyte concentration gradients.
* **ICU Stewart-Hamilton Acid-Base Solver**: Quantitative physicochemical acid-base equilibria, Strong Ion Difference ($SID$), total non-volatile weak acids ($A_{TOT}$), and base excess.
* **Hemodialysis & CRRT Kinetic Modeling**: Single-pool ($spKt/V$), double-pool ($eKt/V$), solute clearance, and post-dialysis urea rebound dynamics.
* **Renal Toxicity GNN**: Screens candidate therapeutics for acute tubular necrosis (ATN), crystal nephropathy, and acute interstitial nephritis.

---

### 5. 🫁 PulmoLab 3D (`/pulmo`)
* **Respiratory Mechanics**: Equation of motion of the respiratory system ($P_{aw} = \frac{V}{C_{rs}} + R_{aw} \cdot \dot{V} + PEEP$).
* **ICU Mechanical Ventilator Waveforms**: Pressure-time, flow-time, and volume-time scalar graphs with dynamic Pressure-Volume ($P\text{--}V$) and Flow-Volume ($F\text{--}V$ loops) illustrating intrinsic PEEP, obstructive scooping, and restrictive shifts.

---

### 6. 🦷 DentoLab 3D (`/dental`)
* **Maxillofacial & 32-Tooth Permanent Dentition**: Zero-copyright procedural Three.js WebGL anatomical model with coronal/sagittal tooth cutaways, enamel, dentin, odontoblast layer, pulp horn, and apical foramen.
* **TMJ Kinematics & Occlusion**: Posselt envelope of mandibular motion, protrusion, retrusion, and Bennett lateral shift.

---

### 7. 💊 Clinical & Veterinary Pharmacopeia Library
* **2.85M+ Live Firestore Reactions**: High-throughput chemical library hosted in Cloud Firestore (`/library`) with uncopyrightable physical coordinates, reaction mechanisms, and primary source citations.
* **Everyday Prescription Medicine Monographs (`rx_med_*`)**: 12 doctor-prescribed everyday medicines online with complete 7-tab Clinical & Veterinary Medical Dossiers:
  * **Quetiapine**, **Sertraline**, **Paracetamol**, **Diltiazem HCl**, **Finerenone**, **Rifaximin**, **Amlodipine**, **Metoprolol**, **Empagliflozin**, **Pantoprazole**, **Apixaban**, and **Levetiracetam**.
* **7-Tab Clinical Medical Dossier**: Mechanism of Action (MoA) & Target PDB, Human MBBS & Veterinary Indications, Pharmacokinetics (ADME), Toxicity & Adverse Events, Pharmacogenomics (CYP450 / P-gp), Drug-Drug Interactions (DDI), and Verified Peer-Reviewed Sources (DOIs, PMIDs, PDB IDs).

---

## 🧠 Centralized AI & Machine Learning Directory ([`ai_models/`](ai_models/))

All machine learning models are organized into dedicated, self-explanatory directories with human-readable file names:

| Category Folder | Model Architecture | Network, Predictor & Training Scripts | What It Does in Plain English |
|---|---|---|---|
| **`cardiovascular_electrophysiology/`** | `cardiac_action_potential_model/` | `cardiac_action_potential_network.py`<br>`cardiac_action_potential_predictor.py` | Predicts action potential duration ($APD_{90}$) and hERG channel blockade risk. |
| **`cardiovascular_electrophysiology/`** | `cardiac_3d_myocardial_strain_fno/` | `myocardial_strain_fourier_neural_operator_network.py`<br>`myocardial_strain_fno_predictor.py` | 3D Fourier Neural Operator simulating myocardial strain tensor fields. |
| **`cardiovascular_electrophysiology/`** | `cardiorenal_crosstalk_interaction_gnn/` | `cardiorenal_interaction_gnn_network.py`<br>`cardiorenal_toxicity_gnn_predictor.py` | Graph Neural Network predicting cardiorenal crosstalk and combined toxicity. |
| **`cardiovascular_electrophysiology/`** | `cardiac_physics_informed_neural_net/` | `aliev_panfilov_pinn_network.py`<br>`cardiac_action_potential_pinn_predictor.py` | Physics-Informed Neural Network enforcing Aliev-Panfilov ventricular excitation. |
| **`cardiovascular_electrophysiology/`** | `cardiac_3d_rotor_spiral_wave_model/` | `ventricular_rotor_spiral_wave_network.py`<br>`rotor_spiral_wave_predictor.py` | Predicts spiral wave reentry rotor cores during complex arrhythmias. |
| **`nephrology_renal_ai/`** | `dialysis_urea_clearance_kinetics_net/` | `dialysis_solute_clearance_kinetics_network.py`<br>`dialysis_clearance_predictor.py` | Kinetic model predicting urea reduction ratio ($URR$) and clearance ($Kt/V$). |
| **`nephrology_renal_ai/`** | `glomerular_filtration_physics_informed_net/` | `glomerular_filtration_pinn_network.py`<br>`glomerular_filtration_predictor.py` | PINN enforcing Starling capillary-Bowman pressure conservation. |
| **`nephrology_renal_ai/`** | `drug_induced_nephrotoxicity_gnn/` | `renal_tubular_toxicity_gnn_network.py`<br>`nephrotoxicity_predictor.py` | Molecular GNN screening molecules for proximal tubule necrosis. |
| **`neurology_brain_ai/`** | `blood_brain_barrier_permeability_gnn/` | `blood_brain_barrier_gnn_network.py`<br>`blood_brain_barrier_predictor.py` | Molecular GNN predicting blood-brain barrier ($\log BB$) permeability. |
| **`neurology_brain_ai/`** | `cerebral_perfusion_fourier_neural_operator/` | `cerebral_hemodynamics_fno_network.py`<br>`cerebral_perfusion_predictor.py` | 3D FNO predicting cerebral blood flow and stroke penumbra. |
| **`neurology_brain_ai/`** | `cortical_spiking_neural_network/` | `izhikevich_cortical_spiking_network.py`<br>`cortical_spike_train_predictor.py` | Izhikevich model simulating physiological cortical spike trains. |
| **`neurology_brain_ai/`** | `synaptic_transmission_axon_propagation_net/` | `synaptic_cleft_axon_conduction_network.py`<br>`synaptic_axon_transmission_predictor.py` | Simulates synaptic cleft neurotransmission and myelinated axon conduction. |
| **`neurology_brain_ai/`** | `whole_nervous_system_connectome_model/` | `whole_connectome_graph_network.py`<br>`connectome_tractography_predictor.py` | Graph Neural Network modeling connectivity across 84 brain parcels. |
| **`quantum_chemistry_potentials/`** | `equivariant_painn_transition_state_ensemble/` | `painn_rotation_equivariant_potential_network.py`<br>`train_painn_on_apple_silicon_gpu.py` | 5-member rotation-equivariant PaiNN potential ensemble predicting $E_a$ and forces. |
| **`pharmacology_intelligence_bionet/`** | `multi_task_drug_pharmacology_network/` | `pharmacology_intelligence_bionet_network.py`<br>`train_pharmacology_intelligence_model.py` | Multi-task deep neural network predicting MoA, target species, and ADME. |

---

## 🛡️ Software as a Medical Device (SaMD) 7-Pillar Legal Shield

Quantum Forge strictly operates under a non-negotiable educational and computational research framework:

1. **Non-Diagnostic, Non-Therapeutic Charter**: Quantum Forge is explicitly an educational simulation and in silico research platform. It does **NOT** constitute medical software, clinical diagnosis, therapeutic planning, surgical guidance, or patient treatment.
2. **Prohibition of Direct Clinical Application**: Simulations and model outputs must never replace the clinical judgment, physical examination, or diagnostic procedures of licensed medical practitioners.
3. **In Silico Research Disclaimer**: All calculated trajectories, $E_a$ values, hemodynamic curves, and neural predictions are theoretical approximations governed by mathematical idealizations.
4. **Dual-Use Chemical Defense Screening**: Chemical inputs are screened against CWC Schedule 1/2/3 and DEA Schedule I/II databases; dangerous or weaponizable compounds are blocked automatically.
5. **Permanent User Facing Disclaimers**: Warning banners and informational modal dialogs are permanently embedded across all client screens.
6. **Zero PHI Storage**: Quantum Forge does not ingest, process, store, or transmit Protected Health Information (PHI) under HIPAA regulations.
7. **Transparent Algorithmic Provenance**: Every reaction template and pharmacology profile links to public, peer-reviewed primary literature (PubMed, CrossRef, PDB).

---

## 🚀 Quick Start Guide

### 1. Web Application (Zero Installation)
Simply visit [https://quantumforgeapp.com](https://quantumforgeapp.com) in any modern browser (Chrome, Edge, Safari, Firefox).

### 2. Local Development Setup

#### Prerequisites
* Flutter SDK 3.24+
* Python 3.10+ (PyTorch, RDKit, ASE, FastAPI, Uvicorn)
* Google Chrome (for automated CDP testing)

#### Frontend
```bash
cd quantum_forge
flutter pub get
flutter run -d chrome
```

#### Run All 564 Automated Tests
```bash
cd quantum_forge
flutter test
```

#### Launch Backend Microservices
```bash
# Launch Transition State & Quantum Chemistry API
cd tx1-fastapi-backend && uvicorn main:app --host 0.0.0.0 --port 8005

# Launch Interventional Cardiology Backend
cd cardiocath-backend && uvicorn main:app --host 0.0.0.0 --port 8002

# Launch Whole Nervous System Backend
cd neurolab-backend && uvicorn main:app --host 0.0.0.0 --port 8003

# Launch Nephrology & Dialysis Backend
cd nephrolab-backend && uvicorn main:app --host 0.0.0.0 --port 8004
```

---

## 📁 Repository Directory Structure

```
Quantum-Forge/
├── quantum_forge/               # Flutter Web Application (Clinical & Chemistry Frontend)
├── tx1-fastapi-backend/         # Core Molecular GNN & PaiNN-Lite MLIP Backend (Port 8005)
├── cardiocath-backend/          # CardioCath 3D Interventional Cath-Lab Backend (Port 8002)
├── neurolab-backend/            # NeuroLab 3D Whole-Nervous-System Backend (Port 8003)
├── nephrolab-backend/           # NephroLab 3D Renal Acid-Base & Nephron Backend (Port 8004)
├── seeder-backend/              # 24/7 Cloud Run Streamer for 2.85M+ Firestore Library
├── ai_models/                   # Master AI & Neural Network Directory with Self-Explanatory Names
├── scripts/                     # Automation, Seeding, Harvesting & Auditing Suites
│   ├── dataset_preparation_pipelines/    # Transition1x conversion and validation pipelines
│   ├── backend_service_control/          # Start, stop, and health scripts
│   ├── database_and_firestore_seeding/   # Firestore library seeders
│   ├── quality_audits/                   # Automated Chrome DevTools audits and physics benchmarks
│   └── autonomous_research_and_harvesting/ # 24/7 continuous paper harvesters and MPS trainers
├── configs/                     # Environment Configurations (Production, Dev, Testing)
├── infrastructure/              # Cloud Build & GCP Provisioning Specifications
├── docs/                        # Architecture Blueprints, Inventory & Directory Guides
└── tests/                       # Integration & Automated Regression Test Suites
```

---

## ⚖️ License & Authorship

Developed and maintained by **Ali Asghar** ([aliasgharinnocent@yahoo.com](mailto:aliasgharinnocent@yahoo.com)) · **Dart Nexus Lab**.

This project is licensed under the **MIT License** with proprietary trademark, brand reservation, and SaMD educational addenda — see the [LICENSE.md](LICENSE.md) and [COPYRIGHT.md](COPYRIGHT.md) files for complete terms. Third-party software components and attributions are detailed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
