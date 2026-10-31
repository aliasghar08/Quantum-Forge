import os
import pytest
from ase.db import connect
import numpy as np

def test_curation():
    path = "data/curated/t1x_hcno_stride50.db"
    if not os.path.exists(path):
        pytest.skip(f"Database {path} not found")
    db = connect(path)
    n = db.count()
    if n == 0:
        pytest.skip(f"Database {path} has 0 rows (raw data not downloaded)")
    assert n > 100000, f"Only {n} rows in curated dataset"
    sample = [db.get(id=i) for i in range(1, 101)]
    for row in sample:
        assert abs(row.data["REF_energy"]) > 1e-3
        assert np.abs(row.data["REF_forces"]).sum() > 1e-3
        assert all(int(z) in {1, 6, 7, 8} for z in row.numbers)
    print(f"Curation: PASS ({n} rows)")

if __name__ == "__main__":
    test_curation()
