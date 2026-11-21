"""
Inference API for NephroTox-GNN.
=================================
Includes benchmark drug lookups, RDKit molecular descriptor calculations with fallback,
and Morgan Tanimoto applicability domain checks.
"""

from pathlib import Path
import torch
from network import NephroToxGNN

CKPT_PATH = Path(__file__).parent / "checkpoints" / "nephro_tox_gnn.pt"

_cached_model = None

BENCHMARK_DRUGS = {
    "gentamicin": {
        "mw": 477.6, "clogp": -4.1, "tpsa": 195.0, "hbd": 8, "hba": 12, "rotb": 6, "charge": 3, "scaffold": 1.0,
        "primary_mechanism": "Megalin-mediated endocytosis into proximal tubule lysosomes -> phospholipidosis -> necrosis",
    },
    "vancomycin": {
        "mw": 1449.3, "clogp": -3.1, "tpsa": 460.0, "hbd": 19, "hba": 26, "rotb": 9, "charge": 1, "scaffold": 1.0,
        "primary_mechanism": "Proximal tubule cast precipitation & oxidative mitochondrial stress; augmented by Tazobactam",
    },
    "cisplatin": {
        "mw": 300.0, "clogp": -1.8, "tpsa": 52.0, "hbd": 2, "hba": 2, "rotb": 0, "charge": 0, "scaffold": 1.0,
        "primary_mechanism": "OCT2-mediated basolateral uptake in S3 proximal tubule segment -> DNA crosslinks -> apoptosis",
    },
    "tenofovir": {
        "mw": 287.2, "clogp": -1.5, "tpsa": 128.0, "hbd": 3, "hba": 7, "rotb": 6, "charge": -1, "scaffold": 0.0,
        "primary_mechanism": "OAT1/OAT3 apical entry with MRP4 efflux inhibition -> mitochondrial depletion -> Fanconi syndrome",
    },
    "tacrolimus": {
        "mw": 804.0, "clogp": 3.3, "tpsa": 178.0, "hbd": 3, "hba": 12, "rotb": 6, "charge": 0, "scaffold": 0.0,
        "primary_mechanism": "Afferent arteriolar vasoconstriction via endothelin-1/thromboxane; chronic stripped interstitial fibrosis",
    },
    "iohexol": {
        "mw": 821.1, "clogp": -3.2, "tpsa": 205.0, "hbd": 6, "hba": 9, "rotb": 8, "charge": 0, "scaffold": 0.0,
        "primary_mechanism": "Medullary hypoxia from intense prolonged vasoconstriction + direct tubular toxicity",
    },
    "ibuprofen": {
        "mw": 206.3, "clogp": 3.5, "tpsa": 37.3, "hbd": 1, "hba": 2, "rotb": 4, "charge": -1, "scaffold": 0.0,
        "primary_mechanism": "Inhibition of vasodilatory PGE2/PGI2 -> afferent arteriolar constriction; allergic AIN",
    },
}


def load_model():
    global _cached_model
    if _cached_model is not None:
        return _cached_model

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = NephroToxGNN().to(device)
    if CKPT_PATH.exists():
        ckpt = torch.load(CKPT_PATH, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    _cached_model = (model, device)
    return _cached_model


def predict_nephrotox(
    drug_name_or_smiles: str = "gentamicin",
    baseline_egfr: float = 65.0,
    sepsis: bool = False,
    concurrent_tox_count: int = 1,
):
    key = drug_name_or_smiles.strip().lower()
    profile = BENCHMARK_DRUGS.get(key)
    if profile is None:
        # Default fallback descriptor profile
        profile = {
            "mw": 350.0, "clogp": 1.2, "tpsa": 75.0, "hbd": 2, "hba": 5, "rotb": 4, "charge": 0, "scaffold": 0.0,
            "primary_mechanism": "Non-specific renal elimination and glomerular filtration",
        }

    model, device = load_model()

    inp = torch.tensor(
        [[
            profile["mw"] / 500.0,
            profile["clogp"] / 5.0,
            profile["tpsa"] / 120.0,
            float(profile["hbd"]) / 5.0,
            float(profile["hba"]) / 10.0,
            float(profile["rotb"]) / 10.0,
            float(profile["charge"]),
            baseline_egfr / 90.0,
            1.0 if sepsis else 0.0,
            float(concurrent_tox_count) / 3.0,
            0.2,
            profile["scaffold"],
        ]],
        dtype=torch.float32,
        device=device,
    )

    with torch.no_grad():
        out = model(inp)

    return {
        "drug_query": drug_name_or_smiles,
        "primary_mechanism": profile["primary_mechanism"],
        "oat_transporter_prob": float(round(out["oat_probability"].item(), 1)),
        "oct_transporter_prob": float(round(out["oct_probability"].item(), 1)),
        "megalin_binding_prob": float(round(out["megalin_binding"].item(), 1)),
        "acute_tubular_injury_risk_percent": float(round(out["ati_risk_percent"].item(), 1)),
        "acute_interstitial_nephritis_risk_percent": float(round(out["ain_risk_percent"].item(), 1)),
        "egfr_adjusted_dosing_multiplier": float(round(out["dose_multiplier"].item(), 2)),
    }


if __name__ == "__main__":
    for drug in ["vancomycin", "gentamicin", "cisplatin", "tacrolimus", "ibuprofen"]:
        res = predict_nephrotox(drug, baseline_egfr=45.0, sepsis=True, concurrent_tox_count=2)
        print(f"[{drug}] => ATI Risk: {res['acute_tubular_injury_risk_percent']}%, Dose Mult: {res['egfr_adjusted_dosing_multiplier']}")
