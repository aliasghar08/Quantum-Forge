#!/usr/bin/env python3
"""Stream curated .db into MACE-compatible .extxyz."""
import argparse
import os
import numpy as np
from ase.db import connect
from ase.io import write, read

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    if os.path.exists(args.out):
        os.remove(args.out)

    db = connect(args.src)
    n = db.count()
    print(f"Converting {n} rows to {args.out}")

    chunk = []
    CHUNK = 10000
    for i, row in enumerate(db.select()):
        atoms = row.toatoms()
        atoms.info["REF_energy"] = float(row.data["REF_energy"])
        atoms.arrays["REF_forces"] = np.asarray(row.data["REF_forces"], dtype=np.float32)
        atoms.info.pop("energy", None)
        atoms.arrays.pop("forces", None)
        chunk.append(atoms)

        if len(chunk) >= CHUNK:
            write(args.out, chunk, format="extxyz", append=True)
            chunk.clear()
            print(f"  wrote {i+1}/{n}")

    if chunk:
        write(args.out, chunk, format="extxyz", append=True)

    first = read(args.out, index=0)
    last = read(args.out, index=-1)
    assert abs(first.info["REF_energy"]) > 1e-3, "First frame zero energy"
    assert abs(last.info["REF_energy"]) > 1e-3, "Last frame zero energy"
    assert np.abs(first.arrays["REF_forces"]).sum() > 1e-3, "First frame zero forces"
    print("PASS")

if __name__ == "__main__":
    main()
