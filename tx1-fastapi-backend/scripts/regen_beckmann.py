from rdkit import Chem
from rdkit.Chem import AllChem

def xyz_from_smiles(smiles: str, title: str, seed: int = 42) -> str:
    mol = Chem.MolFromSmiles(smiles)
    mol = Chem.AddHs(mol)
    AllChem.EmbedMolecule(mol, randomSeed=seed)
    AllChem.MMFFOptimizeMolecule(mol)
    conf = mol.GetConformer()
    lines = [str(mol.GetNumAtoms()), title]
    for i, atom in enumerate(mol.GetAtoms()):
        p = conf.GetAtomPosition(i)
        lines.append(f"{atom.GetSymbol()} {p.x:.6f} {p.y:.6f} {p.z:.6f}")
    return "\n".join(lines)

if __name__ == "__main__":
    reactant = xyz_from_smiles("ON=C1CCCCC1", "Beckmann: Cyclohexanone oxime")
    product  = xyz_from_smiles("O=C1CCCCCN1", "Beckmann: Caprolactam")
    print("=== REACTANT ===")
    print(reactant)
    print("=== PRODUCT ===")
    print(product)
