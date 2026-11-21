"""CardioElectrophys-Net 1D Temporal Convolutional + Residual Architecture (Apple Silicon MPS).

Predicts:
- 120-point human ventricular action potential waveform Vm(t) across 0..600 ms
- APD50 (ms) and APD90 (ms)
- Early Afterdepolarization (EAD) probability [0, 1]
- CiPA qNet net inward/outward charge integral (uC/uF) for Torsades de Pointes (TdP) stratification
"""

from __future__ import annotations

from typing import Dict, List

import torch
import torch.nn as nn
import torch.nn.functional as F

NUM_TIME_POINTS = 120
AP_DURATION_MS = 600.0
AP_TIME_POINTS_MS: List[float] = [
    round(i * (AP_DURATION_MS / (NUM_TIME_POINTS - 1)), 2)
    for i in range(NUM_TIME_POINTS)
]


def normalize_ep_inputs(x_raw: torch.Tensor) -> torch.Tensor:
    """Normalize 7D channel blockade + pacing vector to [-1, 1].

    Columns of x_raw (shape [B, 7]):
      0: b_ikr_herg     [0.0, 1.0] fractional hERG / IKr block
      1: b_ina          [0.0, 1.0] fractional Nav1.5 / INaL block
      2: b_ical         [0.0, 1.0] fractional Cav1.2 / ICaL block
      3: b_iks          [0.0, 1.0] fractional IKs block
      4: b_ik1          [0.0, 1.0] fractional IK1 block
      5: log10_conc_uM  [-3.0, 2.5] log10 plasma concentration (uM)
      6: pacing_hr_bpm  [40.0, 150.0] pacing heart rate (bpm)
    """
    mins = torch.tensor(
        [0.0, 0.0, 0.0, 0.0, 0.0, -3.0, 40.0],
        dtype=x_raw.dtype,
        device=x_raw.device,
    )
    maxs = torch.tensor(
        [1.0, 1.0, 1.0, 1.0, 1.0, 2.5, 150.0],
        dtype=x_raw.dtype,
        device=x_raw.device,
    )
    scaled = 2.0 * (x_raw - mins) / (maxs - mins + 1e-8) - 1.0
    return torch.clamp(scaled, -2.5, 2.5)


class TemporalResBlock1D(nn.Module):
    """1D Temporal Residual Convolutional Block for smooth action potential trajectory synthesis."""

    def __init__(self, channels: int = 64, kernel_size: int = 5):
        super().__init__()
        pad = kernel_size // 2
        self.conv1 = nn.Conv1d(channels, channels, kernel_size=kernel_size, padding=pad)
        self.gn1 = nn.GroupNorm(8, channels)
        self.conv2 = nn.Conv1d(channels, channels, kernel_size=kernel_size, padding=pad)
        self.gn2 = nn.GroupNorm(8, channels)
        self.act = nn.SiLU()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        res = x
        out = self.act(self.gn1(self.conv1(x)))
        out = self.gn2(self.conv2(out))
        return self.act(res + out)


class CardioElectrophysNet(nn.Module):
    """1D ResNet + Neural ODE Surrogate for Ventricular Action Potential & CiPA TdP Risk."""

    def __init__(self, hidden_dim: int = 128, conv_channels: int = 64):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.conv_channels = conv_channels

        # Condition encoder
        self.cond_mlp = nn.Sequential(
            nn.Linear(7, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.SiLU(),
        )

        # Temporal coordinate basis [1, 4, T] combined with condition embedding
        t_grid = torch.linspace(0.0, 1.0, NUM_TIME_POINTS).unsqueeze(0)  # [1, T]
        t_basis = torch.cat(
            [
                t_grid,
                torch.sin(2.0 * 3.14159265 * t_grid),
                torch.cos(2.0 * 3.14159265 * t_grid),
                torch.exp(-4.0 * t_grid),
            ],
            dim=0,
        ).unsqueeze(0)  # [1, 4, T]
        self.register_buffer("t_basis", t_basis)

        self.temporal_stem = nn.Conv1d(hidden_dim + 4, conv_channels, kernel_size=3, padding=1)
        self.res_blocks = nn.ModuleList(
            [
                TemporalResBlock1D(conv_channels, kernel_size=5),
                TemporalResBlock1D(conv_channels, kernel_size=5),
                TemporalResBlock1D(conv_channels, kernel_size=7),
            ]
        )
        self.vm_head = nn.Conv1d(conv_channels, 1, kernel_size=1)

        # Scalar biomarker heads from pooled temporal + condition features
        self.biomarker_head = nn.Sequential(
            nn.Linear(hidden_dim + conv_channels, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, 4),  # [apd50, apd90, ead_logit, qnet]
        )

    def forward(self, x_raw: torch.Tensor) -> Dict[str, torch.Tensor]:
        """Forward pass accepting raw 7D channel-blockade tensor [B, 7]."""
        bsz = x_raw.shape[0]
        x_norm = normalize_ep_inputs(x_raw)
        c_emb = self.cond_mlp(x_norm)  # [B, H]

        # Broadcast condition across 120 time steps and concatenate with temporal basis
        c_time = c_emb.unsqueeze(-1).expand(bsz, self.hidden_dim, NUM_TIME_POINTS)
        t_feat = self.t_basis.expand(bsz, 4, NUM_TIME_POINTS)
        h_t = F.silu(self.temporal_stem(torch.cat([c_time, t_feat], dim=1)))

        for blk in self.res_blocks:
            h_t = blk(h_t)

        # Predict Vm(t) in mV (spanning -90 mV to +42 mV)
        vm_raw = self.vm_head(h_t).squeeze(1)  # [B, 120]
        vm_mv = -86.0 + 128.0 * torch.sigmoid(vm_raw)

        # Global temporal pool + condition embedding for scalar CiPA biomarkers
        h_pool = h_t.mean(dim=-1)  # [B, C]
        bio_out = self.biomarker_head(torch.cat([c_emb, h_pool], dim=-1))

        apd50_ms = 110.0 + 340.0 * torch.sigmoid(bio_out[:, 0])
        apd90_ms = torch.maximum(
            apd50_ms + 45.0,
            190.0 + 390.0 * torch.sigmoid(bio_out[:, 1]),
        )
        ead_prob = torch.sigmoid(bio_out[:, 2])
        qnet_c_f = 0.010 + 0.095 * torch.sigmoid(bio_out[:, 3])

        return {
            "vm_waveform_mv": vm_mv,
            "apd50_ms": apd50_ms,
            "apd90_ms": apd90_ms,
            "ead_probability": ead_prob,
            "qnet_c_f": qnet_c_f,
        }

