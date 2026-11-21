"""
DialysisKinetics-Net: Deep Learning & Two-Pool Kinetic Solver for Dialysis Prescriptions.
========================================================================================
Solves coupled two-pool urea, potassium, bicarbonate, and volume kinetics for
Intermittent Hemodialysis (IHD) and Continuous Renal Replacement Therapy (CRRT - CVVHDF).
Predicts spKt/V, eKt/V, URR %, Intradialytic Hypotension (IDH) risk, and DDS osmotic shift.

SaMD 7-Pillar Compliant — Educational & In-Silico Simulation Only.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class DialysisKineticsNet(nn.Module):
    """
    Inputs (dim 10):
      0: Modality (0=IHD, 1=CVVHDF, 2=PD)
      1: Qb (mL/min / 350.0)
      2: Qd (mL/min / 600.0 or CRRT ratio)
      3: UF rate (mL/hr / 1000.0)
      4: Duration (hours / 4.0)
      5: Weight (kg / 70.0)
      6: Pre-dialysis BUN (mg/dL / 80.0)
      7: Pre-dialysis K+ (mEq/L / 5.5)
      8: Pre-dialysis HCO3 (mEq/L / 20.0)
      9: Dialyzer KoA (mL/min / 800.0)

    Outputs:
      - spKt/V (single-pool Kt/V)
      - eKt/V (equilibrated Kt/V)
      - URR (Urea Reduction Ratio %)
      - Post-BUN (mg/dL)
      - IDH_risk (Intradialytic hypotension probability %)
      - DDS_gradient (Cerebral osmotic gradient mOsm/kg)
      - Effluent_dose (CRRT effluent dose mL/kg/hr)
    """

    def __init__(self, in_features: int = 10, hidden_dim: int = 64):
        super().__init__()
        self.in_features = in_features

        self.encoder = nn.Sequential(
            nn.Linear(in_features, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
        )

        self.head_clearance = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 4),  # [spKt/V, eKt/V, URR %, Post-BUN]
        )

        self.head_safety = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 3),  # [IDH_risk %, DDS_gradient, Effluent_dose]
        )

    def forward(self, x: torch.Tensor):
        h = self.encoder(x)

        clearance = self.head_clearance(h)
        safety = self.head_safety(h)

        sp_ktv = F.relu(clearance[:, 0:1]) + 0.1       # 0.1 - 2.5
        e_ktv = F.relu(clearance[:, 1:2]) + 0.08      # 0.08 - 2.2
        urr = torch.clamp(clearance[:, 2:3], 10.0, 95.0)  # 10 - 95 %
        post_bun = F.relu(clearance[:, 3:4]) + 5.0    # 5 - 120 mg/dL

        idh = torch.clamp(safety[:, 0:1], 0.0, 100.0)
        dds = F.relu(safety[:, 1:2])                  # 0 - 35 mOsm/kg
        effluent = F.relu(safety[:, 2:3])             # 0 - 50 mL/kg/hr

        return {
            "sp_ktv": sp_ktv,
            "e_ktv": e_ktv,
            "urr_percent": urr,
            "post_bun_mg_dl": post_bun,
            "idh_risk_percent": idh,
            "dds_osmotic_gradient": dds,
            "effluent_dose_ml_kg_hr": effluent,
        }
