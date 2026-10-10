#!/usr/bin/env python3
"""Build eval/test.jsonl from held-out reactions using two-pass streaming.

Pass 1: Stream metadata only (row.id, energy, rxn_id) to compute barriers
        and select up to 200 reactions. Never load Atoms into memory in Pass 1.
Pass 2: Fetch only the reactant and product atoms for the selected reactions.
"""
import io
import json
import os
import random
from collections import defaultdict
from ase.db import connect
from ase.io import write
import numpy as np

EV_TO_KCAL = 23.0605

def atoms_to_xyz_string(atoms):
    buf = io.StringIO()
    write(buf, atoms, format="xyz")
    return buf.getvalue()

def main():
    os.makedirs("eval", exist_ok=True)

    with open("data/splits/test_rxn_ids.json") as f:
        test_rxns = set(json.load(f))

    print(f"Building test set from {len(test_rxns)} held-out reactions")
    db_path = "data/raw/transition1x.db"
    if not os.path.exists(db_path):
        db_path = "data/raw/transition1x_synthetic.db"
    db = connect(db_path)

    # Pass 1: Stream energy and frame metadata only (No Atoms in RAM)
    grouped_frames = defaultdict(list)
    for row in db.select():
        rxn = row.key_value_pairs.get("rxn_id", "")
        if rxn not in test_rxns:
            continue
        data = row.data if hasattr(row, "data") else {}
        energy = data.get("energy", data.get("REF_energy"))
        if energy is None:
            continue
        grouped_frames[rxn].append((row.id, float(energy)))

    candidates = []
    for rxn_id, frames in grouped_frames.items():
        if len(frames) < 2:
            continue
        e_reactant = frames[0][1]
        e_product = frames[-1][1]
        energies = [f[1] for f in frames]
        max_idx = int(np.argmax(energies))
        e_ts = energies[max_idx]

        barrier = (e_ts - e_reactant) * EV_TO_KCAL
        if barrier < 1.0:
            continue

        ts_pos = float(max_idx / (len(frames) - 1)) if len(frames) > 1 else 0.5
        candidates.append({
            "reaction_id": rxn_id,
            "reactant_id": frames[0][0],
            "product_id": frames[-1][0],
            "reference_barrier_kcal_mol": float(barrier),
            "ts_position": ts_pos,
            "n_frames": len(frames),
        })

    print(f"Found {len(candidates)} candidate test reactions")
    assert len(candidates) > 0, "Zero candidate test reactions found"

    # Select up to 200
    if len(candidates) > 200:
        random.seed(42)
        candidates = random.sample(candidates, 200)

    # Pass 2: Fetch only reactant and product atoms for chosen reactions
    test_entries = []
    for c in candidates:
        r_atoms = db.get(id=c["reactant_id"]).toatoms()
        p_atoms = db.get(id=c["product_id"]).toatoms()
        test_entries.append({
            "reaction_id": c["reaction_id"],
            "reactant_xyz": atoms_to_xyz_string(r_atoms),
            "product_xyz": atoms_to_xyz_string(p_atoms),
            "reference_barrier_kcal_mol": c["reference_barrier_kcal_mol"],
            "ts_position": c["ts_position"],
            "source": "transition1x",
        })

    out_file = "eval/test.jsonl"
    with open(out_file, "w") as f:
        for entry in test_entries:
            f.write(json.dumps(entry) + "\n")

    print(f"Wrote {len(test_entries)} test entries to {out_file}")
    ts_positions = [e["ts_position"] for e in test_entries]
    print(f"Mean TS position: {np.mean(ts_positions):.3f}")
    assert len(test_entries) > 0
    print("PASS")

if __name__ == "__main__":
    main()
