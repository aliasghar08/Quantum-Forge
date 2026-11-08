"""CardioPINN-Hemodynamics Neural Operator Architecture (Apple Silicon MPS).

Predicts:
- Fractional Flow Reserve (FFR)
- Instantaneous Wave-Free Ratio (iFR)
- Time-Averaged Wall Shear Stress (TAWSS, dynes/cm^2)
- Oscillatory Shear Index (OSI, [0, 0.5])
- Throat Reynolds Number (Re)
- Axial Pressure Drop Delta P(x) (mmHg)
- Hyperemic Coronary Volume Flow Q (mL/min)
"""

from __future__ import annotations

import math
from typing import Dict

import torch
import torch.nn as nn
import torch.nn.functional as F

PINN_INPUT_DIM = 8
PINN_OUTPUT_NAMES = [
    "ffr",
    "ifr",
    "tawss_dynes_cm2",
    "osi",
    "reynolds",
    "delta_p_mmhg",
    "q_flow_ml_min",
]


def normalize_pinn_inputs(x_raw: torch.Tensor) -> torch.Tensor:
    """Normalize raw 8D clinical/spatial inputs to [-1, 1] range for stable MPS training.

    Columns of x_raw (shape [..., 8]):
      0: stenosis_pct       [0.0, 95.0] %
      1: lesion_length_mm   [2.0, 45.0] mm
      2: ref_diam_mm        [1.8, 4.5] mm
      3: heart_rate_bpm     [45.0, 160.0] bpm
      4: sbp_mmhg           [80.0, 200.0] mmHg
      5: dbp_mmhg           [45.0, 120.0] mmHg
      6: micro_res_factor   [0.5, 2.5] dimensionless
      7: axial_x_norm       [0.0, 1.0] normalized vessel coordinate x/L
    """
    mins = torch.tensor(
        [0.0, 2.0, 1.8, 45.0, 80.0, 45.0, 0.5, 0.0],
        dtype=x_raw.dtype,
        device=x_raw.device,
    )
    maxs = torch.tensor(
        [95.0, 45.0, 4.5, 160.0, 200.0, 120.0, 2.5, 1.0],
        dtype=x_raw.dtype,
        device=x_raw.device,
    )
    scaled = 2.0 * (x_raw - mins) / (maxs - mins + 1e-8) - 1.0
    return torch.clamp(scaled, -2.5, 2.5)


class FourierFeatureEncoding(nn.Module):
    """Deterministic multi-frequency sinusoidal positional & physical feature encoding."""

    def __init__(self, in_dim: int = PINN_INPUT_DIM, num_bands: int = 4):
        super().__init__()
        self.in_dim = in_dim
        self.num_bands = num_bands
        freqs = (2.0 ** torch.arange(num_bands, dtype=torch.float32)) * math.pi
        self.register_buffer("freqs", freqs)

    @property
    def out_dim(self) -> int:
        return self.in_dim * (1 + 2 * self.num_bands)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: [B, D]
        angles = x.unsqueeze(-1) * self.freqs  # [B, D, B_freq]
        sin_feats = torch.sin(angles).reshape(x.shape[0], -1)
        cos_feats = torch.cos(angles).reshape(x.shape[0], -1)
        return torch.cat([x, sin_feats, cos_feats], dim=-1)


class PINNResidualBlock(nn.Module):
    """Residual MLP block with LayerNorm and SiLU activation for smooth spatial derivatives."""

    def __init__(self, hidden_dim: int = 128, dropout: float = 0.02):
        super().__init__()
        self.fc1 = nn.Linear(hidden_dim, hidden_dim)
        self.norm1 = nn.LayerNorm(hidden_dim)
        self.fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.norm2 = nn.LayerNorm(hidden_dim)
        self.act = nn.SiLU()
        self.drop = nn.Dropout(dropout)

    def forward(self, h: torch.Tensor) -> torch.Tensor:
        res = h
        out = self.act(self.norm1(self.fc1(h)))
        out = self.drop(out)
        out = self.norm2(self.fc2(out))
        return self.act(res + out)


class CardioPINN(nn.Module):
    """Physics-Informed Neural Operator for 1D-0D Coronary Hemodynamics & Wall Shear Stress."""

    def __init__(self, hidden_dim: int = 128, num_blocks: int = 4, num_bands: int = 4):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.num_blocks = num_blocks
        self.num_bands = num_bands

        self.fourier = FourierFeatureEncoding(PINN_INPUT_DIM, num_bands=num_bands)
        self.input_proj = nn.Sequential(
            nn.Linear(self.fourier.out_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.SiLU(),
        )
        self.blocks = nn.ModuleList(
            [PINNResidualBlock(hidden_dim=hidden_dim) for _ in range(num_blocks)]
        )

        # Dedicated physiological prediction heads
        self.head_ffr = nn.Linear(hidden_dim, 1)
        self.head_ifr = nn.Linear(hidden_dim, 1)
        self.head_tawss = nn.Linear(hidden_dim, 1)
        self.head_osi = nn.Linear(hidden_dim, 1)
        self.head_reynolds = nn.Linear(hidden_dim, 1)
        self.head_delta_p = nn.Linear(hidden_dim, 1)
        self.head_q_flow = nn.Linear(hidden_dim, 1)

    def forward(self, x_raw: torch.Tensor) -> Dict[str, torch.Tensor]:
        """Forward pass accepting raw 8D clinical/spatial tensor [B, 8]."""
        x_norm = normalize_pinn_inputs(x_raw)
        h = self.input_proj(self.fourier(x_norm))
        for blk in self.blocks:
            h = blk(h)

        # Bounded physical outputs
        ffr = 0.15 + 0.85 * torch.sigmoid(self.head_ffr(h)).squeeze(-1)
        ifr = 0.15 + 0.85 * torch.sigmoid(self.head_ifr(h)).squeeze(-1)
        tawss = F.softplus(self.head_tawss(h)).squeeze(-1) * 45.0 + 1.5
        osi = 0.49 * torch.sigmoid(self.head_osi(h)).squeeze(-1)
        reynolds = F.softplus(self.head_reynolds(h)).squeeze(-1) * 350.0 + 20.0
        delta_p = F.softplus(self.head_delta_p(h)).squeeze(-1) * 25.0
        q_flow = F.softplus(self.head_q_flow(h)).squeeze(-1) * 80.0 + 15.0

        return {
            "ffr": ffr,
            "ifr": ifr,
            "tawss_dynes_cm2": tawss,
            "osi": osi,
            "reynolds": reynolds,
            "delta_p_mmhg": delta_p,
            "q_flow_ml_min": q_flow,
        }

