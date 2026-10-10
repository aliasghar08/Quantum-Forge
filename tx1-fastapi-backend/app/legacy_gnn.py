"""Wraps the MolecularGraphNetwork checkpoint as an MLIPCalculator.

Provides backward-compatible architecture supporting:
- Legacy v1 distance-only network (no RBF, no cutoff)
- Upgraded v2a network with Gaussian Radial Basis Functions (RBF) and smooth Cosine Cutoff Envelope
"""

from __future__ import annotations

import os
from pathlib import Path

import torch
import torch.nn as nn


class MolecularGraphNetwork(nn.Module):
    def __init__(
        self,
        hidden_dim: int = 128,
        num_interactions: int = 3,
        max_Z: int = 119,
        num_rbf: int = 64,
        rbf_rmin: float = 0.5,
        rbf_rmax: float = 6.0,
        cutoff: float = 6.0,
        use_rbf: bool = False,
        use_cutoff: bool = False,
    ):
        super().__init__()
        # Preserve all v1 layers exactly
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

        # New v2a components (only active when use_rbf is True)
        self.use_rbf = use_rbf
        self.use_cutoff = use_cutoff
        self.cutoff = cutoff

        if use_rbf:
            self.register_buffer("rbf_centers", torch.linspace(rbf_rmin, rbf_rmax, num_rbf))
            self.rbf_width = (rbf_rmax - rbf_rmin) / num_rbf
            self.rbf_proj = nn.Linear(num_rbf, hidden_dim)

    def forward(
        self, z: torch.Tensor, pos: torch.Tensor, mask: torch.Tensor | None = None
    ) -> torch.Tensor:
        if z.size(1) != pos.size(1):
            raise RuntimeError(
                f"forward: z has {z.size(1)} atoms but pos has {pos.size(1)}"
            )
        node_features = self.embedding(z)

        pos_expanded_1 = pos.unsqueeze(2)
        pos_expanded_2 = pos.unsqueeze(1)
        dist_matrix = torch.norm(pos_expanded_1 - pos_expanded_2, dim=-1)

        if self.use_rbf:
            # Gaussian RBF expansion
            diff = dist_matrix.unsqueeze(-1) - self.rbf_centers
            dist_features = torch.exp(-(diff ** 2) / (2 * self.rbf_width ** 2))
            dist_features = self.rbf_proj(dist_features)
            if self.use_cutoff:
                # Smooth cosine envelope with zero derivative at cutoff
                env = 0.5 * (torch.cos(torch.pi * dist_matrix / self.cutoff) + 1.0)
                env = torch.where(dist_matrix < self.cutoff, env, torch.zeros_like(env))
                dist_features = dist_features * env.unsqueeze(-1)
        else:
            # Original v1 path
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

    def __init__(self, checkpoint: Path | None = None, use_rbf: bool = False, use_cutoff: bool = False) -> None:
        self.checkpoint = checkpoint or checkpoint_path()
        self.use_rbf = use_rbf
        self.use_cutoff = use_cutoff
        self._load()

    def _load(self) -> None:
        if not self.checkpoint.is_file():
            raise FileNotFoundError(f"checkpoint not found at {self.checkpoint}")
        network = MolecularGraphNetwork(use_rbf=self.use_rbf, use_cutoff=self.use_cutoff)
        checkpoint = torch.load(str(self.checkpoint), map_location=torch.device("cpu"), weights_only=False)
        state = checkpoint.get("model_state_dict", checkpoint) if isinstance(checkpoint, dict) else checkpoint

        # Embedding expansion if needed
        if "embedding.weight" in state:
            old = state["embedding.weight"]
            if old.shape[0] < network.embedding.weight.shape[0]:
                new = torch.zeros_like(network.embedding.weight)
                new[: old.shape[0]] = old
                state["embedding.weight"] = new
        network.load_state_dict(state, strict=False)
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
        if self.use_rbf:
            return "tx1-v2a"
        return "tx1-fastapi"
