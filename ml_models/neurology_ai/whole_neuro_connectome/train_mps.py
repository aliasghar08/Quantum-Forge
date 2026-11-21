"""
Training script for WholeNeuro-Connectome on Apple Silicon M1 Pro GPU (mps).
============================================================================
Synthesizes clinical neurological syndromes based on neuroanatomical localization rules.
"""

import os
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import WholeNeuroConnectome, ANATOMICAL_LOCATIONS

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")


def generate_deficit_dataset(n_samples: int = 4000, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    labels = []
    diagnostics = []

    for _ in range(n_samples):
        # Pick ground truth anatomical location 0..9
        loc = random.randint(0, 9)
        vec = [0.0] * 16

        if loc == 0:  # Cortex
            vec[0] = 1.0  # hemiparesis
            vec[1] = 0.8  # UMN
            vec[4] = random.choice([0.0, 3.0])  # facial UMN sparing forehead
            vec[5] = random.choice([0.0, 3.0])  # homonymous hemianopia
            vec[10] = random.choice([1.0, 2.0, 4.0])  # Aphasia / neglect
            vec[8] = 1.5  # brisk DTR
            diag = 0  # Brain MRI

        elif loc == 1:  # Internal Capsule
            vec[0] = 1.0  # dense equal hemiparesis (face=arm=leg)
            vec[1] = 1.0  # pure UMN
            vec[4] = 3.0  # central facial
            vec[8] = 2.0  # hyperreflexia
            vec[10] = 0.0  # no cortical signs
            diag = 0  # Brain MRI

        elif loc == 2:  # Brainstem
            vec[0] = random.choice([1.0, 3.0])  # crossed or quadriparesis
            vec[1] = 0.5  # mixed (ipsilateral CN LMN, contralateral UMN)
            vec[4] = random.choice([1.0, 2.0, 5.0])  # CN III, VI, or bulbar
            vec[6] = random.choice([0.0, 1.0])  # Horner's (Wallenberg)
            vec[9] = 1.0  # ataxia
            diag = 0  # Brain MRI

        elif loc == 3:  # Spinal Cord Tracts
            vec[0] = random.choice([2.0, 3.0])  # paraparesis / tetraparesis
            vec[1] = 1.0  # UMN below level
            vec[2] = random.choice([1.0, 2.0, 3.0])  # sensory level
            vec[3] = random.choice([2.0, 3.0])  # cervical or thoracic
            vec[7] = 2.0 if vec[3] == 2.0 or vec[3] == 3.0 else 0.0  # autonomic dysreflexia
            vec[8] = 2.0  # clonus / Babinski
            diag = 1  # Spine MRI

        elif loc == 4:  # Anterior Horn Cells (ALS/Polio)
            vec[0] = random.choice([1.0, 2.0, 3.0])
            vec[1] = random.choice([-0.8, 0.0])  # LMN or mixed ALS
            vec[2] = 0.0  # NO SENSORY LOSS (hallmark)
            vec[11] = 1.0  # marked fasciculations & atrophy
            diag = 2  # NCS/EMG

        elif loc == 5:  # Nerve Roots (Radiculopathy)
            vec[0] = 4.0  # focal
            vec[1] = -0.9  # LMN
            vec[2] = 4.0  # dermatomal sharp pain
            vec[13] = random.choice([1.0, 3.0])  # C5-C6 or L5-S1
            vec[14] = random.choice([1.0, 5.0, 6.0])  # specific dermatome
            vec[8] = -1.5  # isolated absent reflex
            diag = 1  # Spine MRI

        elif loc == 6:  # Brachial / Lumbosacral Plexus
            vec[0] = 4.0  # arm or leg
            vec[1] = -1.0  # LMN
            vec[2] = 4.0  # multi-dermatome loss
            vec[13] = random.choice([1.0, 2.0])  # Erb or Klumpke
            vec[8] = -1.8  # depressed reflexes
            diag = 2  # NCS/EMG

        elif loc == 7:  # Named Peripheral Nerve
            vec[0] = 4.0  # focal motor drop (wrist drop / foot drop)
            vec[1] = -1.0  # LMN
            vec[2] = 4.0  # strict cutaneous sensory patch
            vec[13] = random.choice([1.0, 3.0])  # radial / peroneal
            diag = 2  # NCS/EMG

        elif loc == 8:  # Neuromuscular Junction
            vec[0] = 4.0  # fluctuating weakness
            vec[1] = -0.2  # flaccid/fatigable
            vec[2] = 0.0  # NO sensory loss
            vec[4] = random.choice([1.0, 5.0])  # ptosis / diplopia / bulbar
            vec[12] = random.choice([1.0, 2.0])  # decrement on repetitive stim
            vec[8] = 0.0  # preserved reflexes
            diag = 3  # AChR-Ab / Tensilon

        else:  # Autonomic Ganglia (9)
            vec[6] = 1.0  # Horner's
            vec[7] = random.choice([1.0, 3.0, 4.0])  # orthostatic / toxidrome
            vec[0] = 0.0  # minimal primary motor weakness
            vec[8] = 0.0
            diag = 4  # Autonomic Tilt Table

        # Add small biological noise
        noisy_vec = [v + random.gauss(0.0, 0.04) for v in vec]
        inputs.append(noisy_vec)
        labels.append(loc)
        diagnostics.append(diag)

    return torch.tensor(inputs, dtype=torch.float32), torch.tensor(labels, dtype=torch.long), torch.tensor(diagnostics, dtype=torch.long)


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"🚀 Training WholeNeuro-Connectome on: {device}")

    x, y, d = generate_deficit_dataset(n_samples=4000)
    split = int(0.85 * len(x))
    x_train, y_train, d_train = x[:split].to(device), y[:split].to(device), d[:split].to(device)
    x_val, y_val, d_val = x[split:].to(device), y[split:].to(device), d[split:].to(device)

    model = WholeNeuroConnectome(in_features=16, hidden_dim=128, num_classes=10).to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    criterion_cls = nn.CrossEntropyLoss()
    criterion_diag = nn.CrossEntropyLoss()

    best_acc = 0.0
    checkpoint_dir = Path("checkpoints")
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    best_path = checkpoint_dir / "whole_neuro_connectome.pt"

    for epoch in range(1, 41):
        model.train()
        optimizer.zero_grad()
        out = model(x_train)
        loss_cls = criterion_cls(out["logits"], y_train)
        loss_diag = criterion_diag(out["diagnostic_probs"], d_train)
        total_loss = loss_cls + 0.4 * loss_diag

        total_loss.backward()
        optimizer.step()

        if epoch % 10 == 0 or epoch == 40:
            model.eval()
            with torch.no_grad():
                val_out = model(x_val)
                val_preds = torch.argmax(val_out["logits"], dim=-1)
                acc = (val_preds == y_val).float().mean().item() * 100.0
                print(f"Epoch {epoch:02d}/40 | Loss: {total_loss.item():.4f} | Val Accuracy: {acc:.1f}%")
                if acc > best_acc:
                    best_acc = acc
                    torch.save({
                        "model_state_dict": model.state_dict(),
                        "epoch": epoch,
                        "val_accuracy": acc,
                        "anatomical_locations": ANATOMICAL_LOCATIONS,
                    }, best_path)

    print(f"✅ Training completed. Best Accuracy: {best_acc:.1f}%. Saved to {best_path}")


if __name__ == "__main__":
    train()
