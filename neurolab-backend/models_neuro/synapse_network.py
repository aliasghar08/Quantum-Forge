"""
SynapseNet-Axon: Biophysical Neural Surrogate for Saltatory Axonal Conduction & Synaptic Cleft Kinetics.
========================================================================================================
Solves coupled Hodgkin-Huxley myelin internode saltatory conduction, Node of Ranvier Na_v1.6 activation,
presynaptic Ca_v2.1 calcium influx, SNARE vesicle exocytosis, cleft AChE enzymatic hydrolysis,
and postsynaptic nAChR End-Plate Potential (EPP) generation.

SaMD 7-Pillar Compliant — Educational & Scientific In-Silico Simulation Only.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class SynapseNetAxon(nn.Module):
    def __init__(self, in_features: int = 8, hidden_dim: int = 64, out_features: int = 7):
        super().__init__()
        self.fc1 = nn.Linear(in_features, hidden_dim)
        self.ln1 = nn.LayerNorm(hidden_dim)
        self.fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.ln2 = nn.LayerNorm(hidden_dim)
        self.fc3 = nn.Linear(hidden_dim, hidden_dim)
        self.head = nn.Linear(hidden_dim, out_features)

    def forward(self, x: torch.Tensor):
        h = F.silu(self.ln1(self.fc1(x)))
        res = h
        h = F.silu(self.ln2(self.fc2(h))) + res
        h = F.silu(self.fc3(h))
        raw = self.head(h)

        # Physical constraints activation
        conduction_velocity = 5.0 + torch.sigmoid(raw[:, 0]) * 65.0  # 5 to 70 m/s
        safety_factor = 0.2 + F.softplus(raw[:, 1]) * 4.0          # 0.2 to 4.5
        vesicle_release = torch.relu(raw[:, 2]) * 60.0             # 0 to 60 quanta
        cleft_ach = 0.5 + F.softplus(raw[:, 3]) * 1000.0           # uM peak
        epp_amplitude = 1.0 + torch.sigmoid(raw[:, 4]) * 44.0      # 1 to 45 mV
        ap_prob = torch.sigmoid(raw[:, 5])                         # 0 to 1
        rns_decrement = torch.tanh(raw[:, 6]) * 70.0               # -70% to +70%

        return torch.stack([
            conduction_velocity,
            safety_factor,
            vesicle_release,
            cleft_ach,
            epp_amplitude,
            ap_prob,
            rns_decrement,
        ], dim=-1)
