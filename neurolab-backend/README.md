# NeuroLab 3D: Whole Nervous System, Connectome & Neurophysiology Backend

Computational microservice powering the **NeuroLab 3D** (`/neuro`) workstation covering the Central Nervous System (CNS), Peripheral Nervous System (PNS), Autonomic Nervous System (ANS), and microscopic synaptic transmission in Quantum Forge.

## Architectural Overview

* **Biophysical Ionic & Cable Theory Engine**: Solves Goldman-Hodgkin-Katz (GHK) membrane potentials, Hodgkin-Huxley ($Na_V1.1\text{–}1.6$, $K_V1.1\text{–}1.4$) action potentials, and Rall's dendritic cable equations.
* **Cerebral Hemodynamics & Perfusion**: Solves Lassen's autoregulation curve ($MAP\text{ 50–150 mmHg}$), Monro-Kellie intracranial volume-pressure doctrine, and cerebral perfusion pressure ($CPP = MAP - ICP$).
* **PyTorch Neurology Neural Network Suite**:
  * `WholeNeuro-Connectome`: Graph neural network mapping structural connectivity across 84 Desikan-Killiany cortical and subcortical parcels.
  * `SynapseNet-Axon`: Spatio-temporal model simulating vesicle quantal release ($SNARE$ complex) and saltatory node of Ranvier conduction.
  * `NeuroSpikeNet`: Izhikevich cortical spiking model predicting spike trains and phase-locking.
  * `NeuroFNO-Perfusion`: 3D Fourier Neural Operator modeling ischemic penumbra perfusion deficits.
  * `NeuroBBB-GNN`: Molecular graph neural network predicting Blood-Brain Barrier logBB permeability.

## Microservice Entrypoints & Endpoints

* `main.py`: FastAPI server running on port `8003` (or Cloud Run service `neurolab-backend`).
* `GET /health`: Healthcheck endpoint.
* `POST /api/neuro/action-potential`: Hodgkin-Huxley and GHK ionic simulations.
* `POST /api/neuro/intracranial-pressure`: Monro-Kellie intracranial pressure and compliance curve.
* `POST /api/neuro/connectome`: Connectome graph Laplacian and tractography queries.
* `POST /api/neuro/bbb-permeability`: Blood-Brain Barrier drug penetration screening.

## Directory Structure

* `neuro_solver.py`: Biophysical solvers for cable theory, intracranial pressure, EEG frequency power spectra, and reflex arcs.
* `models_neuro/`: Neural network definitions for connectome, synapse, spiking, FNO, and BBB models.
* `checkpoints/`: Trained PyTorch checkpoints.
* `test_neuro_solver.py`: Pytest suite validating neurophysiology, cable equations, and connectome metrics.
