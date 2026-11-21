"""Independent MPS Training Pipeline for CardioNephroGNN (5-Member Bootstrap Ensemble).

Features:
1. Bemis-Murcko Chemical Scaffold Splitting + Bootstrap Resampling across 5 Ensemble Members (`member_0.pt` to `member_4.pt`).
2. Multi-Task Masked Loss (Handling sparse target assay matrices).
3. Apple Silicon Metal GPU Acceleration (torch.device("mps")) with os.nice(10) priority.
4. Cosine Annealing Learning Rate Schedule, Gradient Clipping, and Early Stopping.
5. Best Model Checkpoint Serialization + Reference Training SMILES for RDKit Tanimoto OOD Detection.
"""

from __future__ import annotations

import argparse
import collections
import logging
import math
import os
from pathlib import Path
import random
import time
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torch.optim.lr_scheduler import CosineAnnealingLR

# Configure background priority
try:
    os.nice(10)
except Exception:
    pass

from .network import (
    CardioNephroGNN,
    MolecularFeaturizer,
    TARGET_NAMES,
)

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("CardioNephroTrainer")

BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "data" / "cardio_nephro_assays.parquet"
CHECKPOINT_DIR = BASE_DIR / "checkpoints"
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)
BEST_CHECKPOINT = CHECKPOINT_DIR / "cardio_nephro_gnn_best.pt"
ENSEMBLE_SIZE = 5


