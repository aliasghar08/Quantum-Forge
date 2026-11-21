#!/usr/bin/env python3
"""Generate a tiny fake transition1x.db with the real schema.

Purpose: validate the pipeline end-to-end without downloading 20GB.
"""
import json
import os
import random
import numpy as np
from ase import Atoms
from ase.db import connect


def make_fake_reaction(rxn_id, n_frames=10):
    """One reaction with a Gaussian energy bump at midpoint."""
    n_atoms = random.randint(5, 12)
    numbers = [random.choice([1, 6, 7, 8]) for _ in range(n_atoms)]

    reactant_pos = np.random.randn(n_atoms, 3) * 2.0
    product_pos = reactant_pos + np.random.randn(n_atoms, 3) * 0.5

    frames = []
    for i in range(n_frames):
        t = i / (n_frames - 1)
        # Energy: low at ends, high at midpoint
        e = -30.0 + 8.0 * np.sin(np.pi * t) + np.random.randn() * 0.05
        pos = (1 - t) * reactant_pos + t * product_pos
        pos = pos + np.random.randn(*pos.shape) * 0.05
        forces = np.random.randn(*pos.shape) * 0.1
        frames.append((numbers, pos, e, forces))
    return frames


def main():
    os.makedirs("data/raw", exist_ok=True)
    db_path = "data/raw/transition1x_synthetic.db"
    if os.path.exists(db_path):
        os.remove(db_path)

    db = connect(db_path)
    n_reactions = 50
    n_frames_per = 10

    for i in range(n_reactions):
        rxn_id = f"synthetic_rxn_{i:04d}"
        for numbers, pos, energy, forces in make_fake_reaction(rxn_id, n_frames_per):
            atoms = Atoms(numbers=numbers, positions=pos)
            db.write(
                atoms,
                data={"energy": float(energy), "forces": forces},
                key_value_pairs={"rxn_id": rxn_id},
            )

    total = db.count()
    print(f"Wrote {total} rows to {db_path}")

    # Generate matching index files
    all_ids = list(range(total))
    random.seed(42)
    random.shuffle(all_ids)

    n_train = int(0.7 * total)
    n_val = int(0.1 * total)

    train_idx = all_ids[:n_train]
    val_idx = all_ids[n_train:n_train + n_val]
    test_idx = all_ids[n_train + n_val:]

    for name, ids in [("train_idx", train_idx), ("val_idx", val_idx), ("test_idx", test_idx)]:
        with open(f"data/raw/{name}.json", "w") as f:
            json.dump(ids, f)
        print(f"  {name}: {len(ids)} ids")


if __name__ == "__main__":
    main()
