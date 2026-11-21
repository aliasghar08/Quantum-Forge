#!/usr/bin/env python3
"""Filter + stride Transition1x. Emits a clean .db with REF_energy/REF_forces."""
import argparse
import os
import time
from ase.db import connect
import numpy as np

HCNO = {1, 6, 7, 8}

def passes_filters(row):
    z = row.numbers
    if not all(int(x) in HCNO for x in z):
        return False, "element"
    if not hasattr(row, "data"):
        return False, "no_data"
    data = row.data
    if "energy" not in data or "forces" not in data:
        return False, "missing_keys"
    e = data["energy"]
    f = np.asarray(data["forces"])
    if e is None or not np.isfinite(e) or abs(e) < 1e-3:
        return False, "zero_energy"
    if f.size == 0 or not np.isfinite(f).all() or abs(f).sum() < 1e-3:
        return False, "zero_forces"
    return True, "ok"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="data/raw/transition1x.db")
    ap.add_argument("--out", required=True)
    ap.add_argument("--stride", type=int, default=5)
    args = ap.parse_args()

    if os.path.exists(args.out):
        os.remove(args.out)

    src = connect(args.src)
    total = src.count()
    print(f"Source: {total} rows, stride={args.stride}")

    dst = connect(args.out)
    kept = 0
    skipped = {"element": 0, "no_data": 0, "missing_keys": 0,
               "zero_energy": 0, "zero_forces": 0}
    t0 = time.time()

    for row in src.select():
        if row.id % args.stride != 0:
            continue
        ok, reason = passes_filters(row)
        if not ok:
            skipped[reason] = skipped.get(reason, 0) + 1
            continue
        atoms = row.toatoms()
        dst.write(
            atoms,
            data={
                "REF_energy": float(row.data["energy"]),
                "REF_forces": np.asarray(row.data["forces"], dtype=np.float32),
            },
            key_value_pairs={"rxn_id": row.key_value_pairs.get("rxn_id", "")},
        )
        kept += 1
        if kept % 50000 == 0:
            rate = kept / (time.time() - t0)
            print(f"  kept={kept} rate={rate:.0f}/s skipped={skipped}")

    print(f"DONE: kept={kept} skipped={skipped}")
    assert kept > 0, "Kept zero rows — schema mismatch"
    assert skipped["missing_keys"] == 0, "Missing keys — inspect row.data"
    last = dst.get(id=dst.count())
    assert abs(last.data["REF_energy"]) > 1e-3
    print("PASS")

if __name__ == "__main__":
    main()
