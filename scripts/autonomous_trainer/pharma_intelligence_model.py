#!/usr/bin/env python3
"""
PharmaBioNet: Neural Pharmacology & Chemical Mechanism Prediction Model
------------------------------------------------------------------------
Specialized multi-task deep neural network for clinical (MBBS),
pharmaceutical (Pharm-D), and veterinary (DVM) drug intelligence.

Architecture:
- Molecular Structural Feature Encoder (3D Cartesian coordinates + chemical descriptors)
- Multi-Task Predictive Heads:
  1. Mechanism of Action (MoA) Classification Head
  2. Multi-Species Comparative Toxicity & Risk Head [Human, Canine, Feline, Equine, Bovine]
  3. Active-Site Activation Barrier (Ea) Regressor
  4. Curricular Relevance Affinity Head [MBBS, Pharm-D, DVM]
  5. 128-dimensional Latent Semantic Embedding Space for Educational Retrieval
"""

import math
import torch
import torch.nn as nn
import torch.nn.functional as F

MOA_CLASSES = [
    "COX_INHIBITOR",
    "HMG_COA_REDUCTASE_INHIBITOR",
    "ACE_INHIBITOR",
    "INODILATOR_CTNC_SENSITIZER",
    "BETA_LACTAM_TRANSPEPTIDASE_INHIBITOR",
    "FLUOROQUINOLONE_TOPOISOMERASE_INHIBITOR",
    "ANTITUBERCULAR_INHA_INHIBITOR",
    "DOPA_DECARBOXYLASE_SUBSTRATE",
    "ALPHA2_ADRENERGIC_AGONIST",
    "NKCC2_LOOP_DIURETIC",
    "GLUCL_CHLORIDE_CHANNEL_OPENER",
    "DHFR_ANTIFOLATE_INHIBITOR",
    "OTHER_TARGETED_MECHANISM"
]

SPECIES_LIST = ["human", "canine", "feline", "equine", "bovine"]
DISCIPLINE_LIST = ["mbbs", "pharmD", "dvm"]

class MolecularFeatureExtractor(nn.Module):
    """
    Extracts invariant geometric and physical descriptors from 3D XYZ Cartesian
    atomic configurations and constitutional chemical properties.
    """
    def __init__(self, input_dim: int = 32, hidden_dim: int = 128):
        super().__init__()
        self.encoder = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.BatchNorm1d(hidden_dim),
            nn.SiLU(),
            nn.Dropout(0.15),
            nn.Linear(hidden_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.SiLU(),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.encoder(x)

class PharmaBioNet(nn.Module):
    """
    Multi-task Neural Pharmacology and Educational Reasoning Model.
    """
    def __init__(
        self,
        input_dim: int = 32,
        hidden_dim: int = 128,
        embedding_dim: int = 128,
        num_moa_classes: int = len(MOA_CLASSES),
        num_species: int = len(SPECIES_LIST),
        num_disciplines: int = len(DISCIPLINE_LIST),
    ):
        super().__init__()
        self.feature_extractor = MolecularFeatureExtractor(input_dim, hidden_dim)
        
        # Latent Semantic Embedding Projection
        self.embedding_proj = nn.Sequential(
            nn.Linear(hidden_dim, embedding_dim),
            nn.LayerNorm(embedding_dim)
        )

        # 1. Mechanism of Action (MoA) Classification Head
        self.moa_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Dropout(0.1),
            nn.Linear(64, num_moa_classes)
        )

        # 2. Multi-Species Toxicity & Safety Head (multi-label sigmoid)
        # Output: Probability of high species-specific toxicity / contraindication
        self.species_toxicity_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Dropout(0.1),
            nn.Linear(64, num_species)
        )

        # 3. Transition State Activation Barrier (Ea in kcal/mol) Regressor
        self.ea_regressor = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.SiLU(),
            nn.Linear(32, 1)
        )

        # 4. Target Discipline Affinity Head (MBBS, Pharm-D, DVM)
        self.discipline_head = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.SiLU(),
            nn.Linear(32, num_disciplines)
        )

    def forward(self, x: torch.Tensor):
        feats = self.feature_extractor(x)
        
        embeddings = F.normalize(self.embedding_proj(feats), p=2, dim=1)
        moa_logits = self.moa_head(feats)
        species_logits = self.species_toxicity_head(feats)
        pred_ea = self.ea_regressor(feats).squeeze(-1)
        discipline_logits = self.discipline_head(feats)

        return {
            "embeddings": embeddings,
            "moa_logits": moa_logits,
            "species_toxicity_logits": species_logits,
            "pred_ea": pred_ea,
            "discipline_logits": discipline_logits
        }

    def predict_profile(self, features: torch.Tensor) -> dict:
        """Runs evaluation inference and formats human-readable clinical predictions."""
        self.eval()
        with torch.no_grad():
            out = self.forward(features)
            
            moa_idx = torch.argmax(out["moa_logits"], dim=1).item()
            moa_prob = F.softmax(out["moa_logits"], dim=1)[0, moa_idx].item()
            moa_name = MOA_CLASSES[moa_idx]

            species_probs = torch.sigmoid(out["species_toxicity_logits"])[0].tolist()
            species_risks = {
                species: round(prob, 4)
                for species, prob in zip(SPECIES_LIST, species_probs)
            }

            discipline_probs = torch.sigmoid(out["discipline_logits"])[0].tolist()
            discipline_affinities = {
                disc: round(prob, 4)
                for disc, prob in zip(DISCIPLINE_LIST, discipline_probs)
            }

            return {
                "predicted_moa": moa_name,
                "moa_confidence": round(moa_prob, 4),
                "species_toxicity_risks": species_risks,
                "predicted_activation_barrier_kcal_mol": round(out["pred_ea"].item(), 2),
                "discipline_affinities": discipline_affinities,
                "latent_embedding": out["embeddings"][0].tolist()
            }
