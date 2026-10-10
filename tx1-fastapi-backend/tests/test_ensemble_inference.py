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
