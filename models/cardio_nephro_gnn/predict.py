"""Inference API and Benchmark Suite for CardioNephroGNN.

Provides:
1. predict_compound(smiles: str) -> Dict[str, Any]
2. Automated Clinical Benchmark on 5 Reference Drugs:
   - Empagliflozin (SGLT2 target)
   - Losartan (AGTR1 target)
   - Enalaprilat (ACE target)
   - Bisoprolol (ADRB1 target)
   - Terfenadine (hERG cardiotoxicity positive control)
"""

from __future__ import annotations

import argparse
import json
import logging
import math
import os
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import torch
import torch.nn.functional as F

from .network import (
    CardioNephroGNN,
    MolecularFeaturizer,
    TARGET_NAMES,
)

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("CardioNephroPredict")

BASE_DIR = Path(__file__).resolve().parent
CHECKPOINT_PATH = BASE_DIR / "checkpoints" / "cardio_nephro_gnn_best.pt"

_CACHED_MODEL: Optional[CardioNephroGNN] = None
_CACHED_DEVICE: Optional[torch.device] = None


def load_model() -> Tuple[CardioNephroGNN, torch.device]:
    """Load cached model or instantiate from checkpoint on MPS."""
    global _CACHED_MODEL, _CACHED_DEVICE
    if _CACHED_MODEL is not None and _CACHED_DEVICE is not None:
        return _CACHED_MODEL, _CACHED_DEVICE

    device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")

    if not CHECKPOINT_PATH.exists():
        logger.warning(f"Checkpoint {CHECKPOINT_PATH} not found. Running training pass...")
        from .train import train_cardio_nephro_gnn
        _CACHED_MODEL = train_cardio_nephro_gnn(epochs=30)
        _CACHED_DEVICE = device
        return _CACHED_MODEL, _CACHED_DEVICE

    checkpoint = torch.load(CHECKPOINT_PATH, map_location=device)
    hidden_dim = checkpoint.get("hidden_dim", 128)
    num_layers = checkpoint.get("num_layers", 4)

    model = CardioNephroGNN(hidden_dim=hidden_dim, num_layers=num_layers)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.to(device)
    model.eval()

    _CACHED_MODEL = model
    _CACHED_DEVICE = device
    logger.info(f"Loaded CardioNephroGNN from {CHECKPOINT_PATH} on {device}.")
    return _CACHED_MODEL, _CACHED_DEVICE


def predict_compound(smiles: str, compound_name: Optional[str] = None) -> Dict[str, Any]:
    """Predict multi-target binding affinities (pIC50) and hERG cardiotoxicity."""
    graph = MolecularFeaturizer.smiles_to_graph(smiles)
    if graph is None:
        return {
            "error": "Invalid chemical SMILES string",
            "compound_name": compound_name or "Unknown Molecule",
            "smiles": smiles,
        }

    model, device = load_model()

    node_feats = graph["node_features"].to(device)
    adj = graph["adj_matrix"].to(device)
    edge_feats = graph["edge_features"].to(device)

    with torch.no_grad():
        preds = model(node_feats, adj, edge_feats)

    # Decode continuous pIC50 affinities
    affinities: Dict[str, Dict[str, Any]] = {}
    for t_name in TARGET_NAMES:
        pic50 = float(preds[f"{t_name}_pIC50"].item())
        # Convert to nM: IC50_nM = 10^(9.0 - pIC50)
        ic50_nm = round(math.pow(10.0, 9.0 - pic50), 2)

        # Activity tier
        if pic50 >= 8.0:
            tier = "High Potency (< 10 nM)"
        elif pic50 >= 7.0:
            tier = "Sub-micromolar (10 - 100 nM)"
        elif pic50 >= 6.0:
            tier = "Moderate (100 nM - 1 uM)"
        elif pic50 >= 5.0:
            tier = "Weak (1 - 10 uM)"
        else:
            tier = "Inactive (> 10 uM)"

        affinities[t_name] = {
            "pIC50": round(pic50, 2),
            "estimated_IC50_nM": ic50_nm,
            "activity_tier": tier,
        }

    # Decode hERG Cardiotoxicity Risk
    tox_logit = float(preds["herg_cardiotoxic_logit"].item())
    tox_prob = float(torch.sigmoid(torch.tensor(tox_logit)).item())

    herg_ic50_nm = affinities["herg"]["estimated_IC50_nM"]
    # Clinical cutoff: < 10 uM (10,000 nM) indicates dangerous hERG inhibition
    is_qt_risk = (tox_prob >= 0.50) or (herg_ic50_nm < 10000.0)

    if tox_prob >= 0.70 or herg_ic50_nm < 3000.0:
        cardio_risk_cat = "HIGH RISK — Strong hERG Block (Risk of QT Prolongation / Torsades de Pointes)"
    elif tox_prob >= 0.40 or herg_ic50_nm < 10000.0:
        cardio_risk_cat = "MODERATE RISK — Borderline hERG Activity"
    else:
        cardio_risk_cat = "LOW RISK (SAFE) — Minimal hERG Channel Liability"

    return {
        "compound_name": compound_name or "Unknown Molecule",
        "smiles": smiles,
        "num_atoms": graph["num_atoms"],
        "target_affinities": affinities,
        "cardiotoxicity_analysis": {
            "herg_risk_probability": round(tox_prob, 4),
            "risk_classification": cardio_risk_cat,
            "qt_prolongation_warning": is_qt_risk,
            "therapeutic_safety_margin": "Narrow" if is_qt_risk else "Wide",
        },
    }


