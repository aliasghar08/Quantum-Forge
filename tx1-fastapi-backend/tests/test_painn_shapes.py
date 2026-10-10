"""Tests for PaiNN-lite tensor shapes and 3D rotational invariance."""

import pytest
import torch

from app.painn import PaiNNLite


def random_rotation_matrix():
    """Generates a random 3D rotation matrix SO(3)."""
    q, _ = torch.linalg.qr(torch.randn(3, 3))
    if torch.linalg.det(q) < 0:
        q[:, 0] = -q[:, 0]
    return q


def test_painn_forward_shapes():
    model = PaiNNLite(hidden_dim=64, num_layers=3, num_rbf=32)
    B, N = 2, 8
    z = torch.randint(1, 10, (B, N), dtype=torch.long)
    pos = torch.randn(B, N, 3, dtype=torch.float32)
    mask = torch.ones(B, N, dtype=torch.float32)

    energy = model(z, pos, mask)
    assert energy.shape == (B,)
    assert not torch.isnan(energy).any()


def test_painn_rotation_invariance():
    """Energy predicted by PaiNN must be invariant under arbitrary 3D spatial rotation."""
    model = PaiNNLite(hidden_dim=64, num_layers=3, num_rbf=32)
    model.eval()

    z = torch.tensor([[6, 8, 1, 1]], dtype=torch.long)
    pos = torch.tensor([
        [
            [0.0, 0.0, 0.0],
            [1.2, 0.0, 0.0],
            [-0.5, 0.9, 0.0],
            [-0.5, -0.9, 0.0],
        ]
    ], dtype=torch.float32)
    mask = torch.ones(1, 4, dtype=torch.float32)

    with torch.no_grad():
        e_orig = model(z, pos, mask)

    # Apply 5 random 3D rotations
    for _ in range(5):
        R = random_rotation_matrix()
        rotated_pos = pos @ R.T
        with torch.no_grad():
            e_rot = model(z, rotated_pos, mask)

        diff = (e_orig - e_rot).abs().item()
        assert diff < 1e-4, f"PaiNN energy not rotationally invariant: diff={diff}"
