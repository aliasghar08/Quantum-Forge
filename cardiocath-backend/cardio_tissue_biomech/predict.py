"""Inference for CardioTissue-BiomechNet."""

from __future__ import annotations

import os
from pathlib import Path
import time
from typing import Dict, List, Any, Tuple

import torch
from .network import CardioTissueBiomechNet, BIOMECH_MODALITIES

_BIOMECH_CACHE: Dict[str, Any] = {}

def load_biomech_model(checkpoint_path: str | None = None) -> Tuple[CardioTissueBiomechNet, torch.device]:
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    if "model" in _BIOMECH_CACHE:
        return _BIOMECH_CACHE["model"], device

    if checkpoint_path is None:
        p = Path(__file__).resolve().parent / "checkpoints" / "cardio_tissue_biomech_best.pt"
        backend_p = Path(__file__).resolve().parents[2] / "cardiocath-backend" / "checkpoints" / "cardio_tissue_biomech_best.pt"
        checkpoint_path = str(p) if p.exists() else str(backend_p)

    model = CardioTissueBiomechNet().to(device)
    if os.path.exists(checkpoint_path):
        ckpt = torch.load(checkpoint_path, map_location=device, weights_only=False)
        state_dict = ckpt["model_state_dict"] if "model_state_dict" in ckpt else ckpt
        model.load_state_dict(state_dict)
    model.eval()
    _BIOMECH_CACHE["model"] = model
    return model, device


def predict_plaque_biomechanics(
    calcification_arc_deg: float = 180.0,
    calcium_thickness_mm: float = 0.8,
    lesion_length_mm: float = 24.0,
    ref_diam_mm: float = 3.0,
    baseline_lvef: float = 50.0,
    modality: str = "Shockwave_IVL",
    nominal_atm: float = 16.0,
) -> Dict[str, Any]:
    t0 = time.perf_counter()
    model, device = load_biomech_model()

    if modality not in BIOMECH_MODALITIES:
        modality = "Shockwave_IVL"
    m_idx = float(BIOMECH_MODALITIES.index(modality))

    x = torch.tensor([[
        float(calcification_arc_deg),
        float(calcium_thickness_mm),
        float(lesion_length_mm),
        float(ref_diam_mm),
        float(baseline_lvef),
        m_idx,
        float(nominal_atm),
    ]], device=device)

    with torch.no_grad():
        preds = model(x)

    elapsed_ms = (time.perf_counter() - t0) * 1000.0

    frac_atm = round(float(preds["fracture_threshold_atm"].item()), 1)
    exp_idx = round(float(preds["stent_expansion_index"].item()), 3)
    recoil = round(float(preds["acute_recoil_pct"].item()), 1)
    lvef_d = round(float(preds["lvef_recovery_delta"].item()), 1)
    strain_list = [round(float(v), 2) for v in preds["strain_17_segments"].squeeze(0).cpu().tolist()]

    return {
        "modality": modality,
        "calcific_plaque_fracture_threshold_atm": frac_atm,
        "stent_expansion_index": exp_idx,
        "is_optimal_expansion": bool(exp_idx >= 0.85),
        "acute_recoil_pct": recoil,
        "post_revasc_lvef_expected": round(baseline_lvef + lvef_d, 1),
        "lvef_recovery_delta": lvef_d,
        "aha_17_segment_strain_recovery": strain_list,
        "inference_latency_ms": round(elapsed_ms, 2),
        "engine": "CardioTissue-BiomechNet (MPS Residual Biomechanical Surrogate)",
    }
