#!/usr/bin/env python3
"""Run remaining ensemble members (2, 3, 4) and run calibration."""

import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

MEMBERS = [
    (2, 44),
    (3, 45),
    (4, 46),
]

def main():
    for member_id, seed in MEMBERS:
        out_ckpt = BASE_DIR / "models" / "ensemble_v2" / f"member_{member_id}.pt"
        cmd = [
            sys.executable,
            str(BASE_DIR / "scripts" / "train_ensemble.py"),
            "--member-id", str(member_id),
            "--seed", str(seed),
            "--architecture", "painn",
            "--epochs", "35",
            "--batch-size", "4",
            "--grad-accum", "8",
            "--lr", "1e-3",
            "--checkpoint-out", str(out_ckpt),
        ]
        print(f"\n=======================================================")
        print(f"Starting Ensemble Member {member_id} (Seed {seed})")
        print(f"=======================================================")
        subprocess.check_call(cmd)

    print("\n=======================================================")
    print("All 5 members trained! Running calibration...")
    print("=======================================================")
    calib_cmd = [
        sys.executable,
        str(BASE_DIR / "scripts" / "calibrate_uncertainty.py"),
        "--test-data", str(BASE_DIR / "data" / "test.jsonl"),
    ]
    subprocess.check_call(calib_cmd)
    print("✔ Uncertainty Calibration Complete!")

if __name__ == "__main__":
    main()
