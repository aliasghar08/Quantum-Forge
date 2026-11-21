"""
Inference API for DialysisKinetics-Net.
=======================================
"""

from pathlib import Path
import torch
from network import DialysisKineticsNet

CKPT_PATH = Path(__file__).parent / "checkpoints" / "dialysis_kinetics_net.pt"

_cached_model = None


def load_model():
    global _cached_model
    if _cached_model is not None:
        return _cached_model

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = DialysisKineticsNet().to(device)
    if CKPT_PATH.exists():
        ckpt = torch.load(CKPT_PATH, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    _cached_model = (model, device)
    return _cached_model


def predict_dialysis_kinetics(
    modality_index: int = 0,  # 0=IHD, 1=CVVHDF, 2=PD
    qb_ml_min: float = 350.0,
    qd_ml_min: float = 600.0,
    uf_rate_ml_hr: float = 800.0,
    duration_hours: float = 4.0,
    weight_kg: float = 70.0,
    pre_bun_mg_dl: float = 80.0,
    pre_k_meq_l: float = 5.5,
    pre_hco3_meq_l: float = 20.0,
    dialyzer_koa: float = 800.0,
):
    model, device = load_model()

    inp = torch.tensor(
        [[
            float(modality_index),
            qb_ml_min / 350.0,
            qd_ml_min / 600.0,
            uf_rate_ml_hr / 1000.0,
            duration_hours / 4.0,
            weight_kg / 70.0,
            pre_bun_mg_dl / 80.0,
            pre_k_meq_l / 5.5,
            pre_hco3_meq_l / 20.0,
            dialyzer_koa / 800.0,
        ]],
        dtype=torch.float32,
        device=device,
    )

    with torch.no_grad():
        out = model(inp)

    return {
        "sp_ktv": float(round(out["sp_ktv"].item(), 2)),
        "e_ktv": float(round(out["e_ktv"].item(), 2)),
        "urr_percent": float(round(out["urr_percent"].item(), 1)),
        "post_bun_mg_dl": float(round(out["post_bun_mg_dl"].item(), 1)),
        "idh_risk_percent": float(round(out["idh_risk_percent"].item(), 1)),
        "dds_osmotic_gradient_mosm_kg": float(round(out["dds_osmotic_gradient"].item(), 1)),
        "effluent_dose_ml_kg_hr": float(round(out["effluent_dose_ml_kg_hr"].item(), 1)),
    }


if __name__ == "__main__":
    res = predict_dialysis_kinetics()
    print("DialysisKinetics-Net Output:", res)
