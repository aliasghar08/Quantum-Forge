#!/usr/bin/env python3
"""Phase A/C/D Training script for Transition1x GNN on Apple Silicon MPS.

Optimized for FP32 training with gradient accumulation, cosine annealing,
Huber barrier loss, and MPS cache management.
"""

from __future__ import annotations

import argparse
import datetime
import json
import math
import os
import random
import subprocess
import sys
import time
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.optim import AdamW
from torch.optim.lr_scheduler import CosineAnnealingLR
from torch.utils.data import Dataset, DataLoader

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.legacy_gnn import MolecularGraphNetwork


def get_git_sha() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=str(BASE_DIR), stderr=subprocess.DEVNULL
        ).decode().strip()
    except Exception:
        return "unknown"


def element_to_z(symbol: str) -> int:
    mapping = {
        "H": 1, "He": 2, "Li": 3, "Be": 4, "B": 5, "C": 6, "N": 7, "O": 8,
        "F": 9, "Ne": 10, "Na": 11, "Mg": 12, "Al": 13, "Si": 14, "P": 15,
        "S": 16, "Cl": 17, "Ar": 18, "K": 19, "Ca": 20, "Br": 35, "I": 53,
    }
    return mapping.get(symbol.strip().capitalize(), 6)


def parse_xyz(xyz_str: str) -> tuple[list[str], list[list[float]]]:
    lines = [line.strip() for line in xyz_str.strip().split("\n") if line.strip()]
    if len(lines) < 3:
        return [], []
    try:
        num_atoms = int(lines[0])
    except ValueError:
        return [], []
    atoms = []
    positions = []
    for line in lines[2 : 2 + num_atoms]:
        parts = line.split()
        if len(parts) < 4:
            continue
        atoms.append(parts[0])
        try:
            positions.append([float(parts[1]), float(parts[2]), float(parts[3])])
        except ValueError:
            return [], []
    return atoms, positions


def generate_lst_frames(
    r_pos: list[list[float]], p_pos: list[list[float]], n_frames: int = 11
) -> list[list[list[float]]]:
    frames = []
    for i in range(n_frames):
        t = i / (n_frames - 1)
        alpha = 0.5 * (1.0 - math.cos(math.pi * t))
        cur_pos = [
            [
                rp[0] * (1.0 - alpha) + pp[0] * alpha,
                rp[1] * (1.0 - alpha) + pp[1] * alpha,
                rp[2] * (1.0 - alpha) + pp[2] * alpha,
            ]
            for rp, pp in zip(r_pos, p_pos)
        ]
        frames.append(cur_pos)
    return frames


class ReactionDataset(Dataset):
    def __init__(self, jsonl_path: Path, max_samples: int | None = None, n_frames: int = 11):
        self.samples = []
        self.n_frames = n_frames
        if not jsonl_path.is_file():
            raise FileNotFoundError(f"Missing dataset at {jsonl_path}")
        with open(jsonl_path, "r") as f:
            lines = [line.strip() for line in f if line.strip()]
        if max_samples:
            lines = lines[:max_samples]

        for line in lines:
            try:
                item = json.loads(line)
                r_atoms, r_pos = parse_xyz(item["reactant_xyz"])
                p_atoms, p_pos = parse_xyz(item["product_xyz"])
                if not r_atoms or not p_atoms or len(r_atoms) != len(p_atoms):
                    continue
                z_list = [element_to_z(a) for a in r_atoms]
                barrier_kcal = float(item["reference_barrier_kcal_mol"])
                dE_kcal = float(item.get("reference_reaction_energy_kcal_mol", 0.0))
                weight = float(item.get("weight", 1.0))

                frames = generate_lst_frames(r_pos, p_pos, n_frames=n_frames)

                self.samples.append({
                    "reaction_id": item["reaction_id"],
                    "z": torch.tensor(z_list, dtype=torch.long),
                    "frames": torch.tensor(frames, dtype=torch.float32),  # [F, N, 3]
                    "target_barrier_kcal": torch.tensor(barrier_kcal, dtype=torch.float32),
                    "target_dE_kcal": torch.tensor(dE_kcal, dtype=torch.float32),
                    "weight": torch.tensor(weight, dtype=torch.float32),
                })
            except Exception:
                continue

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        return self.samples[idx]


