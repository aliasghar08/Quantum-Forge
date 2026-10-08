"""Regenerate the four Group A templates from correct SMILES.

Run from the repo root with the backend virtualenv active:

    cd tx1-fastapi-backend
    ./venv/bin/python scripts/regen_group_a.py

The script prints four Python string literals in Dart-escaped form, ready to
paste into `reaction_templates.dart`. It also writes the same output to
`scripts/group_a_output.json` for the seed script to consume.
"""

import json
from pathlib import Path
from rdkit import Chem
from rdkit.Chem import AllChem, rdMolDescriptors

TEMPLATES = {
    "diels_alder": {
        "name": "Diels-Alder: butadiene + ethylene",
        "reactant_smiles": "C=CC=C.C=C",
        "product_smiles": "C1CCC=CC1",
        "reactant_title": "Diels-Alder: butadiene + ethylene",
        "product_title": "Diels-Alder: cyclohexene",
    },
    "retro_da": {
        "name": "Retro-Diels-Alder",
        "reactant_smiles": "C1CCC=CC1",
        "product_smiles": "C=CC=C.C=C",
        "reactant_title": "Retro-Diels-Alder: cyclohexene",
        "product_title": "Retro-Diels-Alder: butadiene + ethylene",
    },
    "decarboxylation": {
        "name": "Decarboxylation of malonic acid",
        "reactant_smiles": "O=C(O)CC(=O)O",
        "product_smiles": "CC(=O)O.O=C=O",
        "reactant_title": "Decarboxylation: malonic acid",
        "product_title": "Decarboxylation: acetic acid + CO2",
    },
    "e2_elimination": {
        "name": "E2 elimination of 2-bromobutane",
        "reactant_smiles": "CCC(C)Br",
        "product_smiles": "CC=CC.[H]Br",
        "reactant_title": "E2: 2-bromobutane",
        "product_title": "E2: 2-butene + HBr",
    },
}


def xyz_from_smiles(smiles: str, title: str, seed: int = 42) -> str:
    mol = Chem.MolFromSmiles(smiles)
    if mol is None:
        raise ValueError(f"RDKit could not parse SMILES: {smiles!r}")
    mol = Chem.AddHs(mol)
    if AllChem.EmbedMolecule(mol, randomSeed=seed) != 0:
        raise RuntimeError(f"RDKit could not embed 3D coords for {smiles!r}")
    AllChem.MMFFOptimizeMolecule(mol)
    conf = mol.GetConformer()
    lines = [str(mol.GetNumAtoms()), title]
    for i, atom in enumerate(mol.GetAtoms()):
        p = conf.GetAtomPosition(i)
        lines.append(f"{atom.GetSymbol()} {p.x:.6f} {p.y:.6f} {p.z:.6f}")
    return "\n".join(lines)


def main() -> None:
    out: dict[str, dict[str, str]] = {}
    for tid, cfg in TEMPLATES.items():
        r_xyz = xyz_from_smiles(cfg["reactant_smiles"], cfg["reactant_title"])
        p_xyz = xyz_from_smiles(cfg["product_smiles"], cfg["product_title"])

        # Sanity: both sides must have the same formula.
        r_formula = rdMolDescriptors.CalcMolFormula(
            Chem.AddHs(Chem.MolFromSmiles(cfg["reactant_smiles"]))
        )
        p_formula = rdMolDescriptors.CalcMolFormula(
            Chem.AddHs(Chem.MolFromSmiles(cfg["product_smiles"]))
        )
        if r_formula != p_formula:
            raise ValueError(
                f"{tid}: formulas differ — reactant {r_formula}, product {p_formula}"
            )

        out[tid] = {
            "name": cfg["name"],
            "reactant_xyz": r_xyz,
            "product_xyz": p_xyz,
            "formula": r_formula,
        }
        print(f"=== {tid} ({r_formula}) ===")
        print("--- reactant ---")
        print(r_xyz)
        print("--- product ---")
        print(p_xyz)
        print()

    Path("scripts/group_a_output.json").write_text(json.dumps(out, indent=2))
    print(f"Wrote {len(out)} templates to scripts/group_a_output.json")


if __name__ == "__main__":
    main()
