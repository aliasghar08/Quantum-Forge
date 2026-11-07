"""Standalone Graph Neural Network for Cardio-Nephro Drug Targets.

Implements CardioNephroGNN with:
1. Atom & Bond Featurization from SMILES via RDKit.
2. Multi-Layer Gated Message Passing with Bond Attention.
3. Global Attention Readout (graph-level representation).
4. Multi-Task Heads predicting:
   - herg_pIC50 (continuous affinity)
   - ace_pIC50 (continuous affinity)
   - agtr1_pIC50 (continuous affinity)
   - adrb1_pIC50 (continuous affinity)
   - sglt2_pIC50 (continuous affinity)
   - herg_cardiotoxic_logit (binary classification risk)

100% compatible with Apple Silicon Metal GPU (torch.device("mps")).
Uses pure PyTorch dense/batch operations to avoid sparse scatter kernel issues on Metal.
"""

from __future__ import annotations

import math
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from rdkit import Chem

# Target names list
TARGET_NAMES = ["herg", "ace", "agtr1", "adrb1", "sglt2"]

# Feature Dimensions
ATOM_DIM = 32
BOND_DIM = 10


class MolecularFeaturizer:
    """Converts chemical SMILES into graph tensor representations."""

    ALLOWED_ATOMS = [
        "H", "B", "C", "N", "O", "F", "Si", "P", "S", "Cl", "Br", "I", "Other"
    ]
    HYBRIDIZATIONS = [
        Chem.rdchem.HybridizationType.SP,
        Chem.rdchem.HybridizationType.SP2,
        Chem.rdchem.HybridizationType.SP3,
        Chem.rdchem.HybridizationType.SP3D,
        Chem.rdchem.HybridizationType.SP3D2,
    ]

    @classmethod
    def get_atom_features(cls, atom: Chem.Atom) -> List[float]:
        symbol = atom.GetSymbol()
        sym_one_hot = [1.0 if symbol == s else 0.0 for s in cls.ALLOWED_ATOMS[:-1]]
        if sum(sym_one_hot) == 0.0:
            sym_one_hot.append(1.0)  # Other
        else:
            sym_one_hot.append(0.0)

        degree = atom.GetTotalDegree()
        deg_one_hot = [1.0 if degree == d else 0.0 for d in range(6)]

        formal_charge = atom.GetFormalCharge()
        charge_one_hot = [1.0 if formal_charge == c else 0.0 for c in [-2, -1, 0, 1, 2]]

        hyb = atom.GetHybridization()
        hyb_one_hot = [1.0 if hyb == h else 0.0 for h in cls.HYBRIDIZATIONS]

        is_aromatic = 1.0 if atom.GetIsAromatic() else 0.0
        is_in_ring = 1.0 if atom.IsInRing() else 0.0
        num_h = float(atom.GetTotalNumHs())

        features = (
            sym_one_hot
            + deg_one_hot
            + charge_one_hot
            + hyb_one_hot
            + [is_aromatic, is_in_ring, num_h]
        )
        return features

    @classmethod
    def get_bond_features(cls, bond: Chem.Bond) -> List[float]:
        b_type = bond.GetBondType()
        type_one_hot = [
            1.0 if b_type == Chem.rdchem.BondType.SINGLE else 0.0,
            1.0 if b_type == Chem.rdchem.BondType.DOUBLE else 0.0,
            1.0 if b_type == Chem.rdchem.BondType.TRIPLE else 0.0,
            1.0 if b_type == Chem.rdchem.BondType.AROMATIC else 0.0,
        ]
        is_conjugated = 1.0 if bond.GetIsConjugated() else 0.0
        is_in_ring = 1.0 if bond.IsInRing() else 0.0

        stereo = bond.GetStereo()
        stereo_one_hot = [
            1.0 if stereo == Chem.rdchem.BondStereo.STEREONONE else 0.0,
            1.0 if stereo == Chem.rdchem.BondStereo.STEREOANY else 0.0,
            1.0 if stereo == Chem.rdchem.BondStereo.STEREOZ else 0.0,
            1.0 if stereo == Chem.rdchem.BondStereo.STEREOE else 0.0,
        ]

        return type_one_hot + [is_conjugated, is_in_ring] + stereo_one_hot

    @classmethod
    def smiles_to_graph(cls, smiles: str) -> Optional[Dict[str, torch.Tensor]]:
        """Parse SMILES into node features, dense adjacency, and bond feature tensors."""
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            return None

        num_atoms = mol.GetNumAtoms()
        if num_atoms == 0:
            return None

        atom_feats = [cls.get_atom_features(atom) for atom in mol.GetAtoms()]
        node_features = torch.tensor(atom_feats, dtype=torch.float32)

        # Build dense adjacency matrix (N, N) and edge attribute tensor (N, N, F_e)
        adj_matrix = torch.eye(num_atoms, dtype=torch.float32)  # Self loops
        edge_features = torch.zeros((num_atoms, num_atoms, BOND_DIM), dtype=torch.float32)

        for bond in mol.GetBonds():
            u = bond.GetBeginAtomIdx()
            v = bond.GetEndAtomIdx()
            b_feat = torch.tensor(cls.get_bond_features(bond), dtype=torch.float32)

            adj_matrix[u, v] = 1.0
            adj_matrix[v, u] = 1.0
            edge_features[u, v] = b_feat
            edge_features[v, u] = b_feat

        return {
            "node_features": node_features,
            "adj_matrix": adj_matrix,
            "edge_features": edge_features,
            "num_atoms": num_atoms,
        }