def collate_reactions(batch):
    # Dynamic padding for variable atom counts across reactions
    max_atoms = max(item["z"].size(0) for item in batch)
    B = len(batch)
    F_count = batch[0]["frames"].size(0)

    padded_z = torch.zeros(B, max_atoms, dtype=torch.long)
    padded_frames = torch.zeros(B, F_count, max_atoms, 3, dtype=torch.float32)
    padded_mask = torch.zeros(B, max_atoms, dtype=torch.float32)

    target_barriers = torch.stack([item["target_barrier_kcal"] for item in batch])
    target_dEs = torch.stack([item["target_dE_kcal"] for item in batch])
    weights = torch.stack([item["weight"] for item in batch])

    for i, item in enumerate(batch):
        N = item["z"].size(0)
        padded_z[i, :N] = item["z"]
        padded_frames[i, :, :N, :] = item["frames"]
        padded_mask[i, :N] = 1.0

    return {
        "z": padded_z,
        "frames": padded_frames,
        "mask": padded_mask,
        "target_barrier": target_barriers,
        "target_dE": target_dEs,
        "weight": weights,
    }


def compute_reaction_energies(model, batch_z, batch_frames, batch_mask):
    """Evaluate LST frames for a batch of reactions.

    batch_z: [B, N]
    batch_frames: [B, F, N, 3]
    batch_mask: [B, N]
    Returns:
      pred_barriers_kcal: [B]
      pred_dE_kcal: [B]
      pred_energy_mean: scalar float tensor
    """
    B, F_count, N, _ = batch_frames.shape
    # Flatten batch and frames: [B * F, N]
    flat_z = batch_z.unsqueeze(1).repeat(1, F_count, 1).view(B * F_count, N)
    flat_mask = batch_mask.unsqueeze(1).repeat(1, F_count, 1).view(B * F_count, N)
    flat_pos = batch_frames.view(B * F_count, N, 3)

    flat_energies_ev = model(flat_z, flat_pos, flat_mask)  # [B * F]
    energies_ev = flat_energies_ev.view(B, F_count)  # [B, F]

    EV_TO_KCAL = 23.0605
    e_reactant = energies_ev[:, 0]
    e_max = torch.max(energies_ev, dim=1).values
    e_product = energies_ev[:, -1]

    pred_barriers_kcal = (e_max - e_reactant) * EV_TO_KCAL
    pred_dE_kcal = (e_product - e_reactant) * EV_TO_KCAL

    return pred_barriers_kcal, pred_dE_kcal, energies_ev.mean()


def build_model(architecture: str):
    if architecture == "legacy":
        return MolecularGraphNetwork(hidden_dim=128, num_interactions=3)
    elif architecture == "rbf_cutoff":
        return MolecularGraphNetwork(
            hidden_dim=128,
            num_interactions=3,
            num_rbf=64,
            rbf_rmin=0.5,
            rbf_rmax=6.0,
            cutoff=6.0,
            use_rbf=True,
            use_cutoff=True,
        )
    elif architecture == "painn":
        from app.painn import PaiNNLite
        return PaiNNLite(hidden_dim=64, num_layers=3, num_rbf=32)
    else:
        raise ValueError(f"Unknown architecture: {architecture}")


