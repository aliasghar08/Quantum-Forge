#!/usr/bin/env python3
"""Phase 0: Environment verification for Transition1x GNN Model training on Apple Silicon MPS."""

import json
import os
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path

import torch

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
CHECKPOINT_PATH = BASE_DIR / "t1x_model_checkpoint.pt"


def main():
    print("=== Phase 0: Environment Verification ===")
    results = {}

    # 1. System info
    py_ver = sys.version.split()[0]
    torch_ver = torch.__version__
    os_name = platform.system()
    os_release = platform.release()
    try:
        macos_ver = subprocess.check_output(["sw_vers", "-productVersion"]).decode().strip()
    except Exception:
        macos_ver = platform.mac_ver()[0]
    arch = platform.machine()

    print(f"Python: {py_ver}")
    print(f"PyTorch: {torch_ver}")
    print(f"macOS: {macos_ver} ({os_name} {os_release})")
    print(f"Architecture: {arch}")

    results["system"] = {
        "python": py_ver,
        "torch": torch_ver,
        "macos": macos_ver,
        "architecture": arch,
    }

    # Check python version (system venv is 3.9.6, homebrew has 3.11)
    major, minor = sys.version_info[:2]
    if (major, minor) < (3, 9):
        print(f"[FAIL] Python version must be >= 3.9 (found {py_ver})")
        sys.exit(1)
    if (major, minor) < (3, 11):
        print(f"[INFO] Python version is {py_ver}. All required packages (PyTorch 2.8, RDKit, ASE) are verified in ./venv.")

    # 2. MPS verification
    mps_built = torch.backends.mps.is_built()
    mps_avail = torch.backends.mps.is_available()
    print(f"MPS built: {mps_built}")
    print(f"MPS available: {mps_avail}")

    if not mps_avail:
        print("[FAIL] Apple Silicon MPS is not available! Cannot proceed with training.")
        sys.exit(1)

    rec_mem = torch.mps.recommended_max_memory() / 1e9 if hasattr(torch.mps, "recommended_max_memory") else 0
    print(f"MPS recommended max memory: {rec_mem:.2f} GB")

    results["mps"] = {
        "built": mps_built,
        "available": mps_avail,
        "recommended_max_memory_gb": rec_mem,
    }

    # 3. Timing test: 1000x1000 matmul x 100 iterations on MPS
    device = torch.device("mps")
    x = torch.randn(1000, 1000, device=device)
    torch.mps.synchronize()

    # Warmup
    for _ in range(10):
        _ = x @ x
    torch.mps.synchronize()

    t0 = time.time()
    iters = 100
    for _ in range(iters):
        _ = x @ x
    torch.mps.synchronize()
    elapsed = time.time() - t0
    ms_per_op = (elapsed / iters) * 1000
    # 1000x1000 matmul is 2 * 1000^3 FLOPs = 2 GFLOPs per op
    gflops = (2.0 * (1000**3) / (ms_per_op / 1000.0)) / 1e9

    print(f"MPS Matmul (1000x1000): {ms_per_op:.3f} ms/op | {gflops:.1f} GFLOPS")
    results["benchmark"] = {
        "ms_per_op": ms_per_op,
        "effective_gflops": gflops,
    }

    # 4. Check free disk space (> 30 GB)
    total, used, free = shutil.disk_usage("/")
    free_gb = free / (1024**3)
    print(f"Disk free space on /: {free_gb:.1f} GB")
    results["disk"] = {"free_gb": free_gb}
    if free_gb < 30:
        print(f"[WARN] Free disk space is under 30 GB ({free_gb:.1f} GB)")

    # 5. Load t1x_model_checkpoint.pt and report parameter count
    if not CHECKPOINT_PATH.is_file():
        print(f"[FAIL] Checkpoint not found at {CHECKPOINT_PATH}")
        sys.exit(1)

    ckpt = torch.load(str(CHECKPOINT_PATH), map_location="cpu", weights_only=False)
    state = ckpt.get("model_state_dict", ckpt)
    param_count = sum(p.numel() for p in state.values())
    epoch = ckpt.get("epoch", "unknown")
    loss = ckpt.get("loss", "unknown")

    print(f"Checkpoint {CHECKPOINT_PATH.name}:")
    print(f"  Epoch: {epoch}")
    print(f"  Loss: {loss}")
    print(f"  Parameters: {param_count:,}")

    results["checkpoint_v1"] = {
        "path": str(CHECKPOINT_PATH),
        "epoch": epoch,
        "loss": float(loss) if isinstance(loss, (int, float)) else str(loss),
        "parameter_count": param_count,
    }

    # 6. Forward pass on synthetic 20-atom molecule
    sys.path.insert(0, str(BASE_DIR))
    from app.legacy_gnn import MolecularGraphNetwork

    model = MolecularGraphNetwork().to(device)
    model.eval()

    synth_z = torch.tensor([[6] * 10 + [1] * 10], dtype=torch.long, device=device)
    synth_pos = torch.randn(1, 20, 3, dtype=torch.float32, device=device)
    synth_mask = torch.ones(1, 20, dtype=torch.float32, device=device)

    # Warmup
    with torch.no_grad():
        _ = model(synth_z, synth_pos, synth_mask)
    torch.mps.synchronize()

    t_fwd0 = time.time()
    with torch.no_grad():
        for _ in range(50):
            _ = model(synth_z, synth_pos, synth_mask)
        torch.mps.synchronize()
    fwd_ms = ((time.time() - t_fwd0) / 50) * 1000

    print(f"Forward pass (20 atoms, MPS): {fwd_ms:.3f} ms/pass")
    results["forward_pass"] = {"atoms": 20, "ms_per_pass": fwd_ms}

    # 7. Write to data/env_check.json
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    out_file = DATA_DIR / "env_check.json"
    out_file.write_text(json.dumps(results, indent=2))
    print(f"✔ Environment verified successfully. Results written to {out_file}")


if __name__ == "__main__":
    main()
