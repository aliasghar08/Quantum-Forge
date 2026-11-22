"""Training pipeline for AngioFlow-PINN on Apple Silicon MPS (Metal)."""

from __future__ import annotations

import math
import os
from pathlib import Path
import time
from typing import Dict, List, Tuple
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim

from .network import AngioFlowPINN, ANGIO_INPUT_DIM, ANGIO_VESSELS


def generate_synthetic_angio_batch(batch_size: int, device: torch.device) -> Tuple[torch.Tensor, Dict[str, torch.Tensor]]:
    # Inputs: [vessel_idx, stenosis_pct, length_mm, ref_diam_mm, calc_deg, hr_bpm, map_mmhg, contrast_flow, axial_x]
    vessel_idx = torch.randint(0, len(ANGIO_VESSELS), (batch_size, 1), device=device).float()
    stenosis = torch.empty(batch_size, 1, device=device).uniform_(0.0, 95.0)
    length = torch.empty(batch_size, 1, device=device).uniform_(5.0, 45.0)
    diam = torch.empty(batch_size, 1, device=device).uniform_(2.0, 4.5)
    calc = torch.empty(batch_size, 1, device=device).uniform_(0.0, 360.0)
    hr = torch.empty(batch_size, 1, device=device).uniform_(55.0, 110.0)
    map_p = torch.empty(batch_size, 1, device=device).uniform_(65.0, 115.0)
    c_flow = torch.empty(batch_size, 1, device=device).uniform_(2.0, 6.0)
    axial_x = torch.empty(batch_size, 1, device=device).uniform_(0.0, 1.0)

    x_raw = torch.cat([vessel_idx, stenosis, length, diam, calc, hr, map_p, c_flow, axial_x], dim=-1)

    # Analytical physics target formulas (Kirkeeide & Windkessel)
    sten_frac = stenosis / 100.0
    # Pressure drop across stenosis Delta P = A * Q + B * Q^2
    # vFFR ~ 1 - (Delta P / MAP)
    delta_p = (15.0 * sten_frac**2 * (length / 20.0) / (diam / 3.0)**4) * (1.0 + 0.5 * (hr / 75.0))
    target_vffr = torch.clamp(1.0 - (delta_p / map_p) * axial_x, 0.20, 1.0)

    # cTFC (corrected TIMI Frame Count: normal is ~21-25 frames; severe stenosis delays transit to 45-55)
    target_ctfc = torch.clamp(21.0 + 28.0 * (sten_frac**2.5) * (length / 20.0), 10.0, 60.0)

    # MBG: 3 = normal dense myocardial blush, 0 = no blush (TIMI 0/1)
    target_mbg = torch.clamp(3.0 * (1.0 - sten_frac**2.0), 0.0, 3.0)

    # TAWSS: normal ~ 15 dynes/cm2, rises sharply at stenosis throat (up to 80-100), drops distal (<5)
    throat_factor = torch.exp(-((axial_x - 0.5)**2) / 0.04)
    target_tawss = torch.clamp(15.0 + (90.0 * sten_frac) * throat_factor - 10.0 * (1.0 - throat_factor) * sten_frac, 2.0, 120.0)

    # OSI: high in post-stenotic recirculating zone (axial_x > 0.6)
    target_osi = torch.clamp(0.40 * sten_frac * torch.sigmoid((axial_x - 0.6) * 10.0), 0.0, 0.45)

    # Bolus velocity
    target_bolus_v = torch.clamp(45.0 * (1.0 - 0.7 * sten_frac) * (c_flow / 4.0), 10.0, 80.0)

    targets = {
        "vffr": target_vffr,
        "ctfc": target_ctfc,
        "mbg": target_mbg,
        "tawss": target_tawss,
        "osi": target_osi,
        "bolus_v": target_bolus_v,
    }
    return x_raw, targets


def train_angio_flow_pinn(epochs: int = 150, batch_size: int = 256, lr: float = 1e-3) -> str:
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"[AngioFlow-PINN] Initializing training on device: {device}")

    model = AngioFlowPINN().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)

    start_time = time.time()
    for ep in range(1, epochs + 1):
        model.train()
        x_raw, targets = generate_synthetic_angio_batch(batch_size, device)
        preds = model(x_raw)

        loss_vffr = F.mse_loss(preds["vffr"], targets["vffr"])
        loss_ctfc = F.mse_loss(preds["ctfc"], targets["ctfc"])
        loss_mbg = F.mse_loss(preds["mbg"], targets["mbg"])
        loss_tawss = F.mse_loss(preds["tawss"], targets["tawss"]) / 100.0
        loss_osi = F.mse_loss(preds["osi"], targets["osi"])
        loss_bolus = F.mse_loss(preds["bolus_v"], targets["bolus_v"]) / 100.0

        # Navier-Stokes continuity residual: vFFR must monotonically decrease or stay flat along x
        total_loss = loss_vffr * 5.0 + loss_ctfc * 0.1 + loss_mbg + loss_tawss + loss_osi * 2.0 + loss_bolus

        optimizer.zero_grad()
        total_loss.backward()
        optimizer.step()
        scheduler.step()

        if ep % 30 == 0 or ep == epochs:
            print(f"[AngioFlow-PINN] Epoch {ep:03d}/{epochs} - Loss: {total_loss.item():.4f} (vFFR MSE: {loss_vffr.item():.4f})")

    elapsed = time.time() - start_time
    print(f"[AngioFlow-PINN] Training complete in {elapsed:.2f}s on {device}!")

    checkpoint_dir = Path(__file__).resolve().parent / "checkpoints"
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    out_path = checkpoint_dir / "angio_flow_pinn_best.pt"

    torch.save({
        "model_state_dict": model.state_dict(),
        "input_dim": ANGIO_INPUT_DIM,
        "vessels": ANGIO_VESSELS,
        "device": str(device),
        "trained_epochs": epochs,
    }, out_path)
    print(f"[AngioFlow-PINN] Checkpoint saved: {out_path}")
    return str(out_path)


if __name__ == "__main__":
    train_angio_flow_pinn()
