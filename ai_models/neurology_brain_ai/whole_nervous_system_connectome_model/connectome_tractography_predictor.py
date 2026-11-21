"""
Inference runner for WholeNeuro-Connectome.
==========================================
"""

from pathlib import Path
import torch
from network import WholeNeuroConnectome, ANATOMICAL_LOCATIONS

DIAGNOSTIC_TESTS = [
    "Brain MRI with Diffusion (DWI/FLAIR)",
    "Spine MRI (Cervical / Thoracic / Lumbar)",
    "Nerve Conduction Studies & Electromyography (NCS/EMG)",
    "AChR Antibodies / Repetitive Nerve Stimulation / Tensilon",
    "Autonomic Tilt Table & Sudomotor Axon Reflex (QSART)",
]


class WholeNeuroPredictor:
    def __init__(self, checkpoint_path: str = None):
        if checkpoint_path is None:
            checkpoint_path = str(Path(__file__).parent / "checkpoints" / "whole_neuro_connectome.pt")

        self.device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
        self.model = WholeNeuroConnectome(in_features=16, hidden_dim=128, num_classes=10).to(self.device)

        ckpt = torch.load(checkpoint_path, map_location=self.device)
        self.model.load_state_dict(ckpt["model_state_dict"])
        self.model.eval()

    def predict(self, deficit_vector: list[float]):
        x = torch.tensor([deficit_vector], dtype=torch.float32).to(self.device)
        with torch.no_grad():
            res = self.model(x)
            probs = res["probabilities"][0].cpu().numpy()
            top_idx = int(probs.argmax())
            diag_probs = res["diagnostic_probs"][0].cpu().numpy()
            top_diag = DIAGNOSTIC_TESTS[int(diag_probs.argmax())]
            severity = float(res["severity_score"][0].cpu().item())

        location_rankings = [
            {"location": ANATOMICAL_LOCATIONS[i], "probability": float(probs[i])}
            for i in range(len(ANATOMICAL_LOCATIONS))
        ]
        location_rankings.sort(key=lambda item: item["probability"], reverse=True)

        return {
            "top_location": ANATOMICAL_LOCATIONS[top_idx],
            "confidence_percent": round(float(probs[top_idx]) * 100.0, 1),
            "severity_score": round(severity, 1),
            "recommended_investigation": top_diag,
            "all_rankings": location_rankings,
        }
