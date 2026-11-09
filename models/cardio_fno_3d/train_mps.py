"""
Training script for CardioFNO-3D on Apple Silicon M1 Pro Metal GPU (mps).
Trains Fourier Neural Operator on synthetic 3D myocardial strain & deformation physics.
"""

import math
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import CardioFNO3D


def generate_synthetic_strain_dataset(n_samples: int = 1500, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    seg_targets = []
    global_targets = []

    # 17 AHA segments:
    # 1-6 Basal (Ant, AntSept, InfSept, Inf, InfLat, AntLat)
    # 7-12 Mid (Ant, AntSept, InfSept, Inf, InfLat, AntLat)
    # 13-16 Apical (Ant, Sept, Inf, Lat)
    # 17 Apex

    for _ in range(n_samples):
        edv = random.uniform(90.0, 180.0)
        esv = random.uniform(30.0, 120.0)
        sbp = random.uniform(90.0, 175.0)
        dbp = random.uniform(60.0, 105.0)
        hr = random.uniform(50.0, 110.0)

        # Pathology flags / degrees
        lad_stenosis = random.choice([0.0, 0.0, 0.5, 0.85, 0.99])
        rca_stenosis = random.choice([0.0, 0.0, 0.0, 0.75, 0.95])
        lcx_stenosis = random.choice([0.0, 0.0, 0.6, 0.90])

        is_amyloid = random.random() < 0.15
        is_lbbb = random.random() < 0.15
        is_revasc = (lad_stenosis > 0.5 or rca_stenosis > 0.5) and random.random() < 0.5
        is_post_systolic = (lad_stenosis > 0.7 or rca_stenosis > 0.7) and not is_revasc

        # Normal baseline strain ~ -20%
        base_strain = -21.0 + 0.05 * (edv - 120.0) - 0.03 * (sbp - 120.0)
        strains = [base_strain + random.uniform(-1.5, 1.5) for _ in range(17)]

        if is_amyloid:
            # Apical sparing pattern: Basal & mid severely impaired (-6 to -10%), Apex preserved (-18 to -22%)
            for i in range(12):
                strains[i] = random.uniform(-6.0, -10.0)
            for i in range(12, 17):
                strains[i] = random.uniform(-18.0, -22.5)
        elif is_lbbb:
            # Septal flash / dyssynchrony: early septal pre-stretch / reduced strain
            strains[1] = random.uniform(-8.0, -12.0)  # basal antsept
            strains[2] = random.uniform(-8.0, -12.0)  # basal infsept
            strains[7] = random.uniform(-9.0, -13.0)  # mid antsept
            strains[8] = random.uniform(-9.0, -13.0)  # mid infsept
            strains[13] = random.uniform(-11.0, -14.0)  # apical sept
        else:
            # Ischemia / Infarct based on stenosis
            if lad_stenosis > 0.6 and not is_revasc:
                # LAD territory: 1, 2, 7, 8, 13, 14, 17
                impairment = 14.0 * lad_stenosis
                for seg in [0, 1, 6, 7, 12, 13, 16]:
                    strains[seg] += impairment
            elif lad_stenosis > 0.6 and is_revasc:
                # Post-PCI restored
                for seg in [0, 1, 6, 7, 12, 13, 16]:
                    strains[seg] = base_strain + random.uniform(-1.0, 1.0)

            if rca_stenosis > 0.6 and not is_revasc:
                # RCA territory: 3, 4, 9, 10, 15
                impairment = 12.0 * rca_stenosis
                for seg in [2, 3, 8, 9, 14]:
                    strains[seg] += impairment

            if lcx_stenosis > 0.6 and not is_revasc:
                # LCx territory: 5, 11, 16
                impairment = 11.0 * lcx_stenosis
                for seg in [4, 10, 15]:
                    strains[seg] += impairment

        gls = sum(strains) / 17.0
        # Normal LV torsion is ~12-16 deg, impaired in MI / amyloid
        torsion = 14.5 + (gls + 20.0) * 0.45 + random.uniform(-1.0, 1.0)
        torsion = max(3.0, min(24.0, torsion))
        radial_thickening = 42.0 + (gls + 20.0) * 1.5 + random.uniform(-2.0, 2.0)
        radial_thickening = max(10.0, radial_thickening)
        circumf_shortening = gls * 0.95 + random.uniform(-1.0, 1.0)

        # Normalize inputs
        inp = [
            edv / 200.0,
            esv / 150.0,
            sbp / 200.0,
            dbp / 120.0,
            hr / 120.0,
            lad_stenosis,
            rca_stenosis,
            lcx_stenosis,
            1.0 if is_amyloid else 0.0,
            1.0 if is_lbbb else 0.0,
            1.0 if is_revasc else 0.0,
            1.0 if is_post_systolic else 0.0,
        ]
        inputs.append(inp)
        seg_targets.append(strains)
        global_targets.append([gls, torsion, radial_thickening, circumf_shortening])

    return (
        torch.tensor(inputs, dtype=torch.float32),
        torch.tensor(seg_targets, dtype=torch.float32),
        torch.tensor(global_targets, dtype=torch.float32),
    )


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"[CardioFNO-3D] Training on device: {device}")

    inputs, seg_targets, global_targets = generate_synthetic_strain_dataset(n_samples=2000)
    n_train = 1600

    train_x, val_x = inputs[:n_train].to(device), inputs[n_train:].to(device)
    train_seg, val_seg = seg_targets[:n_train].to(device), seg_targets[n_train:].to(device)
    train_glob, val_glob = global_targets[:n_train].to(device), global_targets[n_train:].to(device)

    model = CardioFNO3D().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    loss_fn = nn.MSELoss()

    batch_size = 64
    n_batches = train_x.size(0) // batch_size
    best_val_loss = float("inf")
    save_path = Path(__file__).resolve().parent / "checkpoints" / "cardio_fno_3d_best.pt"

    for epoch in range(1, 41):
        model.train()
        perm = torch.randperm(train_x.size(0))
        epoch_loss = 0.0

        for b in range(n_batches):
            idx = perm[b * batch_size : (b + 1) * batch_size]
            bx = train_x[idx]
            b_seg = train_seg[idx]
            b_glob = train_glob[idx]

            optimizer.zero_grad()
            pred_seg, pred_glob = model(bx)
            loss = loss_fn(pred_seg, b_seg) + 0.5 * loss_fn(pred_glob, b_glob)
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()

        # Validation
        model.eval()
        with torch.no_grad():
            v_seg, v_glob = model(val_x)
            val_loss = (loss_fn(v_seg, val_seg) + 0.5 * loss_fn(v_glob, val_glob)).item()
            seg_mae = (v_seg - val_seg).abs().mean().item()
            gls_mae = (v_glob[:, 0] - val_glob[:, 0]).abs().mean().item()

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(
                {
                    "model_state_dict": model.state_dict(),
                    "epoch": epoch,
                    "val_loss": val_loss,
                    "seg_mae": seg_mae,
                    "gls_mae": gls_mae,
                },
                save_path,
            )

        if epoch % 5 == 0 or epoch == 40:
            print(
                f"Epoch {epoch:02d} | Train: {epoch_loss/n_batches:.4f} | Val: {val_loss:.4f} | "
                f"Seg MAE: {seg_mae:.2f}% | GLS MAE: {gls_mae:.2f}%"
            )

    print(f"[CardioFNO-3D] Saved best checkpoint to: {save_path}")


if __name__ == "__main__":
    train()

