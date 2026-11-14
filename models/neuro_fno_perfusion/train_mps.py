"""
Training script for NeuroFNO-Perfusion on Apple Silicon M1 Pro Metal GPU (mps).
================================================================================
Trains Spectral Fourier Neural Operator on 3D Circle of Willis collateral flows,
cerebral autoregulation, ischemic core progression, and penumbra volumes.
"""

import os
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import NeuroFNOPerfusion

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")


def generate_synthetic_perfusion_dataset(n_samples: int = 2000, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    targets_collateral = []
    targets_core = []
    targets_rate = []
    targets_penumbra = []
    targets_benefit = []
    targets_regional = []

    for _ in range(n_samples):
        map_val = random.uniform(55.0, 140.0)
        icp_val = random.uniform(8.0, 38.0)
        paco2_val = random.uniform(25.0, 55.0)
        onset_hrs = random.uniform(0.5, 12.0)
        acom_patent = 1.0 if random.random() < 0.70 else 0.0
        pcom_patent = 1.0 if random.random() < 0.60 else 0.0
        lepto_score = random.choice([0.0, 0.33, 0.66, 1.0])
        occ_type = random.choice([0, 1, 1, 1, 2, 3, 4])  # 0=None, 1=Left M1, 2=Basilar, 3=ICA T, 4=Moyamoya
        revasc = 1.0 if (occ_type != 0 and random.random() < 0.40) else 0.0
        sbp = map_val + random.uniform(20.0, 45.0)
        dbp = map_val - random.uniform(15.0, 30.0)
        hct = random.uniform(0.32, 0.50)

        cpp = map_val - icp_val

        # Ground truth biophysical modeling
        collateral_base = (acom_patent * 30.0 + pcom_patent * 25.0 + lepto_score * 45.0)
        # CPP below 60 drops collateral driving pressure
        if cpp < 60.0:
            collateral_base *= max(0.2, cpp / 60.0)
        elif cpp > 110.0:
            collateral_base = min(100.0, collateral_base * 1.1)

        if occ_type == 0:
            core_vol = 0.0
            core_rate = 0.0
            penumbra_vol = 0.0
            benefit = 0.0
            regional = [100.0, 100.0, 100.0]
        else:
            # Core growth rate depends heavily on collaterals
            # Good collaterals: 1.8 mL/hr. Poor collaterals: 6.5 mL/hr.
            rate_factor = 7.0 - (collateral_base / 100.0) * 5.2
            core_rate = max(0.5, rate_factor)

            if revasc > 0.5:
                # Recanalized (TICI 3)
                core_vol = min(40.0, 12.0 + (onset_hrs * core_rate * 0.4))
                penumbra_vol = 0.0
                benefit = 92.0
                regional = [95.0, 95.0, 95.0]
            else:
                core_vol = min(120.0, 15.0 + onset_hrs * core_rate)
                total_at_risk = 135.0 if occ_type == 1 else (150.0 if occ_type == 3 else 90.0)
                penumbra_vol = max(0.0, total_at_risk - core_vol)
                benefit = max(10.0, 100.0 - (core_vol / 120.0) * 80.0)

                if occ_type == 1:
                    regional = [max(10.0, collateral_base * 0.4), 95.0, 95.0]
                elif occ_type == 2:
                    regional = [80.0, 80.0, max(8.0, collateral_base * 0.3)]
                elif occ_type == 3:
                    regional = [max(8.0, collateral_base * 0.25), max(15.0, collateral_base * 0.35), 90.0]
                else:
                    regional = [65.0, 65.0, 85.0]

        inp = [
            map_val / 100.0,
            icp_val / 20.0,
            paco2_val / 40.0,
            onset_hrs / 12.0,
            acom_patent,
            pcom_patent,
            lepto_score,
            float(occ_type),
            revasc,
            sbp / 140.0,
            dbp / 80.0,
            hct / 0.45,
        ]

        inputs.append(inp)
        targets_collateral.append([collateral_base])
        targets_core.append([core_vol])
        targets_rate.append([core_rate])
        targets_penumbra.append([penumbra_vol])
        targets_benefit.append([benefit])
        targets_regional.append([r / 100.0 for r in regional])

    return (
        torch.tensor(inputs, dtype=torch.float32),
        torch.tensor(targets_collateral, dtype=torch.float32),
        torch.tensor(targets_core, dtype=torch.float32),
        torch.tensor(targets_rate, dtype=torch.float32),
        torch.tensor(targets_penumbra, dtype=torch.float32),
        torch.tensor(targets_benefit, dtype=torch.float32),
        torch.tensor(targets_regional, dtype=torch.float32),
    )


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"[*] Training NeuroFNO-Perfusion on device: {device}")

    model = NeuroFNOPerfusion().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    loss_fn = nn.SmoothL1Loss()

    X, y_col, y_core, y_rate, y_pen, y_ben, y_reg = generate_synthetic_perfusion_dataset()
    dataset = torch.utils.data.TensorDataset(X, y_col, y_core, y_rate, y_pen, y_ben, y_reg)
    loader = torch.utils.data.DataLoader(dataset, batch_size=32, shuffle=True)

    epochs = 35
    for epoch in range(1, epochs + 1):
        model.train()
        total_loss = 0.0

        for b_x, b_col, b_core, b_rate, b_pen, b_ben, b_reg in loader:
            b_x = b_x.to(device)
            b_col = b_col.to(device)
            b_core = b_core.to(device)
            b_rate = b_rate.to(device)
            b_pen = b_pen.to(device)
            b_ben = b_ben.to(device)
            b_reg = b_reg.to(device)

            optimizer.zero_grad()
            preds = model(b_x)

            l_col = loss_fn(preds["collateral_flow_index"], b_col)
            l_core = loss_fn(preds["core_volume_ml"], b_core)
            l_rate = loss_fn(preds["core_rate_ml_hr"], b_rate)
            l_pen = loss_fn(preds["penumbra_volume_ml"], b_pen)
            l_ben = loss_fn(preds["tici_benefit_score"], b_ben)
            l_reg = loss_fn(preds["regional_perfusion"] / 100.0, b_reg)

            loss = (
                0.2 * l_col +
                0.3 * l_core +
                0.2 * l_rate +
                0.3 * l_pen +
                0.1 * l_ben +
                0.2 * l_reg
            )

            loss.backward()
            optimizer.step()
            total_loss += loss.item()

        if epoch % 5 == 0 or epoch == epochs:
            avg_loss = total_loss / len(loader)
            print(f"Epoch {epoch:02d}/{epochs:02d} — Loss: {avg_loss:.4f}")

    ckpt_dir = Path(__file__).parent / "checkpoints"
    ckpt_dir.mkdir(parents=True, exist_ok=True)
    ckpt_path = ckpt_dir / "neuro_fno_perfusion.pt"
    torch.save(
        {
            "model_state_dict": model.state_dict(),
            "in_features": 12,
            "architecture": "NeuroFNOPerfusion-Spectral1D",
        },
        ckpt_path,
    )
    print(f"[✓] Checkpoint saved successfully at {ckpt_path}")


if __name__ == "__main__":
    train()
