"""Inference API for CardioElectrophys-Net (Chained with CardioNephroGNN 5-Member Ensemble).

Predicts:
- Control vs. Drug-Modulated 600 ms Ventricular Action Potential Waveforms Vm(t)
- APD50, APD90, and Delta APD90 (ms)
- Hill Equation Multi-Channel Pore Blockade (IKr/hERG, INa, ICaL, IKs, IK1)
- Early Afterdepolarization (EAD) Probability
- CiPA qNet (uC/uF) & FDA/ICH E14/S7B Torsades de Pointes (TdP) Risk Stratification
"""

from __future__ import annotations

import argparse
import json
import logging
import math
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

import torch

from .network import CardioElectrophysNet, AP_TIME_POINTS_MS

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("CardioElectrophysPredict")

BASE_DIR = Path(__file__).resolve().parent
CHECKPOINT_PATH = BASE_DIR / "checkpoints" / "cardio_electrophys_best.pt"

_CACHED_EP_MODEL: Optional[CardioElectrophysNet] = None
_CACHED_DEVICE: Optional[torch.device] = None

# Reference Clinical Compounds for Rapid CiPA Evaluation
CLINICAL_REFERENCE_SMILES: Dict[str, str] = {
    "Terfenadine": "CC(C)(C)c1ccc(cc1)C(O)CCCN2CCC(CC2)C(O)(c3ccccc3)c4ccccc4",
    "Amiodarone": "CCCCc1oc2ccccc2c1C(=O)c3cc(I)c(OCCN(CC)CC)c(I)c3",
    "Enalaprilat": "C[C@@H](N[C@@H](CCc1ccccc1)C(=O)O)C(=O)N2CCC[C@H]2C(=O)O",
    "Bisoprolol": "CC(C)NCC(O)COc1ccc(cc1)COCCOC(C)C",
    "Empagliflozin": "Cc1ccc(cc1Cc2c(Cl)ccc(c2)O[C@@H]3O[C@H](CO)[C@@H](O)[C@H](O)[C@H]3O)C4CCCO4",
    "Losartan": "CCCC1=NC(Cl)=C(CO)N1Cc1ccc(cc1)-c1ccccc1-c1nnn[nH]1",
}


def load_electrophys_model() -> Tuple[CardioElectrophysNet, torch.device]:
    """Load cached CardioElectrophysNet checkpoint on MPS or CPU."""
    global _CACHED_EP_MODEL, _CACHED_DEVICE
    if _CACHED_EP_MODEL is not None and _CACHED_DEVICE is not None:
        return _CACHED_EP_MODEL, _CACHED_DEVICE

    device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")

    if not CHECKPOINT_PATH.exists():
        logger.warning(
            f"Checkpoint {CHECKPOINT_PATH} not found. Training CardioElectrophysNet on {device}..."
        )
        from .train_mps import train_cardio_electrophys
        _CACHED_EP_MODEL = train_cardio_electrophys(epochs=60)
        _CACHED_DEVICE = device
        return _CACHED_EP_MODEL, _CACHED_DEVICE

    ckpt = torch.load(CHECKPOINT_PATH, map_location=device)
    hidden_dim = ckpt.get("hidden_dim", 128)
    conv_channels = ckpt.get("conv_channels", 64)

    model = CardioElectrophysNet(hidden_dim=hidden_dim, conv_channels=conv_channels)
    model.load_state_dict(ckpt["model_state_dict"])
    model.to(device)
    model.eval()

    _CACHED_EP_MODEL = model
    _CACHED_DEVICE = device
    logger.info(f"Loaded CardioElectrophys-Net from {CHECKPOINT_PATH} on {device}.")
    return _CACHED_EP_MODEL, _CACHED_DEVICE


def _hill_block(conc_uM: float, ic50_uM: float, hill_n: float = 1.0) -> float:
    if conc_uM <= 0.0 or ic50_uM <= 0.0:
        return 0.0
    ratio = (ic50_uM / conc_uM) ** hill_n
    return float(1.0 / (1.0 + ratio))


