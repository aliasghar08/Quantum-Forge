"""MPS Training Pipeline for CardioElectrophys-Net (1D ResNet + Neural ODE Surrogate).

Generates biophysical O'Hara-Rudy / Ten Tusscher ventricular cardiomyocyte action potential
trajectories under multi-channel Hill blockade (IKr/hERG, INa, ICaL, IKs, IK1) and trains
CardioElectrophysNet natively on Apple Silicon M1 Pro Metal GPU (torch.device("mps")).
"""

from __future__ import annotations

import argparse
import logging
import math
import os
from pathlib import Path
import time
from typing import Dict, Tuple

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.optim.lr_scheduler import CosineAnnealingLR

try:
    os.nice(10)
except Exception:
    pass

from .network import CardioElectrophysNet, NUM_TIME_POINTS, AP_DURATION_MS

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("CardioElectrophysTrainer")

BASE_DIR = Path(__file__).resolve().parent
CHECKPOINT_DIR = BASE_DIR / "checkpoints"
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)
BEST_CHECKPOINT = CHECKPOINT_DIR / "cardio_electrophys_best.pt"


def get_device() -> torch.device:
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def synthesize_ord_cipa_trajectories(
    batch_size: int,
    device: torch.device,
) -> Tuple[torch.Tensor, Dict[str, torch.Tensor]]:
    """Synthesize biophysical O'Hara-Rudy / CiPA ventricular AP waveforms & biomarkers on MPS."""
    u = torch.rand(batch_size, 7, device=device)

    # Fractional channel blockades [0, 1] via Hill kinetics
    b_ikr = u[:, 0] ** 1.15                # hERG / IKr block
    b_ina = u[:, 1] * 0.75                 # Nav1.5 / INaL block
    b_ical = u[:, 2] * 0.85                # Cav1.2 / ICaL block
    b_iks = u[:, 3] * 0.65                 # IKs block
    b_ik1 = u[:, 4] * 0.50                 # IK1 block
    log10_conc = u[:, 5] * 4.5 - 2.5       # [-2.5, 2.0] -> 0.003 to 100 uM
    hr_bpm = u[:, 6] * 85.0 + 48.0         # [48, 133] bpm

    x_raw = torch.stack(
        [b_ikr, b_ina, b_ical, b_iks, b_ik1, log10_conc, hr_bpm], dim=-1
    )

    # Rate-dependent restitution factor (bradycardia prolongs APD90 and amplifies hERG EAD risk)
    bcl_ms = 60000.0 / hr_bpm
    restitution = torch.clamp((bcl_ms / 850.0) ** 0.35, 0.78, 1.24)

    # Net repolarization reserve deficit vs. inward current block (ICaL/INaL balanced block rescues APD)
    repol_deficit = (
        1.35 * b_ikr
        + 0.38 * b_iks
        + 0.25 * b_ik1
        - 0.68 * b_ical
        - 0.32 * b_ina
    )

    # Baseline APD90 ~ 282 ms at 70 bpm; prolongs strongly with uncompensated IKr block
    apd90_ms = (282.0 * restitution) + 215.0 * F.relu(repol_deficit) - 55.0 * F.relu(-repol_deficit)
    apd90_ms = torch.clamp(apd90_ms, 195.0, 545.0)

    apd50_ms = apd90_ms * (0.74 - 0.09 * b_ical + 0.04 * b_ikr)
    apd50_ms = torch.minimum(
        torch.clamp(apd50_ms, min=125.0),
        apd90_ms - 48.0,
    )

    # CiPA qNet (uC/uF): Integral of net electronic current during plateau (normal ~0.068 uC/uF)
    # High TdP risk < 0.050 uC/uF; Intermediate 0.050 - 0.060; Low > 0.060 uC/uF
    qnet = 0.068 - 0.046 * b_ikr - 0.012 * b_iks + 0.028 * b_ical + 0.015 * b_ina
    qnet = torch.clamp(qnet, 0.015, 0.098)

    # Early Afterdepolarization (EAD) probability triggered by L-type Ca2+ window reactivation
    # during prolonged phase 2/3 plateau (high IKr block + unblocked ICaL + slow pacing)
    ead_drive = 6.5 * (b_ikr - 0.52 - 0.60 * b_ical + 0.12 * (restitution - 1.0))
    ead_prob = torch.sigmoid(ead_drive)

    # Synthesize 120-point membrane potential Vm(t) across t in [0, 600 ms]
    t = torch.linspace(0.0, AP_DURATION_MS, NUM_TIME_POINTS, device=device).unsqueeze(0)  # [1, T]

    v_rest = (-85.5 + 4.5 * b_ik1).unsqueeze(1)  # [B, 1]
    v_peak = (34.0 - 14.0 * b_ina).unsqueeze(1)
    v_plat = (16.0 - 18.0 * b_ical + 6.0 * b_ikr).unsqueeze(1)

    apd50_col = apd50_ms.unsqueeze(1)
    apd90_col = apd90_ms.unsqueeze(1)

    # Phase 0 rapid Na+ upstroke (tau ~ 2.2 ms)
    upstroke = 1.0 - torch.exp(-t / 2.2)

    # Phase 1 transient outward notch (Ito)
    notch = (v_peak - v_plat) * torch.exp(-t / 12.0) * (1.0 - torch.exp(-t / 2.0))

    # Phase 2/3 sigmoid repolarization governed by APD50 and APD90
    tau_repol = torch.clamp((apd90_col - apd50_col) / 2.9, min=14.0)
    repol_gate = 1.0 / (1.0 + torch.exp((t - apd50_col * 1.08) / tau_repol))

    vm_base = v_rest + upstroke * ((v_plat - v_rest) * repol_gate + notch)

    # Superimpose physiological Phase 2/3 Early Afterdepolarization (EAD) depolarizing oscillation
    # when ead_prob > 0.35 (ICaL window reactivation around t ~ 0.72 * APD90)
    ead_amp = (22.0 * F.relu(ead_prob - 0.28)).unsqueeze(1)
    t_ead_center = 0.74 * apd90_col
    ead_envelope = torch.exp(-((t - t_ead_center) ** 2) / (2.0 * (42.0 ** 2)))
    ead_wave = ead_amp * ead_envelope * (0.55 + 0.45 * torch.sin(2.0 * math.pi * (t - t_ead_center) / 68.0))

    vm_mv = torch.clamp(vm_base + ead_wave, -88.0, 40.0)

    targets = {
        "vm_waveform_mv": vm_mv,
        "apd50_ms": apd50_ms,
        "apd90_ms": apd90_ms,
        "ead_probability": ead_prob,
        "qnet_c_f": qnet,
    }
    return x_raw, targets


