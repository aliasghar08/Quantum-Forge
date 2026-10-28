#!/usr/bin/env python3
"""Diagnostic analysis script to pinpoint deficiencies in MLIP checkpoints."""

import json
from collections import defaultdict
from pathlib import Path
import sys
import numpy as np
import torch

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from scripts.eval_barrier_mae import load_model, parse_xyz, element_to_z, generate_lst_frames
EV_TO_KCAL = 23.060541945329334

def diagnose(checkpoint_path: str, architecture: str = "painn"):
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = load_model(Path(checkpoint_path), architecture, device)
    
    test_path = BASE_DIR / "data" / "test.jsonl"
    lines = [json.loads(l) for l in test_path.read_text().splitlines() if l.strip()]
    
    element_errors = defaultdict(list)
    barrier_bin_errors = defaultdict(list)
    size_bin_errors = defaultdict(list)
    source_errors = defaultdict(list)
    all_errors = []
    
    for item in lines:
        r_atoms, r_pos = parse_xyz(item["reactant_xyz"])
        p_atoms, p_pos = parse_xyz(item["product_xyz"])
        ref_b = float(item["reference_barrier_kcal_mol"])
        ref_dE = float(item.get("reference_reaction_energy_kcal_mol", 0.0))
        
        z_list = [element_to_z(a) for a in r_atoms]
        z_tensor = torch.tensor([z_list], dtype=torch.long, device=device).repeat(15, 1)
        mask_tensor = torch.ones(15, len(z_list), dtype=torch.float32, device=device)
        frames = generate_lst_frames(r_pos, p_pos, n_frames=15)
        pos_tensor = torch.tensor(frames, dtype=torch.float32, device=device)
        
        with torch.no_grad():
            energies_ev = model(z_tensor, pos_tensor, mask_tensor).cpu().tolist()
        
        pred_b = (max(energies_ev) - energies_ev[0]) * EV_TO_KCAL
        pred_dE = (energies_ev[-1] - energies_ev[0]) * EV_TO_KCAL
        err_b = abs(pred_b - ref_b)
        err_dE = abs(pred_dE - ref_dE)
        
        all_errors.append((err_b, err_dE, item["reaction_id"], ref_b, pred_b, r_atoms, item.get("source", "unknown")))
        source_errors[item.get("source", "unknown")].append(err_b)
        
        # Analyze by elements present
        for elem in set([a.upper() for a in r_atoms]):
            element_errors[elem].append(err_b)
            
        # Analyze by barrier bin
        if ref_b < 15:
            b_bin = "< 15 kcal/mol"
        elif ref_b <= 30:
            b_bin = "15 - 30 kcal/mol"
        elif ref_b <= 50:
            b_bin = "30 - 50 kcal/mol"
        else:
            b_bin = "> 50 kcal/mol"
        barrier_bin_errors[b_bin].append(err_b)
        
        # Analyze by size
        n_atoms = len(r_atoms)
        if n_atoms < 15:
            s_bin = "< 15 atoms"
        elif n_atoms <= 25:
            s_bin = "15 - 25 atoms"
        else:
            s_bin = "> 25 atoms"
        size_bin_errors[s_bin].append(err_b)
        
    b_maes = [e[0] for e in all_errors]
    dE_maes = [e[1] for e in all_errors]
    
    print(f"=== DEFICIENCY DIAGNOSTIC FOR {checkpoint_path} ===")
    print(f"Total Test Reactions: {len(all_errors)}")
    print(f"Barrier MAE: {np.mean(b_maes):.3f} kcal/mol (Median: {np.median(b_maes):.3f}, Max: {max(b_maes):.3f})")
    print(f"Reaction Energy MAE: {np.mean(dE_maes):.3f} kcal/mol")
    
    print("\n--- Barrier MAE by Source ---")
    for src, errs in sorted(source_errors.items(), key=lambda x: np.mean(x[1]), reverse=True):
        print(f"  {src:25s}: Count={len(errs):3d}, MAE={np.mean(errs):.3f} kcal/mol, Max={max(errs):.3f}")
        
    print("\n--- Barrier MAE by Element Presence ---")
    for elem, errs in sorted(element_errors.items(), key=lambda x: np.mean(x[1]), reverse=True):
        print(f"  Element {elem:2s}: Count={len(errs):3d}, MAE={np.mean(errs):.3f} kcal/mol, Max={max(errs):.3f}")

    print("\n--- Barrier MAE by Barrier Magnitude ---")
    for b_bin, errs in sorted(barrier_bin_errors.items(), key=lambda x: np.mean(x[1]), reverse=True):
        print(f"  {b_bin:16s}: Count={len(errs):3d}, MAE={np.mean(errs):.3f} kcal/mol, Max={max(errs):.3f}")

    print("\n--- Barrier MAE by Molecular Size ---")
    for s_bin, errs in sorted(size_bin_errors.items(), key=lambda x: np.mean(x[1]), reverse=True):
        print(f"  {s_bin:16s}: Count={len(errs):3d}, MAE={np.mean(errs):.3f} kcal/mol, Max={max(errs):.3f}")

    print("\n--- Top 10 Highest Error Reactions ---")
    for err_b, err_dE, rid, ref_b, pred_b, atoms, src in sorted(all_errors, key=lambda x: x[0], reverse=True)[:10]:
        elem_str = "".join(sorted(set(atoms)))
        print(f"  {rid:35s} | Ref: {ref_b:5.1f} | Pred: {pred_b:5.1f} | Err: {err_b:5.2f} kcal/mol | Atoms({len(atoms)}): {elem_str}")

if __name__ == "__main__":
    ckpt = sys.argv[1] if len(sys.argv) > 1 else str(BASE_DIR / "t1x_model_checkpoint_v2b.pt")
    arch = sys.argv[2] if len(sys.argv) > 2 else "painn"
    diagnose(ckpt, arch)
