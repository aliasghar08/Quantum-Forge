# NephroLab 3D: Renal Physiology, Dialysis Kinetics & Glomerular Filtration Backend

Computational microservice powering the **NephroLab 3D** (`/nephro`) institutional nephrology workstation in Quantum Forge.

## Architectural Overview

* **Biophysical Glomerular & Tubular Solver**: Solves Starling capillary-Bowman dynamics, autoregulation (myogenic + tubuloglomerular feedback), and proximal/distal tubule countercurrent electrolyte transport.
* **ICU Stewart-Hamilton Acid-Base & Anion Gap**: Full quantitative acid-base modeling, Strong Ion Difference ($SID$), total non-volatile weak acids ($A_{TOT}$), and base excess.
* **Hemodialysis & CRRT Kinetic Modeling**: Solves single-pool ($spKt/V$), double-pool ($eKt/V$), solute clearance, and ultrafiltration rates.
* **PyTorch Nephrology Neural Suite**:
  * `NephroPINN-Glomerular`: Physics-informed neural net enforcing mass conservation across glomerular slit diaphragms.
  * `NephroTox-GNN`: Molecular graph neural network predicting drug-induced acute tubular necrosis (ATN) and crystal nephropathy.
  * `DialysisKineticsNet`: Multi-compartment solute clearance and urea rebound dynamics predictor.

## Microservice Entrypoints & Endpoints

* `main.py`: FastAPI server running on port `8004` (or Cloud Run service `nephrolab-backend`).
* `GET /health`: Healthcheck endpoint.
* `POST /api/nephro/simulate-dialysis`: Computes urea reduction ratio ($URR$), $Kt/V$, and electrolyte clearance.
* `POST /api/nephro/glomerular-pinn`: Glomerular hemodynamics and filtration barrier permeability.
* `POST /api/nephro/nephrotoxicity`: Drug screening for tubular toxicity and drug-induced acute kidney injury (AKI).

## Directory Structure

* `renal_solver.py`: Analytical and numerical Starling equations, countercurrent multiplier, and Stewart-Hamilton acid-base solver.
* `models_nephro/`: Deep learning architectures and inference pipelines for nephrology AI models.
* `checkpoints/`: Trained PyTorch weights for PINN, GNN, and kinetics models.
* `test_nephro.py`: Pytest suite validating glomerular, dialysis, and toxicity calculations.
