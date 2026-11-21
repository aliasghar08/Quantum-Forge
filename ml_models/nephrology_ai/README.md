# Nephrology & Renal Clearance AI Suite

This directory contains the neural networks and physical surrogates powering **NephroLab 3D** (`/nephro`) and `nephrolab-backend/`.

## Model Models

* **`nephro_pinn_glomerular/`**: Glomerular ultrafiltration PINN (15,561 parameters) solving capillary Starling equilibrium ($\Delta P - \Delta \Pi$), single-nephron GFR, and podocyte slit diaphragm shear stress.
* **`nephro_tox_gnn/`**: Drug-induced nephrotoxicity GNN (15,718 parameters) predicting proximal tubular necrosis probability and early biomarker elevation (KIM-1, NGAL).
* **`dialysis_kinetics_net/`**: Solute kinetic modeling network (13,543 parameters) predicting two-pool urea and creatinine clearance, dialyzer efficiency ($K_d$), and single-pool $Kt/V$.
