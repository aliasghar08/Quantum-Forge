#!/usr/bin/env python3
"""Phase E: Train an individual member of the uncertainty quantification ensemble."""

import argparse
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description="Train ensemble member on MPS.")
    parser.add_argument("--member-id", type=int, required=True)
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--architecture", type=str, default="painn", choices=["legacy", "rbf_cutoff", "painn"])
    parser.add_argument("--epochs", type=int, default=300)
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--grad-accum", type=int, default=8)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--checkpoint-out", type=str, default=None)
    parser.add_argument("--log-dir", type=str, default="data/runs/")
    args = parser.parse_args()

    out_ckpt = args.checkpoint_out or str(BASE_DIR / "models" / "ensemble_v2" / f"member_{args.member_id}.pt")
    Path(out_ckpt).parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        sys.executable,
        str(BASE_DIR / "scripts" / "train_mps.py"),
        "--architecture", args.architecture,
        "--seed", str(args.seed),
        "--epochs", str(args.epochs),
        "--batch-size", str(args.batch_size),
        "--grad-accum", str(args.grad_accum),
        "--lr", str(args.lr),
        "--checkpoint-out", out_ckpt,
        "--log-dir", args.log_dir,
    ]

    print(f"=== Training Ensemble Member {args.member_id} (Seed {args.seed}) ===")
    print("Command:", " ".join(cmd))
    subprocess.check_call(cmd)
    print(f"✔ Ensemble member {args.member_id} completed successfully.")


if __name__ == "__main__":
    main()
