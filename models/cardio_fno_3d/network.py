"""
CardioFNO-3D: 3D Myocardial Strain, Torsion & 17-Segment AHA Bullseye Neural Operator.
Uses 1D/Spectral Fourier Neural Operator blocks and residual projections to map
myocardial biomechanical parameters (regional contractility, fiber angles, infarct burden,
pathology state) into the full 17-segment AHA longitudinal strain tensor (%),
radial thickening, circumferential strain, and apical-basal twist/torsion (deg).
"""

import math
import torch
import torch.nn as nn
import torch.nn.functional as F


class SpectralConv1d(nn.Module):
    """1D Fourier Neural Operator layer with complex weights in frequency domain."""

    def __init__(self, in_channels: int, out_channels: int, modes: int):
        super().__init__()
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.modes = modes
        scale = 1.0 / (in_channels * out_channels)
        self.weights = nn.Parameter(
            scale * torch.randn(in_channels, out_channels, self.modes, dtype=torch.cfloat)
        )

    def compl_mul1d(self, input: torch.Tensor, weights: torch.Tensor) -> torch.Tensor:
        # (batch, in_channel, modes), (in_channel, out_channel, modes) -> (batch, out_channel, modes)
        return torch.einsum("bix,iox->box", input, weights)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        batchsize = x.shape[0]
        # x: (batch, channels, length)
        # Compute Fourier coefficients along spatial dimension
        x_ft = torch.fft.rfft(x)

        # Multiply relevant Fourier modes
        out_ft = torch.zeros(
            batchsize,
            self.out_channels,
            x.size(-1) // 2 + 1,
            device=x.device,
            dtype=torch.cfloat,
        )
        modes_to_use = min(self.modes, x_ft.size(-1))
        out_ft[:, :, :modes_to_use] = self.compl_mul1d(
            x_ft[:, :, :modes_to_use], self.weights[:, :, :modes_to_use]
        )

        # Return to physical space
        x = torch.fft.irfft(out_ft, n=x.size(-1))
        return x


class CardioFNO3D(nn.Module):
    """
    Fourier Neural Operator for 3D Myocardial Regional Deformation and 17-Segment AHA Strain.
    Inputs (dim 12):
      [edv_norm, esv_norm, sbp_norm, dbp_norm, hr_norm,
       lad_stenosis, rca_stenosis, lcx_stenosis,
       amyloid_apical_sparing_flag, lbbb_dyssynchrony_flag,
       pci_revascularized_flag, post_systolic_flag]
    Outputs:
      - 17-segment AHA longitudinal strain (%)
      - Global Longitudinal Strain (GLS %)
      - Apical-basal LV twist / torsion (deg)
      - Radial thickening strain (mean %)
      - Circumferential shortening strain (mean %)
    """

    def __init__(self, in_features: int = 12, hidden_channels: int = 64, modes: int = 8):
        super().__init__()
        self.modes = modes
        self.in_features = in_features
        self.hidden_channels = hidden_channels

        # Uplift 1D feature vector to a 17-node spatial sequence (17 AHA segments)
        self.fc_in = nn.Sequential(
            nn.Linear(in_features, 64),
            nn.GELU(),
            nn.Linear(64, 17 * hidden_channels),
        )

        # Fourier Neural Operator blocks
        self.fno1 = SpectralConv1d(hidden_channels, hidden_channels, modes)
        self.w1 = nn.Conv1d(hidden_channels, hidden_channels, 1)

        self.fno2 = SpectralConv1d(hidden_channels, hidden_channels, modes)
        self.w2 = nn.Conv1d(hidden_channels, hidden_channels, 1)

        self.fno3 = SpectralConv1d(hidden_channels, hidden_channels, modes)
        self.w3 = nn.Conv1d(hidden_channels, hidden_channels, 1)

        # Output projection per segment (longitudinal strain %)
        self.head_segmental = nn.Sequential(
            nn.Conv1d(hidden_channels, 32, 1),
            nn.GELU(),
            nn.Conv1d(32, 1, 1),
        )

        # Global biomechanical deformation head (GLS, Torsion, Radial, Circumferential)
        self.head_global = nn.Sequential(
            nn.Linear(17 * hidden_channels, 64),
            nn.GELU(),
            nn.Linear(64, 4),  # [gls, torsion_deg, radial_thickening_pct, circumf_shortening_pct]
        )

    def forward(self, x: torch.Tensor):
        b = x.shape[0]
        # Project into 17-segment spatial grid: (b, hidden_channels, 17)
        h = self.fc_in(x).view(b, self.hidden_channels, 17)

        # Block 1
        x1 = self.fno1(h) + self.w1(h)
        h = F.gelu(x1)

        # Block 2
        x2 = self.fno2(h) + self.w2(h)
        h = F.gelu(x2)

        # Block 3
        x3 = self.fno3(h) + self.w3(h)
        h = F.gelu(x3)

        # Segmental strains (17 values): (b, 17)
        seg_strain = self.head_segmental(h).squeeze(1)

        # Global outputs: (b, 4)
        h_flat = h.view(b, -1)
        global_out = self.head_global(h_flat)

        return seg_strain, global_out

