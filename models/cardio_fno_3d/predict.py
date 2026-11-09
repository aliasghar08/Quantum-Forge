"""
Inference API for CardioFNO-3D Myocardial Strain & Torsion Operator.
"""

from pathlib import Path
from typing import Dict, Any, List, Optional
import torch
import torch.nn as nn
from network import CardioFNO3D

AHA_17_SEGMENT_NAMES = [
    "1. Basal Anterior",
    "2. Basal Anteroseptal",
    "3. Basal Inferoseptal",
    "4. Basal Inferior",
    "5. Basal Inferolateral",
    "6. Basal Anterolateral",
    "7. Mid Anterior",
    "8. Mid Anteroseptal",
    "9. Mid Inferoseptal",
    "10. Mid Inferior",
    "11. Mid Inferolateral",
    "12. Mid Anterolateral",
    "13. Apical Anterior",
    "14. Apical Septal",
    "15. Apical Inferior",
    "16. Apical Lateral",
    "17. Apex",
]

_MODEL_CACHE = None


def get_model(device: Optional[torch.device] = None):
    global _MODEL_CACHE
    if _MODEL_CACHE is not None:
        return _MODEL_CACHE

    if device is None:
        device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

    ckpt_path = Path(__file__).resolve().parent / "checkpoints" / "cardio_fno_3d_best.pt"
    if not ckpt_path.exists():
        # Fallback to cardiocath-backend copy if available
        backend_ckpt = Path(__file__).resolve().parent.parent.parent / "cardiocath-backend" / "checkpoints" / "cardio_fno_3d_best.pt"
        if backend_ckpt.exists():
            ckpt_path = backend_ckpt

    model = CardioFNO3D().to(device)
    if ckpt_path.exists():
        ckpt = torch.load(ckpt_path, map_location=device)
        model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    _MODEL_CACHE = (model, device)
    return _MODEL_CACHE


def predict_myocardial_strain(
    pathology: str = "normal",
    edv_ml: float = 120.0,
    esv_ml: float = 50.0,
    sbp_mmhg: float = 120.0,
    dbp_mmhg: float = 80.0,
    hr_bpm: float = 72.0,
    lad_stenosis: float = 0.0,
    rca_stenosis: float = 0.0,
    lcx_stenosis: float = 0.0,
    is_revascularized: bool = False,
) -> Dict[str, Any]:
    """
    Computes regional 17-segment AHA strain tensors, GLS %, and LV torsion via CardioFNO-3D.
    """
    p = pathology.lower()
    is_amyloid = "amyloid" in p
    is_lbbb = "lbbb" in p
    if "stemi" in p or "lad" in p:
        lad_stenosis = max(lad_stenosis, 0.90)
    elif "inferior" in p or "rca" in p:
        rca_stenosis = max(rca_stenosis, 0.85)

    is_post_systolic = (lad_stenosis > 0.7 or rca_stenosis > 0.7) and not is_revascularized

    model, device = get_model()

    inp = torch.tensor(
        [
            [
                edv_ml / 200.0,
                esv_ml / 150.0,
                sbp_mmhg / 200.0,
                dbp_mmhg / 120.0,
                hr_bpm / 120.0,
                lad_stenosis,
                rca_stenosis,
                lcx_stenosis,
                1.0 if is_amyloid else 0.0,
                1.0 if is_lbbb else 0.0,
                1.0 if is_revascularized else 0.0,
                1.0 if is_post_systolic else 0.0,
            ]
        ],
        dtype=torch.float32,
        device=device,
    )

    with torch.no_grad():
        seg_out, glob_out = model(inp)

    strains = [round(float(s), 2) for s in seg_out[0].cpu().numpy()]
    gls = round(float(glob_out[0, 0].cpu().item()), 2)
    torsion_deg = round(float(glob_out[0, 1].cpu().item()), 2)
    radial_pct = round(float(glob_out[0, 2].cpu().item()), 2)
    circumf_pct = round(float(glob_out[0, 3].cpu().item()), 2)

    # Calculate Apical-to-Basal ratio for Amyloid detection
    basal_mean = sum(strains[0:6]) / 6.0
    mid_mean = sum(strains[6:12]) / 6.0
    apical_mean = sum(strains[12:17]) / 5.0
    apical_sparing_ratio = round(apical_mean / min(-1.0, (basal_mean + mid_mean) / 2.0), 2)

    segments_data = []
    for i in range(17):
        val = strains[i]
        # Clinical classification: Normal < -18%, Borderline -16 to -18%, Impaired > -16%
        status = "Normal" if val < -18.0 else ("Borderline" if val < -16.0 else "Impaired / Ischemic")
        segments_data.append(
            {
                "segment_id": i + 1,
                "name": AHA_17_SEGMENT_NAMES[i],
                "strain_percent": val,
                "status": status,
            }
        )

    return {
        "status": "success",
        "pathology": p,
        "is_revascularized": is_revascularized,
        "global_longitudinal_strain_gls_pct": gls,
        "lv_torsion_deg": torsion_deg,
        "radial_thickening_pct": radial_pct,
        "circumferential_strain_pct": circumf_pct,
        "apical_sparing_ratio": apical_sparing_ratio,
        "has_apical_sparing_flag": is_amyloid or (apical_sparing_ratio > 1.8),
        "has_septal_flash_flag": is_lbbb,
        "has_post_systolic_shortening": is_post_systolic,
        "segments": segments_data,
        "fno_architecture": "3-Layer SpectralConv1d Fourier Neural Operator on Apple Silicon MPS",
    }

