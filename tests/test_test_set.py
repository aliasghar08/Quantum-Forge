#!/usr/bin/env python3
"""Verify eval/test.jsonl properties and integrity."""
import io
import json
import os
import numpy as np
from ase.io import read

def test_test_set():
    test_path = "eval/test.jsonl"
    assert os.path.exists(test_path), f"Missing {test_path}"

    with open(test_path) as f:
        entries = [json.loads(line) for line in f if line.strip()]

    assert len(entries) > 0, "test.jsonl is empty"
    print(f"Verifying {len(entries)} test set entries...")

    ts_positions = []
    barriers = []

    for i, e in enumerate(entries):
        assert "reaction_id" in e and len(e["reaction_id"]) > 0
        assert "reactant_xyz" in e and "product_xyz" in e
        assert "reference_barrier_kcal_mol" in e

        barrier = e["reference_barrier_kcal_mol"]
        assert barrier > 0, f"Non-positive barrier in {e['reaction_id']}"
        barriers.append(barrier)

        r = read(io.StringIO(e["reactant_xyz"]), format="xyz")
        p = read(io.StringIO(e["product_xyz"]), format="xyz")

        assert len(r) == len(p), f"Atom count mismatch in {e['reaction_id']}: {len(r)} vs {len(p)}"
        assert np.array_equal(r.get_atomic_numbers(), p.get_atomic_numbers()), \
            f"Atomic species mismatch in {e['reaction_id']}"

        if "ts_position" in e:
            pos = e["ts_position"]
            assert 0.0 <= pos <= 1.0, f"Invalid ts_position {pos} in {e['reaction_id']}"
            ts_positions.append(pos)

    # Check for split overlap if split files exist
    if os.path.exists("data/splits/train_idx.json") and os.path.exists("data/splits/test_rxn_ids.json"):
        with open("data/splits/test_rxn_ids.json") as f:
            test_rxns = set(json.load(f))
        for e in entries:
            assert e["reaction_id"] in test_rxns, f"Reaction {e['reaction_id']} not in test split"

    if ts_positions:
        mean_ts = float(np.mean(ts_positions))
        print(f"TS position mean: {mean_ts:.3f} (min={min(ts_positions):.3f}, max={max(ts_positions):.3f})")

    mean_barrier = float(np.mean(barriers))
    print(f"Barrier mean: {mean_barrier:.2f} kcal/mol (min={min(barriers):.2f}, max={max(barriers):.2f})")
    print("test_test_set: PASS")

if __name__ == "__main__":
    test_test_set()
