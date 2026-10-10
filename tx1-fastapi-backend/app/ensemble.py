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

        base_dir = Path(__file__).resolve().parent.parent
        self.metadata_path = metadata_path or (base_dir / "models" / "ensemble_metadata.json")

        if self.metadata_path.is_file():
            try:
                meta = json.loads(self.metadata_path.read_text())
                self.temperature = float(meta.get("temperature", 1.0))
                self.checkpoint_digests = meta.get("checkpoint_digests", [])
            except Exception:
                pass

        if checkpoint_paths is None:
            models_dir = base_dir / "models" / "ensemble_v2"
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
            # Fallback single model or warning
            pass

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
                e = m(z, pos, mask).item()
                energies_ev.append(e)

        mean_ev = sum(energies_ev) / len(energies_ev)
        if len(energies_ev) > 1:
            var = sum((x - mean_ev) ** 2 for x in energies_ev) / (len(energies_ev) - 1)
            raw_std_ev = math.sqrt(var)
        else:
            raw_std_ev = 0.0

        # Calibrated uncertainty in kcal/mol
        uncertainty_kcal = raw_std_ev * 23.0605 * self.temperature
        return float(mean_ev), float(uncertainty_kcal)

    def name(self) -> str:
        return "tx1-v2"
