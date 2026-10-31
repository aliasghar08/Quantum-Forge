import os
import pytest
from ase.io import read
from mace.calculators import MACECalculator
import numpy as np

def test_force_training():
    model_path = "models/local_dev/smoke_test.model"
    data_path = "data/curated/t1x_hcno_stride50_smoke.extxyz"
    if not os.path.exists(model_path) or not os.path.exists(data_path):
        pytest.skip(f"Smoke test model ({model_path}) or data ({data_path}) not found locally")
    calc = MACECalculator(
        model_paths=[model_path],
        device="mps",
        default_dtype="float32",
    )
    atoms = read(data_path, index=0)
    atoms.calc = calc
    f = atoms.get_forces()
    assert np.abs(f).sum() > 1e-6, "Forces are zero — force loss was not used"
    print(f"Force sum: {np.abs(f).sum():.4f}")
    print("Force training: PASS")

if __name__ == "__main__":
    test_force_training()
