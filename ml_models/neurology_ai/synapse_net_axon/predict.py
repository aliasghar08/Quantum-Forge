"""
Inference runner for SynapseNet-Axon.
=====================================
"""

from pathlib import Path
import torch
from network import SynapseNetAxon


class SynapseNetPredictor:
    def __init__(self, checkpoint_path: str = None):
        if checkpoint_path is None:
            checkpoint_path = str(Path(__file__).parent / "checkpoints" / "synapse_net_axon.pt")

        self.device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
        self.model = SynapseNetAxon(in_features=8, hidden_dim=64, out_features=7).to(self.device)

        ckpt = torch.load(checkpoint_path, map_location=self.device)
        self.model.load_state_dict(ckpt["model_state_dict"])
        self.model.eval()

    def predict(
        self,
        myelin_integrity: float = 1.0,
        nav_conductance: float = 1.0,
        cav_conductance: float = 1.0,
        snare_competence: float = 1.0,
        ache_activity: float = 1.0,
        nachr_density: float = 1.0,
        nmb_blocker_level: float = 0.0,
        reversal_agent: float = 0.0,
    ):
        inp = [
            float(myelin_integrity),
            float(nav_conductance),
            float(cav_conductance),
            float(snare_competence),
            float(ache_activity),
            float(nachr_density),
            float(nmb_blocker_level),
            float(reversal_agent),
        ]
        x = torch.tensor([inp], dtype=torch.float32).to(self.device)

        with torch.no_grad():
            out = self.model(x)[0].cpu().numpy()

        cv = float(out[0])
        safety_factor = float(out[1])
        quanta = float(out[2])
        cleft_ach = float(out[3])
        epp = float(out[4])
        ap_success = float(out[5]) > 0.5
        rns_dec = float(out[6])

        # Interpretation
        if myelin_integrity < 0.4:
            pattern = "Demyelinating Conduction Slowing / Block (MS / GBS)"
        elif nachr_density < 0.4:
            pattern = "Myasthenia Gravis (Post-synaptic nAChR blockade with RNS decrement)"
        elif cav_conductance < 0.4:
            pattern = "Lambert-Eaton Myasthenic Syndrome (Pre-synaptic P/Q Ca_v block)"
        elif snare_competence < 0.2:
            pattern = "Botulinum Toxin Flaccid Paralysis (SNARE cleavage)"
        elif nmb_blocker_level > 0.4 and reversal_agent == 0.0:
            pattern = "Neuromuscular Blockade (Non-depolarizing Paralytic)"
        elif nmb_blocker_level > 0.4 and reversal_agent == 1.0:
            pattern = "Reversed Neuromuscular Blockade (Sugammadex / Neostigmine)"
        else:
            pattern = "Physiologically Normal Saltatory Conduction & NMJ Transmission"

        return {
            "conduction_velocity_m_s": round(cv, 1),
            "saltatory_safety_factor": round(safety_factor, 2),
            "vesicle_quantal_release": round(quanta, 1),
            "cleft_transmitter_peak_um": round(cleft_ach, 1),
            "epp_amplitude_mv": round(epp, 1),
            "action_potential_success": ap_success,
            "rns_decrement_percent": round(rns_dec, 1),
            "diagnostic_pattern": pattern,
        }
