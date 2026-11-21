"""
Training script for NephroPINN-Glomerular on Apple Silicon M1 Pro GPU (mps).
============================================================================
Enforces physical consistency via Starling equations, Darcy flow, and TGF/RAAS tone.
"""

import os
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import NephroPINNGlomerular

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")


def generate_nephro_dataset(n_samples: int = 3000, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    targets = []

    for _ in range(n_samples):
        condition = random.choice([0, 1, 2, 3, 4, 5])
        # 0=Normal, 1=Diabetic Hyperfiltration, 2=CRS-1, 3=Triple Whammy (NSAID+ACEi), 4=Bilateral RAS, 5=ATN

        if condition == 0:  # Normal
            map_val = random.uniform(85.0, 105.0)
            ra = random.uniform(0.9, 1.1)
            re = random.uniform(0.9, 1.1)
            kf = random.uniform(3.8, 4.4)
            pi_plasma = random.uniform(24.0, 26.0)
            p_bs = random.uniform(14.0, 16.0)
            hct = random.uniform(0.40, 0.45)
            fena = random.uniform(0.6, 1.2)
        elif condition == 1:  # Diabetic Hyperfiltration
            map_val = random.uniform(95.0, 115.0)
            ra = random.uniform(0.6, 0.8)   # Afferent vasodilation (SGLT2 hyper-reabsorption -> suppressed TGF)
            re = random.uniform(1.2, 1.6)   # Ang II efferent constriction
            kf = random.uniform(4.5, 5.5)
            pi_plasma = random.uniform(22.0, 25.0)
            p_bs = random.uniform(13.0, 15.0)
            hct = random.uniform(0.38, 0.44)
            fena = random.uniform(0.4, 0.8)
        elif condition == 2:  # Cardiorenal Syndrome Type 1
            map_val = random.uniform(65.0, 80.0)  # Low cardiac output / low perfusion
            ra = random.uniform(1.3, 1.8)         # Sympathetic vasoconstriction
            re = random.uniform(1.4, 1.9)         # Intense RAAS activation
            kf = random.uniform(2.8, 3.5)
            pi_plasma = random.uniform(22.0, 26.0)
            p_bs = random.uniform(18.0, 22.0)     # High central venous pressure / renal venous congestion
            hct = random.uniform(0.32, 0.40)
            fena = random.uniform(0.2, 0.7)       # Intense sodium avid prerenal state
        elif condition == 3:  # Triple Whammy (Diuretic + NSAID + ACEi)
            map_val = random.uniform(70.0, 85.0)
            ra = random.uniform(1.8, 2.5)   # NSAID blocks prostaglandins -> afferent constriction!
            re = random.uniform(0.5, 0.7)   # ACEi blocks Ang II -> efferent vasodilation!
            kf = random.uniform(3.0, 3.8)
            pi_plasma = random.uniform(25.0, 28.0)
            p_bs = random.uniform(14.0, 16.0)
            hct = random.uniform(0.40, 0.46)
            fena = random.uniform(0.3, 0.9)
        elif condition == 4:  # Bilateral Renal Artery Stenosis
            map_val = random.uniform(60.0, 75.0)  # Post-stenotic perfusion pressure
            ra = random.uniform(1.5, 2.2)
            re = random.uniform(1.5, 2.0)
            kf = random.uniform(2.5, 3.4)
            pi_plasma = random.uniform(24.0, 27.0)
            p_bs = random.uniform(14.0, 17.0)
            hct = random.uniform(0.35, 0.42)
            fena = random.uniform(0.3, 0.8)
        else:  # Acute Tubular Necrosis (ATN)
            map_val = random.uniform(75.0, 95.0)
            ra = random.uniform(1.2, 1.6)
            re = random.uniform(0.9, 1.2)
            kf = random.uniform(1.5, 2.4)   # Sloughed tubular debris + backleak
            pi_plasma = random.uniform(22.0, 26.0)
            p_bs = random.uniform(22.0, 28.0)  # High intratubular pressure from obstructing casts!
            hct = random.uniform(0.30, 0.38)
            fena = random.uniform(2.5, 5.5)    # Inability to reabsorb Na+! FENa > 2%

        # Analytical Physics / Ground Truth Starling microcirculation
        # Hydrostatic P_gc
        p_gc = map_val * (re / (ra + re + 0.3)) + 15.0
        pi_gc = pi_plasma * 1.15  # protein concentration along capillary
        nfp = max(1.0, (p_gc - p_bs) - (pi_gc - 0.0))
        sngfr = kf * nfp * 0.4
        egfr = sngfr * 2.2  # mL/min
        rbf = (map_val - 5.0) / (ra * 0.06 + re * 0.04 + 0.02)
        rpf = rbf * (1.0 - hct)
        ff = (egfr / max(50.0, rpf)) * 100.0
        uo = max(5.0, egfr * (fena / 100.0) * 60.0)
        if condition in [2, 3, 4] and map_val < 72.0:
            uo = max(2.0, uo * 0.4)  # Oliguria

        inp = [
            map_val / 100.0,
            ra,
            re,
            kf / 4.0,
            pi_plasma / 25.0,
            p_bs / 15.0,
            hct / 0.45,
            float(condition),
        ]

        tgt = [p_gc, nfp, sngfr, egfr, rbf, rpf, ff, uo, fena]

        inputs.append(inp)
        targets.append(tgt)

    return torch.tensor(inputs, dtype=torch.float32), torch.tensor(targets, dtype=torch.float32)


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"🔥 Training NephroPINN-Glomerular on device: {device}")

    x_train, y_train = generate_nephro_dataset(n_samples=4000)
    x_train = x_train.to(device)
    y_train = y_train.to(device)

    model = NephroPINNGlomerular().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    loss_fn = nn.SmoothL1Loss()

    model.train()
    batch_size = 64
    n_batches = len(x_train) // batch_size
    epochs = 40

    for epoch in range(1, epochs + 1):
        perm = torch.randperm(len(x_train))
        epoch_loss = 0.0

        for b in range(n_batches):
            idx = perm[b * batch_size : (b + 1) * batch_size]
            bx, by = x_train[idx], y_train[idx]

            out = model(bx)

            pred_tensor = torch.cat([
                out["p_gc"],
                out["nfp"],
                out["sngfr"],
                out["egfr"],
                out["rbf"],
                out["rpf"],
                out["ff"],
                out["urine_output"],
                out["fena"],
            ], dim=-1)

            # Data Loss
            loss_data = loss_fn(pred_tensor, by)

            # Physics Starling Residual Loss: SNGFR should approximate Kf * NFP * 0.4
            kf_unnorm = bx[:, 3:4] * 4.0
            nfp_pred = out["nfp"]
            sngfr_pred = out["sngfr"]
            loss_starling = loss_fn(sngfr_pred, kf_unnorm * nfp_pred * 0.4)

            total_loss = loss_data + 0.3 * loss_starling

            optimizer.zero_grad()
            total_loss.backward()
            optimizer.step()
            epoch_loss += total_loss.item()

        if epoch % 10 == 0 or epoch == epochs:
            print(f"Epoch {epoch:2d}/{epochs} | Loss: {epoch_loss / n_batches:.4f}")

    ckpt_dir = Path(__file__).parent / "checkpoints"
    ckpt_dir.mkdir(parents=True, exist_ok=True)
    ckpt_path = ckpt_dir / "nephro_pinn_glomerular.pt"

    torch.save({
        "model_state_dict": model.state_dict(),
        "device": str(device),
        "version": "1.0.0",
    }, ckpt_path)
    print(f"✅ Saved trained NephroPINN checkpoint to {ckpt_path}")


if __name__ == "__main__":
    train()
