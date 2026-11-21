"""
Inference API for NephroPINN-Glomerular.
========================================
"""

from pathlib import Path
import torch
from network import NephroPINNGlomerular

CKPT_PATH = Path(__file__).parent / "checkpoints" / "nephro_pinn_glomerular.pt"

_cached_model = None


def load_model():
    global _cached_model
    if _cached_model is not None:
        return _cached_model

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = NephroPINNGlomerular().to(device)
    if CKPT_PATH.exists():
        ckpt = torch.load(CKPT_PATH, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    _cached_model = (model, device)
    return _cached_model


def predict_glomerular_hemodynamics(
    map_mm_hg: float = 93.0,
    afferent_tone_ra: float = 1.0,
    efferent_tone_re: float = 1.0,
    kf_ultrafiltration: float = 4.0,
    plasma_oncotic_pi: float = 25.0,
    bowman_pressure_pbs: float = 15.0,
    hematocrit: float = 0.42,
    condition_index: int = 0,
):
    model, device = load_model()

    inp = torch.tensor(
        [[
            map_mm_hg / 100.0,
            afferent_tone_ra,
            efferent_tone_re,
            kf_ultrafiltration / 4.0,
            plasma_oncotic_pi / 25.0,
            bowman_pressure_pbs / 15.0,
            hematocrit / 0.45,
            float(condition_index),
        ]],
        dtype=torch.float32,
        device=device,
    )

    with torch.no_grad():
        out = model(inp)

    return {
        "p_gc_mm_hg": float(round(out["p_gc"].item(), 1)),
        "net_filtration_pressure_mm_hg": float(round(out["nfp"].item(), 1)),
        "sngfr_nl_min": float(round(out["sngfr"].item(), 1)),
        "egfr_ml_min": float(round(out["egfr"].item(), 1)),
        "renal_blood_flow_ml_min": float(round(out["rbf"].item(), 1)),
        "renal_plasma_flow_ml_min": float(round(out["rpf"].item(), 1)),
        "filtration_fraction_percent": float(round(out["ff"].item(), 1)),
        "urine_output_ml_hr": float(round(out["urine_output"].item(), 1)),
        "fena_percent": float(round(out["fena"].item(), 2)),
    }


if __name__ == "__main__":
    res = predict_glomerular_hemodynamics(map_mm_hg=95.0, condition_index=0)
    print("NephroPINN Prediction:", res)
