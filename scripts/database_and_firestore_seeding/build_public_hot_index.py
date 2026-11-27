#!/usr/bin/env python3
"""
Quantum Forge Public Hot Index Builder
---------------------------------------
Extracts top peer-reviewed literature reactions, clinical medicines, and core curriculum
templates from Firestore /library and local curated sets, stripping heavy 3D coordinate strings
(reactant_xyz, ts_xyz, product_xyz) to create a compact, CDN-deployable gzipped seed catalog.

Output targets:
- quantum_forge/web/data/public_hot_index.json.gz
- quantum_forge/assets/data/public_hot_index.json.gz
"""

import gzip
import json
import logging
import os
import subprocess
import sys
import time
import urllib.request
from typing import Any, Dict, List

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] [%(levelname)s] %(message)s")
logger = logging.getLogger("BuildHotIndex")

PROJECT_ID = os.environ.get("PROJECT_ID", "quantom-forge")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))

TARGET_WEB = os.path.join(REPO_ROOT, "quantum_forge", "web", "data", "public_hot_index.json.gz")
TARGET_ASSETS = os.path.join(REPO_ROOT, "quantum_forge", "assets", "data", "public_hot_index.json.gz")


def get_gcloud_token() -> str:
    try:
        return subprocess.check_output(["gcloud", "auth", "print-access-token"]).decode().strip()
    except Exception as e:
        logger.error("Failed to get gcloud token: %s", e)
        sys.exit(1)


def parse_firestore_fields(fields: Dict[str, Any]) -> Dict[str, Any]:
    out = {}
    for k, v in fields.items():
        if "stringValue" in v:
            out[k] = v["stringValue"]
        elif "integerValue" in v:
            out[k] = int(v["integerValue"])
        elif "doubleValue" in v:
            out[k] = float(v["doubleValue"])
        elif "booleanValue" in v:
            out[k] = v["booleanValue"]
        elif "arrayValue" in v:
            raw_vals = v["arrayValue"].get("values", [])
            out[k] = [
                x.get("stringValue") or x.get("integerValue") or x.get("booleanValue")
                for x in raw_vals
            ]
        elif "mapValue" in v:
            out[k] = parse_firestore_fields(v["mapValue"].get("fields", {}))
        elif "nullValue" in v:
            out[k] = None
    return out


def fetch_verified_reactions_from_firestore(token: str, max_items: int = 25000) -> List[Dict[str, Any]]:
    logger.info("Querying Firestore for up to %d verified / curated literature records...", max_items)
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runQuery"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    # Structured query with selective projection to omit 3D coordinates
    select_fields = [
        {"fieldPath": "name"},
        {"fieldPath": "iupacName"},
        {"fieldPath": "description"},
        {"fieldPath": "category"},
        {"fieldPath": "reference_ea"},
        {"fieldPath": "referenceEa"},
        {"fieldPath": "doi"},
        {"fieldPath": "journal_ref"},
        {"fieldPath": "journalRef"},
        {"fieldPath": "tags"},
        {"fieldPath": "is_derived"},
        {"fieldPath": "isDerived"},
        {"fieldPath": "defaultCatalystName"},
        {"fieldPath": "default_catalyst_name"},
        {"fieldPath": "literatureBarrierKcalMol"},
        {"fieldPath": "hasLiteratureCatalyst"},
        {"fieldPath": "literatureDoi"},
        {"fieldPath": "citation_count"},
        {"fieldPath": "is_mbbs"},
        {"fieldPath": "is_pharm_d"},
        {"fieldPath": "is_dvm"},
        {"fieldPath": "is_polymer"},
        {"fieldPath": "specialty"},
        {"fieldPath": "search_tokens"},
    ]

    structured_query = {
        "from": [{"collectionId": "library"}],
        "select": {"fields": select_fields},
        "where": {
            "fieldFilter": {
                "field": {"fieldPath": "is_derived"},
                "op": "EQUAL",
                "value": {"booleanValue": False},
            }
        },
        "limit": max_items,
    }

    body = json.dumps({"structuredQuery": structured_query}).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")

    results = []
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            for item in data:
                doc = item.get("document")
                if not doc:
                    continue
                doc_id = doc["name"].split("/")[-1]
                flat = parse_firestore_fields(doc.get("fields", {}))

                # Normalize template representation for Flutter ReactionTemplate.fromJson
                ref_ea = flat.get("reference_ea") or flat.get("referenceEa") or 15.0
                record = {
                    "id": doc_id,
                    "name": flat.get("name") or doc_id,
                    "iupacName": flat.get("iupacName") or "",
                    "description": flat.get("description") or "",
                    "category": flat.get("category") or "pharmaceutical",
                    "reactantXyz": "",  # Coordinate-free for compact payload
                    "productXyz": "",   # Coordinate-free for compact payload
                    "referenceEa": float(ref_ea),
                    "doi": flat.get("doi") or "",
                    "journalRef": flat.get("journal_ref") or flat.get("journalRef") or "",
                    "tags": flat.get("tags") or [],
                    "isDerived": flat.get("is_derived", False),
                    "defaultCatalystName": flat.get("defaultCatalystName") or flat.get("default_catalyst_name"),
                    "catalystXyz": None,
                    "literatureBarrierKcalMol": flat.get("literatureBarrierKcalMol"),
                    "hasLiteratureCatalyst": flat.get("hasLiteratureCatalyst", False),
                    "literatureDoi": flat.get("literatureDoi"),
                    "search_tokens": flat.get("search_tokens", []),
                    "citation_count": flat.get("citation_count", 0),
                    "is_mbbs": flat.get("is_mbbs", False),
                    "is_pharm_d": flat.get("is_pharm_d", False),
                    "is_dvm": flat.get("is_dvm", False),
                    "is_polymer": flat.get("is_polymer", False),
                }
                results.append(record)
    except Exception as e:
        logger.error("Failed to query Firestore: %s", e)

    logger.info("Retrieved %d verified literature records from Firestore.", len(results))
    return results


