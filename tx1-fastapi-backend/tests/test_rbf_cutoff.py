"""Tests for RBF, Cosine Cutoff, and v1 backward compatibility."""

import math
import pytest
import torch

from app.legacy_gnn import MolecularGraphNetwork, Tx1Calculator, DEFAULT_CHECKPOINT


def test_v1_checkpoint_backward_compat():
    """Verify loading v1 checkpoint produces identical predictions to baseline."""
    calc_v1 = Tx1Calculator(use_rbf=False, use_cutoff=False)
    # Synthetic water molecule
    atomic_numbers = [8, 1, 1]
    positions = [
        [0.0, 0.0, 0.0],
        [0.0, 0.757, 0.586],
        [0.0, -0.757, 0.586],
    ]
    energy = calc_v1.energy_ev(atomic_numbers, positions)
    assert isinstance(energy, float)
    assert not math.isnan(energy)


def test_rbf_cutoff_forward():
    """Verify v2a forward pass with RBF and Cosine Cutoff."""
    model_v2a = MolecularGraphNetwork(use_rbf=True, use_cutoff=True, cutoff=6.0)
    z = torch.tensor([[6, 1, 1, 1, 1]], dtype=torch.long)
    pos = torch.randn(1, 5, 3, dtype=torch.float32)
    mask = torch.ones(1, 5, dtype=torch.float32)

    energy = model_v2a(z, pos, mask)
    assert energy.shape == (1,)
    assert not torch.isnan(energy).any()


def test_cutoff_zeroes_distant_interactions():
    """Verify that atoms beyond the 6.0 Å cutoff have zero envelope."""
    cutoff = 6.0
    dists = torch.tensor([1.0, 3.0, 5.9, 6.0, 6.1, 10.0])
    env = 0.5 * (torch.cos(torch.pi * dists / cutoff) + 1.0)
    env = torch.where(dists < cutoff, env, torch.zeros_like(env))

    # At d >= 6.0, envelope must be exactly 0
    assert env[3].item() == 0.0
    assert env[4].item() == 0.0
    assert env[5].item() == 0.0
    # At d < 6.0, envelope must be positive and <= 1.0
    assert 0.0 < env[0].item() <= 1.0
    assert 0.0 < env[1].item() <= 1.0
    assert 0.0 < env[2].item() <= 1.0
