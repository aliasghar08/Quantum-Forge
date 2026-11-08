"""CardioPINN-Hemodynamics: Physics-Informed Neural Operator for 1D-0D Coronary Hemodynamics.

Trained natively on Apple Silicon Metal GPU (torch.device("mps")) using analytical
1D Poiseuille/Navier-Stokes (Kirkeeide viscous + Borda-Carnot convective separation)
and 3-Element Windkessel (Rp, C, Rd) conservation residuals.
"""

from .network import CardioPINN, normalize_pinn_inputs
from .predict import (
    load_pinn_model,
    predict_hemodynamics_point,
    predict_spatial_profile,
    predict_virtual_cohort,
)

__all__ = [
    "CardioPINN",
    "normalize_pinn_inputs",
    "load_pinn_model",
    "predict_hemodynamics_point",
    "predict_spatial_profile",
    "predict_virtual_cohort",
]
