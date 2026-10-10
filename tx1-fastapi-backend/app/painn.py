"""PaiNN-lite (Polarizable Atom Interaction Neural Network).

Equivariant message passing neural network carrying both rotation-invariant
scalar features and rotation-equivariant 3D vector features.

Reference:
Schütt, Unke, Gastegger. "Equivariant message passing for the prediction
of tensorial properties and molecular spectra." ICML 2021.
"""

from __future__ import annotations

import math
from pathlib import Path
import torch
import torch.nn as nn
import torch.nn.functional as F


class CosineCutoff(nn.Module):
    def __init__(self, cutoff: float = 6.0):
        super().__init__()
        self.cutoff = cutoff

    def forward(self, distances: torch.Tensor) -> torch.Tensor:
        cut = 0.5 * (torch.cos(torch.pi * distances / self.cutoff) + 1.0)
        return torch.where(distances < self.cutoff, cut, torch.zeros_like(cut))


class GaussianRBF(nn.Module):
    def __init__(self, num_rbf: int = 32, r_min: float = 0.5, r_max: float = 6.0):
        super().__init__()
        centers = torch.linspace(r_min, r_max, num_rbf)
        self.register_buffer("centers", centers)
        self.width = (r_max - r_min) / num_rbf

    def forward(self, distances: torch.Tensor) -> torch.Tensor:
        diff = distances.unsqueeze(-1) - self.centers
        return torch.exp(-(diff ** 2) / (2 * self.width ** 2))


class PaiNNInteraction(nn.Module):
    def __init__(self, hidden_dim: int = 64, num_rbf: int = 32, cutoff: float = 6.0):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.cutoff_fn = CosineCutoff(cutoff)

        self.scalar_message_mlp = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, 3 * hidden_dim),
        )
        self.rbf_proj = nn.Linear(num_rbf, 3 * hidden_dim)

    def forward(
        self,
        s: torch.Tensor,
        v: torch.Tensor,
        dir_ij: torch.Tensor,
        dist_ij: torch.Tensor,
        rbf_ij: torch.Tensor,
        mask: torch.Tensor | None = None,
    ) -> tuple[torch.Tensor, torch.Tensor]:
        """Message step.

        s: [B, N, F]
        v: [B, N, F, 3]
        dir_ij: [B, N, N, 3] (unit direction from i to j)
        dist_ij: [B, N, N]
        rbf_ij: [B, N, N, num_rbf]
        """
        B, N, F = s.shape

        # Filter rbf with cutoff
        cutoff = self.cutoff_fn(dist_ij).unsqueeze(-1)  # [B, N, N, 1]
        rbf_feat = self.rbf_proj(rbf_ij) * cutoff  # [B, N, N, 3F]

        s_proj = self.scalar_message_mlp(s)  # [B, N, 3F]
        s_expanded = s_proj.unsqueeze(1).expand(-1, N, -1, -1)  # [B, N, N, 3F]

        combined = s_expanded * rbf_feat  # [B, N, N, 3F]
        split_s, split_v, split_gate = torch.split(combined, F, dim=-1)

        # Scalar message: sum over neighbors j
        ds = split_s.sum(dim=2)  # [B, N, F]

        # Vector message: split_v * dir_ij + split_gate * v_j
        v_expanded = v.unsqueeze(1).expand(-1, N, -1, -1, -1)  # [B, N, N, F, 3]
        dir_expanded = dir_ij.unsqueeze(3)  # [B, N, N, 1, 3]

        dv = (split_v.unsqueeze(-1) * dir_expanded + split_gate.unsqueeze(-1) * v_expanded).sum(dim=2)  # [B, N, F, 3]

        if mask is not None:
            ds = ds * mask.unsqueeze(-1)
            dv = dv * mask.unsqueeze(-1).unsqueeze(-1)

        return s + ds, v + dv


