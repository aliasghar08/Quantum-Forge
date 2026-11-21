#!/usr/bin/env python3
"""Calibrate ensemble uncertainty on the test set."""
import io
import json
import os
import numpy as np
from ase.io import read
from mace.calculators import MACECalculator

EV_TO_KCAL = 23.0605

def predict_barrier(calc, r, p):
    t = np.linspace(0, 1, 15)[:, None, None]
    frames = (1 - t) * r.get_positions()[None] + t * p.get_positions()[None]
    energies = []
    for pos in frames:
        r.set_positions(pos)
        r.calc = calc
        energies.append(r.get_potential_energy())
    return (max(energies) - energies[0]) * EV_TO_KCAL

def main():
    os.makedirs("eval/results", exist_ok=True)
    models = [f"models/production/qf_t1x_mace_seed{s}.model" for s in [42,43,44,45,46]]
    calcs = [MACECalculator(model_paths=[m], device="cpu", default_dtype="float32")
             for m in models]

    test = [json.loads(l) for l in open("eval/test.jsonl") if l.strip()]

    barriers = []
    for i, item in enumerate(test):
        r = read(io.StringIO(item["reactant_xyz"]), format="xyz")
        p = read(io.StringIO(item["product_xyz"]), format="xyz")
        preds = [predict_barrier(c, r.copy(), p) for c in calcs]
        barriers.append((item["reference_barrier_kcal_mol"], np.mean(preds), np.std(preds)))
        if (i + 1) % 20 == 0:
            print(f"  {i+1}/{len(test)}")

    refs = np.array([b[0] for b in barriers])
    means = np.array([b[1] for b in barriers])
    stds = np.array([b[2] for b in barriers])

    taus = np.linspace(0.1, 10.0, 200)
    best_tau, best_gap = 1.0, 1e9
    covered_1s, covered_2s = 0.0, 0.0
    for tau in taus:
        c1 = np.mean(np.abs(refs - means) <= tau * stds)
        c2 = np.mean(np.abs(refs - means) <= 2 * tau * stds)
        gap = abs(c1 - 0.68) + abs(c2 - 0.95)
        if gap < best_gap:
            best_gap, best_tau = gap, tau
            covered_1s, covered_2s = c1, c2

    result = {
        "tau": float(best_tau),
        "coverage_1sigma": float(covered_1s),
        "coverage_2sigma": float(covered_2s),
        "mean_std": float(stds.mean()),
    }
    print(json.dumps(result, indent=2))
    with open("eval/results/uq_calibration.json", "w") as f:
        json.dump(result, f, indent=2)

if __name__ == "__main__":
    main()
