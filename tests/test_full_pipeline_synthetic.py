#!/usr/bin/env python3
"""Run the full pipeline against a synthetic DB.

Validates: curate, convert, splits, test-set builder, test-set verifier.
Any script that fails here will also fail on the real DB.
"""
import os
import shutil
import subprocess
import sys

PYTHON = sys.executable


def run(cmd, expect_fail=False):
    print(f"\n>>> {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print("STDERR:", result.stderr[-2000:])
        if not expect_fail:
            raise SystemExit(f"FAILED: {' '.join(cmd)}")
    return result


def main():
    # 0. Preserve any real DB or indices
    real_db = "data/raw/transition1x.db"
    backup = "data/raw/transition1x.db.realbak"
    if os.path.exists(real_db) and not os.path.exists(backup):
        shutil.copy(real_db, backup)

    # 1. Generate synthetic DB
    run([PYTHON, "scripts/make_synthetic_db.py"])

    # 2. Point the pipeline at the synthetic DB
    shutil.copy("data/raw/transition1x_synthetic.db", real_db)

    # 3. Curate with stride=1 (keep everything)
    run([PYTHON, "scripts/01_curate_transition1x.py",
         "--src", real_db,
         "--out", "data/curated/t1x_hcno_stride50.db",  # keep hardcoded name
         "--stride", "1"])

    # 4. Convert
    run([PYTHON, "scripts/02_convert_to_extxyz.py",
         "--src", "data/curated/t1x_hcno_stride50.db",
         "--out", "data/curated/t1x_hcno_stride50.extxyz"])

    # 5. Splits
    run([PYTHON, "scripts/03_validate_dataset.py"])

    # 6. Build test set
    run([PYTHON, "scripts/07_build_test_set.py"])

    # 7. Verify test set
    run([PYTHON, "tests/test_test_set.py"])

    # 8. Restore real DB
    if os.path.exists(backup):
        shutil.move(backup, real_db)
        print(f"\nRestored real DB from {backup}")

    print("\n=== SYNTHETIC PIPELINE: PASS ===")
    print("All scripts ran without error on synthetic data.")
    print("Ready to run on the real Transition1x DB.")


if __name__ == "__main__":
    main()
