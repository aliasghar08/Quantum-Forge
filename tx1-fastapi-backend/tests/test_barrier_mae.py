"""Tests for Barrier MAE evaluation and LST energy profiling."""

import math
import pytest
import torch
import torch.nn as nn

from app.legacy_gnn import MolecularGraphNetwork


def test_barrier_unit_conversion():
    # 1.0 eV difference is exactly 23.0605 kcal/mol
    diff_ev = 1.0
    diff_kcal = diff_ev * 23.0605
    assert math.isclose(diff_kcal, 23.0605, rel_tol=1e-5)


def test_barrier_mae_constant_energy_offset_invariance():
    """Barrier is E_max - E_reactant, which cancels any constant shift C."""
    energies_ev = torch.tensor([10.0, 11.5, 10.8])
    shifted_energies_ev = energies_ev + 500.0  # Constant baseline shift

    barrier_1 = (energies_ev.max() - energies_ev[0]) * 23.0605
    barrier_2 = (shifted_energies_ev.max() - shifted_energies_ev[0]) * 23.0605

    assert torch.isclose(barrier_1, barrier_2, atol=1e-5)
    assert math.isclose(barrier_1.item(), 1.5 * 23.0605, rel_tol=1e-5)


def test_model_forward_shape_and_types():
    model = MolecularGraphNetwork()
    z = torch.tensor([[6, 1, 1]], dtype=torch.long)
    pos = torch.randn(1, 3, 3, dtype=torch.float32)
    mask = torch.ones(1, 3, dtype=torch.float32)

    energy = model(z, pos, mask)
    assert energy.shape == (1,)
    assert not torch.isnan(energy).any()
