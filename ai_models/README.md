# Quantum Forge Centralized AI & Machine Learning Models Directory (`ai_models/`)

This directory houses all neural networks, machine learning surrogate models, physics-informed neural networks (PINNs), graph neural networks (GNNs), and equivariant neural potentials across Quantum Forge. Every folder and file is named with self-explanatory, human-readable terminology.

---

## Directory & Subsystem Organization

```
ai_models/
├── cardiovascular_electrophysiology/
│   ├── cardiac_action_potential_model/              # Aliev-Panfilov & Hodgkin-Huxley AP duration predictor
│   │   ├── cardiac_action_potential_network.py
│   │   ├── cardiac_action_potential_predictor.py
│   │   ├── train_action_potential_on_gpu.py
│   │   └── checkpoints/
│   ├── cardiac_3d_myocardial_strain_fno/             # 3D Fourier Neural Operator for myocardial wave mechanics
│   │   ├── myocardial_strain_fourier_neural_operator_network.py
│   │   ├── myocardial_strain_fno_predictor.py
│   │   ├── train_myocardial_strain_fno_on_gpu.py
│   │   └── checkpoints/
│   ├── cardiorenal_crosstalk_interaction_gnn/       # Graph Neural Network for multi-organ toxicity & cardiorenal syndrome
│   │   ├── cardiorenal_interaction_gnn_network.py
│   │   ├── cardiorenal_toxicity_gnn_predictor.py
│   │   ├── train_cardiorenal_gnn_on_gpu.py
│   │   └── checkpoints/
│   ├── cardiac_physics_informed_neural_net/         # Physics-informed neural net enforcing cardiac ODE/PDE laws
│   │   ├── aliev_panfilov_pinn_network.py
│   │   ├── cardiac_action_potential_pinn_predictor.py
│   │   ├── train_cardiac_pinn_on_gpu.py
│   │   └── checkpoints/
│   └── cardiac_3d_rotor_spiral_wave_model/          # Arrhythmia spiral wave rotor core localization network
│       ├── ventricular_rotor_spiral_wave_network.py
│       ├── rotor_spiral_wave_predictor.py
│       ├── train_rotor_model_on_gpu.py
│       └── checkpoints/
│
├── nephrology_renal_ai/
│   ├── dialysis_urea_clearance_kinetics_net/        # Multi-compartment hemodialysis solute clearance model
│   │   ├── dialysis_solute_clearance_kinetics_network.py
│   │   ├── dialysis_clearance_predictor.py
│   │   ├── train_dialysis_model_on_gpu.py
│   │   └── checkpoints/
│   ├── glomerular_filtration_physics_informed_net/  # PINN enforcing Starling capillary-Bowman pressure conservation
│   │   ├── glomerular_filtration_pinn_network.py
│   │   ├── glomerular_filtration_predictor.py
│   │   ├── train_glomerular_pinn_on_gpu.py
│   │   └── checkpoints/
│   └── drug_induced_nephrotoxicity_gnn/             # Molecular GNN screening for acute tubular necrosis
│       ├── renal_tubular_toxicity_gnn_network.py
│       ├── nephrotoxicity_predictor.py
│       ├── train_nephrotoxicity_gnn_on_gpu.py
│       └── checkpoints/
│
├── neurology_brain_ai/
│   ├── blood_brain_barrier_permeability_gnn/        # Molecular GNN predicting logBB penetration & efflux
│   │   ├── blood_brain_barrier_gnn_network.py
│   │   ├── blood_brain_barrier_predictor.py
│   │   ├── train_bbb_gnn_on_gpu.py
│   │   └── checkpoints/
│   ├── cerebral_perfusion_fourier_neural_operator/  # 3D FNO predicting stroke penumbra cerebral blood flow
│   │   ├── cerebral_hemodynamics_fno_network.py
│   │   ├── cerebral_perfusion_predictor.py
│   │   ├── train_cerebral_perfusion_fno_on_gpu.py
│   │   └── checkpoints/
│   ├── cortical_spiking_neural_network/             # Izhikevich spiking neural network simulating cortical spike trains
│   │   ├── izhikevich_cortical_spiking_network.py
│   │   ├── cortical_spike_train_predictor.py
│   │   ├── train_spiking_network_on_gpu.py
│   │   └── checkpoints/
│   ├── synaptic_transmission_axon_propagation_net/ # Microscopic synaptic cleft & Ranvier saltatory conduction model
│   │   ├── synaptic_cleft_axon_conduction_network.py
│   │   ├── synaptic_axon_transmission_predictor.py
│   │   ├── train_synaptic_axon_net_on_gpu.py
│   │   └── checkpoints/
│   └── whole_nervous_system_connectome_model/       # 84-parcel Desikan-Killiany whole-brain connectome GNN
│       ├── whole_connectome_graph_network.py
│       ├── connectome_tractography_predictor.py
│       ├── train_connectome_model_on_gpu.py
│       └── checkpoints/
│
├── quantum_chemistry_potentials/
│   ├── equivariant_painn_transition_state_ensemble/ # 5-member rotation-equivariant PaiNN potential ensemble
│   │   ├── architecture/
│   │   │   └── painn_rotation_equivariant_potential_network.py
│   │   ├── training/
│   │   │   └── train_painn_on_apple_silicon_gpu.py
│   │   └── checkpoints/
│   └── external_foundation_mlip_wrappers/           # Foundation MLIP model wrappers
│       ├── mace/                                    # MACE-MP-0 Materials Potential
│       ├── ani2x/                                   # ANI-2x Organic Chemistry Potential
│       ├── chgnet/                                  # CHGNet Crystal Potential
│       └── gfn2_xtb/                                # GFN2-xTB Semiempirical Quantum Engine
│
├── pharmacology_intelligence_bionet/                # Multi-task deep neural network for drug MoA & bioavailability
│   ├── architecture/
│   │   └── pharmacology_intelligence_bionet_network.py
│   ├── training/
│   │   └── train_pharmacology_intelligence_model.py
│   └── checkpoints/
│
├── continual_learning_replay_engine/                # Autonomous 24/7 continuous fine-tuning pipeline
│   ├── checkpoints/
│   └── pipelines/
│
└── client_on_device_algorithms/                     # On-device Dart algorithms running client-side
    └── dart_algorithms/
        └── neural_reaction_trajectory_compressor.dart
```

---

## Backward Compatibility Guarantee

All model folders include automatic import shims (`__init__.py`, `network.py`, `predict.py`, `train_mps.py`) so existing microservices, Docker containers, and test suites continue executing without interruption whether calling legacy import paths or new descriptive modules.
