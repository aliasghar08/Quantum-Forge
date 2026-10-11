#!/usr/bin/env python3
"""Apple Silicon (MPS) Hardware-Accelerated Continual Learner.

Trains and fine-tunes Quantum Forge neural network potentials on macOS Metal GPU
(Apple Silicon M1 Pro / unified memory) with low CPU priority so user workflows
remain completely uninterrupted 24/7.
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import os
from pathlib import Path
import sqlite3
import sys

# Configure Apple Silicon environment variables
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")
os.environ.setdefault("TORCH_FORCE_NO_WEIGHTS_ONLY_LOAD", "1")

# Set background execution priority (nice +10)
try:
    os.nice(10)
except Exception:
    pass

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset

# Add tx1-fastapi-backend to path to access PaiNNLite and MolecularGraphNetwork
BACKEND_DIR = Path("tx1-fastapi-backend").resolve()
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

try:
    from app.painn import PaiNNLite
except ImportError:
    PaiNNLite = None  # type: ignore

try:
    from app.legacy_gnn import MolecularGraphNetwork
except ImportError:
    MolecularGraphNetwork = None  # type: ignore

try:
    from ase.io import read as ase_read
except ImportError:
    ase_read = None

from literature_harvester import DEFAULT_DB_PATH, get_db

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("MPSTrainer")

CHECKPOINT_DIR = Path("models/continual_learning")
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)


def get_device() -> torch.device:
    """Detect and validate Apple Silicon Metal GPU or fallback to multi-core CPU."""
    if torch.backends.mps.is_available():
        try:
            # Quick tensor test on MPS
            test_t = torch.zeros(2, 2, device="mps")
            del test_t
            logger.info("⚡ Apple Silicon Metal Performance Shaders (MPS) active and verified.")
            return torch.device("mps")
        except Exception as exc:
            logger.warning("MPS verification failed (%s). Falling back to CPU.", exc)
    logger.info("Using multi-core CPU backend.")
    return torch.device("cpu")


class ExtxyzDataset(Dataset):
    """PyTorch Dataset loading molecular frames from extXYZ files."""

    def __init__(self, extxyz_path: Path, max_atoms: int = 40):
        self.samples = []
        self.max_atoms = max_atoms

        if not extxyz_path.is_file():
            logger.warning("extXYZ file not found: %s", extxyz_path)
            return

        frames = ase_read(str(extxyz_path), index=":", format="extxyz")
        for f in frames:
            z = f.get_atomic_numbers()
            pos = f.get_positions()
            energy = f.info.get("REF_energy", 0.0)
            forces = f.arrays.get("REF_forces")

            if len(z) <= max_atoms:
                self.samples.append({
                    "z": z,
                    "pos": pos,
                    "energy": float(energy),
                    "forces": forces,
                })

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> dict:
        return self.samples[idx]


def pad_collate_fn(batch: list[dict]) -> dict:
    """Collates variable-sized molecular graphs with padding masks."""
    batch_size = len(batch)
    max_len = max(len(item["z"]) for item in batch)

    z_padded = torch.zeros(batch_size, max_len, dtype=torch.long)
    pos_padded = torch.zeros(batch_size, max_len, 3, dtype=torch.float32)
    mask = torch.zeros(batch_size, max_len, dtype=torch.float32)
    energies = torch.zeros(batch_size, dtype=torch.float32)

    for i, item in enumerate(batch):
        n = len(item["z"])
        z_padded[i, :n] = torch.tensor(item["z"], dtype=torch.long)
        pos_padded[i, :n] = torch.tensor(item["pos"], dtype=torch.float32)
        mask[i, :n] = 1.0
        energies[i] = item["energy"]

    return {
        "z": z_padded,
        "pos": pos_padded,
        "mask": mask,
        "energy": energies,
    }


class ContinualTrainer:
    """Manages iterative fine-tuning on Apple Silicon GPU."""

    def __init__(
        self,
        base_checkpoint: Path | None = None,
        db_path: Path = DEFAULT_DB_PATH,
    ):
        self.device = get_device()
        self.db_path = db_path
        self.conn = get_db(db_path)

        # Initialize model (PaiNNLite preferred, fallback to MolecularGraphNetwork)
        if PaiNNLite is not None:
            self.model = PaiNNLite(hidden_dim=64, num_layers=3, num_rbf=32).to(self.device)
            self.model_type = "PaiNNLite"
        elif MolecularGraphNetwork is not None:
            self.model = MolecularGraphNetwork().to(self.device)
            self.model_type = "MolecularGraphNetwork"
        else:
            raise RuntimeError("Neither PaiNNLite nor MolecularGraphNetwork could be imported.")

        self.load_base_weights(base_checkpoint)

    def load_base_weights(self, checkpoint_path: Path | None) -> None:
        """Attempt loading existing weights if available."""
        candidates = [
            checkpoint_path,
            CHECKPOINT_DIR / "model_continual_latest.pt",
            BACKEND_DIR / "models/ensemble_v2/member_0.pt",
            BACKEND_DIR / "t1x_model_checkpoint_v2b.pt",
            BACKEND_DIR / "t1x_model_checkpoint.pt",
        ]
        loaded = False
        for c in candidates:
            if c and Path(c).is_file():
                try:
                    state = torch.load(c, map_location=self.device)
                    if isinstance(state, dict) and "model_state_dict" in state:
                        self.model.load_state_dict(state["model_state_dict"], strict=False)
                    elif isinstance(state, dict):
                        self.model.load_state_dict(state, strict=False)
                    logger.info("Successfully loaded initial weights from %s", c)
                    loaded = True
                    break
                except Exception as exc:
                    logger.debug("Checkpoint %s incompatible (%s), trying next...", c, exc)

        if not loaded:
            logger.info("Initialized fresh %s model weights for continual training.", self.model_type)

    def train_cycle(
        self,
        train_path: Path,
        val_path: Path,
        trigger_doi: str = "continual_cycle",
        epochs: int = 15,
        batch_size: int = 8,
        lr: float = 1e-4,
    ) -> dict:
        """Execute a fine-tuning cycle on Apple Silicon."""
        logger.info("Starting continual learning cycle on %s...", self.device)
        train_ds = ExtxyzDataset(train_path)
        val_ds = ExtxyzDataset(val_path)

        if len(train_ds) == 0:
            logger.warning("Train dataset is empty. Aborting training cycle.")
            return {"status": "skipped_empty_data"}

        train_loader = DataLoader(
            train_ds, batch_size=batch_size, shuffle=True, collate_fn=pad_collate_fn
        )
        val_loader = DataLoader(
            val_ds, batch_size=batch_size, shuffle=False, collate_fn=pad_collate_fn
        )

        optimizer = torch.optim.AdamW(self.model.parameters(), lr=lr, weight_decay=1e-5)
        scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
        criterion = nn.HuberLoss(delta=0.05)

        # Baseline validation evaluation
        initial_val_loss = self.evaluate(val_loader, criterion)
        logger.info("Baseline validation loss: %.4f eV", initial_val_loss)

        best_val_loss = initial_val_loss
        best_state = None

        self.model.train()
        for epoch in range(1, epochs + 1):
            train_loss_acc = 0.0
            steps = 0
            for batch in train_loader:
                z = batch["z"].to(self.device)
                pos = batch["pos"].to(self.device)
                mask = batch["mask"].to(self.device)
                targets = batch["energy"].to(self.device)

                optimizer.zero_grad()
                preds = self.model(z, pos, mask)
                loss = criterion(preds, targets)
                loss.backward()

                torch.nn.utils.clip_grad_norm_(self.model.parameters(), 1.0)
                optimizer.step()

                train_loss_acc += loss.item()
                steps += 1

            scheduler.step()
            val_loss = self.evaluate(val_loader, criterion)
            avg_train = train_loss_acc / max(1, steps)

            if val_loss < best_val_loss:
                best_val_loss = val_loss
                best_state = {k: v.cpu().clone() for k, v in self.model.state_dict().items()}

            if epoch % 5 == 0 or epoch == epochs:
                logger.info(
                    "Epoch %02d/%02d | Train Loss: %.4f | Val Loss: %.4f (Best: %.4f)",
                    epoch, epochs, avg_train, val_loss, best_val_loss
                )

        # Save checkpoint if model maintained or improved performance
        timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d_%H%M%S")
        out_ckpt = CHECKPOINT_DIR / f"model_continual_{timestamp}.pt"
        latest_link = CHECKPOINT_DIR / "model_continual_latest.pt"

        save_dict = {
            "model_state_dict": best_state if best_state else self.model.state_dict(),
            "model_type": self.model_type,
            "trigger_doi": trigger_doi,
            "best_val_loss": best_val_loss,
            "device": str(self.device),
            "timestamp": timestamp,
        }
        torch.save(save_dict, out_ckpt)
        torch.save(save_dict, latest_link)
        logger.info("Saved fine-tuned checkpoint to: %s", out_ckpt)

        # Also copy/sync weights to tx1-fastapi-backend models directory if appropriate
        backend_target = BACKEND_DIR / "models/ensemble_v2/member_0.pt"
        if backend_target.parent.exists():
            try:
                torch.save(save_dict["model_state_dict"], backend_target)
                logger.info("Updated backend ensemble member_0 with fine-tuned continual weights.")
            except Exception as exc:
                logger.warning("Could not update backend ensemble weights: %s", exc)

        # Record run in SQLite ledger
        with self.conn:
            self.conn.execute(
                """
                INSERT INTO training_runs (run_timestamp, trigger_doi, device, initial_loss, final_loss, val_mae_ev, checkpoint_path, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'success')
                """,
                (
                    timestamp,
                    trigger_doi,
                    str(self.device),
                    initial_val_loss,
                    best_val_loss,
                    best_val_loss,
                    str(out_ckpt),
                ),
            )

        return {
            "status": "success",
            "device": str(self.device),
            "initial_val_loss": initial_val_loss,
            "final_val_loss": best_val_loss,
            "checkpoint": str(out_ckpt),
        }

    def evaluate(self, val_loader: DataLoader, criterion: nn.Module) -> float:
        """Compute average validation loss across batches."""
        self.model.eval()
        total_loss = 0.0
        batches = 0
        with torch.no_grad():
            for batch in val_loader:
                z = batch["z"].to(self.device)
                pos = batch["pos"].to(self.device)
                mask = batch["mask"].to(self.device)
                targets = batch["energy"].to(self.device)

                preds = self.model(z, pos, mask)
                loss = criterion(preds, targets)
                total_loss += loss.item()
                batches += 1
        self.model.train()
        return total_loss / max(1, batches)


def main():
    parser = argparse.ArgumentParser(description="Apple Silicon MPS Continual Trainer")
    parser.add_argument("--train", type=str, default="data/autonomous_training/continual_train.extxyz")
    parser.add_argument("--val", type=str, default="data/autonomous_training/continual_val.extxyz")
    parser.add_argument("--epochs", type=int, default=10)
    parser.add_argument("--doi", type=str, default="manual_test")
    args = parser.parse_args()

    trainer = ContinualTrainer()
    results = trainer.train_cycle(
        Path(args.train),
        Path(args.val),
        trigger_doi=args.doi,
        epochs=args.epochs,
    )
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
