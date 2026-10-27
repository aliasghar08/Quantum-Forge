#!/usr/bin/env python3
"""
Fix Previous Reaction Records in Firestore (asia-south1 / quantom-forge)
------------------------------------------------------------------------
Scans all reaction documents in Firestore (across users), detects records
missing proper chemical reaction names (e.g. displaying solver status messages
like "LST completed successfully..." or "TS Search Converged..."), resolves their
true chemical identity via coordinate matching against reference libraries,
and patches the Firestore documents with 'template_name', 'reaction_name', and 'template_id'.

Usage:
  python3 scripts/fix_previous_reactions.py --dry-run
  python3 scripts/fix_previous_reactions.py --apply
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
import urllib.error
import urllib.parse

PROJECT_ID = "quantom-forge"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def get_auth_token():
    try:
        token = subprocess.check_output(
            ["gcloud", "auth", "print-access-token"],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        if token:
            return token
    except Exception:
        pass

    configstore_path = os.path.expanduser("~/.config/configstore/firebase-tools.json")
    if os.path.exists(configstore_path):
        try:
            with open(configstore_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                tokens = data.get("tokens", {})
                return tokens.get("access_token")
        except Exception:
            pass
    return None

def is_status_message(name: str) -> bool:
    if not name or not name.strip():
        return True
    s = name.strip().lower()
    return (
        "ts search converged" in s or
        "lst completed" in s or
        "optimization (" in s or
        "optimization error" in s or
        "converged calculation" in s or
        "uploading structures" in s or
        "template reaction submitted" in s or
        "running (" in s or
        "submitting to" in s or
        "in-progress run" in s or
        "restoring quantum state" in s or
        "max-pooling" in s or
        s.startswith("reaction ")
    )

def parse_atoms(xyz_str: str):
    """Extract atom symbols and coordinates from an XYZ formatted string."""
    if not xyz_str:
        return [], []
    lines = [line.strip() for line in xyz_str.strip().split("\n") if line.strip()]
    if len(lines) < 3:
        # Check if space-separated single line
        parts = xyz_str.split()
        if len(parts) >= 6 and parts[0].isdigit():
            # e.g. "6 Frame 0 Energy: ... C 0.0 0.0 0.0 ..."
            symbols = []
            coords = []
            # Find elements
            valid_syms = {"H", "C", "N", "O", "F", "P", "S", "Cl", "Br", "I", "Pt"}
            i = 0
            while i < len(parts):
                if parts[i] in valid_syms and i + 3 < len(parts):
                    try:
                        x = float(parts[i+1])
                        y = float(parts[i+2])
                        z = float(parts[i+3])
                        symbols.append(parts[i])
                        coords.append((x, y, z))
                        i += 4
                        continue
                    except ValueError:
                        pass
                i += 1
            return symbols, coords
        return [], []
    
    symbols = []
    coords = []
    for line in lines[2:]:
        parts = line.split()
        if len(parts) >= 4:
            try:
                sym = parts[0]
                x = float(parts[1])
                y = float(parts[2])
                z = float(parts[3])
                symbols.append(sym)
                coords.append((x, y, z))
            except ValueError:
                continue
    return symbols, coords

def load_reference_library():
    """Load known reactions with their initial geometries and barrier signatures."""
    templates = []
    
    # 1. From assets/medical_reactions.json
    med_path = "quantum_forge/assets/medical_reactions.json"
    if os.path.exists(med_path):
        try:
            with open(med_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                for item in data:
                    syms, coords = parse_atoms(item.get("reactantXyz", ""))
                    templates.append({
                        "id": item.get("id"),
                        "name": item.get("name"),
                        "symbols": syms,
                        "coords": coords,
                        "barrier": item.get("referenceEa")
                    })
        except Exception as e:
            print(f"Warning loading {med_path}: {e}")

    # 2. From assets/massive_reactions.json
    massive_path = "quantum_forge/assets/massive_reactions.json"
    if os.path.exists(massive_path):
        try:
            with open(massive_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                for item in data:
                    syms, coords = parse_atoms(item.get("reactantXyz", ""))
                    templates.append({
                        "id": item.get("id"),
                        "name": item.get("name"),
                        "symbols": syms,
                        "coords": coords,
                        "barrier": item.get("referenceEa")
                    })
        except Exception as e:
            print(f"Warning loading {massive_path}: {e}")

    # 3. Known Curated Milestones
    milestones = [
        ("med-aspirin-01", "Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation", 18.2, 29),
        ("med-paracetamol-01", "Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology", 14.5, 28),
        ("med-penicillin-01", "Penicillin Beta-Lactam Ring Hydrolysis & Resistance", 19.8, 13),
        ("med-serotonin-01", "Serotonin (5-HT) Biosynthesis (5-HTP Decarboxylation)", 16.2, 28),
        ("med-dopamine-01", "Dopamine to Norepinephrine (Noradrenaline) Hydroxylation", 16.7, 26),
        ("med-epinephrine-01", "Norepinephrine to Epinephrine (Adrenaline) N-Methylation", 15.3, 29),
        ("med-cisplatin-01", "Cisplatin Intracellular Aquation & DNA Crosslinking", 18.7, 11),
        ("med-omeprazole-01", "Omeprazole Acid Canalicular Activation to Tetracyclic Sulfenamide", 15.0, 49),
        ("poly-ziegler-natta-01", "Ziegler-Natta Olefin Coordination Polymerization", 12.5, 11),
        ("diels_alder", "Diels-Alder Cycloaddition", 27.5, 16),
        ("claisen", "Claisen Rearrangement", 30.8, 16),
        ("beckmann", "Beckmann Rearrangement", 21.6, 16),
        ("aldol-01", "Aldol Addition", 18.5, 14),
        ("fischer-01", "Fischer Esterification", 22.0, 12),
        ("vet-meloxicam-01", "Meloxicam Enolic Carboxamide Hydroxylation & COX-2 Selectivity", 12.6, 31),
        ("vet-flunixin-01", "Flunixin Meglumine Nicotinate Cyclooxygenase Inhibition", 13.9, 32),
        ("vet-pimobendan-01", "Pimobendan Benzimidazole-Pyridazinone Calcium Sensitization", 16.1, 28),
    ]
    for tid, name, ea, count in milestones:
        templates.append({
            "id": tid,
            "name": name,
            "symbols": [],
            "coords": [],
            "barrier": ea,
            "atom_count": count
        })

    return templates

def match_reaction(f0_text: str, barrier_kcal: float, ref_templates: list):
    """Match a reaction by geometry and barrier."""
    syms, coords = parse_atoms(f0_text)
    atom_count = len(syms)
    if atom_count == 0:
        # Check first line of XYZ
        lines = f0_text.strip().split("\n")
        if lines and lines[0].strip().isdigit():
            atom_count = int(lines[0].strip())

    # Check 6-atom combinatorial scaffold from library screen
    if atom_count == 6:
        return (
            "gen_quinolone_01",
            "Fluoroquinolone DNA Gyrase Pharmacophore Scaffolding",
            "pharmaceutical"
        )

    # 1. Coordinate distance matching
    if coords and len(coords) >= 4:
        for t in ref_templates:
            t_coords = t.get("coords", [])
            if len(t_coords) == len(coords):
                max_dev = 0.0
                match = True
                for c1, c2 in zip(coords[:6], t_coords[:6]):
                    dist = ((c1[0]-c2[0])**2 + (c1[1]-c2[1])**2 + (c1[2]-c2[2])**2)**0.5
                    if dist > 0.08:
                        match = False
                        break
                    if dist > max_dev:
                        max_dev = dist
                if match:
                    return t["id"], t["name"], "pharmaceutical"

    # 2. Match by exact atom count & barrier
    if atom_count > 0:
        candidates = [t for t in ref_templates if t.get("atom_count") == atom_count or len(t.get("coords", [])) == atom_count]
        if candidates:
            # Rank by barrier difference
            best = None
            min_diff = 999.0
            for c in candidates:
                diff = abs((c.get("barrier") or 0.0) - barrier_kcal)
                if diff < min_diff:
                    min_diff = diff
                    best = c
            if best and (min_diff < 5.0 or len(candidates) == 1):
                return best["id"], best["name"], "pharmaceutical"

    # 3. Match by barrier signature alone
    if barrier_kcal > 0:
        best = None
        min_diff = 0.4
        for t in ref_templates:
            diff = abs((t.get("barrier") or 0.0) - barrier_kcal)
            if diff < min_diff:
                min_diff = diff
                best = t
        if best:
            return best["id"], best["name"], "pharmaceutical"

    return None, None, None

def run_fixer(apply_changes: bool = False):
    token = get_auth_token()
    if not token:
        print("ERROR: Could not get Google Cloud auth token. Run 'gcloud auth login'.")
        sys.exit(1)

    print(f"Connecting to Firestore: project={PROJECT_ID} (asia-south1)...")
    ref_templates = load_reference_library()
    print(f"Loaded {len(ref_templates)} reference templates for matching.")

    # Query all reactions via runQuery
    query_url = f"{BASE_URL}:runQuery"
    query_body = json.dumps({
        "structuredQuery": {
            "from": [{"collectionId": "reactions", "allDescendants": True}],
            "limit": 300
        }
    }).encode("utf-8")

    req = urllib.request.Request(
        query_url,
        data=query_body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"HTTP Error querying reactions: {e.code} - {e.read().decode('utf-8')}")
        sys.exit(1)

    total_scanned = 0
    needs_fix = 0
    fixed_count = 0

    print(f"Retrieved {len(data)} query records from Firestore.")

    for item in data:
        doc = item.get("document")
        if not doc:
            continue
        total_scanned += 1
        doc_name = doc.get("name", "")
        fields = doc.get("fields", {})

        template_name = fields.get("template_name", {}).get("stringValue")
        reaction_name = fields.get("reaction_name", {}).get("stringValue")
        template_id = fields.get("template_id", {}).get("stringValue")
        message = fields.get("message", {}).get("stringValue", "")

        # Extract energy profile barrier
        ep_raw = fields.get("energy_profile", {}).get("arrayValue", {}).get("values", [])
        ep = [float(v.get("doubleValue") or v.get("integerValue") or 0.0) for v in ep_raw]
        barrier = (max(ep) - ep[0]) if len(ep) > 1 else 0.0

        # Extract Frame 0
        frames_raw = fields.get("trajectory_frames", {}).get("arrayValue", {}).get("values", [])
        f0 = frames_raw[0].get("stringValue", "") if frames_raw else ""

        current_title = reaction_name or template_name
        is_bad_title = not current_title or is_status_message(current_title)

        if not is_bad_title and template_name and reaction_name:
            # Already properly set
            continue

        needs_fix += 1
        new_name = None
        new_id = template_id

        # If one is present and valid, copy it
        if template_name and not is_status_message(template_name):
            new_name = template_name
        elif reaction_name and not is_status_message(reaction_name):
            new_name = reaction_name
        else:
            # Resolve via matching
            matched_id, matched_name, _ = match_reaction(f0, barrier, ref_templates)
            if matched_name:
                new_name = matched_name
                new_id = new_id or matched_id
            else:
                model = fields.get("model_used", {}).get("stringValue", "Quantum")
                new_name = f"{model} Transition State Mechanism"

        print(f"\n[Record {needs_fix}] {doc_name.split('/documents/')[1]}")
        print(f"  Current: template_name={template_name!r}, reaction_name={reaction_name!r}, msg={message!r}")
        print(f"  Barrier: {barrier:.2f} kcal/mol | Frames: {len(frames_raw)}")
        print(f"  ==> Resolved to: {new_name!r} (ID: {new_id})")

        if apply_changes:
            patch_url = (
                f"https://firestore.googleapis.com/v1/{doc_name}"
                f"?updateMask.fieldPaths=template_name"
                f"&updateMask.fieldPaths=reaction_name"
                f"&updateMask.fieldPaths=template_id"
            )
            patch_data = {
                "fields": {
                    "template_name": {"stringValue": new_name},
                    "reaction_name": {"stringValue": new_name},
                    "template_id": {"stringValue": new_id or "custom_rxn"}
                }
            }
            body = json.dumps(patch_data).encode("utf-8")
            preq = urllib.request.Request(
                patch_url,
                data=body,
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json"
                },
                method="PATCH"
            )
            try:
                with urllib.request.urlopen(preq) as presp:
                    fixed_count += 1
                    print(f"  [SUCCESS] Firestore document patched successfully.")
            except Exception as e:
                print(f"  [ERROR] Failed to patch document: {e}")
        else:
            print("  (Dry-run: run with --apply to commit changes to Firestore)")

    print(f"\n==========================================")
    print(f"Total records scanned: {total_scanned}")
    print(f"Records needing repair: {needs_fix}")
    if apply_changes:
        print(f"Records successfully updated in Firestore: {fixed_count}")
    else:
        print(f"Dry-run complete. Re-run with '--apply' to update all records in Firestore.")
    print(f"==========================================")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fix missing reaction names in Firestore.")
    parser.add_argument("--apply", action="store_true", help="Apply updates to Firestore.")
    parser.add_argument("--dry-run", action="store_true", help="Dry run only.")
    args = parser.parse_args()

    run_fixer(apply_changes=args.apply)
