#!/usr/bin/env python3
"""Evaluate barrier MAE on the 200-reaction test set."""
import io
import json
import os
import numpy as np
from ase.io import read
from mace.calculators import MACECalculator
import torch

EV_TO_KCAL = 23.0605

def generate_lst_frames(reactant_pos, product_pos, n_frames=15):
    t = np.linspace(0, 1, n_frames)[:, None, None]
    return (1 - t) * reactant_pos[None] + t * product_pos[None]

def main():
    os.makedirs("eval/results", exist_ok=True)
    device = "mps" if torch.backends.mps.is_available() else "cpu"
    calc = MACECalculator(
        model_paths=["models/production/qf_t1x_mace.model"],
        device=device,
        default_dtype="float32",
    )

    test = [json.loads(l) for l in open("eval/test.jsonl") if l.strip()]
    print(f"Test reactions: {len(test)}")

    errors = []
    for i, item in enumerate(test):
        ref = item["reference_barrier_kcal_mol"]
        r = read(io.StringIO(item["reactant_xyz"]), format="xyz")
        p = read(io.StringIO(item["product_xyz"]), format="xyz")

        frames_pos = generate_lst_frames(r.get_positions(), p.get_positions(), 15)
        energies = []
        for pos in frames_pos:
            r.set_positions(pos)
            r.calc = calc
            energies.append(r.get_potential_energy())

        barrier = (max(energies) - energies[0]) * EV_TO_KCAL
        err = abs(barrier - ref)
        errors.append(err)
        if (i + 1) % 20 == 0:
            print(f"  {i+1}/{len(test)} MAE so far: {np.mean(errors):.4f}")

    mae = np.mean(errors)
    max_err = np.max(errors)
    print(f"\nBarrier MAE: {mae:.4f} kcal/mol")
    print(f"Max error:   {max_err:.4f} kcal/mol")

    result = {
        "n_test": len(test),
        "barrier_mae_kcal": float(mae),
        "max_error_kcal": float(max_err),
        "per_reaction": [
            {"reaction_id": t["reaction_id"], "error": float(e)}
            for t, e in zip(test, errors)
        ],
    }
    with open("eval/results/barrier_mae.json", "w") as f:
        json.dump(result, f, indent=2)
    print("Saved eval/results/barrier_mae.json")

if __name__ == "__main__":
    main()
