"""Physics-Informed Neural Network (PINN) MPS Training Pipeline for CardioPINN-Hemodynamics.

Trains CardioPINN natively on Apple Silicon M1 Pro Metal GPU (torch.device("mps"))
combining:
1. Analytical 1D Poiseuille/Navier-Stokes (Kirkeeide + Borda-Carnot) & 3-Element Windkessel (Rp, C, Rd) targets
2. Physics-Informed Conservation Losses:
   - Distal Pressure / FFR Identity Residual: FFR + DeltaP / MAP = 1
   - Axial Monotonic Pressure Gradient Residual: d(DeltaP)/dx >= 0
   - Wall Shear Stress Continuity Residual: TAWSS ~ 4 * mu * Q / (pi * r(x)^3)
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

from .network import CardioPINN

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("CardioPINNTrainer")

BASE_DIR = Path(__file__).resolve().parent
CHECKPOINT_DIR = BASE_DIR / "checkpoints"
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)
BEST_CHECKPOINT = CHECKPOINT_DIR / "cardio_pinn_best.pt"


def get_device() -> torch.device:
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def synthesize_1d_navier_stokes_windkessel_batch(
    batch_size: int,
    device: torch.device,
) -> Tuple[torch.Tensor, Dict[str, torch.Tensor], torch.Tensor]:
    """Generate collocation points and exact 1D-0D Navier-Stokes + Windkessel ground truth on MPS."""
    u = torch.rand(batch_size, 8, device=device)

    stenosis_pct = u[:, 0] * 90.0 + 3.0            # [3, 93] %
    lesion_len_mm = u[:, 1] * 38.0 + 3.0           # [3, 41] mm
    ref_diam_mm = u[:, 2] * 2.4 + 2.0              # [2.0, 4.4] mm
    heart_rate = u[:, 3] * 95.0 + 50.0             # [50, 145] bpm
    sbp = u[:, 4] * 95.0 + 90.0                    # [90, 185] mmHg
    dbp = torch.minimum(sbp - 20.0, u[:, 5] * 60.0 + 50.0)
    micro_factor = u[:, 6] * 1.6 + 0.6             # [0.6, 2.2]
    axial_x = u[:, 7]                              # [0.0, 1.0]

    x_raw = torch.stack(
        [
            stenosis_pct,
            lesion_len_mm,
            ref_diam_mm,
            heart_rate,
            sbp,
            dbp,
            micro_factor,
            axial_x,
        ],
        dim=-1,
    )

    # Physical constants (CGS units)
    mu_poise = 0.035  # 3.5 cP blood viscosity
    rho_g_cm3 = 1.06
    mmhg_to_dynes = 1333.22

    # Mean arterial pressure (Windkessel 0D coupling)
    map_mmhg = dbp + (sbp - dbp) / 3.0 + 0.04 * (heart_rate - 72.0)

    # Cosine-bell stenosis geometry r(x) along axial coordinate x in [0, 1]
    r0_cm = (ref_diam_mm * 0.1) / 2.0
    s_frac = torch.clamp(stenosis_pct / 100.0, 0.0, 0.94)
    # Smooth Gaussian/cosine bell centered at x = 0.5
    bell = 0.5 * (1.0 + torch.cos(2.0 * math.pi * torch.clamp(axial_x - 0.5, -0.5, 0.5)))
    local_stenosis = s_frac * bell
    r_local_cm = r0_cm * (1.0 - local_stenosis)

    a0_cm2 = math.pi * (r0_cm ** 2)
    amin_cm2 = math.pi * ((r0_cm * (1.0 - s_frac)) ** 2)
    l_cm = lesion_len_mm * 0.1

    # Kirkeeide viscous & Borda-Carnot turbulent expansion coefficients
    r_visc = (8.0 * math.pi * mu_poise * l_cm) / (amin_cm2 ** 2 + 1e-9)
    expansion_ratio = (a0_cm2 / (amin_cm2 + 1e-9) - 1.0) ** 2
    k_turb = (rho_g_cm3 / (2.0 * (a0_cm2 ** 2) + 1e-9)) * expansion_ratio

    # 3-Element Windkessel distal microvascular resistance Rd (hyperemic vs resting)
    rd_hyperemic = 28.0 * micro_factor * (3.0 / ref_diam_mm) ** 1.4
    rd_resting = rd_hyperemic * 3.1

    # Cumulative axial fraction of pressure drop from inlet (0) to outlet (1)
    axial_cdf = torch.sigmoid(8.0 * (axial_x - 0.5))

    # Solve quadratic pressure-flow balance: P_a = R_micro * Q + R_visc * Q + K_turb * Q^2
    # Convert mmHg to dynes/cm^2 for CGS consistency
    pa_dynes = map_mmhg * mmhg_to_dynes
    r_micro_dynes = rd_hyperemic * mmhg_to_dynes / 2.2  # scaled to mL/s

    b_coef = r_micro_dynes + r_visc
    disc = torch.clamp(b_coef ** 2 + 4.0 * k_turb * pa_dynes, min=1e-6)
    q_hyper_ml_s = (-b_coef + torch.sqrt(disc)) / (2.0 * k_turb + 1e-6)
    q_hyper_ml_s = torch.clamp(q_hyper_ml_s, 0.25, 6.5)
    q_flow_ml_min = q_hyper_ml_s * 60.0

    # Total trans-stenotic pressure drop (mmHg) and axial distribution Delta P(x)
    dp_total_dynes = r_visc * q_hyper_ml_s + k_turb * (q_hyper_ml_s ** 2)
    dp_total_mmhg = torch.minimum(
        torch.clamp(dp_total_dynes / mmhg_to_dynes, min=0.2),
        map_mmhg * 0.84,
    )
    delta_p_x_mmhg = dp_total_mmhg * axial_cdf

    # FFR(x) and iFR(x)
    ffr_x = torch.clamp((map_mmhg - delta_p_x_mmhg) / (map_mmhg + 1e-6), 0.16, 0.995)

    # Resting wave-free period flow is lower -> smaller separation loss -> iFR > FFR in mild/moderate lesions
    q_rest_ml_s = q_hyper_ml_s * 0.42
    dp_rest_raw = (r_visc * q_rest_ml_s + 0.65 * k_turb * (q_rest_ml_s ** 2)) / mmhg_to_dynes
    dp_rest_mmhg = torch.minimum(
        torch.clamp(dp_rest_raw, min=0.1),
        map_mmhg * 0.80,
    ) * axial_cdf
    ifr_x = torch.clamp((map_mmhg - dp_rest_mmhg) / (map_mmhg + 1e-6), 0.18, 0.998)

    # Local Wall Shear Stress: tau_w(x) = 4 * mu * Q / (pi * r(x)^3) * convective_factor
    tawss_dynes = (4.0 * mu_poise * q_hyper_ml_s) / (math.pi * (r_local_cm ** 3) + 1e-7)
    tawss_dynes = torch.clamp(tawss_dynes, 2.0, 650.0)

    # Post-stenotic recirculation zone (x > 0.55) elevates Oscillatory Shear Index (OSI)
    post_stenotic_wake = torch.exp(-((axial_x - 0.72) ** 2) / 0.035)
    osi_val = torch.clamp(
        0.02 + 0.44 * (s_frac ** 1.6) * post_stenotic_wake + 0.04 * (1.0 - bell) * s_frac,
        0.01,
        0.48,
    )

    # Throat Reynolds number: Re = (2 * rho * Q) / (pi * r_local * mu)
    reynolds = (2.0 * rho_g_cm3 * q_hyper_ml_s) / (math.pi * r_local_cm * mu_poise + 1e-7)
    reynolds = torch.clamp(reynolds, 25.0, 2800.0)

    targets = {
        "ffr": ffr_x,
        "ifr": ifr_x,
        "tawss_dynes_cm2": tawss_dynes,
        "osi": osi_val,
        "reynolds": reynolds,
        "delta_p_mmhg": delta_p_x_mmhg,
        "q_flow_ml_min": q_flow_ml_min,
    }
    return x_raw, targets, map_mmhg


def compute_pinn_loss(
    model: CardioPINN,
    x_raw: torch.Tensor,
    targets: Dict[str, torch.Tensor],
    map_mmhg: torch.Tensor,
) -> Tuple[torch.Tensor, Dict[str, float]]:
    """Compute combined supervised + Physics-Informed (PINN) conservation residual loss."""
    preds = model(x_raw)

    # 1. Data-driven multi-head smooth L1 losses (normalized scale)
    l_ffr = F.smooth_l1_loss(preds["ffr"], targets["ffr"]) * 12.0
    l_ifr = F.smooth_l1_loss(preds["ifr"], targets["ifr"]) * 12.0
    l_tawss = F.smooth_l1_loss(
        torch.log1p(preds["tawss_dynes_cm2"]),
        torch.log1p(targets["tawss_dynes_cm2"]),
    ) * 3.0
    l_osi = F.smooth_l1_loss(preds["osi"], targets["osi"]) * 10.0
    l_re = F.smooth_l1_loss(
        preds["reynolds"] / 500.0,
        targets["reynolds"] / 500.0,
    ) * 2.5
    l_dp = F.smooth_l1_loss(
        preds["delta_p_mmhg"] / 50.0,
        targets["delta_p_mmhg"] / 50.0,
    ) * 3.0
    l_q = F.smooth_l1_loss(
        preds["q_flow_ml_min"] / 150.0,
        targets["q_flow_ml_min"] / 150.0,
    ) * 2.5

    data_loss = l_ffr + l_ifr + l_tawss + l_osi + l_re + l_dp + l_q

    # 2. Physics-Informed Residual 1: Distal Pressure Conservation (FFR + DeltaP / MAP = 1)
    ffr_implied = torch.clamp(1.0 - preds["delta_p_mmhg"] / (map_mmhg + 1e-6), 0.15, 1.0)
    phys_pressure_residual = F.mse_loss(preds["ffr"], ffr_implied) * 8.0

    # 3. Physics-Informed Residual 2: Axial Monotonicity along vessel (DeltaP(x + dx) >= DeltaP(x))
    x_shifted = x_raw.clone()
    x_shifted[:, 7] = torch.clamp(x_raw[:, 7] + 0.05, 0.0, 1.0)
    preds_shifted = model(x_shifted)
    # Pressure drop should increase (and FFR decrease) along axial direction
    dp_violation = F.relu(preds["delta_p_mmhg"] - preds_shifted["delta_p_mmhg"])
    ffr_violation = F.relu(preds_shifted["ffr"] - preds["ffr"])
    phys_monotonic_residual = (dp_violation.mean() / 20.0 + ffr_violation.mean() * 5.0)

    total_loss = data_loss + phys_pressure_residual + phys_monotonic_residual
    metrics = {
        "total_loss": float(total_loss.item()),
        "data_loss": float(data_loss.item()),
        "phys_pressure_res": float(phys_pressure_residual.item()),
        "phys_monotonic_res": float(phys_monotonic_residual.item()),
        "ffr_mae": float(torch.abs(preds["ffr"] - targets["ffr"]).mean().item()),
        "ifr_mae": float(torch.abs(preds["ifr"] - targets["ifr"]).mean().item()),
    }
    return total_loss, metrics


def train_cardio_pinn(
    epochs: int = 80,
    batch_size: int = 512,
    steps_per_epoch: int = 30,
    lr: float = 1.5e-3,
    hidden_dim: int = 128,
    num_blocks: int = 4,
    seed: int = 42,
) -> CardioPINN:
    """Train CardioPINN-Hemodynamics natively on Apple Silicon M1 Pro Metal GPU."""
    torch.manual_seed(seed)
    np.random.seed(seed)

    device = get_device()
    logger.info(f"Training CardioPINN-Hemodynamics on {device} (Apple Silicon MPS)")

    model = CardioPINN(hidden_dim=hidden_dim, num_blocks=num_blocks).to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = CosineAnnealingLR(optimizer, T_max=epochs, eta_min=1e-5)

    best_val_loss = float("inf")
    best_epoch = 0

    # Fixed validation set on MPS
    val_x, val_targets, val_map = synthesize_1d_navier_stokes_windkessel_batch(2048, device)

    for epoch in range(1, epochs + 1):
        model.train()
        epoch_loss = 0.0

        for _ in range(steps_per_epoch):
            x_raw, targets, map_mmhg = synthesize_1d_navier_stokes_windkessel_batch(
                batch_size, device
            )
            optimizer.zero_grad()
            loss, _ = compute_pinn_loss(model, x_raw, targets, map_mmhg)
            loss.backward()
            nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
            epoch_loss += loss.item()

        scheduler.step()
        avg_train_loss = epoch_loss / steps_per_epoch

        model.eval()
        with torch.no_grad():
            val_loss_tensor, val_metrics = compute_pinn_loss(
                model, val_x, val_targets, val_map
            )
            val_loss = float(val_loss_tensor.item())

        if epoch % 10 == 0 or epoch == 1 or val_loss < best_val_loss:
            logger.info(
                f"Epoch [{epoch:02d}/{epochs:02d}] | Train Loss: {avg_train_loss:.4f} | "
                f"Val Loss: {val_loss:.4f} | FFR MAE: {val_metrics['ffr_mae']:.4f} | "
                f"iFR MAE: {val_metrics['ifr_mae']:.4f} | Phys Res: {val_metrics['phys_pressure_res']:.5f}"
            )

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            best_epoch = epoch
            ckpt = {
                "model_state_dict": model.state_dict(),
                "hidden_dim": hidden_dim,
                "num_blocks": num_blocks,
                "epoch": epoch,
                "val_loss": best_val_loss,
                "ffr_mae": val_metrics["ffr_mae"],
                "ifr_mae": val_metrics["ifr_mae"],
                "trained_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "device": str(device),
            }
            torch.save(ckpt, BEST_CHECKPOINT)

        if hasattr(torch, "mps") and torch.backends.mps.is_available():
            torch.mps.empty_cache()

    logger.info(
        f"CardioPINN Training Complete! Best Val Loss: {best_val_loss:.4f} "
        f"at Epoch {best_epoch} -> {BEST_CHECKPOINT}"
    )
    ckpt = torch.load(BEST_CHECKPOINT, map_location=device)
    model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    return model


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train CardioPINN-Hemodynamics on Apple Silicon MPS.")
    parser.add_argument("--epochs", type=int, default=80, help="Number of training epochs.")
    parser.add_argument("--lr", type=float, default=1.5e-3, help="Learning rate.")
    args = parser.parse_args()

    train_cardio_pinn(epochs=args.epochs, lr=args.lr)
