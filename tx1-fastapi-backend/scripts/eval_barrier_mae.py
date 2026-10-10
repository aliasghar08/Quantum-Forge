#!/usr/bin/env python3
"""Evaluate barrier and reaction energy MAE on a held-out test dataset."""

from __future__ import annotations

import argparse
import json
import math
import sys
import time
from collections import defaultdict
from pathlib import Path

import torch

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.legacy_gnn import MolecularGraphNetwork


def parse_xyz(xyz_str: str) -> tuple[list[str], list[list[float]]]:
    lines = [line.strip() for line in xyz_str.strip().split("\n") if line.strip()]
    if len(lines) < 3:
        return [], []
    try:
        num_atoms = int(lines[0])
    except ValueError:
        return [], []
    atoms = []
    positions = []
    for line in lines[2 : 2 + num_atoms]:
        parts = line.split()
        if len(parts) < 4:
            continue
        atoms.append(parts[0])
        try:
            positions.append([float(parts[1]), float(parts[2]), float(parts[3])])
        except ValueError:
            return [], []
    return atoms, positions


def element_to_z(symbol: str) -> int:
    mapping = {
        "H": 1, "He": 2, "Li": 3, "Be": 4, "B": 5, "C": 6, "N": 7, "O": 8,
        "F": 9, "Ne": 10, "Na": 11, "Mg": 12, "Al": 13, "Si": 14, "P": 15,
        "S": 16, "Cl": 17, "Ar": 18, "K": 19, "Ca": 20, "Br": 35, "I": 53,
    }
    return mapping.get(symbol.strip().capitalize(), 6)


def generate_lst_frames(
    r_pos: list[list[float]], p_pos: list[list[float]], n_frames: int = 15
) -> list[list[list[float]]]:
    frames = []
    for i in range(n_frames):
        t = i / (n_frames - 1)
        alpha = 0.5 * (1.0 - math.cos(math.pi * t))
        cur_pos = [
            [
                rp[0] * (1.0 - alpha) + pp[0] * alpha,
                rp[1] * (1.0 - alpha) + pp[1] * alpha,
                rp[2] * (1.0 - alpha) + pp[2] * alpha,
            ]
            for rp, pp in zip(r_pos, p_pos)
        ]
        frames.append(cur_pos)
    return frames


def load_model(checkpoint_path: Path, architecture: str, device: torch.device):
    if architecture == "legacy":
        model = MolecularGraphNetwork()
    elif architecture == "rbf_cutoff":
        model = MolecularGraphNetwork(use_rbf=True, use_cutoff=True)
    elif architecture == "painn":
        from app.painn import PaiNNLite
        model = PaiNNLite()
    else:
        raise ValueError(f"Unknown architecture: {architecture}")

    ckpt = torch.load(str(checkpoint_path), map_location="cpu", weights_only=False)
    state = ckpt.get("model_state_dict", ckpt) if isinstance(ckpt, dict) else ckpt

    # Handle embedding size mismatch if necessary
    if hasattr(model, "embedding") and "embedding.weight" in state:
        old = state["embedding.weight"]
        if old.shape[0] < model.embedding.weight.shape[0]:
            new = torch.zeros_like(model.embedding.weight)
            new[: old.shape[0]] = old
            state["embedding.weight"] = new

    model.load_state_dict(state, strict=False)
    model.to(device)
    model.eval()
    return model


