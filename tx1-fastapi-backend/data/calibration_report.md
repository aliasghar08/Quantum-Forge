# Uncertainty Quantification Calibration Report

## Executive Summary
- **Ensemble Members**: 5
- **Evaluation Dataset**: test.jsonl (200 reactions)
- **Optimal Calibration Temperature (τ)**: **4.93**

## Empirical Coverage Table

| Confidence Interval | Theoretical Gaussian | Raw Coverage (τ=1.0) | Calibrated Coverage (τ=4.93) | Target Status |
|---|---|---|---|---|
| **±1σ** | 68.3% | 30.5% | **69.5%** | ✔ PASS (63–73%) |
| **±2σ** | 95.5% | 44.5% | **91.5%** | ✔ PASS (90–100%) |
| **±3σ** | 99.7% | 49.5% | **98.0%** | ✔ PASS |

## Ensemble Checkpoints & Digests
- **Member 0**: `member_0.pt` (`sha256:ea5159b44ab191c17afcd1e5e906ee66503ba0984da80681d4439fa90032430c`)
- **Member 1**: `member_1.pt` (`sha256:d119e55544b79c614063fdeb17a1380c2d35038e849ce214bd1bf172576e08c7`)
- **Member 2**: `member_2.pt` (`sha256:d81120e610c05bf125aafe72f58bbe4f7b04cc0e45179f131a025adf418e2ae4`)
- **Member 3**: `member_3.pt` (`sha256:88fd16794a8fcf1d2eff99dd46dc526af023595bc797970134293e5ac7eee14b`)
- **Member 4**: `member_4.pt` (`sha256:608d83c2ec09dfea68161b9486e7ed541b7d370076b6b5c85661271979b8e0bf`)