def main():
    parser = argparse.ArgumentParser(description="Train Transition1x GNN on MPS.")
    parser.add_argument("--data-dir", type=str, default="data/")
    parser.add_argument("--checkpoint-out", type=str, default="t1x_model_checkpoint_v2a.pt")
    parser.add_argument("--epochs", type=int, default=300)
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--grad-accum", type=int, default=4)
    parser.add_argument("--lr", type=float, default=1e-3)
    parser.add_argument("--weight-decay", type=float, default=1e-5)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--device", type=str, default="auto")
    parser.add_argument("--architecture", type=str, default="legacy", choices=["legacy", "rbf_cutoff", "painn"])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--log-dir", type=str, default="data/runs/")
    parser.add_argument("--resume", type=str, default=None)
    parser.add_argument("--frames", type=int, default=11)
    args = parser.parse_args()

    # Seed
    random.seed(args.seed)
    torch.manual_seed(args.seed)

    # Device
    if args.device == "auto":
        device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
    else:
        device = torch.device(args.device)

    print(f"=== Starting Training ({args.architecture}) on {device} ===")
    print(f"Hyperparameters: epochs={args.epochs}, bs={args.batch_size}, accum={args.grad_accum}, lr={args.lr}, seed={args.seed}")

    data_dir = Path(args.data_dir)
    log_dir = Path(args.log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"{timestamp}_{args.architecture}.jsonl"

    # Datasets
    train_limit = 100 if args.dry_run else None
    val_limit = 50 if args.dry_run else None

    train_ds = ReactionDataset(data_dir / "train.jsonl", max_samples=train_limit, n_frames=args.frames)
    val_ds = ReactionDataset(data_dir / "val.jsonl", max_samples=val_limit, n_frames=args.frames)

    train_loader = DataLoader(
        train_ds, batch_size=args.batch_size, shuffle=True, collate_fn=collate_reactions
    )
    val_loader = DataLoader(
        val_ds, batch_size=args.batch_size, shuffle=False, collate_fn=collate_reactions
    )

    print(f"Train samples: {len(train_ds)}, Val samples: {len(val_ds)}")

    # Model
    model = build_model(args.architecture).to(device)
    optimizer = AdamW(model.parameters(), lr=args.lr, weight_decay=args.weight_decay, betas=(0.9, 0.999))
    scheduler = CosineAnnealingLR(optimizer, T_max=args.epochs, eta_min=1e-6)

    start_epoch = 0
    if args.resume and Path(args.resume).is_file():
        ckpt = torch.load(args.resume, map_location="cpu", weights_only=False)
        model.load_state_dict(ckpt.get("model_state_dict", ckpt), strict=False)
        if "optimizer_state_dict" in ckpt:
            optimizer.load_state_dict(ckpt["optimizer_state_dict"])
        start_epoch = ckpt.get("epoch", 0) + 1
        print(f"Resumed from {args.resume} at epoch {start_epoch}")

    # Section 11 weights: {"energy": 0.01, "barrier": 1.0}
    w_barrier = 1.0
    w_energy = 0.01

    best_val_mae = float("inf")
    patience = 30
    patience_counter = 0
    git_sha = get_git_sha()

    total_epochs = 1 if args.dry_run else args.epochs

    for epoch in range(start_epoch, start_epoch + total_epochs):
        model.train()
        t_epoch_start = time.time()
        running_loss = 0.0
        barrier_mae_sum = 0.0
        sample_count = 0

        optimizer.zero_grad()

        for step, batch in enumerate(train_loader):
            z = batch["z"].to(device)
            frames = batch["frames"].to(device)
            mask = batch["mask"].to(device)
            target_b = batch["target_barrier"].to(device)
            weights = batch["weight"].to(device)

            pred_b, pred_dE, pred_e_mean = compute_reaction_energies(model, z, frames, mask)

            # Huber loss with delta=1.0 kcal/mol
            b_loss = F.huber_loss(pred_b, target_b, delta=1.0, reduction="none")
            weighted_b_loss = (b_loss * weights).mean()
            # Small regularizing energy penalty
            e_loss = pred_e_mean.abs() * 0.001

            loss = (w_barrier * weighted_b_loss + w_energy * e_loss) / args.grad_accum
            loss.backward()

            if (step + 1) % args.grad_accum == 0 or (step + 1) == len(train_loader):
                torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=5.0)
                optimizer.step()
                optimizer.zero_grad()

            bs = z.size(0)
            running_loss += (loss.item() * args.grad_accum) * bs
            barrier_mae_sum += torch.abs(pred_b - target_b).sum().item()
            sample_count += bs

        if device.type == "mps":
            torch.mps.synchronize()

        train_loss = running_loss / sample_count if sample_count else 0.0
        train_mae = barrier_mae_sum / sample_count if sample_count else 0.0

        # Validation
        model.eval()
        val_loss_sum = 0.0
        val_mae_sum = 0.0
        val_count = 0

        with torch.no_grad():
            for batch in val_loader:
                z = batch["z"].to(device)
                frames = batch["frames"].to(device)
                mask = batch["mask"].to(device)
                target_b = batch["target_barrier"].to(device)
                weights = batch["weight"].to(device)

                pred_b, _, pred_e_mean = compute_reaction_energies(model, z, frames, mask)
                b_loss = F.huber_loss(pred_b, target_b, delta=1.0, reduction="none")
                weighted_b_loss = (b_loss * weights).mean()
                loss = w_barrier * weighted_b_loss + w_energy * pred_e_mean.abs() * 0.001

                bs = z.size(0)
                val_loss_sum += loss.item() * bs
                val_mae_sum += torch.abs(pred_b - target_b).sum().item()
                val_count += bs

        if device.type == "mps":
            torch.mps.synchronize()
            if (epoch + 1) % 10 == 0:
                torch.mps.empty_cache()

        scheduler.step()
        wall_time = time.time() - t_epoch_start
        val_loss = val_loss_sum / val_count if val_count else 0.0
        val_mae = val_mae_sum / val_count if val_count else 0.0
        samples_per_sec = sample_count / wall_time if wall_time > 0 else 0

        mps_mem_gb = 0.0
        if device.type == "mps" and hasattr(torch.mps, "current_allocated_memory"):
            mps_mem_gb = torch.mps.current_allocated_memory() / 1e9

        epoch_log = {
            "epoch": epoch + 1,
            "train_loss": round(train_loss, 4),
            "train_barrier_mae_kcal": round(train_mae, 4),
            "val_loss": round(val_loss, 4),
            "val_barrier_mae_kcal": round(val_mae, 4),
            "lr": round(optimizer.param_groups[0]["lr"], 6),
            "wall_time_s": round(wall_time, 2),
            "mps_memory_allocated_gb": round(mps_mem_gb, 3),
            "samples_per_second": round(samples_per_sec, 2),
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        }

        print(
            f"Epoch {epoch+1:3d} | Train Loss: {train_loss:.4f} | Train MAE: {train_mae:.2f} kcal/mol | "
            f"Val MAE: {val_mae:.2f} kcal/mol | {samples_per_sec:.1f} samples/s ({wall_time:.1f}s)"
        )

        with open(log_file, "a") as f:
            f.write(json.dumps(epoch_log) + "\n")

        # Save best checkpoint
        if not args.dry_run:
            if val_mae < best_val_mae:
                best_val_mae = val_mae
                patience_counter = 0
                out_path = Path(args.checkpoint_out)
                torch.save({
                    "epoch": epoch + 1,
                    "model_state_dict": model.state_dict(),
                    "optimizer_state_dict": optimizer.state_dict(),
                    "loss": float(val_loss),
                    "best_val_barrier_mae_kcal": float(best_val_mae),
                    "hyperparameters": vars(args),
                    "git_sha": git_sha,
                    "timestamp": epoch_log["timestamp"],
                }, str(out_path))
                print(f"  ★ New best checkpoint saved to {out_path} (Val MAE: {best_val_mae:.2f} kcal/mol)")
            else:
                patience_counter += 1
                if patience_counter >= patience:
                    print(f"Early stopping triggered at epoch {epoch+1} (patience={patience})")
                    break

            # Checkpoint every 20 epochs
            if (epoch + 1) % 20 == 0:
                periodic_path = Path(f"{args.checkpoint_out}.epoch{epoch+1}.pt")
                torch.save({
                    "epoch": epoch + 1,
                    "model_state_dict": model.state_dict(),
                    "optimizer_state_dict": optimizer.state_dict(),
                    "loss": float(val_loss),
                }, str(periodic_path))
                print(f"  Periodic checkpoint saved to {periodic_path}")

    if args.dry_run:
        print("\n✔ Dry run completed successfully without error.")


if __name__ == "__main__":
    main()