class PaiNNUpdate(nn.Module):
    def __init__(self, hidden_dim: int = 64):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.lin_v = nn.Linear(hidden_dim, 2 * hidden_dim, bias=False)
        self.mlp_s = nn.Sequential(
            nn.Linear(2 * hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, 3 * hidden_dim),
        )

    def forward(
        self, s: torch.Tensor, v: torch.Tensor, mask: torch.Tensor | None = None
    ) -> tuple[torch.Tensor, torch.Tensor]:
        """Update step combining scalar and equivariant vector features."""
        B, N, F, _ = v.shape

        # Linear transform on vectors: [B, N, 3, F] -> [B, N, 3, 2F]
        v_perm = v.permute(0, 1, 3, 2)
        v_trans = self.lin_v(v_perm).permute(0, 1, 3, 2)  # [B, N, 2F, 3]
        v_u, v_w = torch.split(v_trans, F, dim=2)

        # Invariant scalar from vectors: dot product
        v_norm_sq = (v_u ** 2).sum(dim=-1)  # [B, N, F]
        v_norm = torch.sqrt(v_norm_sq + 1e-8)

        combined_s = torch.cat([s, v_norm], dim=-1)  # [B, N, 2F]
        a = self.mlp_s(combined_s)  # [B, N, 3F]
        a_s, a_vv, a_v = torch.split(a, F, dim=-1)

        ds = a_s
        dv = v_w * a_vv.unsqueeze(-1)

        s_out = s + ds
        v_out = v + dv

        if mask is not None:
            s_out = s_out * mask.unsqueeze(-1)
            v_out = v_out * mask.unsqueeze(-1).unsqueeze(-1)

        return s_out, v_out


class PaiNNLite(nn.Module):
    """PaiNN-lite equivariant potential."""

    def __init__(
        self,
        hidden_dim: int = 64,
        num_layers: int = 3,
        num_rbf: int = 32,
        cutoff: float = 6.0,
        max_Z: int = 119,
    ):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.num_layers = num_layers
        self.cutoff = cutoff

        self.embedding = nn.Embedding(max_Z, hidden_dim)
        self.rbf = GaussianRBF(num_rbf=num_rbf, r_min=0.5, r_max=cutoff)

        self.interactions = nn.ModuleList([
            PaiNNInteraction(hidden_dim=hidden_dim, num_rbf=num_rbf, cutoff=cutoff)
            for _ in range(num_layers)
        ])
        self.updates = nn.ModuleList([
            PaiNNUpdate(hidden_dim=hidden_dim) for _ in range(num_layers)
        ])

        self.readout = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim // 2),
            nn.SiLU(),
            nn.Linear(hidden_dim // 2, 1),
        )

    def forward(
        self, z: torch.Tensor, pos: torch.Tensor, mask: torch.Tensor | None = None
    ) -> torch.Tensor:
        """Forward pass predicting total scalar molecular energy.

        z: LongTensor [B, N]
        pos: FloatTensor [B, N, 3]
        mask: FloatTensor [B, N] | None
        """
        B, N = z.shape
        s = self.embedding(z)  # [B, N, F]
        v = torch.zeros(B, N, self.hidden_dim, 3, device=pos.device, dtype=pos.dtype)

        # Pairwise displacement vectors and distances
        # diff_ij = pos_j - pos_i
        diff_ij = pos.unsqueeze(1) - pos.unsqueeze(2)  # [B, N, N, 3]
        dist_ij = torch.norm(diff_ij, dim=-1) + 1e-8  # [B, N, N]
        dir_ij = diff_ij / dist_ij.unsqueeze(-1)  # [B, N, N, 3]

        rbf_ij = self.rbf(dist_ij)  # [B, N, N, num_rbf]

        for interaction, update in zip(self.interactions, self.updates):
            s, v = interaction(s, v, dir_ij, dist_ij, rbf_ij, mask)
            s, v = update(s, v, mask)

        per_atom_energy = self.readout(s).squeeze(-1)  # [B, N]
        if mask is not None:
            per_atom_energy = per_atom_energy * mask

        total_energy = per_atom_energy.sum(dim=-1)  # [B]
        return total_energy
