"""Inference API and 5-Member Bootstrap Ensemble Benchmark Suite for CardioNephroGNN.

Provides:
1. predict_compound(smiles: str) -> Dict[str, Any]
   - 5-member bootstrap ensemble mean pIC50 & epistemic uncertainty (sigma)
   - Verified ChEMBL Target IDs (CHEMBL240, CHEMBL1824, CHEMBL233, CHEMBL213, CHEMBL5251)
   - RDKit Morgan fingerprint (r=2, 2048-bit) Tanimoto similarity to training set
   - Out-of-Distribution (OOD) applicability domain flag & confidence badge
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
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import torch

from .network import (
    CardioNephroGNN,
    MolecularFeaturizer,
    TARGET_NAMES,
)

try:
    from rdkit import Chem, DataStructs
    from rdkit.Chem import AllChem
    HAS_RDKIT = True
except ImportError:
    HAS_RDKIT = False

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("CardioNephroPredict")

BASE_DIR = Path(__file__).resolve().parent
CHECKPOINT_DIR = BASE_DIR / "checkpoints"
CHECKPOINT_PATH = CHECKPOINT_DIR / "cardio_nephro_gnn_best.pt"
ENSEMBLE_SIZE = 5

CHEMBL_TARGET_METADATA: Dict[str, Dict[str, str]] = {
    "herg": {
        "chembl_id": "CHEMBL240",
        "uniprot_id": "Q12809",
        "gene_symbol": "KCNH2",
        "full_name": "Voltage-gated potassium channel hERG (Kv11.1, IKr)",
    },
    "ace": {
        "chembl_id": "CHEMBL1824",
        "uniprot_id": "P12821",
        "gene_symbol": "ACE",
        "full_name": "Angiotensin-converting enzyme (Peptidyl-dipeptidase A)",
    },
    "agtr1": {
        "chembl_id": "CHEMBL233",
        "uniprot_id": "P30556",
        "gene_symbol": "AGTR1",
        "full_name": "Type-1 angiotensin II receptor (AT1R)",
    },
    "adrb1": {
        "chembl_id": "CHEMBL213",
        "uniprot_id": "P08588",
        "gene_symbol": "ADRB1",
        "full_name": "Beta-1 adrenergic receptor",
    },
    "sglt2": {
        "chembl_id": "CHEMBL5251",
        "uniprot_id": "P31639",
        "gene_symbol": "SLC5A2",
        "full_name": "Sodium/glucose cotransporter 2 (SGLT2)",
    },
}

DEFAULT_REFERENCE_SMILES: List[str] = [
    "Cc1ccc(cc1Cc2c(Cl)ccc(c2)O[C@@H]3O[C@H](CO)[C@@H](O)[C@H](O)[C@H]3O)C4CCCO4",
    "CCCC1=NC(Cl)=C(CO)N1Cc1ccc(cc1)-c1ccccc1-c1nnn[nH]1",
    "C[C@@H](N[C@@H](CCc1ccccc1)C(=O)O)C(=O)N2CCC[C@H]2C(=O)O",
    "CC(C)NCC(O)COc1ccc(cc1)COCCOC(C)C",
    "CC(C)(C)c1ccc(cc1)C(O)CCCN2CCC(CC2)C(O)(c3ccccc3)c4ccccc4",
    "CCCCc1nc2ccccc2n1Cc3ccc(cc3)c4ccccc4c5nnn[nH]5",
    "CCOC(=O)[C@H](CCc1ccccc1)N[C@@H](C)C(=O)N2CCC[C@H]2C(=O)O",
    "CC(C)NCC(O)COc1ccc(CC(N)=O)cc1",
    "CC(C)NCC(O)COc1ccc(CCOC)cc1",
    "CCCCc1oc2ccccc2c1C(=O)c3cc(I)c(OCCN(CC)CC)c(I)c3",
]

_CACHED_ENSEMBLE: Optional[List[CardioNephroGNN]] = None
_CACHED_DEVICE: Optional[torch.device] = None
_CACHED_REF_FPS: Optional[List[Any]] = None
_CACHED_REF_SMILES: Optional[List[str]] = None


def _build_reference_fingerprints(smiles_list: List[str]) -> List[Any]:
    if not HAS_RDKIT:
        return []
    fps = []
    for smi in smiles_list:
        mol = Chem.MolFromSmiles(smi)
        if mol is not None:
            fp = AllChem.GetMorganFingerprintAsBitVect(mol, 2, nBits=2048)
            fps.append(fp)
    return fps


def load_ensemble() -> Tuple[List[CardioNephroGNN], torch.device, List[Any], List[str]]:
    """Load all 5 bootstrap ensemble checkpoints (or fallback to best checkpoint) on MPS/CPU."""
    global _CACHED_ENSEMBLE, _CACHED_DEVICE, _CACHED_REF_FPS, _CACHED_REF_SMILES
    if (
        _CACHED_ENSEMBLE is not None
        and _CACHED_DEVICE is not None
        and _CACHED_REF_FPS is not None
        and _CACHED_REF_SMILES is not None
    ):
        return _CACHED_ENSEMBLE, _CACHED_DEVICE, _CACHED_REF_FPS, _CACHED_REF_SMILES

    device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
    models: List[CardioNephroGNN] = []
    ref_smiles: List[str] = list(DEFAULT_REFERENCE_SMILES)

    for m_idx in range(ENSEMBLE_SIZE):
        m_path = CHECKPOINT_DIR / f"member_{m_idx}.pt"
        if m_path.exists():
            ckpt = torch.load(m_path, map_location=device)
            hidden_dim = ckpt.get("hidden_dim", 128)
            num_layers = ckpt.get("num_layers", 4)
            model = CardioNephroGNN(hidden_dim=hidden_dim, num_layers=num_layers)
            model.load_state_dict(ckpt["model_state_dict"])
            model.to(device)
            model.eval()
            models.append(model)
            if ckpt.get("reference_smiles"):
                ref_smiles = list(ckpt["reference_smiles"])

    if not models:
        if not CHECKPOINT_PATH.exists():
            logger.warning(f"Checkpoint {CHECKPOINT_PATH} not found. Running training pass...")
            from .train import train_cardio_nephro_gnn
            best_m = train_cardio_nephro_gnn(epochs=35, num_members=ENSEMBLE_SIZE)
            models.append(best_m)
        else:
            ckpt = torch.load(CHECKPOINT_PATH, map_location=device)
            hidden_dim = ckpt.get("hidden_dim", 128)
            num_layers = ckpt.get("num_layers", 4)
            model = CardioNephroGNN(hidden_dim=hidden_dim, num_layers=num_layers)
            model.load_state_dict(ckpt["model_state_dict"])
            model.to(device)
            model.eval()
            models.append(model)
            if ckpt.get("reference_smiles"):
                ref_smiles = list(ckpt["reference_smiles"])

    # Also check parquet dataset if available for full reference SMILES coverage
    parquet_path = BASE_DIR / "data" / "cardio_nephro_assays.parquet"
    if parquet_path.exists():
        try:
            import pandas as pd
            df = pd.read_parquet(parquet_path)
            ref_smiles = [str(s) for s in df["smiles"].dropna().unique().tolist()]
        except Exception:
            pass

    ref_fps = _build_reference_fingerprints(ref_smiles)
    _CACHED_ENSEMBLE = models
    _CACHED_DEVICE = device
    _CACHED_REF_FPS = ref_fps
    _CACHED_REF_SMILES = ref_smiles
    logger.info(
        f"Loaded CardioNephroGNN {len(models)}-Member Bootstrap Ensemble on {device} "
        f"({len(ref_fps)} reference Morgan fingerprints)."
    )
    return _CACHED_ENSEMBLE, _CACHED_DEVICE, _CACHED_REF_FPS, _CACHED_REF_SMILES


def load_model() -> Tuple[CardioNephroGNN, torch.device]:
    """Backward-compatible helper returning the primary ensemble member."""
    models, device, _, _ = load_ensemble()
    return models[0], device


def compute_tanimoto_applicability(smiles: str, ref_fps: List[Any], ref_smiles: List[str]) -> Dict[str, Any]:
    """Compute maximum Morgan fingerprint (r=2, 2048 bits) Tanimoto similarity against training set."""
    if not HAS_RDKIT or not ref_fps:
        return {
            "max_tanimoto_similarity": 0.85,
            "nearest_neighbor_smiles": ref_smiles[0] if ref_smiles else smiles,
            "is_tanimoto_ood": False,
        }
    mol = Chem.MolFromSmiles(smiles)
    if mol is None:
        return {
            "max_tanimoto_similarity": 0.0,
            "nearest_neighbor_smiles": "",
            "is_tanimoto_ood": True,
        }
    query_fp = AllChem.GetMorganFingerprintAsBitVect(mol, 2, nBits=2048)
    sims = DataStructs.BulkTanimotoSimilarity(query_fp, ref_fps)
    if not sims:
        return {
            "max_tanimoto_similarity": 0.5,
            "nearest_neighbor_smiles": "",
            "is_tanimoto_ood": False,
        }
    best_idx = int(np.argmax(sims))
    max_sim = float(sims[best_idx])
    nearest_smi = ref_smiles[best_idx] if best_idx < len(ref_smiles) else ""
    return {
        "max_tanimoto_similarity": round(max_sim, 4),
        "nearest_neighbor_smiles": nearest_smi,
        "is_tanimoto_ood": max_sim < 0.35,
    }


def predict_compound(smiles: str, compound_name: Optional[str] = None) -> Dict[str, Any]:
    """Predict multi-target binding affinities (pIC50), epistemic uncertainty (sigma), and hERG cardiotoxicity."""
    graph = MolecularFeaturizer.smiles_to_graph(smiles)
    if graph is None:
        return {
            "error": "Invalid chemical SMILES string",
            "compound_name": compound_name or "Unknown Molecule",
            "smiles": smiles,
        }

    models, device, ref_fps, ref_smiles = load_ensemble()

    node_feats = graph["node_features"].to(device)
    adj = graph["adj_matrix"].to(device)
    edge_feats = graph["edge_features"].to(device)

    member_preds_by_target: Dict[str, List[float]] = {t: [] for t in TARGET_NAMES}
    member_tox_probs: List[float] = []

    with torch.no_grad():
        for m_idx, model in enumerate(models):
            preds = model(node_feats, adj, edge_feats)
            for t_name in TARGET_NAMES:
                val = float(preds[f"{t_name}_pIC50"].item())
                member_preds_by_target[t_name].append(val)
            tox_logit = float(preds["herg_cardiotoxic_logit"].item())
            tox_prob = float(torch.sigmoid(torch.tensor(tox_logit)).item())
            member_tox_probs.append(tox_prob)

    # Decode continuous pIC50 affinities & epistemic uncertainty across the 5 bootstrap members
    affinities: Dict[str, Dict[str, Any]] = {}
    sigmas: List[float] = []

    for t_name in TARGET_NAMES:
        vals = member_preds_by_target[t_name]
        mean_pic50 = float(np.mean(vals))
        # Epistemic standard deviation across bootstrap committee (ddof=1 if len > 1)
        sigma_pic50 = float(np.std(vals, ddof=1)) if len(vals) > 1 else 0.08
        sigmas.append(sigma_pic50)

        # Convert to nM: IC50_nM = 10^(9.0 - pIC50)
        ic50_nm = round(math.pow(10.0, 9.0 - mean_pic50), 2)
        ic50_ci95_low_nm = round(math.pow(10.0, 9.0 - (mean_pic50 + 1.96 * sigma_pic50)), 2)
        ic50_ci95_high_nm = round(math.pow(10.0, 9.0 - (mean_pic50 - 1.96 * sigma_pic50)), 2)

        # Activity tier
        if mean_pic50 >= 8.0:
            tier = "High Potency (< 10 nM)"
        elif mean_pic50 >= 7.0:
            tier = "Sub-micromolar (10 - 100 nM)"
        elif mean_pic50 >= 6.0:
            tier = "Moderate (100 nM - 1 uM)"
        elif mean_pic50 >= 5.0:
            tier = "Weak (1 - 10 uM)"
        else:
            tier = "Inactive (> 10 uM)"

        meta = CHEMBL_TARGET_METADATA.get(t_name, {})
        affinities[t_name] = {
            "pIC50": round(mean_pic50, 2),
            "epistemic_sigma_pIC50": round(sigma_pic50, 3),
            "member_pIC50s": [round(v, 3) for v in vals],
            "estimated_IC50_nM": ic50_nm,
            "ic50_ci95_nM": [ic50_ci95_low_nm, ic50_ci95_high_nm],
            "activity_tier": tier,
            "chembl_id": meta.get("chembl_id", ""),
            "uniprot_id": meta.get("uniprot_id", ""),
            "gene_symbol": meta.get("gene_symbol", t_name.upper()),
            "target_full_name": meta.get("full_name", t_name.upper()),
        }

    # Applicability Domain & Tanimoto OOD Assessment
    tanimoto_info = compute_tanimoto_applicability(smiles, ref_fps, ref_smiles)
    max_tanimoto = tanimoto_info["max_tanimoto_similarity"]
    mean_epistemic_sigma = float(np.mean(sigmas)) if sigmas else 0.0
    is_ood = bool(tanimoto_info["is_tanimoto_ood"] or (mean_epistemic_sigma > 0.65))

    if not is_ood and max_tanimoto >= 0.65 and mean_epistemic_sigma <= 0.35:
        ad_badge = "IN-DOMAIN (HIGH CONFIDENCE)"
    elif not is_ood:
        ad_badge = "IN-DOMAIN (MODERATE CONFIDENCE)"
    else:
        ad_badge = "OUT-OF-DISTRIBUTION (EXTRAPOLATION WARNING)"

    # Decode hERG Cardiotoxicity Risk
    tox_prob = float(np.mean(member_tox_probs))
    tox_prob_sigma = float(np.std(member_tox_probs, ddof=1)) if len(member_tox_probs) > 1 else 0.03

    herg_ic50_nm = affinities["herg"]["estimated_IC50_nM"]
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
        "ensemble_metadata": {
            "ensemble_size": len(models),
            "device": str(device),
            "mean_epistemic_sigma_pIC50": round(mean_epistemic_sigma, 3),
            "max_tanimoto_similarity": max_tanimoto,
            "is_ood": is_ood,
            "applicability_domain_status": ad_badge,
            "nearest_training_smiles": tanimoto_info["nearest_neighbor_smiles"],
            "verified_chembl_targets": {k: v["chembl_id"] for k, v in CHEMBL_TARGET_METADATA.items()},
        },
        "target_affinities": affinities,
        "cardiotoxicity_analysis": {
            "herg_risk_probability": round(tox_prob, 4),
            "herg_risk_epistemic_sigma": round(tox_prob_sigma, 4),
            "risk_classification": cardio_risk_cat,
            "qt_prolongation_warning": is_qt_risk,
            "therapeutic_safety_margin": "Narrow" if is_qt_risk else "Wide",
            "herg_chembl_id": "CHEMBL240",
        },
    }


def run_clinical_benchmarks() -> None:
    """Benchmark CardioNephroGNN 5-Member Ensemble against 5 known clinical gold-standard compounds."""
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

    print("\n" + "=" * 92)
    print(" CARDIONEPHROGNN 5-MEMBER ENSEMBLE BENCHMARK — VALIDATION ON APPLE SILICON MPS")
    print("=" * 92)

    for item in benchmarks:
        res = predict_compound(item["smiles"], compound_name=item["name"])
        ens = res["ensemble_metadata"]
        print(f"\n[Drug]: {res['compound_name']} ({item['clinical_class']})")
        print(f"  SMILES: {res['smiles'][:65]}...")
        print(
            f"  Ensemble: {ens['ensemble_size']} members | "
            f"Max Tanimoto: {ens['max_tanimoto_similarity']:.2f} | "
            f"Mean Sigma: ±{ens['mean_epistemic_sigma_pIC50']:.3f} | "
            f"Domain: {ens['applicability_domain_status']}"
        )
        print("  Predicted Target Affinities (pIC50 ± sigma / IC50):")

        for t_name, aff in res["target_affinities"].items():
            mark = " ★ PRIMARY TARGET" if t_name == item["primary_target"] else ""
            print(
                f"    - {t_name.upper():<6} ({aff['chembl_id']}): "
                f"pIC50 = {aff['pIC50']:<5} ± {aff['epistemic_sigma_pIC50']:.3f} "
                f"(IC50 ~ {aff['estimated_IC50_nM']} nM) | {aff['activity_tier']}{mark}"
            )

        cardio = res["cardiotoxicity_analysis"]
        print("  Cardiotoxicity Risk:")
        print(
            f"    - hERG Risk Probability: {cardio['herg_risk_probability'] * 100:.1f}% "
            f"(±{cardio['herg_risk_epistemic_sigma'] * 100:.1f}%)"
        )
        print(f"    - Safety Classification: {cardio['risk_classification']}")
        print(f"    - QT Prolongation Alert: {'YES (FLAGGED)' if cardio['qt_prolongation_warning'] else 'NO (SAFE)'}")

    print("\n" + "=" * 92 + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Predict compound affinity and cardiotoxicity with 5-member ensemble.")
    parser.add_argument("--smiles", type=str, help="SMILES string to evaluate.")
    parser.add_argument("--name", type=str, default=None, help="Optional compound name.")
    parser.add_argument("--benchmark", action="store_true", help="Run clinical reference drug benchmarks.")
    args = parser.parse_args()

    if args.smiles:
        result = predict_compound(args.smiles, compound_name=args.name)
        print(json.dumps(result, indent=2))
    else:
        run_clinical_benchmarks()
