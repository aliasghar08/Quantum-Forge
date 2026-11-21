# Cardiovascular & Electrophysiology AI Suite

This directory contains the neural networks and physical surrogates powering **CardioCath 3D Lab** (`/cardiac`) and `cardiocath-backend/`.

## Model Models

* **`cardio_pinn/`**: Physics-Informed Neural Network (144,651 parameters) solving 1D pulsatile coronary Navier-Stokes momentum equations to estimate Fractional Flow Reserve (FFR), instantaneous wave-free ratio (iFR), and microvascular resistance index.
* **`cardio_electrophys/`**: 2D myocardial action potential surrogate (209,893 parameters) predicting conduction velocity, transmembrane potential ($V_m$), and action potential duration (APD90).
* **`cardio_nephro_gnn/`**: 5-member GNN ensemble (354,699 parameters) trained on ChEMBL bioactivity data for $hERG$, $Na_v1.5$, $Ca_v1.2$ cardiotoxicity, and renal clearance risk.
* **`cardio_fno_3d/`**: 3D Fourier Neural Operator (254,405 parameters) mapping pressure loads to regional myocardial strain bullseyes and Global Longitudinal Strain (GLS).
* **`cardio_rotor_3d/`**: 3D phase-singularity neural tracker (68,588 parameters) identifying re-entrant driver rotors for catheter ablation targeting.