def compute_ep_loss(
    model: CardioElectrophysNet,
    x_raw: torch.Tensor,
    targets: Dict[str, torch.Tensor],
) -> Tuple[torch.Tensor, Dict[str, float]]:
    """Compute multi-task waveform + CiPA biomarker + biophysical consistency loss."""
    preds = model(x_raw)

    # 1. Waveform trajectory loss (normalized mV scale)
    l_vm = F.smooth_l1_loss(preds["vm_waveform_mv"] / 50.0, targets["vm_waveform_mv"] / 50.0) * 8.0

    # Temporal derivative smoothness & phase-0/phase-3 slope fidelity
    dvm_pred = preds["vm_waveform_mv"][:, 1:] - preds["vm_waveform_mv"][:, :-1]
    dvm_true = targets["vm_waveform_mv"][:, 1:] - targets["vm_waveform_mv"][:, :-1]
    l_dvm = F.smooth_l1_loss(dvm_pred / 15.0, dvm_true / 15.0) * 4.0

    # 2. Biomarker losses
    l_apd50 = F.smooth_l1_loss(preds["apd50_ms"] / 100.0, targets["apd50_ms"] / 100.0) * 5.0
    l_apd90 = F.smooth_l1_loss(preds["apd90_ms"] / 100.0, targets["apd90_ms"] / 100.0) * 6.0
    l_ead = F.smooth_l1_loss(preds["ead_probability"], targets["ead_probability"]) * 6.0
    l_qnet = F.smooth_l1_loss(preds["qnet_c_f"] * 20.0, targets["qnet_c_f"] * 20.0) * 6.0

    total_loss = l_vm + l_dvm + l_apd50 + l_apd90 + l_ead + l_qnet
    vm_mae_mv = float(torch.abs(preds["vm_waveform_mv"] - targets["vm_waveform_mv"]).mean().item())
    apd90_mae_ms = float(torch.abs(preds["apd90_ms"] - targets["apd90_ms"]).mean().item())

    return total_loss, {
        "total_loss": float(total_loss.item()),
        "vm_mae_mv": vm_mae_mv,
        "apd90_mae_ms": apd90_mae_ms,
    }


