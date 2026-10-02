"""Wraps the original MolecularGraphNetwork checkpoint as an MLIPCalculator.

Extracted from main.py so the registry can load it on demand instead of at
module import time. The class definition and the checkpoint path resolution
are byte-identical to the previous version — the only change is that the
loader is a callable rather than a module-level global.
"""

from __future__ import annotations

import os
from pathlib import Path

import torch
import torch.nn as nn


class MolecularGraphNetwork(nn.Module):
    def __init__(self, hidden_dim: int = 128, num_interactions: int = 3, max_Z: int = 119):
        super().__init__()
        self.embedding = nn.Embedding(max_Z, hidden_dim)

        self.distance_expansion = nn.Sequential(
            nn.Linear(1, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
        )

        self.interaction_layers = nn.ModuleList([
            nn.Sequential(
                nn.Linear(hidden_dim * 2, hidden_dim),
                nn.SiLU(),
                nn.Linear(hidden_dim, hidden_dim),
            )
            for _ in range(num_interactions)
        ])

        self.energy_readout = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim // 2),
            nn.SiLU(),
            nn.Linear(hidden_dim // 2, 1),
        )

    def forward(self, z: torch.Tensor, pos: torch.Tensor, mask: torch.Tensor | None = None) -> torch.Tensor:
        if z.size(1) != pos.size(1):
            raise RuntimeError(
                f"forward: z has {z.size(1)} atoms but pos has {pos.size(1)}"
            )
        node_features = self.embedding(z)

        pos_expanded_1 = pos.unsqueeze(2)
        pos_expanded_2 = pos.unsqueeze(1)
        dist_matrix = torch.norm(pos_expanded_1 - pos_expanded_2, dim=-1)

        dist_features = self.distance_expansion(dist_matrix.unsqueeze(-1))

        for layer in self.interaction_layers:
            expanded_nodes = node_features.unsqueeze(2).expand(-1, -1, pos.size(1), -1)
            combined = torch.cat([expanded_nodes, dist_features], dim=-1)
            messages = layer(combined).sum(dim=2)
            node_features = node_features + messages

        per_atom_energy = self.energy_readout(node_features).squeeze(-1)
        if mask is not None:
            per_atom_energy = per_atom_energy * mask

        total_energy = per_atom_energy.sum(dim=-1)
        return total_energy


BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_CHECKPOINT = BASE_DIR / "t1x_model_checkpoint.pt"


def checkpoint_path() -> Path:
    override = os.environ.get("T1X_CHECKPOINT", "").strip()
    return Path(override).expanduser() if override else DEFAULT_CHECKPOINT


class Tx1Calculator:
    """MLIPCalculator adapter over the GNN checkpoint."""

    _model: MolecularGraphNetwork | None = None

    def __init__(self) -> None:
        self._load()

    def _load(self) -> None:
        path = checkpoint_path()
        if not path.is_file():
            raise FileNotFoundError(f"checkpoint not found at {path}")
        network = MolecularGraphNetwork()
        checkpoint = torch.load(str(path), map_location=torch.device("cpu"))
        state = checkpoint.get("model_state_dict", checkpoint) if isinstance(checkpoint, dict) else checkpoint
        # Embedding expansion, unchanged.
        if "embedding.weight" in state:
            old = state["embedding.weight"]
            if old.shape[0] < network.embedding.weight.shape[0]:
                new = torch.zeros_like(network.embedding.weight)
                new[: old.shape[0]] = old
                state["embedding.weight"] = new
        network.load_state_dict(state)
        network.eval()
        self._model = network

    def energy_ev(
        self,
        atomic_numbers: list[int],
        positions: list[list[float]],
    ) -> float:
        if self._model is None:
            raise RuntimeError("Model is not loaded")
        dev = next(self._model.parameters()).device
        z = torch.tensor(atomic_numbers, dtype=torch.long, device=dev).unsqueeze(0)
        pos = torch.tensor(positions, dtype=torch.float32, device=dev).unsqueeze(0)
        mask = (z != 0).float()
        with torch.no_grad():
            energy = self._model(z, pos, mask)
        return float(energy.item())

    def name(self) -> str:
        return "tx1-fastapi"