def run_clinical_benchmarks() -> None:
    """Benchmark CardioNephroGNN against 5 known clinical gold-standard compounds."""
    benchmarks = [
        {
            "name": "Empagliflozin",
            "smiles": "Cc1ccc(cc1Cc2c(Cl)ccc(c2)O[C@@H]3O[C@H](CO)[C@@H](O)[C@H](O)[C@H]3O)C4CCCO4",
            "clinical_class": "SGLT2 Inhibitor (Cardio-Renal Protective)",
            "primary_target": "sglt2",
        },
        {
            "name": "Losartan",
            "smiles": "CCCC1=NC(Cl)=C(CO)N1Cc1ccc(cc1)-c1ccccc1-c1nnn[nH]1",
            "clinical_class": "Angiotensin Receptor Blocker (ARB)",
            "primary_target": "agtr1",
        },
        {
            "name": "Enalaprilat",
            "smiles": "C[C@@H](N[C@@H](CCc1ccccc1)C(=O)O)C(=O)N2CCC[C@H]2C(=O)O",
            "clinical_class": "ACE Inhibitor (Heart Failure & Nephropathy)",
            "primary_target": "ace",
        },
        {
            "name": "Bisoprolol",
            "smiles": "CC(C)NCC(O)COc1ccc(cc1)COCCOC(C)C",
            "clinical_class": "Cardioselective Beta-1 Blocker",
            "primary_target": "adrb1",
        },
        {
            "name": "Terfenadine",
            "smiles": "CC(C)(C)c1ccc(cc1)C(O)CCCN2CCC(CC2)C(O)(c3ccccc3)c4ccccc4",
            "clinical_class": "Withdrawn Antihistamine (Known Fatal Torsades Inducer)",
            "primary_target": "herg",
        },
    ]

    print("\n" + "=" * 80)
    print(" CARDIONEPHROGNN CLINICAL BENCHMARK — VALIDATION ON APPLE SILICON MPS")
    print("=" * 80)

    for item in benchmarks:
        res = predict_compound(item["smiles"], compound_name=item["name"])
        print(f"\n[Drug]: {res['compound_name']} ({item['clinical_class']})")
        print(f"  SMILES: {res['smiles'][:65]}...")
        print(f"  Num Atoms: {res['num_atoms']}")
        print("  Predicted Target Affinities (pIC50 / IC50):")

        for t_name, aff in res["target_affinities"].items():
            mark = " ★ PRIMARY TARGET" if t_name == item["primary_target"] else ""
            print(f"    - {t_name.upper():<6}: pIC50 = {aff['pIC50']:<5} (IC50 ~ {aff['estimated_IC50_nM']} nM) | {aff['activity_tier']}{mark}")

        cardio = res["cardiotoxicity_analysis"]
        print(f"  Cardiotoxicity Risk:")
        print(f"    - hERG Risk Probability: {cardio['herg_risk_probability'] * 100:.1f}%")
        print(f"    - Safety Classification: {cardio['risk_classification']}")
        print(f"    - QT Prolongation Alert: {'YES (FLAGGED)' if cardio['qt_prolongation_warning'] else 'NO (SAFE)'}")

    print("\n" + "=" * 80 + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Predict compound affinity and cardiotoxicity.")
    parser.add_argument("--smiles", type=str, help="SMILES string to evaluate.")
    parser.add_argument("--name", type=str, default=None, help="Optional compound name.")
    parser.add_argument("--benchmark", action="store_true", help="Run clinical reference drug benchmarks.")
    args = parser.parse_args()

    if args.smiles:
        result = predict_compound(args.smiles, compound_name=args.name)
        print(json.dumps(result, indent=2))
    else:
        run_clinical_benchmarks()