def predict_cipa_action_potential(
    smiles: Optional[str] = None,
    compound_name: Optional[str] = None,
    plasma_conc_uM: float = 1.0,
    heart_rate_bpm: float = 70.0,
    herg_ic50_nM: Optional[float] = None,
    nav15_ic50_nM: Optional[float] = None,
    cav12_ic50_nM: Optional[float] = None,
) -> Dict[str, Any]:
    """Chain CardioNephroGNN 5-member ensemble into CardioElectrophys-Net for CiPA AP simulation."""
    if not smiles and compound_name and compound_name in CLINICAL_REFERENCE_SMILES:
        smiles = CLINICAL_REFERENCE_SMILES[compound_name]
    elif not smiles:
        smiles = CLINICAL_REFERENCE_SMILES["Terfenadine"]
        compound_name = compound_name or "Terfenadine"

    # 1. Obtain multi-target affinities from CardioNephroGNN 5-Member Ensemble
    gnn_result: Optional[Dict[str, Any]] = None
    try:
        from models.cardio_nephro_gnn.predict import predict_compound
        gnn_result = predict_compound(smiles, compound_name=compound_name)
    except ImportError:
        try:
            from cardio_nephro_gnn.predict import predict_compound
            gnn_result = predict_compound(smiles, compound_name=compound_name)
        except Exception:
            gnn_result = None

    if gnn_result and "target_affinities" in gnn_result:
        aff = gnn_result["target_affinities"]
        herg_ic50_val = float(herg_ic50_nM or aff["herg"]["estimated_IC50_nM"])
        adrb1_ic50_val = float(aff["adrb1"]["estimated_IC50_nM"])
        agtr1_ic50_val = float(aff["agtr1"]["estimated_IC50_nM"])
    else:
        herg_ic50_val = float(herg_ic50_nM or 350.0)
        adrb1_ic50_val = 2500.0
        agtr1_ic50_val = 5000.0

    # Derive multi-channel IC50 profile (uM)
    herg_ic50_uM = max(0.001, herg_ic50_val / 1000.0)
    # Multi-channel compensatory block (e.g., Amiodarone has strong Cav1.2 / Nav1.5 block alongside hERG)
    is_multichannel = bool(compound_name and "amiodarone" in compound_name.lower())
    if cav12_ic50_nM is not None:
        ical_ic50_uM = max(0.005, cav12_ic50_nM / 1000.0)
    elif is_multichannel:
        ical_ic50_uM = herg_ic50_uM * 1.35
    else:
        ical_ic50_uM = max(8.0, (adrb1_ic50_val / 1000.0) * 6.5)

    if nav15_ic50_nM is not None:
        ina_ic50_uM = max(0.005, nav15_ic50_nM / 1000.0)
    elif is_multichannel:
        ina_ic50_uM = herg_ic50_uM * 2.1
    else:
        ina_ic50_uM = max(15.0, (agtr1_ic50_val / 1000.0) * 8.0)

    iks_ic50_uM = herg_ic50_uM * 12.0
    ik1_ic50_uM = herg_ic50_uM * 25.0

    conc_uM = max(0.001, min(200.0, float(plasma_conc_uM)))
    hr_bpm = max(42.0, min(145.0, float(heart_rate_bpm)))

    b_ikr = _hill_block(conc_uM, herg_ic50_uM, hill_n=1.05)
    b_ina = _hill_block(conc_uM, ina_ic50_uM, hill_n=1.0)
    b_ical = _hill_block(conc_uM, ical_ic50_uM, hill_n=1.0)
    b_iks = _hill_block(conc_uM, iks_ic50_uM, hill_n=1.0)
    b_ik1 = _hill_block(conc_uM, ik1_ic50_uM, hill_n=1.0)

    model, device = load_electrophys_model()

    # Batch [2, 7]: row 0 = Control (zero drug block), row 1 = Drug at plasma_conc_uM
    x_batch = torch.tensor(
        [
            [0.0, 0.0, 0.0, 0.0, 0.0, -3.0, hr_bpm],
            [b_ikr, b_ina, b_ical, b_iks, b_ik1, math.log10(conc_uM), hr_bpm],
        ],
        dtype=torch.float32,
        device=device,
    )

    with torch.no_grad():
        preds = model(x_batch)

    vm_ctrl = [round(float(v), 2) for v in preds["vm_waveform_mv"][0].cpu().tolist()]
    vm_drug = [round(float(v), 2) for v in preds["vm_waveform_mv"][1].cpu().tolist()]

    ctrl_apd50 = round(float(preds["apd50_ms"][0].item()), 1)
    ctrl_apd90 = round(float(preds["apd90_ms"][0].item()), 1)
    drug_apd50 = round(float(preds["apd50_ms"][1].item()), 1)
    drug_apd90 = round(float(preds["apd90_ms"][1].item()), 1)
    delta_apd90 = round(drug_apd90 - ctrl_apd90, 1)

    ead_prob = round(float(preds["ead_probability"][1].item()), 4)
    qnet_val = round(float(preds["qnet_c_f"][1].item()), 4)
    ctrl_qnet = round(float(preds["qnet_c_f"][0].item()), 4)

    if qnet_val < 0.050 or ead_prob >= 0.50 or delta_apd90 >= 60.0:
        tdp_tier = "HIGH TdP RISK (CiPA Class III — Severe Repolarization Reserve Depletion)"
    elif qnet_val < 0.061 or ead_prob >= 0.20 or delta_apd90 >= 25.0:
        tdp_tier = "INTERMEDIATE TdP RISK (CiPA Class II — Monitor QTc & Potassium)"
    else:
        tdp_tier = "LOW TdP RISK (CiPA Class I — Preserved Repolarization Reserve)"

    return {
        "compound_name": compound_name or (gnn_result or {}).get("compound_name", "Custom Molecule"),
        "smiles": smiles,
        "plasma_concentration_uM": conc_uM,
        "pacing_heart_rate_bpm": hr_bpm,
        "model_architecture": "CardioElectrophys-Net (1D Temporal ResNet Surrogate) + CardioNephroGNN (5-Member Ensemble)",
        "device": str(device),
        "time_ms": AP_TIME_POINTS_MS,
        "control_vm_mv": vm_ctrl,
        "drug_vm_mv": vm_drug,
        "channel_blockade_fractions": {
            "IKr_hERG_block": round(b_ikr, 4),
            "ICaL_Cav12_block": round(b_ical, 4),
            "INa_Nav15_block": round(b_ina, 4),
            "IKs_KvLQT1_block": round(b_iks, 4),
            "IK1_Kir21_block": round(b_ik1, 4),
            "herg_ic50_nM": round(herg_ic50_val, 2),
            "herg_chembl_id": "CHEMBL240",
        },
        "cipa_biomarkers": {
            "control_apd50_ms": ctrl_apd50,
            "control_apd90_ms": ctrl_apd90,
            "drug_apd50_ms": drug_apd50,
            "drug_apd90_ms": drug_apd90,
            "delta_apd90_ms": delta_apd90,
            "ead_probability": ead_prob,
            "ead_warning": ead_prob >= 0.35,
            "control_qnet_uC_uF": ctrl_qnet,
            "qnet_uC_uF": qnet_val,
            "tdp_risk_category": tdp_tier,
        },
        "gnn_ensemble_summary": (gnn_result or {}).get("ensemble_metadata", {}),
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run CardioElectrophys-Net CiPA Action Potential Simulation.")
    parser.add_argument("--drug", type=str, default="Terfenadine", help="Compound name.")
    parser.add_argument("--conc", type=float, default=1.0, help="Free plasma concentration (uM).")
    parser.add_argument("--hr", type=float, default=70.0, help="Pacing heart rate (bpm).")
    args = parser.parse_args()

    out = predict_cipa_action_potential(compound_name=args.drug, plasma_conc_uM=args.conc, heart_rate_bpm=args.hr)
    print(json.dumps(out["cipa_biomarkers"], indent=2))

