"""CardioElectrophys-Net: 1D Temporal Convolutional + Residual Neural Surrogate for
O'Hara-Rudy / CiPA Human Ventricular Cardiomyocyte Electrophysiology.

Trained natively on Apple Silicon M1 Pro Metal GPU (torch.device("mps")).
Chains directly with CardioNephroGNN multi-target pIC50 predictions to simulate
dose-dependent 600 ms action potential waveforms Vm(t), APD50/APD90 prolongation,
Early Afterdepolarizations (EADs), and CiPA qNet Torsades de Pointes risk.
"""

from .network import CardioElectrophysNet, AP_TIME_POINTS_MS
from .predict import (
    load_electrophys_model,
    predict_cipa_action_potential,
)

__all__ = [
    "CardioElectrophysNet",
    "AP_TIME_POINTS_MS",
    "load_electrophys_model",
    "predict_cipa_action_potential",
]

