# Quantum Forge: Master Project Directory Guide

Welcome to **Quantum Forge**! This guide provides a clear, plain-English overview of the entire repository structure. Whether you are a computational chemist, cardiologist, clinical researcher, ML engineer, or software developer, this document explains the purpose of every folder and file without requiring you to dig through the code.

---

## 🗺️ High-Level Architectural Map

Quantum Forge is structured as a full-stack, AI-accelerated scientific and clinical simulation ecosystem:
```
Quantum-Forge/
├── quantum_forge/               # Flutter Web Application (Clinical & Chemistry Frontend)
├── tx1-fastapi-backend/         # Core Molecular GNN & PaiNN-Lite MLIP Backend
├── cardiocath-backend/          # CardioCath 3D Interventional Cath-Lab Backend
├── neurolab-backend/            # NeuroLab 3D Whole-Nervous-System Backend
├── nephrolab-backend/           # NephroLab 3D Renal Acid-Base & Nephron Backend
├── seeder-backend/              # 24/7 Cloud Run Streamer for 2.85M+ Firestore Library
├── ml_models/                   # Master Machine Learning Model Directory (21 Checkpoints)
├── scripts/                     # Automation, Seeding, Harvesting & Auditing Suites
├── data/                        # Research Datasets, Trajectories, Ledgers & Replay Buffers
├── configs/                     # Environment Configurations (Production, Dev, Testing)
├── infrastructure/              # Cloud Build & GCP Provisioning Specifications
├── docs/                        # Technical Architecture, Inventory & Governance Reports
└── tests/                       # Root Integration & Automated Regression Test Suites
```

---

## 1. Root Directory & Configuration Files

| File / Folder | Purpose in Plain English |
| --- | --- |
| `README.md` | The main project homepage with badges, architecture overview, web app links, and quick-start instructions. |
| `LICENSE` | Open-source project license terms. |
| `COPYRIGHT.md` | Comprehensive IP, trademark, and copyright declarations for Quantum Forge assets. |
| `SECURITY.md` | Security disclosure guidelines and vulnerability reporting policies. |
| `THIRD_PARTY_LICENSES.md` | Attributions for external scientific libraries (RDKit, ASE, PyTorch, NGL Viewer, Three.js). |
| `codemagic.yaml` | Codemagic continuous integration & deployment pipeline for automated Flutter Web builds. |
| `requirements.txt` | Python dependencies for local development and root-level automation scripts. |
| `.python-version` | Pinned Python runtime version (3.11 / 3.14). |
| `.gitignore` | Ignores temporary caches, OS artifacts, build directories, and virtual environments. |
| `.dockerignore` / `.gcloudignore` | Excludes unnecessary local files from container builds and Google Cloud deployments. |

---

## 2. Machine Learning Checkpoints (`ml_models/`)

