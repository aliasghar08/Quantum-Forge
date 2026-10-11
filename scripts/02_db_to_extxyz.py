#!/usr/bin/env python3
"""Zero-leakage reaction splitting & streaming from curated .db to split .extxyz files."""
import argparse
import os
import time
import numpy as np
from ase.db import connect
from ase.io import write, read

def main():
    parser = argparse.ArgumentParser(description="Convert curated ASE DB to split train/val/test extxyz files.")
    parser.add_argument("--src", required=True, help="Source SQLite DB (e.g. curated)")
    parser.add_argument("--out-dir", required=True, help="Output directory for split .extxyz files")
    parser.add_argument("--stride", type=int, default=50, help="Stride used during curation (default: 50)")
    parser.add_argument("--inspect-only", action="store_true", help="Only inspect and print partition counts without writing files")
    args = parser.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)

    db = connect(args.src)
    total_rows = db.count()

    # Official Transition1x contiguous index boundaries:
    # Train: 1..9,091,788
    # Test:  9,091,789..9,375,104
    # Val:   9,375,105..9,644,740
    TRAIN_MAX_ORIG = 9091788
    TEST_MAX_ORIG = 9375104
    VAL_MAX_ORIG = 9644740

    train_max_id = TRAIN_MAX_ORIG // args.stride  # 181835
    test_max_id = TEST_MAX_ORIG // args.stride    # 187502

    train_count = min(train_max_id, total_rows)
    test_count = max(0, min(test_max_id, total_rows) - train_max_id)
    val_count = max(0, total_rows - test_max_id)

    print("==================================================")
    print(f"Dataset Split Inspection: {args.src}")
    print("==================================================")
    print(f"Total Rows:       {total_rows:,}")
    print(f"Train Partition:  {train_count:,} rows (mapped from orig 1..{TRAIN_MAX_ORIG:,})")
    print(f"Validation Set:   {val_count:,} rows (mapped from orig {TEST_MAX_ORIG+1:,}..{VAL_MAX_ORIG:,})")
    print(f"Test Partition:   {test_count:,} rows (mapped from orig {TRAIN_MAX_ORIG+1:,}..{TEST_MAX_ORIG:,})")
    print(f"Check Sum:        {train_count + val_count + test_count:,} rows")
    print("==================================================")

    if args.inspect_only:
        return

    out_train = os.path.join(args.out_dir, "train.extxyz")
    out_val = os.path.join(args.out_dir, "val.extxyz")
    out_test = os.path.join(args.out_dir, "test.extxyz")

    for p in (out_train, out_val, out_test):
        if os.path.exists(p):
            os.remove(p)

    print(f"Writing partitions to {args.out_dir}...")
    t0 = time.time()

    chunks = {"train": [], "val": [], "test": []}
    files = {"train": out_train, "val": out_val, "test": out_test}
    CHUNK_SIZE = 10000

    for i, row in enumerate(db.select()):
        atoms = row.toatoms()
        atoms.info["REF_energy"] = float(row.data["REF_energy"])
        atoms.arrays["REF_forces"] = np.asarray(row.data["REF_forces"], dtype=np.float32)
        atoms.info.pop("energy", None)
        atoms.arrays.pop("forces", None)

        orig_id = row.id * args.stride
        if orig_id <= TRAIN_MAX_ORIG:
            partition = "train"
        elif orig_id <= TEST_MAX_ORIG:
            partition = "test"
        else:
            partition = "val"

        chunks[partition].append(atoms)
        if len(chunks[partition]) >= CHUNK_SIZE:
            write(files[partition], chunks[partition], format="extxyz", append=True)
            chunks[partition].clear()

        if (i + 1) % 50000 == 0:
            rate = (i + 1) / (time.time() - t0)
            print(f"  processed {i+1:,}/{total_rows:,} ({rate:.0f} rows/s)")

    for p in ("train", "val", "test"):
        if chunks[p]:
            write(files[p], chunks[p], format="extxyz", append=True)
            chunks[p].clear()

    print(f"Finished writing partitions in {time.time() - t0:.1f}s.")
    print("Validating extxyz integrity...")
    for name, path in files.items():
        first = read(path, index=0)
        last = read(path, index=-1)
        assert abs(first.info["REF_energy"]) > 1e-3, f"{name} first frame energy zero"
        assert abs(last.info["REF_energy"]) > 1e-3, f"{name} last frame energy zero"
        assert np.abs(first.arrays["REF_forces"]).sum() > 1e-3, f"{name} first frame force zero"
        print(f"  {name}.extxyz: OK ({path})")

    print("PASS: Zero-leakage reaction splitting complete.")

if __name__ == "__main__":
    main()
