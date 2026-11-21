#!/usr/bin/env python3
"""Reaction-grouped stratified split + tripwires."""
import json
import os
import random
from collections import defaultdict
from ase.db import connect
import numpy as np

def main():
    os.makedirs("data/splits", exist_ok=True)
    db = connect("data/curated/t1x_hcno_stride50.db")
    # Check if DB has populated reaction IDs
    has_rxn_ids = False
    for row in db.select(limit=10):
        if row.key_value_pairs.get("rxn_id"):
            has_rxn_ids = True
            break

    if has_rxn_ids:
        by_rxn = defaultdict(list)
        for row in db.select():
            rxn = row.key_value_pairs.get("rxn_id") or f"unknown_{row.id}"
            by_rxn[rxn].append(row.id)

        rxns = sorted(by_rxn.keys())
        print(f"Total reactions: {len(rxns)}")
        random.seed(42)
        random.shuffle(rxns)

        n = len(rxns)
        n_train = int(0.85 * n)
        n_val = int(0.05 * n)
        train_rxns = rxns[:n_train]
        val_rxns = rxns[n_train:n_train + n_val]
        test_rxns = rxns[n_train + n_val:]

        assert not (set(train_rxns) & set(val_rxns))
        assert not (set(train_rxns) & set(test_rxns))
        assert not (set(val_rxns) & set(test_rxns))

        def ids_for(rxn_list):
            return [i for r in rxn_list for i in by_rxn[r]]

        splits = {
            "train_idx": ids_for(train_rxns),
            "val_idx": ids_for(val_rxns),
            "test_rxn_ids": test_rxns,
        }
    else:
        # Map curated rows to official Figshare split boundaries:
        # Train: original 0..9091787 | Test: 9091788..9375103 | Val: 9375104..9644739
        # Stride = 50: original_id = row.id * 50
        print("Using official Figshare split boundaries for stride=50 curation")
        train_ids = []
        val_ids = []
        test_ids = []
        for row in db.select():
            orig_id = row.id * 50
            if orig_id < 9091788:
                train_ids.append(row.id)
            elif orig_id < 9375104:
                test_ids.append(row.id)
            else:
                val_ids.append(row.id)

        splits = {
            "train_idx": train_ids,
            "val_idx": val_ids,
            "test_rxn_ids": test_ids,
        }

    for k, v in splits.items():
        with open(f"data/splits/{k}.json", "w") as f:
            json.dump(v, f)
        print(f"{k}: {len(v)}")

    sample = [db.get(id=i) for i in splits["train_idx"][:100]]
    energies = [r.data["REF_energy"] for r in sample]
    print(f"train energy mean={np.mean(energies):.4f} std={np.std(energies):.4f}")
    assert np.std(energies) > 0.1, "Energy variance too low"
    print("PASS")

if __name__ == "__main__":
    main()
