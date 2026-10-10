from ase.io import read
import numpy as np

def test_convert():
    first = read("data/curated/t1x_hcno_stride50.extxyz", index=0)
    last = read("data/curated/t1x_hcno_stride50.extxyz", index=-1)
    for atoms in (first, last):
        assert abs(atoms.info["REF_energy"]) > 1e-3
        assert np.abs(atoms.arrays["REF_forces"]).sum() > 1e-3
        assert "energy" not in atoms.info
        assert "forces" not in atoms.arrays
    print("Convert: PASS")

if __name__ == "__main__":
    test_convert()
