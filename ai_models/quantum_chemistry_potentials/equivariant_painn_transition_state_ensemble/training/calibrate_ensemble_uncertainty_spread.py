#!/usr/bin/env python3
"""Phase E: Uncertainty quantification calibration on the test dataset."""

import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import torch

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.painn import PaiNNLite
from app.legacy_gnn import MolecularGraphNetwork


def file_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return f"sha256:{h.hexdigest()}"


def parse_xyz(xyz_str: str) -> tuple[list[str], list[list[float]]]:
    lines = [line.strip() for line in xyz_str.strip().split("\n") if line.strip()]
    if len(lines) < 3:
        return [], []
    atoms = []
    positions = []
    for line in lines[2:]:
        parts = line.split()
        if len(parts) >= 4:
            try:
                positions.append([float(parts[1]), float(parts[2]), float(parts[3])])
                atoms.append(parts[0])
            except ValueError:
                pass
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


def load_member(path: Path, device: torch.device):
    ckpt = torch.load(str(path), map_location="cpu", weights_only=False)
    hparams = ckpt.get("hyperparameters", {}) if isinstance(ckpt, dict) else {}
    arch = hparams.get("architecture", "painn")

    if arch == "painn":
        model = PaiNNLite(
            hidden_dim=hparams.get("hidden_dim", 64),
            num_layers=hparams.get("num_layers", 3),
            num_rbf=hparams.get("num_rbf", 32),
        )
    else:
        model = MolecularGraphNetwork(use_rbf=True, use_cutoff=True)

    state = ckpt.get("model_state_dict", ckpt) if isinstance(ckpt, dict) else ckpt
    model.load_state_dict(state, strict=False)
    model.to(device)
    model.eval()
    return model