def train_cardio_electrophys(
    epochs: int = 75,
    batch_size: int = 256,
    steps_per_epoch: int = 28,
    lr: float = 1.5e-3,
    hidden_dim: int = 128,
    conv_channels: int = 64,
    seed: int = 42,
) -> CardioElectrophysNet:
    """Train CardioElectrophys-Net natively on Apple Silicon M1 Pro Metal GPU."""
    torch.manual_seed(seed)
    np.random.seed(seed)

    device = get_device()
    logger.info(f"Training CardioElectrophys-Net on {device} (Apple Silicon MPS)")

    model = CardioElectrophysNet(hidden_dim=hidden_dim, conv_channels=conv_channels).to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = CosineAnnealingLR(optimizer, T_max=epochs, eta_min=1e-5)

    best_val_loss = float("inf")
    best_epoch = 0

    val_x, val_targets = synthesize_ord_cipa_trajectories(1024, device)

    for epoch in range(1, epochs + 1):
        model.train()
        epoch_loss = 0.0

        for _ in range(steps_per_epoch):
            x_raw, targets = synthesize_ord_cipa_trajectories(batch_size, device)
            optimizer.zero_grad()
            loss, _ = compute_ep_loss(model, x_raw, targets)
            loss.backward()
            nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
            epoch_loss += loss.item()

        scheduler.step()
        avg_train_loss = epoch_loss / steps_per_epoch

        model.eval()
        with torch.no_grad():
            val_loss_tensor, val_metrics = compute_ep_loss(model, val_x, val_targets)
            val_loss = float(val_loss_tensor.item())

        if epoch % 10 == 0 or epoch == 1 or val_loss < best_val_loss:
            logger.info(
                f"Epoch [{epoch:02d}/{epochs:02d}] | Train Loss: {avg_train_loss:.4f} | "
                f"Val Loss: {val_loss:.4f} | Vm MAE: {val_metrics['vm_mae_mv']:.2f} mV | "
                f"APD90 MAE: {val_metrics['apd90_mae_ms']:.2f} ms"
            )

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            best_epoch = epoch
            ckpt = {
                "model_state_dict": model.state_dict(),
                "hidden_dim": hidden_dim,
                "conv_channels": conv_channels,
                "epoch": epoch,
                "val_loss": best_val_loss,
                "vm_mae_mv": val_metrics["vm_mae_mv"],
                "apd90_mae_ms": val_metrics["apd90_mae_ms"],
                "trained_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "device": str(device),
            }
            torch.save(ckpt, BEST_CHECKPOINT)

        if hasattr(torch, "mps") and torch.backends.mps.is_available():
            torch.mps.empty_cache()

    logger.info(
        f"CardioElectrophys-Net Training Complete! Best Val Loss: {best_val_loss:.4f} "
        f"at Epoch {best_epoch} -> {BEST_CHECKPOINT}"
    )
    ckpt = torch.load(BEST_CHECKPOINT, map_location=device)
    model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    return model


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train CardioElectrophys-Net on Apple Silicon MPS.")
    parser.add_argument("--epochs", type=int, default=75, help="Number of training epochs.")
    parser.add_argument("--lr", type=float, default=1.5e-3, help="Learning rate.")
    args = parser.parse_args()

    train_cardio_electrophys(epochs=args.epochs, lr=args.lr)
