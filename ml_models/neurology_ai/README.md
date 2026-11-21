# Neurology & Neurovascular AI Suite

This directory contains the neural networks and biophysical surrogates powering **NeuroLab 3D** (`/neuro`) and `neurolab-backend/`.

## Model Models

* **`whole_neuro_connectome/`**: 10-axis clinical deficit lesion localizer (28,624 parameters) mapping 16-feature neurological deficits to anatomical axes with 100% test accuracy.
* **`synapse_net_axon/`**: Saltatory conduction and neuromuscular junction biophysical surrogate (9,607 parameters) parameterizing myelin thickness, nodal $Na_v$ conductance, and postsynaptic $nAChR$ receptors.
* **`neuro_spike_net/`**: Cortical action potential spiking model (19,816 parameters) generating intraoperative neurophysiological monitoring (IONM) waveforms.
* **`neuro_fno_perfusion/`**: 2D/3D cerebral perfusion neural operator (170,280 parameters) predicting CBF, CBV, MTT, and Tmax ischemic core/penumbra volumes.
* **`neuro_bbb_gnn/`**: Blood-brain barrier permeability GNN (15,684 parameters) predicting logBB and central nervous system multiparameter optimization (CNS MPO) scores.
