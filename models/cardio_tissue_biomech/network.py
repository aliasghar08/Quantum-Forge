"""CardioTissue-BiomechNet: Residual Biomechanical Surrogate for Coronary Plaque & Myocardial Recovery.

Predicts:
- Calcific plaque fracture threshold (atm) across Standard Balloon, Rotablator, and Shockwave IVL
- Stent expansion index (0.60 to 1.10) & acute recoil (%)
- Post-revascularization LVEF recovery (%)
- 17-segment AHA myocardial longitudinal strain recovery (%)
"""

from __future__ import annotations

import math
from typing import Dict, List, Any

import torch
import torch.nn as nn
import torch.nn.functional as F

BIOMECH_MODALITIES = ["Standard_NC_Balloon", "Rotablator_Atherectomy", "Shockwave_IVL"]

class CardioTissueBiomechNet(nn.Module):
    def __init__(self, in_dim: int = 7, hidden_dim: int = 128):
        super().__init__()
        # Input features: [calcification_arc_deg, calcium_thickness_mm, lesion_length_mm, ref_diam_mm, baseline_lvef, modality_idx, nominal_atm]
        self.in_proj = nn.Linear(in_dim, hidden_dim)

        self.res1 = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
        )
        self.ln1 = nn.LayerNorm(hidden_dim)

        self.res2 = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
        )
        self.ln2 = nn.LayerNorm(hidden_dim)

        # Output heads
        self.fracture_head = nn.Linear(hidden_dim, 1)      # Required ATM or probability of fracture
        self.expansion_head = nn.Linear(hidden_dim, 1)     # Stent expansion index [0.60, 1.10]
        self.recoil_head = nn.Linear(hidden_dim, 1)        # Acute recoil pct [2.0, 25.0]%
        self.lvef_recov_head = nn.Linear(hidden_dim, 1)    # LVEF delta [%]
        self.strain_17_head = nn.Linear(hidden_dim, 17)    # 17 AHA segment strain delta [%]

    def forward(self, x: torch.Tensor) -> Dict[str, torch.Tensor]:
        h = F.silu(self.in_proj(x))
        h = self.ln1(h + F.silu(self.res1(h)))
        h = self.ln2(h + F.silu(self.res2(h)))

        fracture_atm = torch.clamp(10.0 + 20.0 * torch.sigmoid(self.fracture_head(h)), 8.0, 30.0)
        expansion_idx = torch.clamp(0.65 + 0.40 * torch.sigmoid(self.expansion_head(h)), 0.60, 1.10)
        recoil_pct = torch.clamp(2.0 + 20.0 * torch.sigmoid(self.recoil_head(h)), 2.0, 25.0)
        lvef_delta = torch.clamp(1.0 + 12.0 * torch.sigmoid(self.lvef_recov_head(h)), 0.0, 15.0)
        strain_17 = torch.clamp(-1.0 - 5.0 * torch.sigmoid(self.strain_17_head(h)), -7.0, -0.5)

        return {
            "fracture_threshold_atm": fracture_atm,
            "stent_expansion_index": expansion_idx,
            "acute_recoil_pct": recoil_pct,
            "lvef_recovery_delta": lvef_delta,
            "strain_17_segments": strain_17,
        }
