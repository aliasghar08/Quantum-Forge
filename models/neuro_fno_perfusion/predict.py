"""
Inference API for NeuroFNO-Perfusion.
=====================================
"""

from pathlib import Path
import torch
from network import NeuroFNOPerfusion

CKPT_PATH = Path(__file__).parent / "checkpoints" / "neuro_fno_perfusion.pt"

_cached_model = None


def load_model():
    global _cached_model
    if _cached_model is not None:
        return _cached_model

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = NeuroFNOPerfusion().to(device)
    if CKPT_PATH.exists():
        ckpt = torch.load(CKPT_PATH, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    _cached_model = (model, device)
    return _cached_model


def predict_perfusion(
    mean_arterial_pressure: float = 110.0,
    icp_mm_hg: float = 14.0,
    paco2_mm_hg: float = 40.0,
    hours_from_onset: float = 3.5,
    acom_patent: bool = True,
    pcom_patent: bool = True,
    leptomeningeal_grade: float = 0.66,
    occlusion_type: int = 1,  # 0=None, 1=Left M1, 2=Basilar, 3=ICA T, 4=Moyamoya
    is_revascularized: bool = False,
    systolic_bp: float = 150.0,
    diastolic_bp: float = 90.0,
    hematocrit: float = 0.42,
):
    model, device = load_model()

    inp = torch.tensor(
        [[
            mean_arterial_pressure / 100.0,
            icp_mm_hg / 20.0,
            paco2_mm_hg / 40.0,
            hours_from_onset / 12.0,
            1.0 if acom_patent else 0.0,
            1.0 if pcom_patent else 0.0,
            leptomeningeal_grade,
            float(occlusion_type),
            1.0 if is_revascularized else 0.0,
            systolic_bp / 140.0,
            diastolic_bp / 80.0,
            hematocrit / 0.45,
        ]],
        dtype=torch.float32,
        device=device,
    )

    with torch.no_grad():
        out = model(inp)

    reg = out["regional_perfusion"][0].cpu().numpy().tolist()

    return {
        "collateral_flow_index": float(round(out["collateral_flow_index"].item(), 1)),
        "core_volume_ml": float(round(out["core_volume_ml"].item(), 1)),
        "core_growth_rate_ml_hr": float(round(out["core_rate_ml_hr"].item(), 2)),
        "penumbra_volume_ml": float(round(out["penumbra_volume_ml"].item(), 1)),
        "tici_benefit_score": float(round(out["tici_benefit_score"].item(), 1)),
        "mca_perfusion_percent": float(round(reg[0], 1)),
        "aca_perfusion_percent": float(round(reg[1], 1)),
        "pca_perfusion_percent": float(round(reg[2], 1)),
    }


if __name__ == "__main__":
    res = predict_perfusion()
    print("NeuroFNO-Perfusion Output:", res)
