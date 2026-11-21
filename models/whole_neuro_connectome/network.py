"""
WholeNeuro-Connectome: Deep Neural Network for Whole-Nervous-System Lesion Localization.
========================================================================================
Maps multi-system clinical deficit vectors across Motor (UMN/LMN), Sensory, Cranial Nerves,
Visual Fields, Autonomic Reflexes, and Dermatomes/Myotomes to 10 anatomical neuro-axes:
Cortical, Internal Capsule, Brainstem, Spinal Cord, Anterior Horn, Roots, Plexuses,
Named Peripheral Nerves, Neuromuscular Junction (NMJ), and Autonomic Ganglia.

SaMD 7-Pillar Compliant — Educational & Scientific In-Silico Simulation Only.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F

ANATOMICAL_LOCATIONS = [
    "Cerebral Cortex (Hemispheric)",
    "Subcortical Internal Capsule / Basal Ganglia",
    "Brainstem (Midbrain / Pons / Medulla)",
    "Spinal Cord (Cervical / Thoracic / Conus)",
    "Anterior Horn Cells (Motor Neuron)",
    "Spinal Nerve Roots (Radiculopathy)",
    "Brachial / Lumbosacral Plexus",
    "Named Peripheral Nerve (Mononeuropathy)",
    "Neuromuscular Junction (NMJ)",
    "Autonomic Ganglia & Sympathetic Chain",
]


class WholeNeuroConnectome(nn.Module):
    def __init__(self, in_features: int = 16, hidden_dim: int = 128, num_classes: int = 10):
        super().__init__()
        self.fc1 = nn.Linear(in_features, hidden_dim)
        self.ln1 = nn.LayerNorm(hidden_dim)
        self.fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.ln2 = nn.LayerNorm(hidden_dim)
        self.fc3 = nn.Linear(hidden_dim, hidden_dim // 2)
        self.ln3 = nn.LayerNorm(hidden_dim // 2)

        # Localization logits
        self.classifier = nn.Linear(hidden_dim // 2, num_classes)

        # Auxiliary heads: Severity Score (0-100), Suggested Diagnostic Test Index
        self.severity_head = nn.Linear(hidden_dim // 2, 1)
        self.diagnostic_head = nn.Linear(hidden_dim // 2, 5)  # 0=Brain MRI, 1=Spine MRI, 2=NCS/EMG, 3=AChR-Ab/Tensilon, 4=Autonomic Tilt

    def forward(self, x: torch.Tensor):
        h = F.gelu(self.ln1(self.fc1(x)))
        res = h
        h = F.gelu(self.ln2(self.fc2(h))) + res
        h = F.gelu(self.ln3(self.fc3(h)))

        logits = self.classifier(h)
        probs = F.softmax(logits, dim=-1)
        severity = torch.sigmoid(self.severity_head(h)) * 100.0
        diagnostic_probs = F.softmax(self.diagnostic_head(h), dim=-1)

        return {
            "logits": logits,
            "probabilities": probs,
            "severity_score": severity,
            "diagnostic_probs": diagnostic_probs,
        }
