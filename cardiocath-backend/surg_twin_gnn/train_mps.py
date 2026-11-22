"""Training pipeline for SurgTwin-GNN on Apple Silicon MPS (Metal)."""

from __future__ import annotations

import os
from pathlib import Path
import time
import torch
import torch.nn as nn
import torch.optim as optim

from .network import SurgTwinGNN, SURG_ARTERY_NODES, SURG_STRATEGIES


def generate_synthetic_surg_batch(batch_size: int, device: torch.device):
    num_nodes = len(SURG_ARTERY_NODES)
    # Node features: [stenosis_pct, length_mm, ref_diam_mm, calc_deg, is_grafted, is_stented, flow_baseline, baseline_pressure]
    node_feats = torch.empty(batch_size, num_nodes, 8, device=device).uniform_(0.0, 1.0)
    # Give some realistic distributions
    node_feats[:, :, 0] *= 95.0  # stenosis %
    node_feats[:, :, 1] *= 40.0  # length
    node_feats[:, :, 2] = 2.0 + 2.0 * node_feats[:, :, 2]  # diam
    node_feats[:, :, 3] *= 360.0  # calcification

    # Baseline tree adjacency
    adj = torch.zeros(batch_size, num_nodes, num_nodes, device=device)
    for b in range(batch_size):
        # Aorta -> LM, RCA
        adj[b, 0, 1] = adj[b, 1, 0] = 1.0
        adj[b, 0, 6] = adj[b, 6, 0] = 1.0
        # LM -> LAD, LCx
        adj[b, 1, 2] = adj[b, 2, 1] = 1.0
        adj[b, 1, 4] = adj[b, 4, 1] = 1.0
        # LAD -> D1
        adj[b, 2, 3] = adj[b, 3, 2] = 1.0
        # LCx -> OM1
        adj[b, 4, 5] = adj[b, 5, 4] = 1.0
        # RCA -> PDA
        adj[b, 6, 7] = adj[b, 7, 6] = 1.0

    strategies = torch.randint(0, len(SURG_STRATEGIES), (batch_size,), device=device)

    # Targets
    target_perfusion = torch.empty(batch_size, 1, device=device).uniform_(0.60, 0.95)
    target_competitive = torch.empty(batch_size, 1, device=device).uniform_(0.05, 0.40)
    target_patency = torch.empty(batch_size, 1, device=device).uniform_(0.70, 0.95)
    target_mace = torch.empty(batch_size, 1, device=device).uniform_(0.02, 0.15)
    target_vtc = torch.empty(batch_size, 1, device=device).uniform_(4.0, 12.0)

    targets = {
        "perfusion": target_perfusion,
        "competitive": target_competitive,
        "patency": target_patency,
        "mace": target_mace,
        "vtc": target_vtc,
    }
    return node_feats, adj, strategies, targets


def train_surg_twin_gnn(epochs: int = 120, batch_size: int = 128, lr: float = 1e-3) -> str:
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    print(f"[SurgTwin-GNN] Training on {device}...")

    model = SurgTwinGNN().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)

    t0 = time.time()
    for ep in range(1, epochs + 1):
        model.train()
        nodes, adj, strats, targets = generate_synthetic_surg_batch(batch_size, device)
        preds = model(nodes, adj, strats)

        loss_p = nn.functional.mse_loss(preds["perfusion_reserve"], targets["perfusion"])
        loss_c = nn.functional.mse_loss(preds["competitive_flow_risk"], targets["competitive"])
        loss_pat = nn.functional.mse_loss(preds["patency_12mo"], targets["patency"])
        loss_m = nn.functional.mse_loss(preds["mace_30day"], targets["mace"])
        loss_vtc = nn.functional.mse_loss(preds["vtc_distance_mm"], targets["vtc"]) / 10.0

        total_loss = loss_p * 2.0 + loss_c + loss_pat + loss_m * 2.0 + loss_vtc

        optimizer.zero_grad()
        total_loss.backward()
        optimizer.step()

        if ep % 30 == 0 or ep == epochs:
            print(f"[SurgTwin-GNN] Epoch {ep:03d}/{epochs} - Total Loss: {total_loss.item():.4f}")

    print(f"[SurgTwin-GNN] Training complete in {time.time() - t0:.2f}s!")

    ckpt_dir = Path(__file__).resolve().parent / "checkpoints"
    ckpt_dir.mkdir(parents=True, exist_ok=True)
    out_path = ckpt_dir / "surg_twin_gnn_best.pt"

    torch.save({
        "model_state_dict": model.state_dict(),
        "strategies": SURG_STRATEGIES,
        "nodes": SURG_ARTERY_NODES,
        "trained_epochs": epochs,
    }, out_path)
    return str(out_path)


if __name__ == "__main__":
    train_surg_twin_gnn()
