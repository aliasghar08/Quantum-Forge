"""
CardioRotor-3D: 3D Reaction-Diffusion Monodomain Wave Propagation & Rotor Mapping Neural Network.
Simulates cardiac electrical wave propagation, conduction velocity anisotropy,
scar border-zone re-entrant circuits, spiral-wave phase singularities (rotors),
and response to RF scar homogenization vs. CRT biventricular pacing.
"""

import math
import torch
import torch.nn as nn
import torch.nn.functional as F


class CardioRotor3D(nn.Module):
    """
    3D/2D Spatiotemporal Convolutional Residual Network for Monodomain Action Potential Propagation.
    Maps tissue properties (conductance anisotropy, scar geometry, refractory heterogeneity)
    into a 32x32 epicardial activation time map (ms), rotor phase singularity density,
    and VT/VF vulnerability index.
    """

    def __init__(self, in_channels: int = 6, hidden_channels: int = 32):
        super().__init__()
        # Input channels:
        # [conductance_map, refractory_period_map, scar_density_map,
        #  pacing_site_map, rf_ablation_lesion_map, crt_biv_pacing_map]

        self.stem = nn.Sequential(
            nn.Conv2d(in_channels, hidden_channels, kernel_size=3, padding=1),
            nn.BatchNorm2d(hidden_channels),
            nn.GELU(),
        )

        # 3 ResNet blocks
        self.res1 = self._make_block(hidden_channels)
        self.res2 = self._make_block(hidden_channels)
        self.res3 = self._make_block(hidden_channels)

        # Head 1: Activation isochrone map (32x32 ms)
        self.head_activation = nn.Sequential(
            nn.Conv2d(hidden_channels, 16, kernel_size=3, padding=1),
            nn.GELU(),
            nn.Conv2d(16, 1, kernel_size=1),
        )

        # Head 2: Rotor phase singularity heatmap (32x32 probability of rotor core)
        self.head_rotor_core = nn.Sequential(
            nn.Conv2d(hidden_channels, 16, kernel_size=3, padding=1),
            nn.GELU(),
            nn.Conv2d(16, 1, kernel_size=1),
            nn.Sigmoid(),
        )

        # Head 3: Global scalar indicators: [vt_vf_vulnerability_index, dominant_rotor_freq_hz, crt_resync_delta_ms]
        self.head_global = nn.Sequential(
            nn.AdaptiveAvgPool2d((1, 1)),
            nn.Flatten(),
            nn.Linear(hidden_channels, 32),
            nn.GELU(),
            nn.Linear(32, 3),
        )

    def _make_block(self, channels: int):
        return nn.Sequential(
            nn.Conv2d(channels, channels, kernel_size=3, padding=1),
            nn.BatchNorm2d(channels),
            nn.GELU(),
            nn.Conv2d(channels, channels, kernel_size=3, padding=1),
            nn.BatchNorm2d(channels),
        )

    def forward(self, x: torch.Tensor):
        h = self.stem(x)
        h = F.gelu(h + self.res1(h))
        h = F.gelu(h + self.res2(h))
        h = F.gelu(h + self.res3(h))

        act_map = self.head_activation(h).squeeze(1)
        rotor_map = self.head_rotor_core(h).squeeze(1)
        global_scalars = self.head_global(h)

        return act_map, rotor_map, global_scalars

