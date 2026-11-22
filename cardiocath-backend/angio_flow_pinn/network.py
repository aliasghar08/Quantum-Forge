"""AngioFlow-PINN Neural Operator Architecture (Apple Silicon MPS).

Physics-Informed Neural Operator for 1D-0D Coronary Navier-Stokes Hemodynamics
and Contrast Dye Advection-Diffusion Cine Angiography.

Predicts spatial:
- wire-free vFFR / QFR [0.2, 1.0]
- corrected TIMI Frame Count (cTFC) [10.0, 60.0]
- Myocardial Blush Grade (MBG) [0.0, 3.0]
- Time-Averaged Wall Shear Stress (TAWSS, dynes/cm^2) [2.0, 120.0]
- Oscillatory Shear Index (OSI) [0.0, 0.5]
- Contrast Bolus Velocity (cm/s) [10.0, 80.0]
"""

from __future__ import annotations

import math
from typing import Dict, List, Tuple

import torch
import torch.nn as nn
import torch.nn.functional as F

ANGIO_VESSELS = ["LM", "LAD", "D1", "S1", "LCx", "OM1", "RCA", "PDA", "PLV"]
ANGIO_INPUT_DIM = 9  # [vessel_idx, stenosis_pct, length_mm, ref_diam_mm, calc_deg, hr_bpm, map_mmhg, contrast_flow, axial_x]

def normalize_angio_inputs(x_raw: torch.Tensor) -> torch.Tensor:
    """Normalize raw 9D coronary hemodynamic inputs for stable MPS training."""
    mins = torch.tensor([0.0, 0.0, 2.0, 1.5, 0.0, 40.0, 50.0, 1.0, 0.0], dtype=x_raw.dtype, device=x_raw.device)
    maxs = torch.tensor([8.0, 99.0, 50.0, 5.0, 360.0, 150.0, 140.0, 10.0, 1.0], dtype=x_raw.dtype, device=x_raw.device)
    scaled = 2.0 * (x_raw - mins) / (maxs - mins + 1e-8) - 1.0
    return torch.clamp(scaled, -2.5, 2.5)


class SinusoidalEncoding(nn.Module):
    def __init__(self, in_dim: int = ANGIO_INPUT_DIM, num_bands: int = 4):
        super().__init__()
        self.in_dim = in_dim
        self.num_bands = num_bands
        freqs = (2.0 ** torch.arange(num_bands, dtype=torch.float32)) * math.pi
        self.register_buffer("freqs", freqs)

    @property
    def out_dim(self) -> int:
        return self.in_dim * (1 + 2 * self.num_bands)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        angles = x.unsqueeze(-1) * self.freqs
        sin_f = torch.sin(angles).reshape(x.shape[0], -1)
        cos_f = torch.cos(angles).reshape(x.shape[0], -1)
        return torch.cat([x, sin_f, cos_f], dim=-1)


class AngioFlowPINN(nn.Module):
    """Physics-Informed Neural Operator for Wire-Free vFFR/QFR & Angiographic Perfusion."""

    def __init__(self, hidden_dim: int = 128, num_layers: int = 4):
        super().__init__()
        self.encoder = SinusoidalEncoding(ANGIO_INPUT_DIM, num_bands=4)
        in_dim = self.encoder.out_dim

        self.input_layer = nn.Linear(in_dim, hidden_dim)
        self.res_blocks = nn.ModuleList([
            nn.Sequential(
                nn.Linear(hidden_dim, hidden_dim),
                nn.SiLU(),
                nn.Linear(hidden_dim, hidden_dim),
            )
            for _ in range(num_layers)
        ])
        self.layer_norms = nn.ModuleList([nn.LayerNorm(hidden_dim) for _ in range(num_layers)])

        # Physics prediction heads
        self.vffr_head = nn.Linear(hidden_dim, 1)
        self.ctfc_head = nn.Linear(hidden_dim, 1)
        self.mbg_head = nn.Linear(hidden_dim, 1)
        self.tawss_head = nn.Linear(hidden_dim, 1)
        self.osi_head = nn.Linear(hidden_dim, 1)
        self.bolus_v_head = nn.Linear(hidden_dim, 1)

    def forward(self, x_raw: torch.Tensor) -> Dict[str, torch.Tensor]:
        x_norm = normalize_angio_inputs(x_raw)
        h = F.silu(self.input_layer(self.encoder(x_norm)))

        for block, ln in zip(self.res_blocks, self.layer_norms):
            h = ln(h + F.silu(block(h)))

        # Physics bound scalings
        vffr = torch.clamp(0.20 + 0.80 * torch.sigmoid(self.vffr_head(h)), 0.20, 1.0)
        ctfc = torch.clamp(10.0 + 50.0 * torch.sigmoid(self.ctfc_head(h)), 10.0, 60.0)
        mbg = torch.clamp(3.0 * torch.sigmoid(self.mbg_head(h)), 0.0, 3.0)
        tawss = torch.clamp(2.0 + 118.0 * F.softplus(self.tawss_head(h)) / 3.0, 2.0, 120.0)
        osi = torch.clamp(0.50 * torch.sigmoid(self.osi_head(h)), 0.0, 0.50)
        bolus_v = torch.clamp(10.0 + 70.0 * torch.sigmoid(self.bolus_v_head(h)), 10.0, 80.0)

        return {
            "vffr": vffr,
            "ctfc": ctfc,
            "mbg": mbg,
            "tawss": tawss,
            "osi": osi,
            "bolus_v": bolus_v,
        }