All machine learning models across Quantum Forge are cataloged in `ml_models/` and documented in detail within [docs/ML_MODELS_INVENTORY.md](file:///Users/aliasghar08/development/Quantum%20Forge%20Repo/Quantum-Forge/docs/ML_MODELS_INVENTORY.md):

| Subdirectory | Model Family & Architecture | What It Does in Plain English |
| --- | --- | --- |
| `ml_models/tx1_painn_ensemble/` | `TX1PaiNN` (5-member deep ensemble) | Predicts quantum mechanical potential energies ($E$), atomic forces ($F$), and epistemic uncertainty ($\sigma$). Trained on Transition1x. |
| `ml_models/pharma_bionet/` | `PharmaBioNet` Multi-Task GNN | Evaluates molecular graphs to predict Mechanism of Action (MoA), target species, and therapeutic classification. |
| `ml_models/continual_learning/` | Continual Learning Checkpoints | Checkpoints produced automatically by the 24/7 background MPS trainer as new papers are ingested. |
| `ml_models/cardio_electrophysiology/` | `CardioElectrophysNet`, `CardioNephroGNN`, `CardioPINN` | Predicts hERG potassium channel blockade, CiPA cardiac safety, QT prolongation, and arterial hemodynamics. |
| `ml_models/neurology_ai/` | `NeuroElectrophysGNN`, `NeuroBBBPenetrationGNN`, `NeuroPlasticityPINN` | Simulates Hodgkin-Huxley ionic channel conductances, Blood-Brain Barrier (BBB) penetration, and synaptic plasticity. |
| `ml_models/nephrology_ai/` | `NephroTransportGNN`, `NephroAcidBasePINN`, `RenalClearanceGNN` | Solves Stewart-Hamilton acid-base balance, proximal/distal tubule solute fluxes, and glomerular filtration rate (GFR). |
| `ml_models/external_mlips/` | MACE, CHGNet, ANI-2x, GFN2-xTB | External foundation potentials wrapped for comparative benchmarking against TX1. |
| `ml_models/client_algorithms/` | Client-Side Classical Solvers | Numerical algorithms running directly in the browser (4th-order Runge-Kutta, Nelder-Mead simplex, Pade approximants). |

---

## 3. Automation & Scripts Directory (`scripts/`)

Organized into dedicated functional subdirectories with self-explanatory names:

### A. Autonomous Research Pipeline (`scripts/autonomous_research_pipeline/`)
* **`autonomous_pipeline_daemon.py`**: The master 24/7 supervisor daemon that runs on Apple Silicon Metal (MPS) or Cloud Run, monitoring academic networks, ingesting reaction coordinates, creating zero-leakage splits, and fine-tuning models.
* **`literature_harvester.py`**: Queries OpenAlex, CrossRef, EuropePMC, and PubMed REST APIs for newly published transition states and synthesis papers.
* **`scholarly_verifier.py`**: Enforces strict peer-review authenticity, verifying DOIs, author affiliations, and citation metrics.
* **`data_ingester.py`**: Validates physical invariants (mass/charge balance) and outputs `.extxyz` reaction trajectories.
* **`mps_trainer.py`**: Continual PyTorch fine-tuning engine optimized for Apple Silicon MPS GPU acceleration.
* **`pharma_intelligence_model.py` / `train_pharma_model.py`**: Architecture and training pipeline for the PharmaBioNet GNN.
* **`Dockerfile.harvester`**: Container configuration for autonomous cloud research nodes.

### B. Firestore Seeding (`scripts/firestore_seeding/`)
* **`firestore_bulk_reaction_seeder.py`**: High-performance multi-threaded streamer that generates and uploads reactions to Firestore `/library` (currently **2.85M+ reactions** live), handling quota limits and token refresh automatically.
* **`firestore_fix_legacy_reactions.py`**: Maintenance script to migrate older Firestore documents to modern schemas.
* **`firestore_upload_derived_jsonl.py`**: Batch uploader for derived reaction JSONL files.
* **`firestore_enrich_clinical_library.py`**: Annotates medical reactions with clinical and pharmacological metadata.

### C. Dataset Generators (`scripts/dataset_generators/`)
* **`generate_medical_reactions.py`**: Combinatorial reaction engine generating chemical pathways across medical specialties.
* **`export_medical_dart.py`**: Compiles generated reactions into zero-latency Dart source files embedded in the Flutter app.
* **`export_pharmacopeia_dart.py`**: Builds the official Quantum Forge Pharmacopeia catalog.
* **`enrich_all_templates_with_catalysts.py`**: Adds organometallic and enzymatic catalysts to reaction templates.
* **`generate_synthetic_db.py`**: Generates synthetic databases for offline testing.

### D. Quality Audits & Benchmarks (`scripts/quality_audits/`)
* **`audit_and_fix_template_dois.py`**: Verifies and repairs DOI references in reaction templates.
* **`capture_cardio_audit.py`**: Validates hemodynamic pressure curves and electrophysiology waveforms.
* **`capture_oscilloscope_realism.py`**: Tests medical monitor oscilloscope rendering and thermal paper output.
* **`verify_library_and_history_tags.py`**: Cross-checks Firestore library tags against client-side search filters.
* **`01_curate_transition1x.py` - `07_build_test_set.py`**: Data curation, conversion, validation, and MACE model benchmarking suite.

### E. Service Management (`scripts/service_management/`)
* **`start_backend.sh`**: Launches local microservices on standardized ports.
* **`stop_backends.sh`**: Gracefully terminates background service processes.
* **`health_backends.sh`**: Probes health endpoints across all backend microservices.
* **`build_all_backends.sh`**: Triggers Docker builds across all service containers.

> **Backward Compatibility**: `scripts/autonomous_trainer/` and root `scripts/*.py` entrypoints are preserved with lightweight proxy wrappers so existing cron jobs, launchd daemons, and Docker builds never break.

---

## 4. Backend Microservices

| Microservice | Technology | What It Powers |
| --- | --- | --- |
| **`tx1-fastapi-backend/`** | FastAPI, PyTorch, ASE | Main computational chemistry backend: energy, forces, NEB optimization, PaiNN-Lite MLIP ensemble inference, and Avogadro 2 bridge. |
| **`cardiocath-backend/`** | FastAPI, PyTorch | CardioCath 3D: Wiggers diagrams, coronary fluoroscopy gantry kinematics, invasive hemodynamics, and cardiac PINN. |
| **`neurolab-backend/`** | FastAPI, PyTorch | NeuroLab 3D: Hodgkin-Huxley multi-compartment solver, EEG spectral power, and whole-nervous-system electrophysiology. |
| **`nephrolab-backend/`** | FastAPI, PyTorch | NephroLab 3D: Stewart acid-base equilibria, GFR modeling, and nephron solute transport. |
| **`seeder-backend/`** | FastAPI, Cloud Run | 24/7 dedicated background worker streaming reactions into Firestore `/library` with zero downtime. |
| **`mace-backend/`, `ani2x-backend/`, etc.** | Flask / FastAPI | Auxiliary containerized MLIP workers for benchmark comparisons. |

---

## 5. Client Application (`quantum_forge/`)

The client is a responsive Flutter Web application delivering zero-installation 3D simulation:

```
quantum_forge/lib/
├── core/                        # Global themes, constants, API endpoints, audio synthesis
├── features/                    # Modular feature workstations:
│   ├── cardiac/                 # CardioCath 3D: Catheterization, Fluoroscopy, Wiggers, Oscilloscope
│   ├── neuro/                   # NeuroLab 3D: Whole-Nervous-System 3D WebGL, Patch-Clamp, EEG
│   ├── nephro/                  # NephroLab 3D: Renal Acid-Base, Tubule Transport, GFR
│   ├── pulmo/                   # PulmoLab 3D: Respiratory Mechanics, Ventilator Waveforms
│   ├── dental/                  # DentoLab 3D: Maxillofacial, Endodontics, Dental Arch
│   ├── clinical_core/           # MultiOrganPatientState, 7-Pillar SaMD Legal Shield, Master Vitals
│   ├── reaction_library/        # Firestore 2.85M+ reaction browser & search
│   ├── reaction_runner/         # 3D NGL WebGL viewer, NEB trajectory player, energy profile chart
│   ├── pharmacopeia/            # Drug library, MOA, dosing, CYP450 metabolism
│   ├── pharmacogenomics/        # Genetic allele drug sensitivity matrix
│   ├── ddi/                     # Drug-Drug Interaction checker
│   ├── education/               # Clinical cases, OSCE simulations, Medical Board Q-Bank
│   └── ward/                    # Multi-bed virtual ICU & telemetry ward
├── screens/                     # Top-level screen layouts and navigation shells
└── state/                       # Riverpod state notifiers and reactive view-models
```

---

## 6. Research Data & Configurations

### Data Directory (`data/`)
* **`verified_literature_trajectories/`**: 364+ independently verified reaction pathways extracted from peer-reviewed publications (`.extxyz`).
* **`ledgers/`**: SQLite database (`literature_ledger.sqlite`) tracking paper harvest status, DOI verification, and training cycles.
* **`continual_replay_buffers/`**: JSONL log streams capturing continual learning runs and loss trajectories.
* **`autonomous_training/`**: Working directory utilized by active local and cloud harvester nodes.
* **`curated/`, `processed/`, `raw/`, `splits/`**: Transition1x dataset slices and zero-data-leakage splits.

### Configuration Directory (`configs/`)
* **`production/`**: Production cluster configurations (`mace_gcp_production.yaml`).
* **`local_dev/`**: Local workstation development configurations (`mace_local_dev.yaml`).
* **`testing/`**: Continuous integration and smoke-test configs (`mace_local_smoke.yaml`).

---

## 7. Cloud Infrastructure (`infrastructure/`)

* **`infrastructure/cloudbuild/cloudbuild_harvester.yaml`**: Automated Google Cloud Build trigger building and deploying the autonomous harvester image to Google Artifact Registry.
* **`infrastructure/gcp/`**: Shell scripts for automating GCP Compute Engine Spot VMs, distributed hyperparameter sweeps, and Google Cloud Storage artifact syncing.

---

## 8. Verification & Quality Assurance

All components are protected by automated tests across both backend and frontend:
* **Backend PyTest Suites**: 98+ tests across TX1, CardioCath, NeuroLab, NephroLab, and Autonomous Trainer (`pytest tests/`).
* **Flutter Test Suites**: 564 automated unit, widget, and integration tests (`cd quantum_forge && flutter test`).
* **Flutter Static Analysis**: Zero analyzer warnings or lints (`cd quantum_forge && flutter analyze`).
