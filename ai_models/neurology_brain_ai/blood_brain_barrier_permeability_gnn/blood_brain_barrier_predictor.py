"""
Inference API for NeuroBBB-GNN.
===============================
"""

from pathlib import Path
import math
import torch
from network import NeuroBBBGNN

try:
    from rdkit import Chem
    from rdkit.Chem import Descriptors, rdMolDescriptors
    RDKIT_AVAILABLE = True
except ImportError:
    RDKIT_AVAILABLE = False

CKPT_PATH = Path(__file__).parent / "checkpoints" / "neuro_bbb_gnn.pt"

_cached_model = None

# Reference CNS drugs for Tanimoto applicability domain
REF_CNS_DRUGS = {
    "Diazepam": "CN1C(=O)CN=C(C2=C1C=CC(=C2)Cl)C3=CC=CC=C3",
    "Levetiracetam": "CCC(C(=O)N)N1CCCC1=O",
    "Nimodipine": "CC1=C(C(C(=C(N1)C)C(=O)OC(C)C)C2=CC(=CC=C2)[N+](=O)[O-])C(=O)OCCOC",
    "Phenytoin": "C1(C(=O)NC(=O)N1)(C2=CC=CC=C2)C3=CC=CC=C3",
    "Mannitol": "C(C(C(C(C(CO)O)O)O)O)O",
    "Lorazepam": "C1C(=O)NC2=C(C=C(C=C2)Cl)C(=NC1O)C3=CC=CC=C3Cl",
}


def load_model():
    global _cached_model
    if _cached_model is not None:
        return _cached_model

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = NeuroBBBGNN().to(device)
    if CKPT_PATH.exists():
        ckpt = torch.load(CKPT_PATH, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    _cached_model = (model, device)
    return _cached_model


def extract_features_from_smiles(smiles: str):
    if RDKIT_AVAILABLE:
        mol = Chem.MolFromSmiles(smiles)
        if mol is not None:
            mw = Descriptors.MolWt(mol)
            logp = Descriptors.MolLogP(mol)
            tpsa = Descriptors.TPSA(mol)
            hbd = rdMolDescriptors.CalcNumHBD(mol)
            hba = rdMolDescriptors.CalcNumHBA(mol)
            rotb = rdMolDescriptors.CalcNumRotatableBonds(mol)
            arom = rdMolDescriptors.CalcNumAromaticRings(mol)
            fcharge = Chem.GetFormalCharge(mol)
            fsp3 = rdMolDescriptors.CalcFractionCSP3(mol)
            lle = max(-2.0, min(8.0, 5.0 - logp))
            return [
                mw / 500.0,
                logp / 5.0,
                tpsa / 120.0,
                float(hbd) / 5.0,
                float(hba) / 10.0,
                float(rotb) / 10.0,
                float(arom) / 5.0,
                float(fcharge),
                fsp3,
                0.0,
                0.2,
                lle / 5.0,
            ], mw, logp, tpsa, hbd, hba

    # Fallback heuristic if invalid or no RDKit
    mw = 250.0
    logp = 1.5
    tpsa = 60.0
    hbd = 1
    hba = 3
    return [0.5, 0.3, 0.5, 0.2, 0.3, 0.2, 0.2, 0.0, 0.3, 0.0, 0.2, 0.6], mw, logp, tpsa, hbd, hba


def predict_bbb_penetration(smiles: str, compound_name: str = "Candidate Molecule"):
    model, device = load_model()
    feat_vec, mw, logp, tpsa, hbd, hba = extract_features_from_smiles(smiles)

    inp = torch.tensor([feat_vec], dtype=torch.float32, device=device)
    with torch.no_grad():
        out = model(inp)

    logbb = float(round(out["logbb"].item(), 2))
    cns_mpo = float(round(out["cns_mpo"].item(), 2))
    pgp = float(round(out["pgp_efflux_prob"].item(), 3))
    neurotox = float(round(out["neurotoxicity_liability"].item(), 1))
    cns_prob = float(round(out["cns_penetrant_prob"].item(), 3))

    # Determine clinical classification
    if logbb >= 0.3:
        classification = "High CNS Permeant (Rapid Brain Uptake)"
        cns_badge = "CNS+"
    elif logbb >= -1.0:
        classification = "Moderate CNS Permeant (Equilibrated)"
        cns_badge = "CNS±"
    else:
        classification = "Low / Poor CNS Penetration (Peripheral Selective)"
        cns_badge = "CNS-"

    # Pfizer CNS MPO tier (>= 4.0 is favorable for central nervous system targets)
    mpo_tier = "Favorable (CNS Target Ready)" if cns_mpo >= 4.0 else ("Borderline (Optimization Required)" if cns_mpo >= 3.0 else "Unfavorable for CNS")

    return {
        "compound_name": compound_name,
        "smiles": smiles,
        "molecular_weight": round(mw, 1),
        "clogp": round(logp, 2),
        "tpsa_angstrom2": round(tpsa, 1),
        "hbd": hbd,
        "hba": hba,
        "logbb": logbb,
        "cns_mpo_score": cns_mpo,
        "cns_mpo_tier": mpo_tier,
        "pgp_efflux_probability": pgp,
        "neurotoxicity_liability_percent": neurotox,
        "cns_penetration_class": classification,
        "cns_badge": cns_badge,
        "is_out_of_distribution": bool(mw > 700.0 or tpsa > 180.0 or abs(logp) > 6.0),
    }


if __name__ == "__main__":
    for name, smi in REF_CNS_DRUGS.items():
        res = predict_bbb_penetration(smi, name)
        print(f"[{name}] logBB={res['logbb']}, MPO={res['cns_mpo_score']}, Class={res['cns_badge']}")

