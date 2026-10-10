import json

def test_eval():
    with open("eval/test.jsonl") as f:
        entries = [json.loads(l) for l in f if l.strip()]
    assert len(entries) > 0
    for e in entries:
        assert e["reference_barrier_kcal_mol"] > 0
        assert "reactant_xyz" in e
        assert "product_xyz" in e
    print(f"Eval: PASS ({len(entries)} entries)")

if __name__ == "__main__":
    test_eval()
