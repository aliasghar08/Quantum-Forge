"""Tests for Ensemble inference and uncertainty scaling."""

import math
import pytest
import torch

from app.ensemble import EnsemblePredictor
from app.painn import PaiNNLite


def test_ensemble_mock_prediction(tmp_path):
    # Create 3 small mock checkpoints
    ckpts = []
    for i in range(3):
        m = PaiNNLite(hidden_dim=32, num_layers=2, num_rbf=16)
        p = tmp_path / f"member_{i}.pt"
        torch.save({
            "model_state_dict": m.state_dict(),
            "hyperparameters": {"hidden_dim": 32, "num_layers": 2, "num_rbf": 16},
        }, str(p))
        ckpts.append(p)

    ens = EnsemblePredictor(checkpoint_paths=ckpts, architecture="painn")
    ens.temperature = 1.2

    z = [6, 1, 1, 1, 1]
    pos = [
        [0.0, 0.0, 0.0],
        [0.6, 0.6, 0.6],
        [-0.6, -0.6, 0.6],
        [-0.6, 0.6, -0.6],
        [0.6, -0.6, -0.6],
    ]

    mean_ev, uncert_kcal = ens.predict_with_uncertainty(z, pos)
    assert isinstance(mean_ev, float)
    assert isinstance(uncert_kcal, float)
    assert uncert_kcal >= 0.0
    assert ens.name() == "tx1-v2"

    # Test vectorized batch prediction
    molecules = [
        {"atomic_numbers": z, "positions": pos},
        {"atomic_numbers": [8, 1, 1], "positions": [[0.0, 0.0, 0.0], [0.8, 0.6, 0.0], [-0.8, 0.6, 0.0]]},
    ]
    batch_res = ens.predict_batch_with_uncertainty(molecules)
    assert len(batch_res) == 2
    for b_mean, b_uncert in batch_res:
        assert isinstance(b_mean, float)
        assert isinstance(b_uncert, float)
        assert b_uncert >= 0.0
    assert math.isclose(batch_res[0][0], mean_ev, rel_tol=1e-4)
