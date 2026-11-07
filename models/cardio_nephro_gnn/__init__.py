"""Cardiology & Nephrology Drug Affinity and Cardiotoxicity GNN.

A standalone, independent PyTorch Graph Neural Network pipeline running on
Apple Silicon Metal Performance Shaders (MPS) for predicting:
1. Target binding affinity (pIC50) across key cardio-renal targets (hERG, ACE, AGTR1, ADRB1, SGLT2).
2. hERG-mediated cardiotoxicity / QT-prolongation risk.
"""

from .network import CardioNephroGNN, MolecularFeaturizer
from .predict import predict_compound

__all__ = ["CardioNephroGNN", "MolecularFeaturizer", "predict_compound"]

