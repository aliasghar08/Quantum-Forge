"""
Training script for CardioRotor-3D on Apple Silicon M1 Pro Metal GPU (mps).
Trains spatiotemporal monodomain surrogate for rotor mapping & ablation response.
"""

import math
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import CardioRotor3D


def generate_synthetic_rotor_dataset(n_samples: int = 1200, grid_size: int = 32, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = torch.zeros((n_samples, 6, grid_size, grid_size), dtype=torch.float32)
    act_targets = torch.zeros((n_samples, grid_size, grid_size), dtype=torch.float32)
    rotor_targets = torch.zeros((n_samples, grid_size, grid_size), dtype=torch.float32)
    global_targets = torch.zeros((n_samples, 3), dtype=torch.float32)

    Y, X = torch.meshgrid(torch.linspace(0, 1, grid_size), torch.linspace(0, 1, grid_size), indexing="ij")

    for i in range(n_samples):
        # 0: Conductance (normal 0.8-1.0)
        cond = 0.85 + 0.15 * torch.rand((grid_size, grid_size))
        # 1: Refractory period (normal 240-280 ms)
        erp = 250.0 + 30.0 * torch.rand((grid_size, grid_size))
        # 2: Scar density (dense core + border zone)
        scar = torch.zeros((grid_size, grid_size))
        has_scar = random.random() < 0.65
        cx, cy = random.uniform(0.3, 0.7), random.uniform(0.3, 0.7)
        r_scar = random.uniform(0.12, 0.28)

        if has_scar:
            dist = torch.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
            scar = torch.clamp(1.0 - dist / r_scar, 0.0, 1.0)
            cond = cond * (1.0 - 0.85 * scar)
            erp = erp * (1.0 + 0.35 * scar)

        # 3: Pacing site (sinus vs RV apex)
        pace = torch.zeros((grid_size, grid_size))
        pace_type = random.choice(["sinus", "rv_apex", "biv_crt"])
        if pace_type == "sinus":
            pace[0, 16] = 1.0
        elif pace_type == "rv_apex":
            pace[31, 16] = 1.0
        else:
            pace[31, 8] = 1.0
            pace[31, 24] = 1.0

        # 4: RF ablation lesion
        rf = torch.zeros((grid_size, grid_size))
        is_ablated = has_scar and random.random() < 0.4
        if is_ablated:
            rf_dist = torch.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
            rf = (rf_dist < r_scar * 1.15).float()
            cond = cond * (1.0 - rf)

        # 5: CRT Biv pacing active
        is_crt = pace_type == "biv_crt"
        crt_map = torch.ones((grid_size, grid_size)) if is_crt else torch.zeros((grid_size, grid_size))

        inputs[i, 0] = cond
        inputs[i, 1] = erp / 300.0
        inputs[i, 2] = scar
        inputs[i, 3] = pace
        inputs[i, 4] = rf
        inputs[i, 5] = crt_map

        # Ground truth activation isochrone (ms)
        if pace_type == "sinus":
            act = torch.sqrt(X ** 2 + Y ** 2) * 110.0
        elif pace_type == "rv_apex":
            act = torch.sqrt(X ** 2 + (1.0 - Y) ** 2) * 135.0
        else:
            # CRT biventricular resynchronization
            d1 = torch.sqrt((X - 0.25) ** 2 + (1.0 - Y) ** 2)
            d2 = torch.sqrt((X - 0.75) ** 2 + (1.0 - Y) ** 2)
            act = torch.minimum(d1, d2) * 75.0

        if has_scar and not is_ablated:
            # Slow conduction delay across border zone
            act = act + 45.0 * scar
            # Rotor core forms at the boundary of scar
            rotor_core = torch.exp(-((dist - r_scar) ** 2) / 0.005)
            vulnerability = 0.82
            freq_hz = 5.8
        elif is_ablated:
            rotor_core = torch.zeros((grid_size, grid_size))
            vulnerability = 0.08
            freq_hz = 1.2
        else:
            rotor_core = torch.zeros((grid_size, grid_size))
            vulnerability = 0.12
            freq_hz = 1.2

        act_targets[i] = act
        rotor_targets[i] = rotor_core
        resync_delta = 42.0 if is_crt else 0.0
        global_targets[i] = torch.tensor([vulnerability, freq_hz, resync_delta])

    return inputs, act_targets, rotor_targets, global_targets


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"[CardioRotor-3D] Training on device: {device}")

    inputs, act_t, rotor_t, glob_t = generate_synthetic_rotor_dataset(n_samples=1200)
    n_train = 950

    train_x, val_x = inputs[:n_train].to(device), inputs[n_train:].to(device)
    train_act, val_act = act_t[:n_train].to(device), act_t[n_train:].to(device)
    train_rot, val_rot = rotor_t[:n_train].to(device), rotor_t[n_train:].to(device)
    train_glob, val_glob = glob_t[:n_train].to(device), glob_t[n_train:].to(device)

    model = CardioRotor3D().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    loss_mse = nn.MSELoss()
    loss_bce = nn.BCELoss()

    batch_size = 32
    n_batches = train_x.size(0) // batch_size
    best_val_loss = float("inf")
    save_path = Path(__file__).resolve().parent / "checkpoints" / "cardio_rotor_3d_best.pt"

    for epoch in range(1, 31):
        model.train()
        perm = torch.randperm(train_x.size(0))
        epoch_loss = 0.0

        for b in range(n_batches):
            idx = perm[b * batch_size : (b + 1) * batch_size]
            bx = train_x[idx]
            b_act = train_act[idx]
            b_rot = train_rot[idx]
            b_glob = train_glob[idx]

            optimizer.zero_grad()
            p_act, p_rot, p_glob = model(bx)
            loss = (
                loss_mse(p_act, b_act) * 0.02
                + loss_bce(p_rot, b_rot) * 5.0
                + loss_mse(p_glob, b_glob)
            )
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()

        # Validation
        model.eval()
        with torch.no_grad():
            v_act, v_rot, v_glob = model(val_x)
            val_loss = (
                loss_mse(v_act, val_act) * 0.02
                + loss_bce(v_rot, val_rot) * 5.0
                + loss_mse(v_glob, val_glob)
            ).item()
            act_mae = (v_act - val_act).abs().mean().item()

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(
                {
                    "model_state_dict": model.state_dict(),
                    "epoch": epoch,
                    "val_loss": val_loss,
                    "act_mae_ms": act_mae,
                },
                save_path,
            )

        if epoch % 5 == 0 or epoch == 30:
            print(
                f"Epoch {epoch:02d} | Train: {epoch_loss/n_batches:.4f} | Val: {val_loss:.4f} | "
                f"Act Isochrone MAE: {act_mae:.2f} ms"
            )

    print(f"[CardioRotor-3D] Saved best checkpoint to: {save_path}")


if __name__ == "__main__":
    train()

