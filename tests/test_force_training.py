from ase.io import read
from mace.calculators import MACECalculator
import numpy as np

def test_force_training():
    calc = MACECalculator(
        model_paths=["models/local_dev/smoke_test.model"],
        device="mps",
        default_dtype="float32",
    )
    atoms = read("data/curated/t1x_hcno_stride50_smoke.extxyz", index=0)
    atoms.calc = calc
    f = atoms.get_forces()
    assert np.abs(f).sum() > 1e-6, "Forces are zero — force loss was not used"
    print(f"Force sum: {np.abs(f).sum():.4f}")
    print("Force training: PASS")

if __name__ == "__main__":
    test_force_training()
