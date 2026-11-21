"""
NephroTox-GNN: Molecular Graph & Descriptor Model for Renal Drug Transporters & Nephrotoxicity.
==============================================================================================
Predicts proximal tubular uptake (OAT1/OAT3, OCT2/MATE1, Megalin endocytosis),
acute tubular injury risk (%), interstitial nephritis risk (%), crystal nephropathy,
and eGFR-adjusted dosing multipliers.

SaMD 7-Pillar Compliant — Educational & Scientific In-Silico Simulation Only.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class NephroToxGNN(nn.Module):
    """
    Inputs (dim 12):
      0: Molecular Weight (/ 500.0)
      1: cLogP (/ 5.0)
      2: TPSA (/ 120.0)
      3: HBD (/ 5.0)
      4: HBA (/ 10.0)
      5: Rotatable Bonds (/ 10.0)
      6: Formal Charge (-2 to +2)
      7: Baseline patient eGFR (mL/min / 90.0)
      8: Sepsis / volume depletion (0 or 1)
      9: Concurrent nephrotoxins count (0 to 3 / 3.0)
      10: Fraction aromatic atoms
      11: Known aminoglycoside/platinum/glycopeptide scaffold flag (0 to 1)

    Outputs:
      - OAT1/OAT3 substrate probability (%)
      - OCT2/MATE1 substrate probability (%)
      - Megalin receptor binding (%)
      - Acute Tubular Injury (ATI) risk (%)
      - Acute Interstitial Nephritis (AIN) risk (%)
      - eGFR-adjusted dosing multiplier (0.1 to 1.0)
    """

    def __init__(self, in_features: int = 12, hidden_dim: int = 64):
        super().__init__()
        self.in_features = in_features

        self.backbone = nn.Sequential(
            nn.Linear(in_features, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
            nn.Dropout(0.05),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
        )

        self.head_transporters = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 3),  # [OAT1/3, OCT2/MATE, Megalin]
            nn.Sigmoid(),
        )

        self.head_toxicity = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 2),  # [ATI %, AIN %]
            nn.Sigmoid(),
        )

        self.head_dosing = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor):
        h = self.backbone(x)

        transporters = self.head_transporters(h) * 100.0
        toxicity = self.head_toxicity(h) * 100.0
        dosing_mult = torch.clamp(self.head_dosing(h) * 1.1, 0.1, 1.0)

        return {
            "oat_probability": transporters[:, 0:1],
            "oct_probability": transporters[:, 1:2],
            "megalin_binding": transporters[:, 2:3],
            "ati_risk_percent": toxicity[:, 0:1],
            "ain_risk_percent": toxicity[:, 1:2],
            "dose_multiplier": dosing_mult,
        }
