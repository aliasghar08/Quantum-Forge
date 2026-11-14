"""
Inference API for NeuroSpike-Net.
=================================
"""

from pathlib import Path
import torch
from network import NeuroSpikeNet

CKPT_PATH = Path(__file__).parent / "checkpoints" / "neuro_spike_net.pt"

_cached_model = None


def load_model():
    global _cached_model
    if _cached_model is not None:
        return _cached_model

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = NeuroSpikeNet().to(device)
    if CKPT_PATH.exists():
        ckpt = torch.load(CKPT_PATH, map_location=device, weights_only=False)
        model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    _cached_model = (model, device)
    return _cached_model


def predict_spectral_and_asm(
    state_index: int = 2,  # 0=alpha, 1=delta, 2=status epilepticus, 3=burst suppression
    lorazepam_level: float = 0.0,
    levetiracetam_level: float = 0.0,
    phenytoin_level: float = 0.0,
    valproate_level: float = 0.0,
    propofol_level: float = 0.0,
    core_temp_c: float = 37.0,
    paco2_mm_hg: float = 40.0,
    map_mm_hg: float = 110.0,
    icp_mm_hg: float = 14.0,
):
    model, device = load_model()

    inp = torch.tensor(
        [[
            float(state_index),
            lorazepam_level,
            levetiracetam_level,
            phenytoin_level,
            valproate_level,
            propofol_level,
            core_temp_c / 37.0,
            paco2_mm_hg / 40.0,
            map_mm_hg / 100.0,
            icp_mm_hg / 20.0,
        ]],
        dtype=torch.float32,
        device=device,
    )

    with torch.no_grad():
        out = model(inp)

    spec = out["spectral_powers"][0].cpu().numpy().tolist()

    return {
        "delta_power_percent": float(round(spec[0], 1)),
        "theta_power_percent": float(round(spec[1], 1)),
        "alpha_power_percent": float(round(spec[2], 1)),
        "beta_power_percent": float(round(spec[3], 1)),
        "alpha_delta_ratio": float(round(out["alpha_delta_ratio"].item(), 2)),
        "burst_suppression_ratio": float(round(out["burst_suppression_ratio"].item(), 1)),
        "spike_wave_index": float(round(out["spike_wave_index"].item(), 1)),
        "seizure_termination_probability": float(round(out["seizure_termination_prob"].item(), 1)),
    }


if __name__ == "__main__":
    res = predict_spectral_and_asm(state_index=2, lorazepam_level=1.0, levetiracetam_level=1.0)
    print("NeuroSpike-Net Output:", res)

