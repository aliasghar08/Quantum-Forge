"""Training pipeline for CardioTissue-BiomechNet on Apple Silicon MPS (Metal)."""

from __future__ import annotations

import os
from pathlib import Path
import time
import torch
import torch.nn as nn
import torch.optim as optim

from .network import CardioTissueBiomechNet, BIOMECH_MODALITIES


def generate_synthetic_biomech_batch(batch_size: int, device: torch.device):
    # Features: [calcification_arc_deg, calcium_thickness_mm, lesion_length_mm, ref_diam_mm, baseline_lvef, modality_idx, nominal_atm]
    arc = torch.empty(batch_size, 1, device=device).uniform_(0.0, 360.0)
    thick = torch.empty(batch_size, 1, device=device).uniform_(0.2, 1.5)
    length = torch.empty(batch_size, 1, device=device).uniform_(10.0, 40.0)
    diam = torch.empty(batch_size, 1, device=device).uniform_(2.2, 4.0)
    lvef = torch.empty(batch_size, 1, device=device).uniform_(30.0, 65.0)
    modality = torch.randint(0, len(BIOMECH_MODALITIES), (batch_size, 1), device=device).float()
    atm = torch.empty(batch_size, 1, device=device).uniform_(12.0, 24.0)

    x = torch.cat([arc, thick, length, diam, lvef, modality, atm], dim=-1)

    # Targets based on known interventional biomechanics
    # Rotablator (modality 1) and Shockwave IVL (modality 2) achieve >90% expansion in heavy calcium (arc > 180)
    # NC Balloon (modality 0) fails in heavy calcium (<75% expansion, high recoil)
    is_ivl = (modality == 2.0).float()
    is_rota = (modality == 1.0).float()
    is_balloon = (modality == 0.0).float()

    calc_sev = (arc / 360.0) * (thick / 1.0)
    target_exp = torch.clamp(0.92 - 0.30 * calc_sev * is_balloon + 0.05 * is_ivl + 0.03 * is_rota, 0.60, 1.05)
    target_recoil = torch.clamp(5.0 + 15.0 * calc_sev * is_balloon - 3.0 * is_ivl, 2.0, 25.0)
    target_frac = torch.clamp(16.0 + 10.0 * calc_sev * is_balloon - 6.0 * is_ivl, 8.0, 28.0)
    target_lvef = torch.clamp(4.0 + 6.0 * (1.0 - lvef / 70.0), 1.0, 12.0)
    target_strain = torch.clamp(-2.0 - 2.5 * torch.ones(batch_size, 17, device=device), -6.5, -1.0)

    targets = {
        "fracture": target_frac,
        "expansion": target_exp,
        "recoil": target_recoil,
        "lvef": target_lvef,
        "strain": target_strain,
    }
    return x, targets


def train_cardio_tissue_biomech(epochs: int = 120, batch_size: int = 128, lr: float = 1e-3) -> str:
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"[CardioTissue-BiomechNet] Training on {device}...")

    model = CardioTissueBiomechNet().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)

    t0 = time.time()
    for ep in range(1, epochs + 1):
        model.train()
        x, targets = generate_synthetic_biomech_batch(batch_size, device)
        preds = model(x)

        l_frac = nn.functional.mse_loss(preds["fracture_threshold_atm"], targets["fracture"]) / 10.0
        l_exp = nn.functional.mse_loss(preds["stent_expansion_index"], targets["expansion"]) * 10.0
        l_rec = nn.functional.mse_loss(preds["acute_recoil_pct"], targets["recoil"]) / 10.0
        l_lvef = nn.functional.mse_loss(preds["lvef_recovery_delta"], targets["lvef"])
        l_str = nn.functional.mse_loss(preds["strain_17_segments"], targets["strain"])

        total_loss = l_frac + l_exp + l_rec + l_lvef + l_str

        optimizer.zero_grad()
        total_loss.backward()
        optimizer.step()

        if ep % 30 == 0 or ep == epochs:
            print(f"[CardioTissue-BiomechNet] Epoch {ep:03d}/{epochs} - Loss: {total_loss.item():.4f}")

    print(f"[CardioTissue-BiomechNet] Training complete in {time.time() - t0:.2f}s!")

    ckpt_dir = Path(__file__).resolve().parent / "checkpoints"
    ckpt_dir.mkdir(parents=True, exist_ok=True)
    out_path = ckpt_dir / "cardio_tissue_biomech_best.pt"

    torch.save({
        "model_state_dict": model.state_dict(),
        "modalities": BIOMECH_MODALITIES,
        "trained_epochs": epochs,
    }, out_path)
    return str(out_path)


if __name__ == "__main__":
    train_cardio_tissue_biomech()