def evaluate(
    model,
    data_path: Path,
    device: torch.device,
    n_frames: int = 15,
    max_samples: int | None = None,
):
    with open(data_path, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    if max_samples:
        lines = lines[:max_samples]

    barrier_errors = []
    reaction_energy_errors = []
    results_per_reaction = []
    source_barrier_errors = defaultdict(list)

    EV_TO_KCAL = 23.0605

    t0 = time.time()
    for line in lines:
        item = json.loads(line)
        rx_id = item["reaction_id"]
        rx_xyz = item["reactant_xyz"]
        px_xyz = item["product_xyz"]
        ref_barrier = float(item["reference_barrier_kcal_mol"])
        ref_dE = float(item.get("reference_reaction_energy_kcal_mol", 0.0))
        source = item.get("source", "transition1x")

        r_atoms, r_pos = parse_xyz(rx_xyz)
        p_atoms, p_pos = parse_xyz(px_xyz)

        if not r_atoms or not p_atoms:
            continue

        z_list = [element_to_z(a) for a in r_atoms]
        z_tensor = torch.tensor([z_list], dtype=torch.long, device=device)
        mask_tensor = torch.ones(1, len(z_list), dtype=torch.float32, device=device)

        frames = generate_lst_frames(r_pos, p_pos, n_frames=n_frames)

        # Batch forward pass for all frames
        batch_z = z_tensor.repeat(n_frames, 1)
        batch_mask = mask_tensor.repeat(n_frames, 1)
        batch_pos = torch.tensor(frames, dtype=torch.float32, device=device)

        with torch.no_grad():
            energies_ev = model(batch_z, batch_pos, batch_mask).cpu().tolist()

        # Barrier = (max(E) - E[0]) * 23.0605
        pred_barrier = (max(energies_ev) - energies_ev[0]) * EV_TO_KCAL
        pred_dE = (energies_ev[-1] - energies_ev[0]) * EV_TO_KCAL

        b_err = abs(pred_barrier - ref_barrier)
        dE_err = abs(pred_dE - ref_dE)

        barrier_errors.append(b_err)
        reaction_energy_errors.append(dE_err)
        source_barrier_errors[source].append(b_err)

        results_per_reaction.append({
            "reaction_id": rx_id,
            "source": source,
            "ref_barrier_kcal": ref_barrier,
            "pred_barrier_kcal": round(pred_barrier, 4),
            "barrier_error_kcal": round(b_err, 4),
            "ref_reaction_energy_kcal": ref_dE,
            "pred_reaction_energy_kcal": round(pred_dE, 4),
            "reaction_energy_error_kcal": round(dE_err, 4),
        })

    elapsed = time.time() - t0
    barrier_mae = sum(barrier_errors) / len(barrier_errors) if barrier_errors else 0.0
    reaction_energy_mae = sum(reaction_energy_errors) / len(reaction_energy_errors) if reaction_energy_errors else 0.0
    max_barrier_err = max(barrier_errors) if barrier_errors else 0.0

    # Sort to find 10 worst cases
    results_per_reaction.sort(key=lambda x: x["barrier_error_kcal"], reverse=True)
    worst_10 = results_per_reaction[:10]

    source_breakdown = {
        src: {
            "count": len(errs),
            "barrier_mae_kcal": round(sum(errs) / len(errs), 4),
        }
        for src, errs in source_barrier_errors.items()
    }

    throughput = len(lines) / elapsed if elapsed > 0 else 0

    return {
        "total_evaluated": len(lines),
        "barrier_mae_kcal": round(barrier_mae, 4),
        "reaction_energy_mae_kcal": round(reaction_energy_mae, 4),
        "max_barrier_error_kcal": round(max_barrier_err, 4),
        "throughput_reactions_per_sec": round(throughput, 2),
        "elapsed_seconds": round(elapsed, 2),
        "per_source_breakdown": source_breakdown,
        "worst_10_cases": worst_10,
    }


def main():
    parser = argparse.ArgumentParser(description="Evaluate barrier MAE on held-out dataset.")
    parser.add_argument("--checkpoint", type=str, default=str(BASE_DIR / "t1x_model_checkpoint.pt"))
    parser.add_argument("--data", type=str, default=str(BASE_DIR / "data" / "test.jsonl"))
    parser.add_argument("--architecture", type=str, default="legacy", choices=["legacy", "rbf_cutoff", "painn"])
    parser.add_argument("--device", type=str, default="auto")
    parser.add_argument("--out", type=str, default=str(BASE_DIR / "data" / "baseline_results.json"))
    parser.add_argument("--frames", type=int, default=15)
    parser.add_argument("--max-samples", type=int, default=None)
    args = parser.parse_args()

    if args.device == "auto":
        dev = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
    else:
        dev = torch.device(args.device)

    print(f"Loading checkpoint {args.checkpoint} on {dev} (architecture: {args.architecture})...")
    model = load_model(Path(args.checkpoint), args.architecture, dev)

    data_path = Path(args.data)
    if not data_path.is_file():
        print(f"[FAIL] Data file not found: {data_path}")
        sys.exit(1)

    print(f"Evaluating on {data_path}...")
    metrics = evaluate(model, data_path, dev, n_frames=args.frames, max_samples=args.max_samples)

    out_p = Path(args.out)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    out_p.write_text(json.dumps(metrics, indent=2))

    print("\n=== Evaluation Results ===")
    print(f"Total Reactions: {metrics['total_evaluated']}")
    print(f"Barrier MAE: {metrics['barrier_mae_kcal']:.2f} kcal/mol")
    print(f"Reaction Energy MAE: {metrics['reaction_energy_mae_kcal']:.2f} kcal/mol")
    print(f"Max Barrier Error: {metrics['max_barrier_error_kcal']:.2f} kcal/mol")
    print(f"Throughput: {metrics['throughput_reactions_per_sec']:.1f} reactions/sec ({metrics['elapsed_seconds']}s total)")
    print("\nSource Breakdown:")
    for src, stats in metrics["per_source_breakdown"].items():
        print(f"  {src}: {stats['count']} samples, MAE = {stats['barrier_mae_kcal']:.2f} kcal/mol")
    print(f"\nResults saved to {out_p}")


if __name__ == "__main__":
    main()
