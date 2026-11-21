# CardioCath 3D: Interventional Cardiology, Electrophysiology & Hemodynamics Backend

High-performance computational microservice powering the **CardioCath 3D Lab** (`/cardiac`) simulation suite in Quantum Forge.

## Architectural Overview

* **Cardiovascular Sciences Engine**: Solves pulsatile Navier-Stokes coronary hemodynamics, Murray's Law bifurcation branching, and DK-Crush / Culotte / TAP stenting fluid shear stress.
* **5-Channel ICU Bedside Oscilloscope**: Real-time Lead II & V1 ECG, invasive arterial blood pressure (ABP Pa/Pd with dicrotic notch), SpO2 plethysmograph, and EtCO2 capnogram.
* **Cardiorenal Multi-Organ Coupling**: Bidirectional integration with `NephroLab 3D` computing cardiorenal syndromes (Types 1–5), RAAS activation, and glomerular-perfusion crosstalk.
* **4-Model PyTorch Neural Network Suite**:
  * `CardioElectrophysNet`: Action potential duration ($APD_{90}$) and hERG channel blockade prediction.
  * `CardioNephroGNN`: Molecular graph neural network predicting multi-organ cardiorenal toxicity.
  * `CardioPINN`: Physics-informed neural network enforcing Aliev-Panfilov reaction-diffusion equations.
  * `CardioFNO-3D`: 3D Fourier Neural Operator modeling myocardial strain wave propagation.

## Microservice Entrypoints & Endpoints

* `main.py`: FastAPI server running on port `8002` (or Cloud Run service `cardiocath-backend`).
* `GET /health`: Healthcheck endpoint.
* `POST /api/cardiac/hemodynamics`: Computes coronary perfusion, fractional flow reserve (FFR), and bifurcation fluid dynamics.
* `POST /api/cardiac/electrophysiology`: Computes QT prolongation, CiPA arrhythmia risk, and action potential curves.
* `POST /api/cardiac/rotor-mapping`: 3D spiral wave rotor core localization and phase singularity tracking.
* `POST /api/cardio-nephro/cross-talk`: Evaluates cardiorenal hemodynamic coupling.

## Directory Structure

* `hemodynamics_solver.py`: Navier-Stokes, Windkessel 3-element lumped-parameter model, and Murray's bifurcation mechanics.
* `cardio_electrophys/`: Action potential duration and hERG channel pharmacology model.
* `cardio_nephro_gnn/`: Cardiorenal toxicity graph neural network.
* `cardio_pinn/`: Aliev-Panfilov physics-informed neural network.
* `test_hemodynamics.py`: Comprehensive test suite verifying hemodynamic calculations and neural predictions.
