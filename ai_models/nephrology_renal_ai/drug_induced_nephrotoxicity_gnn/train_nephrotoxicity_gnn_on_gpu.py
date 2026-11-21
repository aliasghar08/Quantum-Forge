"""
Training script for NephroTox-GNN on Apple Silicon M1 Pro GPU (mps).
====================================================================
"""

import os
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import NephroToxGNN

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")


def generate_nephrotox_dataset(n_samples: int = 3000, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    targets = []

    # Known benchmark drug profiles
    # (mw, clogp, tpsa, hbd, hba, rotb, charge, oat, oct, megalin, ati_base, ain_base)
    drug_classes = [
        # Aminoglycoside (Gentamicin)
        (477.6, -4.1, 195.0, 8, 12, 6, +3, 10.0, 25.0, 95.0, 85.0, 15.0, 1.0),
        # Glycopeptide (Vancomycin)
        (1449.3, -3.1, 460.0, 19, 26, 9, +1, 15.0, 10.0, 80.0, 75.0, 35.0, 1.0),
        # Platinum Chemotherapy (Cisplatin)
        (300.0, -1.8, 52.0, 2, 2, 0, 0, 12.0, 92.0, 30.0, 90.0, 10.0, 1.0),
        # Nucleotide Reverse Transcriptase Inhibitor (Tenofovir)
        (287.2, -1.5, 128.0, 3, 7, 6, -1, 95.0, 15.0, 20.0, 65.0, 15.0, 0.0),
        # Calcineurin Inhibitor (Tacrolimus)
        (804.0, 3.3, 178.0, 3, 12, 6, 0, 20.0, 15.0, 10.0, 70.0, 10.0, 0.0),
        # Iodinated Contrast (Iohexol)
        (821.1, -3.2, 205.0, 6, 9, 8, 0, 25.0, 10.0, 15.0, 60.0, 5.0, 0.0),
        # NSAID (Ibuprofen)
        (206.3, 3.5, 37.3, 1, 2, 4, -1, 88.0, 12.0, 5.0, 40.0, 65.0, 0.0),
        # Safe Control (Penicillin G)
        (334.4, 1.8, 86.0, 2, 5, 4, -1, 80.0, 10.0, 5.0, 15.0, 55.0, 0.0),
    ]

    for _ in range(n_samples):
        base_drug = random.choice(drug_classes)
        mw, clogp, tpsa, hbd, hba, rotb, charge, oat_base, oct_base, meg_base, ati_b, ain_b, scaffold = base_drug

        egfr = random.uniform(15.0, 120.0)
        sepsis = random.choice([0.0, 0.0, 1.0])
        concurrent_tox = random.choice([0, 1, 2, 3])

        # Feature noise
        mw_n = max(50.0, mw + random.uniform(-10.0, 10.0))
        clogp_n = clogp + random.uniform(-0.3, 0.3)
        tpsa_n = max(10.0, tpsa + random.uniform(-5.0, 5.0))
        aromatic_frac = random.uniform(0.1, 0.6)

        # Transporter affinities
        oat = min(100.0, max(2.0, oat_base + random.uniform(-5.0, 5.0)))
        oct_val = min(100.0, max(2.0, oct_base + random.uniform(-5.0, 5.0)))
        megalin = min(100.0, max(2.0, meg_base + random.uniform(-5.0, 5.0)))

        # Toxicity amplification
        risk_amp = (1.0 + sepsis * 0.45 + concurrent_tox * 0.25) * (1.0 + max(0.0, (60.0 - egfr) / 60.0) * 0.5)
        ati_risk = min(99.0, ati_b * risk_amp * random.uniform(0.9, 1.1))
        ain_risk = min(95.0, ain_b * (1.0 + concurrent_tox * 0.15) * random.uniform(0.9, 1.1))

        # Dosing multiplier based on CKD staging
        if egfr >= 60.0:
            dose_mult = 1.0
        elif egfr >= 30.0:
            dose_mult = 0.5 + (egfr - 30.0) / 30.0 * 0.25
        elif egfr >= 15.0:
            dose_mult = 0.25 + (egfr - 15.0) / 15.0 * 0.25
        else:
            dose_mult = 0.15

        inp = [
            mw_n / 500.0,
            clogp_n / 5.0,
            tpsa_n / 120.0,
            float(hbd) / 5.0,
            float(hba) / 10.0,
            float(rotb) / 10.0,
            float(charge),
            egfr / 90.0,
            sepsis,
            float(concurrent_tox) / 3.0,
            aromatic_frac,
            scaffold,
        ]

        tgt = [oat, oct_val, megalin, ati_risk, ain_risk, dose_mult]

        inputs.append(inp)
        targets.append(tgt)

    return torch.tensor(inputs, dtype=torch.float32), torch.tensor(targets, dtype=torch.float32)


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"🔥 Training NephroTox-GNN on device: {device}")

    x_train, y_train = generate_nephrotox_dataset(n_samples=4000)
    x_train = x_train.to(device)
    y_train = y_train.to(device)

    model = NephroToxGNN().to(device)
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
                out["oat_probability"],
                out["oct_probability"],
                out["megalin_binding"],
                out["ati_risk_percent"],
                out["ain_risk_percent"],
                out["dose_multiplier"],
            ], dim=-1)

            loss = loss_fn(pred_tensor, by)

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()

        if epoch % 10 == 0 or epoch == epochs:
            print(f"Epoch {epoch:2d}/{epochs} | Loss: {epoch_loss / n_batches:.4f}")

    ckpt_dir = Path(__file__).parent / "checkpoints"
    ckpt_dir.mkdir(parents=True, exist_ok=True)
    ckpt_path = ckpt_dir / "nephro_tox_gnn.pt"

    torch.save({
        "model_state_dict": model.state_dict(),
        "device": str(device),
        "version": "1.0.0",
    }, ckpt_path)
    print(f"✅ Saved trained NephroTox-GNN checkpoint to {ckpt_path}")


if __name__ == "__main__":
    train()
