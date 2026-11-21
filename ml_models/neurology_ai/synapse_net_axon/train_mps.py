"""
Training script for SynapseNet-Axon on Apple Silicon M1 Pro GPU (mps).
======================================================================
"""

import os
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import SynapseNetAxon

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")


def generate_synapse_dataset(n_samples: int = 3500, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    targets = []

    for _ in range(n_samples):
        # 8 inputs:
        # 0: myelin (0.1 to 1.0)
        # 1: nav (0.0 to 1.0)
        # 2: cav (0.0 to 1.0)
        # 3: snare (0.0 to 1.0)
        # 4: ache (0.0 to 1.0)
        # 5: nachr (0.0 to 1.0)
        # 6: nmb_blocker (0.0 to 1.0)
        # 7: reversal (0.0 or 1.0)

        myelin = random.uniform(0.15, 1.0)
        nav = random.uniform(0.1, 1.0)
        cav = random.uniform(0.1, 1.0)
        snare = random.uniform(0.05, 1.0)
        ache = random.uniform(0.1, 1.0)
        nachr = random.uniform(0.1, 1.0)
        nmb = random.uniform(0.0, 1.0) if random.random() < 0.35 else 0.0
        reversal = 1.0 if (nmb > 0.3 and random.random() < 0.5) else 0.0

        effective_blocker = max(0.0, nmb - (0.85 if reversal == 1.0 else 0.0))
        effective_nachr = nachr * (1.0 - 0.9 * effective_blocker)

        # Ground truth biophysical calculations
        cv = 5.0 + 58.0 * (myelin ** 1.5) * (nav ** 0.5)
        safety_factor = 2.4 * myelin * (nav ** 0.8)
        quanta = 45.0 * (cav ** 2.0) * snare
        cleft_ach = 800.0 * (quanta / 45.0) / (0.3 + 0.7 * ache)
        epp = 35.0 * (effective_nachr ** 1.2) * (quanta / 45.0)
        ap_success = 1.0 if epp > 15.0 and safety_factor > 1.0 else 0.0

        # RNS decrement (MG has decrement > 10%, LEMS has increment / facilitation)
        if effective_nachr < 0.4:
            rns_dec = random.uniform(20.0, 55.0)  # MG decrement
        elif cav < 0.4:
            rns_dec = random.uniform(-45.0, -15.0)  # LEMS facilitation
        else:
            rns_dec = random.uniform(-4.0, 4.0)

        inputs.append([myelin, nav, cav, snare, ache, nachr, nmb, reversal])
        targets.append([cv, safety_factor, quanta, cleft_ach, epp, ap_success, rns_dec])

    return torch.tensor(inputs, dtype=torch.float32), torch.tensor(targets, dtype=torch.float32)


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"🚀 Training SynapseNet-Axon on: {device}")

    x, y = generate_synapse_dataset(n_samples=3500)
    split = int(0.85 * len(x))
    x_train, y_train = x[:split].to(device), y[:split].to(device)
    x_val, y_val = x[split:].to(device), y[split:].to(device)

    model = SynapseNetAxon(in_features=8, hidden_dim=64, out_features=7).to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1.5e-3, weight_decay=1e-4)
    criterion = nn.MSELoss()

    checkpoint_dir = Path("checkpoints")
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    best_path = checkpoint_dir / "synapse_net_axon.pt"
    best_loss = float("inf")

    for epoch in range(1, 41):
        model.train()
        optimizer.zero_grad()
        preds = model(x_train)
        loss = criterion(preds, y_train)
        loss.backward()
        optimizer.step()

        if epoch % 10 == 0 or epoch == 40:
            model.eval()
            with torch.no_grad():
                val_preds = model(x_val)
                val_loss = criterion(val_preds, y_val).item()
                print(f"Epoch {epoch:02d}/40 | Train Loss: {loss.item():.4f} | Val MSE: {val_loss:.4f}")
                if val_loss < best_loss:
                    best_loss = val_loss
                    torch.save({
                        "model_state_dict": model.state_dict(),
                        "epoch": epoch,
                        "val_loss": val_loss,
                    }, best_path)

    print(f"✅ Training completed. Best Val Loss: {best_loss:.4f}. Saved to {best_path}")


if __name__ == "__main__":
    train()
