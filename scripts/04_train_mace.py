#!/usr/bin/env python3
"""Thin wrapper around mace.cli.run_train with environment validation."""
import argparse
import os
import subprocess
import sys

os.environ["TORCH_FORCE_NO_WEIGHTS_ONLY_LOAD"] = "1"

def validate_mps():
    import torch
    if not torch.backends.mps.is_available():
        print("Warning: MPS not available")
    else:
        try:
            x = torch.randn(4, 3, device="mps", requires_grad=True)
            y = (x ** 3).sum()
            g = torch.autograd.grad(y, x, create_graph=True)[0]
            g2 = torch.autograd.grad(g.sum(), x)[0]
            assert torch.isfinite(g2).all()
            print("MPS second-order autograd: PASS")
        except Exception as e:
            print(f"MPS second-order autograd FAILED: {e}")
            print("Falling back to CPU")
            return "cpu"
    return "mps"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", required=True)
    ap.add_argument("--device", default=None)
    args = ap.parse_args()

    device = args.device
    if device is None:
        device = validate_mps()

    cmd = [sys.executable, "-m", "mace.cli.run_train",
           "--config", args.config, "--device", device]
    print(f"Running: {' '.join(cmd)}")
    subprocess.run(cmd, check=True)

if __name__ == "__main__":
    main()