def get_device() -> torch.device:
    """Select MPS on Apple Silicon M1 Pro, fallback to CPU."""
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def scaffold_split(
    df: pd.DataFrame,
    train_ratio: float = 0.80,
    val_ratio: float = 0.10,
    test_ratio: float = 0.10,
    seed: int = 42,
) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Split dataset by Bemis-Murcko chemical scaffolds to test generalization."""
    scaffold_to_indices: Dict[str, List[int]] = collections.defaultdict(list)

    for idx, row in df.iterrows():
        scaffold = str(row.get("scaffold", ""))
        scaffold_to_indices[scaffold].append(idx)

    # Shuffle scaffolds
    rng = random.Random(seed)
    scaffolds = list(scaffold_to_indices.keys())
    rng.shuffle(scaffolds)

    # Sort scaffold groups by size descending for balanced grouping
    scaffold_groups = [scaffold_to_indices[sc] for sc in scaffolds]
    scaffold_groups.sort(key=len, reverse=True)

    total_samples = len(df)
    train_cutoff = int(train_ratio * total_samples)
    val_cutoff = int((train_ratio + val_ratio) * total_samples)

    train_inds: List[int] = []
    val_inds: List[int] = []
    test_inds: List[int] = []

    for group in scaffold_groups:
        if len(train_inds) + len(group) <= train_cutoff:
            train_inds.extend(group)
        elif len(train_inds) + len(val_inds) + len(group) <= val_cutoff:
            val_inds.extend(group)
        else:
            test_inds.extend(group)

    train_df = df.iloc[train_inds].copy().reset_index(drop=True)
    val_df = df.iloc[val_inds].copy().reset_index(drop=True)
    test_df = df.iloc[test_inds].copy().reset_index(drop=True)

    logger.info(
        f"Scaffold Split (seed={seed}) -> Train: {len(train_df)}, "
        f"Val: {len(val_df)}, Test: {len(test_df)}"
    )
    return train_df, val_df, test_df


class CardioNephroDataset:
    """Pre-computes molecular graphs and target vectors for fast MPS training."""

    def __init__(self, df: pd.DataFrame):
        self.samples: List[Dict[str, Any]] = []

        for _, row in df.iterrows():
            smiles = str(row["smiles"])
            graph = MolecularFeaturizer.smiles_to_graph(smiles)
            if graph is None:
                continue

            # Target dictionary
            targets: Dict[str, float] = {}
            for t_name in TARGET_NAMES:
                val = row.get(f"{t_name}_pIC50")
                targets[f"{t_name}_pIC50"] = float(val) if pd.notna(val) else float("nan")

            tox = row.get("herg_cardiotoxic")
            targets["herg_cardiotoxic"] = float(tox) if pd.notna(tox) else float("nan")

            self.samples.append({
                "smiles": smiles,
                "compound_name": row.get("compound_name", "Unknown"),
                "graph": graph,
                "targets": targets,
            })

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> Dict[str, Any]:
        return self.samples[idx]


def compute_multi_task_loss(
    predictions: Dict[str, torch.Tensor],
    targets: Dict[str, float],
    device: torch.device,
) -> Tuple[torch.Tensor, Dict[str, float]]:
    """Compute masked loss for sparse target arrays."""
    huber = nn.SmoothL1Loss(reduction="none")
    bce = nn.BCEWithLogitsLoss(reduction="none")

    total_loss = torch.tensor(0.0, device=device)
    loss_metrics: Dict[str, float] = {}
    valid_tasks = 0

    # Continuous pIC50 affinity regression heads
    for t_name in TARGET_NAMES:
        key = f"{t_name}_pIC50"
        true_val = targets.get(key, float("nan"))
        if not math.isnan(true_val):
            y_true = torch.tensor([true_val], device=device, dtype=torch.float32)
            y_pred = predictions[key]
            task_loss = huber(y_pred, y_true).mean()
            total_loss = total_loss + task_loss
            loss_metrics[key] = task_loss.item()
            valid_tasks += 1

    # Binary hERG cardiotoxicity risk head
    tox_val = targets.get("herg_cardiotoxic", float("nan"))
    if not math.isnan(tox_val):
        y_tox = torch.tensor([tox_val], device=device, dtype=torch.float32)
        y_tox_pred = predictions["herg_cardiotoxic_logit"]
        tox_loss = bce(y_tox_pred, y_tox).mean()
        total_loss = total_loss + 0.6 * tox_loss
        loss_metrics["herg_cardiotoxic"] = tox_loss.item()
        valid_tasks += 1

    if valid_tasks > 0:
        total_loss = total_loss / valid_tasks

    return total_loss, loss_metrics


def train_single_member(
    member_idx: int,
    df: pd.DataFrame,
    all_smiles: List[str],
    device: torch.device,
    epochs: int = 35,
    lr: float = 3e-4,
    hidden_dim: int = 128,
    num_layers: int = 4,
    base_seed: int = 42,
) -> Tuple[CardioNephroGNN, float, float]:
    """Train a single bootstrap ensemble member on Apple Silicon MPS."""
    seed = base_seed + member_idx * 17
    torch.manual_seed(seed)
    random.seed(seed)
    np.random.seed(seed)

    train_df, val_df, test_df = scaffold_split(df, seed=seed)
    # Bootstrap resample training set with replacement (plus unique anchor coverage)
    rng = np.random.default_rng(seed)
    boot_indices = rng.choice(len(train_df), size=len(train_df), replace=True)
    # Combine bootstrap draw with full train_df for robust small-N convergence with distinct member weights
    boot_train_df = pd.concat(
        [train_df, train_df.iloc[boot_indices]], ignore_index=True
    )

    train_dataset = CardioNephroDataset(boot_train_df)
    val_dataset = CardioNephroDataset(val_df)
    test_dataset = CardioNephroDataset(test_df)

    model = CardioNephroGNN(
        hidden_dim=hidden_dim,
        num_layers=num_layers,
        dropout=0.10 + 0.015 * member_idx,
    ).to(device)

    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = CosineAnnealingLR(optimizer, T_max=epochs, eta_min=1e-5)

    best_val_loss = float("inf")
    best_epoch = 0
    member_ckpt_path = CHECKPOINT_DIR / f"member_{member_idx}.pt"

    logger.info(
        f"--- Training Ensemble Member #{member_idx} (seed={seed}, "
        f"boot_train={len(train_dataset)}, val={len(val_dataset)}) on {device} ---"
    )

    for epoch in range(1, epochs + 1):
        model.train()
        train_loss = 0.0
        train_count = 0

        indices = list(range(len(train_dataset)))
        random.shuffle(indices)

        for idx in indices:
            item = train_dataset[idx]
            g = item["graph"]
            targets = item["targets"]

            node_feats = g["node_features"].to(device)
            adj = g["adj_matrix"].to(device)
            edge_feats = g["edge_features"].to(device)

            optimizer.zero_grad()
            preds = model(node_feats, adj, edge_feats)
            loss, _ = compute_multi_task_loss(preds, targets, device)

            if loss.requires_grad and not torch.isnan(loss):
                loss.backward()
                nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
                optimizer.step()
                train_loss += loss.item()
                train_count += 1

        scheduler.step()
        avg_train_loss = train_loss / max(train_count, 1)

        # Validation Step
        model.eval()
        val_loss = 0.0
        val_count = 0

        with torch.no_grad():
            for idx in range(len(val_dataset)):
                item = val_dataset[idx]
                g = item["graph"]
                targets = item["targets"]

                node_feats = g["node_features"].to(device)
                adj = g["adj_matrix"].to(device)
                edge_feats = g["edge_features"].to(device)

                preds = model(node_feats, adj, edge_feats)
                loss, _ = compute_multi_task_loss(preds, targets, device)
                if not torch.isnan(loss):
                    val_loss += loss.item()
                    val_count += 1

        avg_val_loss = val_loss / max(val_count, 1)

        if epoch % 10 == 0 or epoch == 1 or avg_val_loss < best_val_loss:
            logger.info(
                f"[Member {member_idx}] Epoch [{epoch:02d}/{epochs:02d}] | "
                f"Train Loss: {avg_train_loss:.4f} | Val Loss: {avg_val_loss:.4f}"
            )

        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            best_epoch = epoch
            checkpoint = {
                "model_state_dict": model.state_dict(),
                "member_idx": member_idx,
                "seed": seed,
                "hidden_dim": hidden_dim,
                "num_layers": num_layers,
                "epoch": epoch,
                "val_loss": best_val_loss,
                "target_names": TARGET_NAMES,
                "reference_smiles": all_smiles,
                "trained_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "device": str(device),
            }
            torch.save(checkpoint, member_ckpt_path)

        if hasattr(torch, "mps") and torch.backends.mps.is_available():
            torch.mps.empty_cache()

    checkpoint = torch.load(member_ckpt_path, map_location=device)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    test_loss = 0.0
    test_count = 0
    with torch.no_grad():
        for idx in range(len(test_dataset)):
            item = test_dataset[idx]
            g = item["graph"]
            targets = item["targets"]

            node_feats = g["node_features"].to(device)
            adj = g["adj_matrix"].to(device)
            edge_feats = g["edge_features"].to(device)

            preds = model(node_feats, adj, edge_feats)
            loss, _ = compute_multi_task_loss(preds, targets, device)
            if not torch.isnan(loss):
                test_loss += loss.item()
                test_count += 1

    avg_test_loss = test_loss / max(test_count, 1)
    logger.info(
        f"[Member {member_idx}] Saved {member_ckpt_path.name} "
        f"(Best Val: {best_val_loss:.4f} @ Ep {best_epoch}, Test: {avg_test_loss:.4f})"
    )
    return model, best_val_loss, avg_test_loss


def train_cardio_nephro_gnn(
    epochs: int = 35,
    lr: float = 3e-4,
    hidden_dim: int = 128,
    num_layers: int = 4,
    seed: int = 42,
    num_members: int = ENSEMBLE_SIZE,
) -> CardioNephroGNN:
    """Train the 5-member CardioNephroGNN bootstrap ensemble on Apple Silicon MPS."""
    device = get_device()
    logger.info(
        f"Targeting Training Device: {device} "
        f"(Apple Silicon Hardware Accelerated | {num_members}-Member Bootstrap Ensemble)"
    )

    if not DATA_PATH.exists():
        logger.warning(f"Dataset {DATA_PATH} not found. Launching harvester...")
        from .harvest_chembl import build_cardio_nephro_dataset
        df = build_cardio_nephro_dataset(live_fetch=True)
    else:
        df = pd.read_parquet(DATA_PATH)

    all_smiles = [str(s) for s in df["smiles"].dropna().unique().tolist()]
    logger.info(f"Loaded {len(df)} compounds ({len(all_smiles)} unique SMILES) for ensemble training.")

    best_overall_val = float("inf")
    best_model: Optional[CardioNephroGNN] = None
    best_member_idx = 0

    for m_idx in range(num_members):
        model, val_loss, _ = train_single_member(
            member_idx=m_idx,
            df=df,
            all_smiles=all_smiles,
            device=device,
            epochs=epochs,
            lr=lr,
            hidden_dim=hidden_dim,
            num_layers=num_layers,
            base_seed=seed,
        )
        if val_loss < best_overall_val or best_model is None:
            best_overall_val = val_loss
            best_model = model
            best_member_idx = m_idx

    # Copy best member checkpoint to BEST_CHECKPOINT for backward compatibility
    best_member_ckpt = CHECKPOINT_DIR / f"member_{best_member_idx}.pt"
    if best_member_ckpt.exists():
        ckpt_data = torch.load(best_member_ckpt, map_location=device)
        ckpt_data["ensemble_size"] = num_members
        torch.save(ckpt_data, BEST_CHECKPOINT)
        logger.info(
            f"5-Member Ensemble Training Complete! Best Member: #{best_member_idx} "
            f"(Val Loss: {best_overall_val:.4f}) -> synced to {BEST_CHECKPOINT.name}"
        )

    assert best_model is not None
    return best_model


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train CardioNephroGNN 5-Member Ensemble on Apple Silicon.")
    parser.add_argument("--epochs", type=int, default=35, help="Number of training epochs per member.")
    parser.add_argument("--lr", type=float, default=3e-4, help="Learning rate.")
    parser.add_argument("--members", type=int, default=5, help="Number of bootstrap ensemble members.")
    args = parser.parse_args()

    train_cardio_nephro_gnn(epochs=args.epochs, lr=args.lr, num_members=args.members)
