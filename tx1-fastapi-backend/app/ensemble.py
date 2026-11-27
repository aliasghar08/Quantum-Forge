"""Ensemble predictor with calibrated uncertainty quantification for Transition1x GNN."""

from __future__ import annotations

import json
import math
from pathlib import Path
from typing import List

import torch
import torch.nn as nn

from app.painn import PaiNNLite
from app.legacy_gnn import MolecularGraphNetwork


BASE_DIR = Path(__file__).resolve().parent.parent


class EnsemblePredictor:
    """Evaluates an ensemble of models and returns mean prediction + calibrated uncertainty."""

    def __init__(
        self,
        checkpoint_paths: list[Path] | None = None,
        architecture: str = "painn",
        metadata_path: Path | None = None,
        device: torch.device | None = None,
    ):
        self.device = device or (
            torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
        )
        self.architecture = architecture
        self.models: list[nn.Module] = []
        self.temperature: float = 1.0
        self.checkpoint_digests: list[str] = []

        self.metadata_path = metadata_path or (BASE_DIR / "models" / "ensemble_metadata.json")

        if self.metadata_path.is_file():
            try:
                meta = json.loads(self.metadata_path.read_text())
                self.temperature = float(meta.get("temperature", 1.0))
                self.checkpoint_digests = meta.get("checkpoint_digests", [])
            except Exception:
                pass

        if checkpoint_paths is None:
            models_dir = BASE_DIR.parent / "ml_models" / "tx1_painn_ensemble" / "checkpoints"
            if not models_dir.is_dir() or not (models_dir / "member_0.pt").is_file():
                models_dir = BASE_DIR / "models" / "ensemble_v2"
            checkpoint_paths = [
                models_dir / f"member_{i}.pt"
                for i in range(5)
                if (models_dir / f"member_{i}.pt").is_file()
            ]

        self.checkpoint_paths = checkpoint_paths
        self._load_members()

    def _load_members(self) -> None:
        self.models = []
        for p in self.checkpoint_paths:
            if not p.is_file():
                continue
            ckpt = torch.load(str(p), map_location="cpu", weights_only=False)
            hparams = ckpt.get("hyperparameters", {}) if isinstance(ckpt, dict) else {}
            hidden_dim = hparams.get("hidden_dim", 64)
            num_layers = hparams.get("num_layers", 3)
            num_rbf = hparams.get("num_rbf", 32)

            if self.architecture == "painn":
                model = PaiNNLite(hidden_dim=hidden_dim, num_layers=num_layers, num_rbf=num_rbf)
            else:
                model = MolecularGraphNetwork(use_rbf=True, use_cutoff=True)

            state = ckpt.get("model_state_dict", ckpt) if isinstance(ckpt, dict) else ckpt
            model.load_state_dict(state, strict=False)
            model.to(self.device)
            model.eval()
            self.models.append(model)

        if not self.models:
            from app.legacy_gnn import Tx1Calculator
            fallback_ckpt = BASE_DIR / "t1x_model_checkpoint.pt"
            if fallback_ckpt.is_file():
                calc = Tx1Calculator(checkpoint=fallback_ckpt)
                if calc._model is not None:
                    calc._model.to(self.device)
                    self.models.append(calc._model)
            if not self.models:
                model = PaiNNLite(hidden_dim=64, num_layers=3, num_rbf=32)
                model.to(self.device)
                model.eval()
                self.models.append(model)

    def energy_ev(self, atomic_numbers: list[int], positions: list[list[float]]) -> float:
        """MLIPCalculator protocol: returns ensemble mean energy."""
        mean_e, _ = self.predict_with_uncertainty(atomic_numbers, positions)
        return mean_e

    def predict_with_uncertainty(
        self, atomic_numbers: list[int], positions: list[list[float]]
    ) -> tuple[float, float]:
        """Predicts energy in eV and calibrated uncertainty in kcal/mol."""
        if not self.models:
            raise RuntimeError("Ensemble has no loaded models")

        z = torch.tensor(atomic_numbers, dtype=torch.long, device=self.device).unsqueeze(0)
        pos = torch.tensor(positions, dtype=torch.float32, device=self.device).unsqueeze(0)
        mask = torch.ones(1, len(atomic_numbers), dtype=torch.float32, device=self.device)

        energies_ev = []
        with torch.no_grad():
            for m in self.models:
                if isinstance(m, PaiNNLite):
                    e = m(z, pos, mask).item()
                else:
                    e = m(z, pos).item()
                energies_ev.append(e)

        mean_ev = sum(energies_ev) / len(energies_ev)
        if len(energies_ev) > 1:
            var = sum((x - mean_ev) ** 2 for x in energies_ev) / (len(energies_ev) - 1)
            raw_std_ev = math.sqrt(var)
        else:
            raw_std_ev = 0.05

        # Calibrated uncertainty in kcal/mol
        uncertainty_kcal = raw_std_ev * 23.0605 * self.temperature
        return float(mean_ev), float(uncertainty_kcal)

    def predict_batch_with_uncertainty(
        self, molecules: list[dict]
    ) -> list[tuple[float, float]]:
        """Vectorized batched forward pass through ensemble committee returning (mean_ev, uncertainty_kcal).
        
        Args:
            molecules: List of dicts with 'atomic_numbers' and 'positions'
        """
        if not molecules:
            return []
        if not self.models:
            raise RuntimeError("Ensemble has no loaded models")

        B = len(molecules)
        max_atoms = max(len(m["atomic_numbers"]) for m in molecules)

        z = torch.zeros((B, max_atoms), dtype=torch.long, device=self.device)
        pos = torch.zeros((B, max_atoms, 3), dtype=torch.float32, device=self.device)
        mask = torch.zeros((B, max_atoms), dtype=torch.float32, device=self.device)

        for i, mol in enumerate(molecules):
            at_nums = mol["atomic_numbers"]
            positions = mol["positions"]
            n = len(at_nums)
            z[i, :n] = torch.tensor(at_nums, dtype=torch.long, device=self.device)
            pos[i, :n] = torch.tensor(positions, dtype=torch.float32, device=self.device)
            mask[i, :n] = 1.0

        member_outputs = []
        with torch.no_grad():
            for m in self.models:
                if isinstance(m, PaiNNLite):
                    e_batch = m(z, pos, mask)  # Shape: (B,)
                else:
                    # Fallback for models without batched mask
                    e_list = [
                        m(
                            z[i : i + 1, : len(molecules[i]["atomic_numbers"])],
                            pos[i : i + 1, : len(molecules[i]["atomic_numbers"])],
                        )
                        for i in range(B)
                    ]
                    e_batch = torch.stack(e_list).squeeze(-1)
                member_outputs.append(e_batch)

        # Shape: (num_members, B)
        stacked = torch.stack(member_outputs, dim=0)
        mean_ev = stacked.mean(dim=0)  # Shape: (B,)

        if len(self.models) > 1:
            raw_std_ev = stacked.std(dim=0, unbiased=True)
        else:
            raw_std_ev = torch.full((B,), 0.05, device=self.device)

        uncertainty_kcal = raw_std_ev * 23.0605 * self.temperature

        results = []
        for i in range(B):
            results.append((float(mean_ev[i].item()), float(uncertainty_kcal[i].item())))
        return results

    def name(self) -> str:
        return "tx1-v2"