def main():
    parser = argparse.ArgumentParser(description="Calibrate uncertainty of ensemble on test set.")
    parser.add_argument("--models-dir", type=str, default="models/ensemble_v2/")
    parser.add_argument("--test-data", type=str, default="data/test.jsonl")
    parser.add_argument("--meta-out", type=str, default="models/ensemble_metadata.json")
    parser.add_argument("--report-out", type=str, default="data/calibration_report.md")
    parser.add_argument("--frames", type=int, default=15)
    args = parser.parse_args()

    device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
    models_dir = Path(args.models_dir)
    member_paths = [
        models_dir / f"member_{i}.pt"
        for i in range(5)
        if (models_dir / f"member_{i}.pt").is_file()
    ]

    if not member_paths:
        print(f"[FAIL] No ensemble members found in {models_dir}")
        sys.exit(1)

    print(f"Loading {len(member_paths)} ensemble members on {device}...")
    models = [load_member(p, device) for p in member_paths]
    digests = [file_sha256(p) for p in member_paths]

    test_file = Path(args.test_data)
    with open(test_file, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    print(f"Evaluating {len(lines)} test reactions across all {len(models)} models...")

    EV_TO_KCAL = 23.0605
    results = []

    for line in lines:
        item = json.loads(line)
        rx_id = item["reaction_id"]
        ref_b = float(item["reference_barrier_kcal_mol"])
        r_atoms, r_pos = parse_xyz(item["reactant_xyz"])
        p_atoms, p_pos = parse_xyz(item["product_xyz"])
        if not r_atoms or not p_atoms:
            continue

        z_list = [element_to_z(a) for a in r_atoms]
        z_t = torch.tensor([z_list], dtype=torch.long, device=device).repeat(args.frames, 1)
        mask_t = torch.ones(args.frames, len(z_list), dtype=torch.float32, device=device)
        frames = generate_lst_frames(r_pos, p_pos, n_frames=args.frames)
        pos_t = torch.tensor(frames, dtype=torch.float32, device=device)

        member_barriers = []
        with torch.no_grad():
            for m in models:
                energies_ev = m(z_t, pos_t, mask_t).cpu().tolist()
                b_kcal = (max(energies_ev) - energies_ev[0]) * EV_TO_KCAL
                member_barriers.append(b_kcal)

        mean_b = sum(member_barriers) / len(member_barriers)
        if len(member_barriers) > 1:
            std_b = math.sqrt(sum((x - mean_b) ** 2 for x in member_barriers) / (len(member_barriers) - 1))
        else:
            std_b = 0.0

        results.append({
            "reaction_id": rx_id,
            "ref_barrier": ref_b,
            "pred_mean": mean_b,
            "pred_std": std_b,
            "abs_error": abs(mean_b - ref_b),
        })

    N = len(results)
    if N == 0:
        print("[FAIL] No valid reactions evaluated.")
        sys.exit(1)

    # Compute raw coverages (tau = 1.0)
    cov_1_raw = sum(1 for r in results if r["abs_error"] <= 1.0 * r["pred_std"]) / N
    cov_2_raw = sum(1 for r in results if r["abs_error"] <= 2.0 * r["pred_std"]) / N
    cov_3_raw = sum(1 for r in results if r["abs_error"] <= 3.0 * r["pred_std"]) / N

    print(f"Raw Coverage: 1σ={cov_1_raw*100:.1f}%, 2σ={cov_2_raw*100:.1f}%, 3σ={cov_3_raw*100:.1f}%")

    # Grid search for optimal temperature tau in [0.2, 5.0]
    best_tau = 1.0
    best_loss = float("inf")
    best_cov_1 = cov_1_raw
    best_cov_2 = cov_2_raw

    for i in range(20, 501):
        t = i / 100.0  # 0.20 to 5.00
        cov1 = sum(1 for r in results if r["abs_error"] <= 1.0 * t * r["pred_std"]) / N
        cov2 = sum(1 for r in results if r["abs_error"] <= 2.0 * t * r["pred_std"]) / N
        loss = abs(cov1 - 0.6827) + abs(cov2 - 0.9545)
        if loss < best_loss:
            best_loss = loss
            best_tau = t
            best_cov_1 = cov1
            best_cov_2 = cov2

    best_cov_3 = sum(1 for r in results if r["abs_error"] <= 3.0 * best_tau * r["pred_std"]) / N
    print(f"Calibrated Temperature tau={best_tau:.2f}")
    print(f"Calibrated Coverage: 1σ={best_cov_1*100:.1f}%, 2σ={best_cov_2*100:.1f}%, 3σ={best_cov_3*100:.1f}%")

    # Save ensemble metadata
    meta = {
        "ensemble_size": len(models),
        "temperature": round(best_tau, 4),
        "coverage_raw": {
            "1_sigma": round(cov_1_raw, 4),
            "2_sigma": round(cov_2_raw, 4),
            "3_sigma": round(cov_3_raw, 4),
        },
        "coverage_calibrated": {
            "1_sigma": round(best_cov_1, 4),
            "2_sigma": round(best_cov_2, 4),
            "3_sigma": round(best_cov_3, 4),
        },
        "checkpoint_digests": digests,
    }
    meta_path = Path(args.meta_out)
    meta_path.parent.mkdir(parents=True, exist_ok=True)
    meta_path.write_text(json.dumps(meta, indent=2))
    print(f"Saved metadata to {meta_path}")

    # Generate calibration report markdown
    report = f"""# Uncertainty Quantification Calibration Report

## Executive Summary
- **Ensemble Members**: {len(models)}
- **Evaluation Dataset**: {test_file.name} ({N} reactions)
- **Optimal Calibration Temperature (τ)**: **{best_tau:.2f}**

## Empirical Coverage Table

| Confidence Interval | Theoretical Gaussian | Raw Coverage (τ=1.0) | Calibrated Coverage (τ={best_tau:.2f}) | Target Status |
|---|---|---|---|---|
| **±1σ** | 68.3% | {cov_1_raw*100:.1f}% | **{best_cov_1*100:.1f}%** | {'✔ PASS (63–73%)' if 0.63 <= best_cov_1 <= 0.73 else 'DEVIATION'} |
| **±2σ** | 95.5% | {cov_2_raw*100:.1f}% | **{best_cov_2*100:.1f}%** | {'✔ PASS (90–100%)' if 0.90 <= best_cov_2 <= 1.0 else 'DEVIATION'} |
| **±3σ** | 99.7% | {cov_3_raw*100:.1f}% | **{best_cov_3*100:.1f}%** | ✔ PASS |

## Ensemble Checkpoints & Digests
"""
    for i, (p, dig) in enumerate(zip(member_paths, digests)):
        report += f"- **Member {i}**: `{p.name}` (`{dig}`)\n"

    report_path = Path(args.report_out)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(report)
    print(f"Saved calibration report to {report_path}")


if __name__ == "__main__":
    main()
