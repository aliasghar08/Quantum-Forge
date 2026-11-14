"""
Training script for NeuroSpike-Net on Apple Silicon M1 Pro Metal GPU (mps).
===========================================================================
"""

import os
import random
from pathlib import Path
import torch
import torch.nn as nn
import torch.optim as optim
from network import NeuroSpikeNet

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")


def generate_synthetic_spike_dataset(n_samples: int = 2000, seed: int = 42):
    random.seed(seed)
    torch.manual_seed(seed)

    inputs = []
    targets_spec = []
    targets_adr = []
    targets_bsr = []
    targets_spike = []
    targets_term = []

    for _ in range(n_samples):
        state = random.choice([0, 1, 2, 2, 3])  # 0=alpha, 1=delta, 2=status epilepticus, 3=burst suppression
        loraz = random.choice([0.0, 0.0, 0.5, 1.0])
        keppra = random.choice([0.0, 0.0, 0.5, 1.0])
        pheny = random.choice([0.0, 0.0, 0.5, 1.0])
        valp = random.choice([0.0, 0.0, 0.5, 1.0])
        propofol = random.choice([0.0, 0.0, 0.5, 1.0])
        temp = random.uniform(33.0, 39.5)
        paco2 = random.uniform(25.0, 55.0)
        map_val = random.uniform(60.0, 140.0)
        icp_val = random.uniform(8.0, 35.0)

        drug_efficacy = (loraz * 0.45 + keppra * 0.35 + pheny * 0.30 + valp * 0.30 + propofol * 0.70)
        drug_efficacy = min(1.0, drug_efficacy)

        # Baseline spectral distributions [Delta, Theta, Alpha, Beta]
        if state == 0:  # Normal Alpha
            delta = 12.0
            theta = 18.0
            alpha = 55.0
            beta = 15.0
            bsr = 0.0
            spike_idx = 2.0
            term_prob = 100.0
        elif state == 1:  # Focal Delta
            delta = 55.0
            theta = 25.0
            alpha = 15.0
            beta = 5.0
            bsr = 5.0
            spike_idx = 8.0
            term_prob = 100.0
        elif state == 2:  # Status Epilepticus (3 Hz spike-wave)
            if drug_efficacy > 0.6:
                # Aborted to post-ictal delta/alpha
                delta = 35.0
                theta = 30.0
                alpha = 25.0
                beta = 10.0
                spike_idx = 10.0
                term_prob = 92.0
                bsr = propofol * 40.0
            else:
                # Active seizure
                delta = 65.0  # high-amplitude 3 Hz paroxysms
                theta = 15.0
                alpha = 8.0
                beta = 12.0
                spike_idx = 94.0 - drug_efficacy * 40.0
                term_prob = drug_efficacy * 80.0
                bsr = 0.0
        else:  # Burst suppression
            delta = 20.0
            theta = 10.0
            alpha = 5.0
            beta = 5.0
            bsr = 65.0 + propofol * 25.0
            spike_idx = 5.0
            term_prob = 98.0

        total_spec = delta + theta + alpha + beta
        spec_norm = [d / total_spec * 100.0 for d in [delta, theta, alpha, beta]]
        adr_val = spec_norm[2] / max(1.0, spec_norm[0])

        inp = [
            float(state),
            loraz,
            keppra,
            pheny,
            valp,
            propofol,
            temp / 37.0,
            paco2 / 40.0,
            map_val / 100.0,
            icp_val / 20.0,
        ]

        inputs.append(inp)
        targets_spec.append(spec_norm)
        targets_adr.append([adr_val])
        targets_bsr.append([bsr])
        targets_spike.append([spike_idx])
        targets_term.append([term_prob])

    return (
        torch.tensor(inputs, dtype=torch.float32),
        torch.tensor(targets_spec, dtype=torch.float32),
        torch.tensor(targets_adr, dtype=torch.float32),
        torch.tensor(targets_bsr, dtype=torch.float32),
        torch.tensor(targets_spike, dtype=torch.float32),
        torch.tensor(targets_term, dtype=torch.float32),
    )


def train():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"[*] Training NeuroSpike-Net on device: {device}")

    model = NeuroSpikeNet().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    loss_fn = nn.SmoothL1Loss()

    X, y_spec, y_adr, y_bsr, y_spk, y_term = generate_synthetic_spike_dataset()
    dataset = torch.utils.data.TensorDataset(X, y_spec, y_adr, y_bsr, y_spk, y_term)
    loader = torch.utils.data.DataLoader(dataset, batch_size=32, shuffle=True)

    epochs = 35
    for epoch in range(1, epochs + 1):
        model.train()
        total_loss = 0.0

        for b_x, b_spec, b_adr, b_bsr, b_spk, b_term in loader:
            b_x = b_x.to(device)
            b_spec = b_spec.to(device)
            b_adr = b_adr.to(device)
            b_bsr = b_bsr.to(device)
            b_spk = b_spk.to(device)
            b_term = b_term.to(device)

            optimizer.zero_grad()
            preds = model(b_x)

            l_spec = loss_fn(preds["spectral_powers"], b_spec)
            l_adr = loss_fn(preds["alpha_delta_ratio"], b_adr)
            l_bsr = loss_fn(preds["burst_suppression_ratio"], b_bsr)
            l_spk = loss_fn(preds["spike_wave_index"], b_spk)
            l_term = loss_fn(preds["seizure_termination_prob"], b_term)

            loss = 0.3 * l_spec + 0.2 * l_adr + 0.2 * l_bsr + 0.3 * l_spk + 0.2 * l_term
            loss.backward()
            optimizer.step()
            total_loss += loss.item()

        if epoch % 5 == 0 or epoch == epochs:
            avg_loss = total_loss / len(loader)
            print(f"Epoch {epoch:02d}/{epochs:02d} — Loss: {avg_loss:.4f}")

    ckpt_dir = Path(__file__).parent / "checkpoints"
    ckpt_dir.mkdir(parents=True, exist_ok=True)
    ckpt_path = ckpt_dir / "neuro_spike_net.pt"
    torch.save(
        {
            "model_state_dict": model.state_dict(),
            "in_features": 10,
            "architecture": "NeuroSpikeNet-JansenRitCoupled",
        },
        ckpt_path,
    )
    print(f"[✓] Checkpoint saved successfully at {ckpt_path}")


if __name__ == "__main__":
    train()

