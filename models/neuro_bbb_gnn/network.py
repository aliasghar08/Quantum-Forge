"""
NeuroBBB-GNN: Blood-Brain Barrier Permeation & CNS Neurotoxicity Neural Graph Model.
===================================================================================
Predicts logBB (brain/plasma partition coefficient), CNS MPO (Multi-Parameter Optimization),
P-gp efflux liability, and seizure/neurotoxicity risk from chemical structure and descriptors.
Strictly Educational / Scientific In-Silico Simulation — SaMD Compliant.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class NeuroBBBGNN(nn.Module):
    """
    Inputs (dim 12):
      0: Molecular Weight (/ 500.0)
      1: cLogP (/ 5.0)
      2: Topological Polar Surface Area TPSA (/ 120.0)
      3: Hydrogen Bond Donors HBD (/ 5.0)
      4: Hydrogen Bond Acceptors HBA (/ 10.0)
      5: Rotatable Bonds (/ 10.0)
      6: Aromatic Rings (/ 5.0)
      7: Formal Charge
      8: Fraction sp3 Carbons (Fsp3)
      9: Acidic pKa feature (normalized)
      10: Basic pKa feature (normalized)
      11: Lipophilic efficiency index
    Outputs:
      - logBB (continuous, typically -2.5 to +1.2)
      - CNS MPO score (0.0 to 6.0)
      - P-gp efflux probability (0.0 to 1.0)
      - Seizure / Central Neurotoxicity liability (0.0 to 100.0%)
      - High CNS penetration class probability (logBB > -0.1)
    """

    def __init__(self, in_features: int = 12, hidden_dim: int = 64):
        super().__init__()
        self.in_features = in_features

        self.backbone = nn.Sequential(
            nn.Linear(in_features, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
            nn.Dropout(0.1),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
        )

        self.head_logbb = nn.Linear(hidden_dim, 1)

        self.head_cns_mpo = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.Sigmoid(),  # multiplied by 6.0
        )

        self.head_pgp = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.Sigmoid(),
        )

        self.head_neurotoxicity = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor):
        h = self.backbone(x)
        logbb = self.head_logbb(h)
        cns_mpo = self.head_cns_mpo(h) * 6.0
        pgp = self.head_pgp(h)
        neurotox = self.head_neurotoxicity(h) * 100.0
        cns_penetrant_prob = torch.sigmoid((logbb + 0.1) * 2.5)

        return {
            "logbb": logbb,
            "cns_mpo": cns_mpo,
            "pgp_efflux_prob": pgp,
            "neurotoxicity_liability": neurotox,
            "cns_penetrant_prob": cns_penetrant_prob,
        }
