"""
NephroPINN-Glomerular: Physics-Informed Neural Network for Glomerular Hemodynamics.
==================================================================================
Coupled Starling glomerular microcirculation, myogenic autoregulation,
tubuloglomerular feedback (TGF), and renin-angiotensin-aldosterone system (RAAS).

Starling Equation:
    SNGFR = K_f * [(P_GC - P_BS) - (pi_GC - pi_BS)]
    eGFR = SNGFR * N_nephrons
    RPF = (MAP - RVP) / (R_A + R_E + R_V)
    FF = GFR / RPF

SaMD 7-Pillar Compliant — Educational & Scientific In-Silico Simulation Only.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class NephroPINNGlomerular(nn.Module):
    """
    Inputs (dim 8):
      0: MAP (mmHg / 100.0)
      1: Afferent resistance tone Ra (0.5 to 2.5)
      2: Efferent resistance tone Re (0.5 to 2.5)
      3: Glomerular ultrafiltration coefficient Kf (mL/min/mmHg / 4.0)
      4: Plasma oncotic pressure pi_plasma (mmHg / 25.0)
      5: Bowman's space hydraulic pressure P_bs (mmHg / 15.0)
      6: Hematocrit Hct (fraction / 0.45)
      7: Condition index (0=Normal, 1=Diabetic Hyperfiltration, 2=CRS-1, 3=Triple Whammy, 4=Bilateral RAS, 5=ATN)

    Outputs:
      - P_gc (Glomerular capillary hydraulic pressure, mmHg)
      - Net Filtration Pressure NFP (mmHg)
      - SNGFR (Single-nephron GFR, nL/min)
      - eGFR (Whole-kidney GFR, mL/min/1.73m^2)
      - RBF (Renal blood flow, mL/min)
      - RPF (Renal plasma flow, mL/min)
      - Filtration Fraction FF (%)
      - Urine Output Flow rate (mL/hr)
      - FENa (Fractional Excretion of Sodium, %)
    """

    def __init__(self, in_features: int = 8, hidden_dim: int = 64):
        super().__init__()
        self.in_features = in_features

        self.encoder = nn.Sequential(
            nn.Linear(in_features, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
        )

        self.head_pressures = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.SiLU(),
            nn.Linear(32, 2),  # [P_gc, NFP]
        )

        self.head_flows = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.SiLU(),
            nn.Linear(32, 4),  # [SNGFR, eGFR, RBF, RPF]
        )

        self.head_kinetics = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.SiLU(),
            nn.Linear(32, 3),  # [FF %, UrineOutput mL/hr, FENa %]
        )

    def forward(self, x: torch.Tensor):
        h = self.encoder(x)

        pressures = self.head_pressures(h)
        flows = self.head_flows(h)
        kinetics = self.head_kinetics(h)

        p_gc = F.relu(pressures[:, 0:1]) + 20.0     # 20 - 80 mmHg
        nfp = F.relu(pressures[:, 1:2]) + 1.0       # 1 - 35 mmHg
        sngfr = F.relu(flows[:, 0:1]) + 2.0         # 2 - 80 nL/min
        egfr = F.relu(flows[:, 1:2]) + 1.0          # 1 - 160 mL/min
        rbf = F.relu(flows[:, 2:3]) + 50.0          # 50 - 1500 mL/min
        rpf = F.relu(flows[:, 3:4]) + 25.0          # 25 - 800 mL/min

        ff = torch.clamp(kinetics[:, 0:1], 2.0, 45.0)       # 2 - 45 %
        uo = F.relu(kinetics[:, 1:2])                       # 0 - 300 mL/hr
        fena = F.relu(kinetics[:, 2:3])                     # 0.1 - 10 %

        return {
            "p_gc": p_gc,
            "nfp": nfp,
            "sngfr": sngfr,
            "egfr": egfr,
            "rbf": rbf,
            "rpf": rpf,
            "ff": ff,
            "urine_output": uo,
            "fena": fena,
        }
