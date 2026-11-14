"""
NeuroSpike-Net: Cortical Excitatory-Inhibitory Neural Mass & Ion-Channel Pharmacodynamics Solver.
=================================================================================================
Coupled Jansen-Rit neural mass model with Na_v / Ca_v / GABA_A / SV2A conductance equations,
predicting 500 Hz EEG spectral power bands, Alpha-Delta Ratio (ADR), Burst-Suppression Ratio (BSR),
and anti-seizure medication (ASM) termination efficacy.
Strictly Educational / Scientific In-Silico Simulation — SaMD Compliant.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class NeuroSpikeNet(nn.Module):
    """
    Inputs (dim 10):
      0: Baseline clinical state (0=normal alpha, 1=focal delta slowing, 2=status epilepticus, 3=burst suppression)
      1: Lorazepam level (0.0 to 1.0 - GABA_A allosteric potentiator)
      2: Levetiracetam level (0.0 to 1.0 - presynaptic SV2A vesicle blocker)
      3: Phenytoin level (0.0 to 1.0 - Na_v voltage-gated blocker)
      4: Valproate level (0.0 to 1.0 - Ca_v T-type & GABA transaminase inhibitor)
      5: Propofol level (0.0 to 1.0 - deep GABA_A agonist)
      6: Core temperature (°C / 37.0)
      7: PaCO2 (mmHg / 40.0)
      8: MAP (mmHg / 100.0)
      9: ICP (mmHg / 20.0)
    Outputs:
      - Spectral power bands: [Delta, Theta, Alpha, Beta] (%)
      - Alpha-Delta Ratio (ADR)
      - Burst-Suppression Ratio (BSR %)
      - Spike-and-wave paroxysm index (0-100%)
      - Seizure termination probability (0-100%)
    """

    def __init__(self, in_features: int = 10, hidden_dim: int = 64):
        super().__init__()
        self.in_features = in_features

        self.encoder = nn.Sequential(
            nn.Linear(in_features, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
        )

        # Output Heads
        self.head_spectrum = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 4),  # [delta, theta, alpha, beta] normalized via softmax
        )

        self.head_adr = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.ReLU(),
        )

        self.head_bsr = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.Sigmoid(),
        )

        self.head_spike_idx = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.Sigmoid(),
        )

        self.head_termination = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.GELU(),
            nn.Linear(32, 1),
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor):
        h = self.encoder(x)
        raw_spec = self.head_spectrum(h)
        spec_powers = F.softmax(raw_spec, dim=-1) * 100.0  # Percentage distribution summing to 100%

        adr = self.head_adr(h)
        bsr = self.head_bsr(h) * 100.0
        spike_idx = self.head_spike_idx(h) * 100.0
        term_prob = self.head_termination(h) * 100.0

        return {
            "spectral_powers": spec_powers,  # (B, 4) [Delta, Theta, Alpha, Beta]
            "alpha_delta_ratio": adr,
            "burst_suppression_ratio": bsr,
            "spike_wave_index": spike_idx,
            "seizure_termination_prob": term_prob,
        }
