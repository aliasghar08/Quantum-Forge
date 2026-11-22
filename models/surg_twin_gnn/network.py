"""SurgTwin-GNN: Heterogeneous Graph Neural Network for Pre-Surgical Cardiac Digital Twins.

Models native coronary arteries, stenoses, calcific arcs, myocardial territories,
and surgical bypass conduits (LIMA-LAD, RIMA, SVG, Radial) and prosthetic valves (TAVR, SAVR).

Predicts:
- Territorial myocardial perfusion reserve [0.0, 1.0]
- Competitive graft flow risk [0.0, 1.0]
- 12-Month patency rate [0.0, 1.0]
- 30-Day MACE risk [0.0, 1.0]
- TAVR Valve-to-Coronary (VTC) clearance distance (mm) [0.0, 15.0]
"""

from __future__ import annotations

import math
from typing import Dict, List, Any

import torch
import torch.nn as nn
import torch.nn.functional as F

SURG_ARTERY_NODES = ["Aorta", "LM", "LAD", "D1", "LCx", "OM1", "RCA", "PDA"]
SURG_STRATEGIES = ["CABG", "Hybrid", "IVUS_PCI", "TAVR_SAVR", "OMT"]

class SurgTwinGNN(nn.Module):
    def __init__(self, node_in_dim: int = 8, hidden_dim: int = 64, num_rounds: int = 3):
        super().__init__()
        self.node_in_dim = node_in_dim
        self.hidden_dim = hidden_dim
        self.num_rounds = num_rounds

        self.node_embed = nn.Linear(node_in_dim, hidden_dim)
        self.strategy_embed = nn.Embedding(len(SURG_STRATEGIES), hidden_dim)

        # Message Passing Layer: aggregate upstream & bypass neighbors
        self.msg_net = nn.Sequential(
            nn.Linear(hidden_dim * 2, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
        )
        self.update_gru = nn.GRUCell(hidden_dim, hidden_dim)

        # Output prediction heads
        self.perfusion_head = nn.Linear(hidden_dim, 1)
        self.competitive_flow_head = nn.Linear(hidden_dim, 1)
        self.patency_head = nn.Linear(hidden_dim, 1)
        self.mace_head = nn.Linear(hidden_dim, 1)
        self.vtc_head = nn.Linear(hidden_dim, 1)
        self.uncertainty_head = nn.Linear(hidden_dim, 1)

    def forward(
        self,
        node_feats: torch.Tensor,       # [B, N_nodes, 8]
        adj_matrix: torch.Tensor,       # [B, N_nodes, N_nodes]
        strategy_idx: torch.Tensor,     # [B]
    ) -> Dict[str, torch.Tensor]:
        B, N, _ = node_feats.shape
        h = self.node_embed(node_feats)  # [B, N, H]
        s_emb = self.strategy_embed(strategy_idx).unsqueeze(1).expand(-1, N, -1)
        h = h + s_emb

        # Message passing rounds
        for _ in range(self.num_rounds):
            # Aggregation: sum neighbor features weighted by adj
            # Expand for pairwise message computation
            h_i = h.unsqueeze(2).expand(-1, -1, N, -1)
            h_j = h.unsqueeze(1).expand(-1, N, -1, -1)
            msgs = self.msg_net(torch.cat([h_i, h_j], dim=-1))  # [B, N, N, H]
            adj_w = adj_matrix.unsqueeze(-1)  # [B, N, N, 1]
            agg_msgs = (msgs * adj_w).sum(dim=2)  # [B, N, H]

            # Flatten for GRUCell
            h_flat = h.reshape(B * N, self.hidden_dim)
            agg_flat = agg_msgs.reshape(B * N, self.hidden_dim)
            h_updated = self.update_gru(agg_flat, h_flat)
            h = h_updated.reshape(B, N, self.hidden_dim)

        # Graph-level pooling (mean across nodes)
        g_repr = h.mean(dim=1)  # [B, H]

        perfusion = torch.clamp(torch.sigmoid(self.perfusion_head(g_repr)), 0.05, 0.99)
        competitive_flow = torch.clamp(torch.sigmoid(self.competitive_flow_head(g_repr)), 0.01, 0.95)
        patency = torch.clamp(torch.sigmoid(self.patency_head(g_repr)), 0.40, 0.98)
        mace_risk = torch.clamp(torch.sigmoid(self.mace_head(g_repr)), 0.01, 0.45)
        vtc_dist = torch.clamp(15.0 * torch.sigmoid(self.vtc_head(g_repr)), 0.5, 15.0)
        uncertainty = torch.clamp(0.20 * torch.sigmoid(self.uncertainty_head(g_repr)), 0.01, 0.20)

        return {
            "perfusion_reserve": perfusion,
            "competitive_flow_risk": competitive_flow,
            "patency_12mo": patency,
            "mace_30day": mace_risk,
            "vtc_distance_mm": vtc_dist,
            "uncertainty_sigma": uncertainty,
        }
