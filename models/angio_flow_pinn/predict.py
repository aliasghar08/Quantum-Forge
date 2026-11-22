"""Inference & vFFR/QFR evaluation for AngioFlow-PINN."""

from __future__ import annotations

import os
from pathlib import Path
import time
from typing import Dict, List, Any, Tuple

import torch
from .network import AngioFlowPINN, ANGIO_VESSELS, ANGIO_INPUT_DIM

_MODEL_CACHE: Dict[str, Any] = {}

def load_angio_flow_model(checkpoint_path: str | None = None) -> Tuple[AngioFlowPINN, torch.device]:
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    if "model" in _MODEL_CACHE:
        return _MODEL_CACHE["model"], device

    if checkpoint_path is None:
        default_p = Path(__file__).resolve().parent / "checkpoints" / "angio_flow_pinn_best.pt"
        backend_p = Path(__file__).resolve().parents[2] / "cardiocath-backend" / "checkpoints" / "angio_flow_pinn_best.pt"
        if default_p.exists():
            checkpoint_path = str(default_p)
        elif backend_p.exists():
            checkpoint_path = str(backend_p)
        else:
            checkpoint_path = str(default_p)

    model = AngioFlowPINN().to(device)
    if os.path.exists(checkpoint_path):
        ckpt = torch.load(checkpoint_path, map_location=device, weights_only=False)
        state_dict = ckpt["model_state_dict"] if "model_state_dict" in ckpt else ckpt
        model.load_state_dict(state_dict)
    model.eval()
    _MODEL_CACHE["model"] = model
    return model, device


def predict_angio_qfr(
    vessel: str = "LAD",
    stenosis_pct: float = 75.0,
    lesion_length_mm: float = 20.0,
    ref_diam_mm: float = 3.0,
    calcification_deg: float = 90.0,
    heart_rate_bpm: float = 72.0,
    map_mmhg: float = 93.0,
    contrast_flow_rate: float = 4.0,
    num_spatial_points: int = 10,
) -> Dict[str, Any]:
    t0 = time.perf_counter()
    model, device = load_angio_flow_model()

    v_idx = float(ANGIO_VESSELS.index(vessel) if vessel in ANGIO_VESSELS else 1)
    axial_points = torch.linspace(0.0, 1.0, num_spatial_points, device=device).unsqueeze(-1)
    n = num_spatial_points

    inputs = torch.zeros((n, ANGIO_INPUT_DIM), device=device)
    inputs[:, 0] = v_idx
    inputs[:, 1] = float(stenosis_pct)
    inputs[:, 2] = float(lesion_length_mm)
    inputs[:, 3] = float(ref_diam_mm)
    inputs[:, 4] = float(calcification_deg)
    inputs[:, 5] = float(heart_rate_bpm)
    inputs[:, 6] = float(map_mmhg)
    inputs[:, 7] = float(contrast_flow_rate)
    inputs[:, 8] = axial_points.squeeze(-1)

    with torch.no_grad():
        preds = model(inputs)

    elapsed_ms = (time.perf_counter() - t0) * 1000.0

    vffr_profile = preds["vffr"].squeeze(-1).cpu().tolist()
    tawss_profile = preds["tawss"].squeeze(-1).cpu().tolist()
    osi_profile = preds["osi"].squeeze(-1).cpu().tolist()

    distal_vffr = round(float(vffr_profile[-1]), 3)
    distal_ctfc = round(float(preds["ctfc"][0].item()), 1)
    distal_mbg = round(float(preds["mbg"][0].item()), 2)
    mean_tawss = round(float(sum(tawss_profile) / len(tawss_profile)), 2)
    max_osi = round(float(max(osi_profile)), 3)
    bolus_v = round(float(preds["bolus_v"][0].item()), 1)

    # Heuristic SYNTAX score addition based on vessel territory + stenosis + calcification
    syntax_base = 3.5 if vessel in ["LM", "LAD"] else 2.0
    if stenosis_pct >= 70:
        syntax_base += 2.0
    if calcification_deg >= 180:
        syntax_base += 1.0
    if lesion_length_mm >= 20:
        syntax_base += 1.0

    return {
        "vessel": vessel,
        "vffr_qfr": distal_vffr,
        "is_hemodynamically_significant": bool(distal_vffr <= 0.80),
        "ctfc": distal_ctfc,
        "mbg": distal_mbg,
        "mean_tawss_dynes_cm2": mean_tawss,
        "peak_osi": max_osi,
        "contrast_bolus_velocity_cm_s": bolus_v,
        "syntax_score_segment": round(syntax_base, 1),
        "spatial_vffr_curve": [round(v, 3) for v in vffr_profile],
        "spatial_tawss_curve": [round(t, 2) for t in tawss_profile],
        "inference_latency_ms": round(elapsed_ms, 2),
        "engine": "AngioFlow-PINN (MPS Metal Physics-Informed Operator)",
    }