class GatedMessagePassingLayer(nn.Module):
    """MPS-optimized graph message passing layer with edge gating."""

    def __init__(self, hidden_dim: int, dropout: float = 0.1):
        super().__init__()
        self.hidden_dim = hidden_dim

        # Message formulation from sender node and bond
        self.message_linear = nn.Linear(hidden_dim * 2, hidden_dim)
        self.attention_linear = nn.Linear(hidden_dim * 2, 1)

        # Node update
        self.update_linear = nn.Linear(hidden_dim * 2, hidden_dim)
        self.norm = nn.LayerNorm(hidden_dim)
        self.dropout = nn.Dropout(dropout)

    def forward(
        self,
        h: torch.Tensor,            # (N, hidden_dim)
        adj: torch.Tensor,          # (N, N)
        edge_attr: torch.Tensor,    # (N, N, hidden_dim)
    ) -> torch.Tensor:
        num_atoms = h.shape[0]

        # Broadcast node pairs (N, N, hidden_dim)
        h_send = h.unsqueeze(0).expand(num_atoms, -1, -1)  # j (senders)
        h_recv = h.unsqueeze(1).expand(-1, num_atoms, -1)  # i (receivers)

        # Message m_ij = GELU(W_m [h_j || e_ij])
        msg_in = torch.cat([h_send, edge_attr], dim=-1)
        m_ij = F.gelu(self.message_linear(msg_in))

        # Attention coefficient alpha_ij = Softmax_j(W_a [h_i || m_ij])
        att_in = torch.cat([h_recv, m_ij], dim=-1)
        att_logits = self.attention_linear(att_in).squeeze(-1)  # (N, N)

        # Mask non-adjacent entries
        mask = (adj == 0.0)
        att_logits = att_logits.masked_fill(mask, -1e9)
        alpha = F.softmax(att_logits, dim=-1).unsqueeze(-1)  # (N, N, 1)
        alpha = torch.nan_to_num(alpha, nan=0.0)

        # Aggregate messages a_i = sum_j alpha_ij * m_ij
        aggregated = torch.sum(alpha * m_ij, dim=1)  # (N, hidden_dim)

        # Node update with residual connection
        updated = F.gelu(self.update_linear(torch.cat([h, aggregated], dim=-1)))
        h_next = self.norm(h + self.dropout(updated))
        return h_next


class CardioNephroGNN(nn.Module):
    """Multi-task Graph Neural Network for Cardio-Renal Affinity & Cardiotoxicity."""

    def __init__(
        self,
        atom_dim: int = ATOM_DIM,
        bond_dim: int = BOND_DIM,
        hidden_dim: int = 128,
        num_layers: int = 4,
        dropout: float = 0.1,
    ):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.num_layers = num_layers

        # Node and bond encoders
        self.atom_encoder = nn.Sequential(
            nn.Linear(atom_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
        )
        self.bond_encoder = nn.Sequential(
            nn.Linear(bond_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
        )

        # Stacked message passing layers
        self.layers = nn.ModuleList([
            GatedMessagePassingLayer(hidden_dim, dropout)
            for _ in range(num_layers)
        ])

        # Global gated attention readout
        self.gate_net = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, 1),
        )
        self.readout_linear = nn.Linear(hidden_dim, hidden_dim)
        self.readout_norm = nn.LayerNorm(hidden_dim)

        # Multi-Target Affinity Heads (Regression: pIC50)
        self.affinity_heads = nn.ModuleDict({
            target: nn.Sequential(
                nn.Linear(hidden_dim, hidden_dim // 2),
                nn.GELU(),
                nn.Dropout(dropout),
                nn.Linear(hidden_dim // 2, 1),
            )
            for target in TARGET_NAMES
        })

        # hERG Cardiotoxicity Risk Head (Binary Classification Logits)
        self.herg_toxicity_head = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim // 2),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(hidden_dim // 2, 1),
        )

    def forward(
        self,
        node_features: torch.Tensor,  # (N, atom_dim)
        adj_matrix: torch.Tensor,     # (N, N)
        edge_features: torch.Tensor,  # (N, N, bond_dim)
    ) -> Dict[str, torch.Tensor]:
        # Encode initial node and edge embeddings
        h = self.atom_encoder(node_features)
        e = self.bond_encoder(edge_features)

        # Message passing layers
        for layer in self.layers:
            h = layer(h, adj_matrix, e)

        # Global Attention Pooling
        gate_weights = F.softmax(self.gate_net(h), dim=0)  # (N, 1)
        h_mol = torch.sum(gate_weights * self.readout_linear(h), dim=0, keepdim=True)  # (1, hidden_dim)
        h_mol = self.readout_norm(h_mol)

        # Compute output predictions
        predictions: Dict[str, torch.Tensor] = {}
        for target in TARGET_NAMES:
            predictions[f"{target}_pIC50"] = self.affinity_heads[target](h_mol).squeeze(-1)

        # Cardiotoxicity classification logit
        predictions["herg_cardiotoxic_logit"] = self.herg_toxicity_head(h_mol).squeeze(-1)
        return predictions


def collate_single_molecule(data: Dict[str, torch.Tensor], device: torch.device) -> Dict[str, torch.Tensor]:
    """Transfer single molecule graph tensors to training device (MPS / CPU)."""
    return {
        "node_features": data["node_features"].to(device),
        "adj_matrix": data["adj_matrix"].to(device),
        "edge_features": data["edge_features"].to(device),
    }
