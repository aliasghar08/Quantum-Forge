import json

def test_splits():
    with open("data/splits/train_idx.json") as f:
        train = set(json.load(f))
    with open("data/splits/val_idx.json") as f:
        val = set(json.load(f))
    with open("data/splits/test_rxn_ids.json") as f:
        test = set(json.load(f))
    assert len(train & val) == 0
    assert len(train) > 0
    assert len(val) > 0
    assert len(test) > 0
    print(f"Splits: PASS (train={len(train)}, val={len(val)}, test_rxns={len(test)})")

if __name__ == "__main__":
    test_splits()
