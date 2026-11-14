"""
NeuroFNO-Perfusion: 3D Circle of Willis Collateral & Ischemic Penumbra Fourier Neural Operator.
============================================================================================
Maps coupled neuro-hemodynamic parameters (MAP, ICP, PaCO2, onset hours, collateral grade,
occlusion topology, and recanalization status) into collateral flow recruitment index,
infarct core volume (mL), core growth rate (mL/hr), and salvageable penumbra volume (mL).
Strictly Educational / Scientific In-Silico Simulation — SaMD Compliant.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class SpectralConv1d(nn.Module):
    """1D Fourier Neural Operator layer with complex frequency weights."""

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
        return torch.einsum("bix,iox->box", input, weights)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        batchsize = x.shape[0]
        x_ft = torch.fft.rfft(x)

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
        x = torch.fft.irfft(out_ft, n=x.size(-1))
        return x


class NeuroFNOPerfusion(nn.Module):
    """
    Inputs (dim 12):
      0: MAP (normalized / 100)
      1: ICP (normalized / 20)
      2: PaCO2 (normalized / 40)
      3: Hours from onset (/ 12)
      4: ACom collateral patency (0.0 or 1.0)
      5: PCom collateral patency (0.0 or 1.0)
      6: Leptomeningeal collateral score (0.0 to 1.0)
      7: Occlusion type (0=None, 1=Left M1, 2=Basilar, 3=ICA Terminus, 4=Moyamoya)
      8: Revascularized (0=TICI 0, 1=TICI 3)
      9: SBP (normalized / 140)
      10: DBP (normalized / 80)
      11: Hematocrit (normalized / 0.45)
    Outputs:
      - Collateral recruitment flow index (%)
      - Ischemic core volume (mL)
      - Core progression rate (mL/hr)
      - Salvageable penumbra volume (mL)
      - TICI recanalization benefit score (0-100)
      - Perfusion status [MCA, ACA, PCA] (0-100%)
    """

    def __init__(self, in_features: int = 12, modes: int = 8, width: int = 48):
        super().__init__()
        self.in_features = in_features
        self.width = width
        self.modes = modes

        # Lift input features to hidden channel dimension
        self.fc_in = nn.Linear(in_features, width * 8)

        # Spectral Fourier layers
        self.conv0 = SpectralConv1d(width, width, modes)
        self.conv1 = SpectralConv1d(width, width, modes)
        self.w0 = nn.Conv1d(width, width, 1)
        self.w1 = nn.Conv1d(width, width, 1)

        # Output projection heads
        self.head_collateral = nn.Sequential(
            nn.Linear(width * 8, 64),
            nn.GELU(),
            nn.Linear(64, 1),
            nn.Sigmoid(),
        )

        self.head_core = nn.Sequential(
            nn.Linear(width * 8, 64),
            nn.GELU(),
            nn.Linear(64, 2),  # [core_volume_ml, core_growth_rate_ml_hr]
            nn.ReLU(),
        )

        self.head_penumbra = nn.Sequential(
            nn.Linear(width * 8, 64),
            nn.GELU(),
            nn.Linear(64, 1),  # [penumbra_volume_ml]
            nn.ReLU(),
        )

        self.head_tici_benefit = nn.Sequential(
            nn.Linear(width * 8, 64),
            nn.GELU(),
            nn.Linear(64, 1),
            nn.Sigmoid(),
        )

        self.head_regional = nn.Sequential(
            nn.Linear(width * 8, 64),
            nn.GELU(),
            nn.Linear(64, 3),  # [mca_perf %, aca_perf %, pca_perf %]
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor):
        # x shape: (B, 12)
        B = x.shape[0]
        h = self.fc_in(x)  # (B, width * 8)
        h_spatial = h.view(B, self.width, 8)  # (B, width, 8)

        # FNO Layer 0
        h1 = self.conv0(h_spatial) + self.w0(h_spatial)
        h1 = F.gelu(h1)

        # FNO Layer 1
        h2 = self.conv1(h1) + self.w1(h1)
        h2 = F.gelu(h2)

        feat = (h2 + h_spatial).view(B, -1)  # (B, width * 8)

        collateral_index = self.head_collateral(feat) * 100.0
        core_preds = self.head_core(feat)
        core_vol = core_preds[:, 0:1]
        core_rate = core_preds[:, 1:2]
        penumbra_vol = self.head_penumbra(feat)
        tici_benefit = self.head_tici_benefit(feat) * 100.0
        regional_perf = self.head_regional(feat) * 100.0

        return {
            "collateral_flow_index": collateral_index,
            "core_volume_ml": core_vol,
            "core_rate_ml_hr": core_rate,
            "penumbra_volume_ml": penumbra_vol,
            "tici_benefit_score": tici_benefit,
            "regional_perfusion": regional_perf,
        }