def load_local_curated_templates() -> List[Dict[str, Any]]:
    """Loads bundled curated medical and veterinary templates as fallback/seed."""
    curated = []
    med_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "medical_reactions.json")
    if os.path.exists(med_path):
        try:
            with open(med_path, "r", encoding="utf-8") as f:
                items = json.load(f)
                for item in items:
                    item_copy = dict(item)
                    item_copy["reactantXyz"] = ""
                    item_copy["productXyz"] = ""
                    item_copy["catalystXyz"] = None
                    curated.append(item_copy)
            logger.info("Loaded %d local medical templates from %s", len(items), med_path)
        except Exception as e:
            logger.warning("Error loading medical reactions: %s", e)

    vet_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "veterinary_reactions.json")
    if os.path.exists(vet_path):
        try:
            with open(vet_path, "r", encoding="utf-8") as f:
                items = json.load(f)
                for item in items:
                    item_copy = dict(item)
                    item_copy["reactantXyz"] = ""
                    item_copy["productXyz"] = ""
                    item_copy["catalystXyz"] = None
                    curated.append(item_copy)
            logger.info("Loaded %d local veterinary templates from %s", len(items), vet_path)
        except Exception as e:
            logger.warning("Error loading veterinary reactions: %s", e)

    return curated


def main():
    token = get_gcloud_token()
    records = fetch_verified_reactions_from_firestore(token, max_items=25000)

    # Merge with local curated templates, ensuring uniqueness by ID
    local_curated = load_local_curated_templates()
    seen_ids = set()
    combined: List[Dict[str, Any]] = []

    for r in local_curated:
        rid = r.get("id") or r.get("name")
        if rid and rid not in seen_ids:
            seen_ids.add(rid)
            combined.append(r)

    for r in records:
        rid = r.get("id")
        if rid and rid not in seen_ids:
            seen_ids.add(rid)
            combined.append(r)

    logger.info("Total deduplicated hot index templates: %d", len(combined))

    json_str = json.dumps(combined, separators=(",", ":"))
    raw_size_kb = len(json_str.encode("utf-8")) / 1024.0

    # Ensure output directories exist
    os.makedirs(os.path.dirname(TARGET_WEB), exist_ok=True)
    os.makedirs(os.path.dirname(TARGET_ASSETS), exist_ok=True)

    # Write gzipped and raw bundles
    for target in [TARGET_WEB, TARGET_ASSETS]:
        with gzip.open(target, "wt", encoding="utf-8", compresslevel=9) as gz:
            gz.write(json_str)
        gz_size_kb = os.path.getsize(target) / 1024.0

        # Also write uncompressed json for direct rootBundle reading
        uncompressed_path = target.replace(".json.gz", ".json")
        with open(uncompressed_path, "w", encoding="utf-8") as f:
            f.write(json_str)

        logger.info("Generated %s (Gzip: %.1f KB | Raw: %.1f KB)", target, gz_size_kb, raw_size_kb)

    # Also stage in hosting_dist/data for Firebase Hosting build
    hosting_data_dir = os.path.join(REPO_ROOT, "quantum_forge", "hosting_dist", "data")
    os.makedirs(hosting_data_dir, exist_ok=True)
    with gzip.open(os.path.join(hosting_data_dir, "public_hot_index.json.gz"), "wt", encoding="utf-8", compresslevel=9) as gz:
        gz.write(json_str)
    with open(os.path.join(hosting_data_dir, "public_hot_index.json"), "w", encoding="utf-8") as f:
        f.write(json_str)
    logger.info("Staged in hosting_dist/data/ for Firebase Hosting.")

    logger.info("Public Hot Index build complete!")


if __name__ == "__main__":
    main()
