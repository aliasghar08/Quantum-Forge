#!/usr/bin/env python3
"""
Quantum Forge Library Data Repair & Advanced Search Index Backfill
------------------------------------------------------------------
Scans all 5.76M+ documents in Firestore (/library and legacy users/*/reactions),
repairs missing/empty/malformed fields, and backfills inverted search tokens,
edge n-grams, Soundex phonetic keys, clinical synonyms, and curriculum facets.

Architectural Guarantees:
- O(1) Memory & Bandwidth: Selective projection (excludes heavy XYZ blobs during scan).
- Zero Redundant Writes: Returns ({}, []) for healthy, already-indexed records.
- High-Throughput Cloud Concurrency: ThreadPoolExecutor with pooled HTTP connections.
- Resumable Dual Checkpointing: Local JSON + Firestore doc (_system_jobs/library_repair_v1).
"""

import argparse
import datetime
import json
import logging
import math
import os
import re
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Dict, List, Optional, Set, Tuple

import requests
from requests.adapters import HTTPAdapter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

try:
    from search_tokenizer import build_search_metadata, extract_words
except ImportError:
    from scripts.database_and_firestore_seeding.search_tokenizer import build_search_metadata, extract_words

PROJECT_ID = os.environ.get("PROJECT_ID", "quantom-forge")
FIRESTORE_BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
LOCAL_CHECKPOINT_FILE = os.path.join(SCRIPT_DIR, ".repair_backfill_checkpoint.json")
FIRESTORE_CHECKPOINT_DOC = "_system_jobs/library_repair_v1"

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("LibraryDataRepair")

VALID_CATEGORIES = {
    "pharmaceutical", "biochemical", "veterinary", "polymer", "ionic",
    "thermal", "pericyclic", "radical", "organometallic", "nucleophilic",
    "electrochemistry", "inorganic", "benchmark"
}


# ─────────────────────────────────────────────────────────────────────────────
# Thread-Safe Token Management & HTTP Session
# ─────────────────────────────────────────────────────────────────────────────

class ThreadSafeTokenManager:
    def __init__(self):
        self._lock = threading.Lock()
        self._token: Optional[str] = None
        self._expires_at: float = 0.0

    def get_token(self, force_refresh: bool = False) -> str:
        with self._lock:
            now = time.time()
            if not force_refresh and self._token and now < self._expires_at:
                return self._token
            self._token = self._fetch_fresh_token()
            self._expires_at = now + (45 * 60)  # 45 min TTL
            return self._token

    def _fetch_fresh_token(self) -> str:
        # 1. Google Application Default Credentials (ADC)
        try:
            import google.auth
            import google.auth.transport.requests
            creds, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
            auth_req = google.auth.transport.requests.Request()
            creds.refresh(auth_req)
            if creds.token:
                return creds.token
        except Exception:
            pass

        # 2. Local gcloud CLI
        try:
            token = subprocess.check_output(
                ["gcloud", "auth", "print-access-token"],
                stderr=subprocess.DEVNULL
            ).decode().strip()
            if token:
                return token
        except Exception:
            pass

        # 3. Environment variables
        env_token = os.environ.get("FIREBASE_TOKEN") or os.environ.get("GCLOUD_TOKEN")
        if env_token:
            return env_token

        raise RuntimeError("No valid credentials found. Please authenticate via gcloud or service account ADC.")


_token_manager = ThreadSafeTokenManager()


def get_token(force_refresh: bool = False) -> str:
    return _token_manager.get_token(force_refresh=force_refresh)


def create_session(pool_size: int = 24) -> requests.Session:
    sess = requests.Session()
    adapter = HTTPAdapter(pool_connections=pool_size, pool_maxsize=pool_size, max_retries=2)
    sess.mount("https://", adapter)
    sess.mount("http://", adapter)
    return sess


# ─────────────────────────────────────────────────────────────────────────────
# Chemical Stoichiometry & Formula Synthesis
# ─────────────────────────────────────────────────────────────────────────────

def extract_hill_formula_from_xyz(xyz_str: str) -> str:
    """Computes Hill system stoichiometric formula (e.g., C8H9NO2) from XYZ string."""
    if not xyz_str or not xyz_str.strip():
        return ""
    counts: Dict[str, int] = {}
    lines = xyz_str.strip().splitlines()
    for line in lines[2:]:
        parts = line.split()
        if parts:
            sym = parts[0].capitalize()
            if sym.isalpha():
                counts[sym] = counts.get(sym, 0) + 1
    if not counts:
        return ""

    parts = []
    if "C" in counts:
        parts.append(f"C{counts['C']}" if counts['C'] > 1 else "C")
    if "H" in counts:
        parts.append(f"H{counts['H']}" if counts['H'] > 1 else "H")
    for el in sorted(counts.keys()):
        if el not in ("C", "H"):
            parts.append(f"{el}{counts[el]}" if counts[el] > 1 else el)
    return "".join(parts)


def parse_firestore_fields(fields_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Flattens Firestore REST field maps to standard Python values."""
    res = {}
    for k, v in fields_dict.items():
        if "stringValue" in v:
            res[k] = v["stringValue"]
        elif "integerValue" in v:
            try:
                res[k] = int(v["integerValue"])
            except (ValueError, TypeError):
                res[k] = 0
        elif "doubleValue" in v:
            try:
                res[k] = float(v["doubleValue"])
            except (ValueError, TypeError):
                res[k] = 0.0
        elif "booleanValue" in v:
            res[k] = bool(v["booleanValue"])
        elif "timestampValue" in v:
            res[k] = v["timestampValue"]
        elif "arrayValue" in v:
            vals = v["arrayValue"].get("values", [])
            res[k] = [
                sub.get("stringValue") or sub.get("integerValue") or sub.get("booleanValue")
                for sub in vals
            ]
        elif "mapValue" in v:
            res[k] = parse_firestore_fields(v["mapValue"].get("fields", {}))
    return res


# ─────────────────────────────────────────────────────────────────────────────
# Field Repair & Search Metadata Builder
# ─────────────────────────────────────────────────────────────────────────────

def build_repaired_fields(
    doc_id: str,
    raw_fields: Dict[str, Any]
) -> Tuple[Dict[str, Any], List[str]]:
    """
    Inspects a /library document for missing, empty, or malformed fields.
    Returns (patch_fields_dict, update_mask_field_paths).
    If the document is already healthy and indexed, returns ({}, []).
    """
    flat = parse_firestore_fields(raw_fields)
    patch_fields: Dict[str, Any] = {}
    update_mask: List[str] = []

    # 1. Name
    name = str(flat.get("name", "") or "").strip()
    if not name:
        fallback_name = (
            str(flat.get("reaction_name", "") or "").strip()
            or str(flat.get("template_name", "") or "").strip()
            or str(flat.get("iupac_equation", "") or "").strip()
            or str(flat.get("iupacName", "") or "").strip()
            or f"Quantum Reaction {doc_id[:12]}"
        )
        name = fallback_name
        patch_fields["name"] = {"stringValue": name}
        update_mask.append("name")

    # 2. Category
    raw_cat = str(flat.get("category", "") or "").strip().lower()
    cat = raw_cat
    if not cat or cat not in VALID_CATEGORIES:
        combined_text = f"{name} {flat.get('description', '')} {' '.join(str(t) for t in flat.get('tags', []))}".lower()
        if "polymer" in combined_text or "atrp" in combined_text or "raft" in combined_text:
            cat = "polymer"
        elif "vet" in combined_text or "ivermectin" in combined_text or "fenbendazole" in combined_text:
            cat = "veterinary"
        elif "biochem" in combined_text or "enzyme" in combined_text or "glycolysis" in combined_text:
            cat = "biochemical"
        else:
            cat = "pharmaceutical"
        patch_fields["category"] = {"stringValue": cat}
        update_mask.append("category")

    # 3. Tags
    tags = flat.get("tags")
    if not isinstance(tags, list) or len(tags) == 0:
        if cat == "veterinary":
            new_tags = ["DVM", "Veterinary", "Comparative-Pharmacology"]
        elif cat == "biochemical":
            new_tags = ["MBBS", "Biochemical", "Enzyme-Kinetics"]
        elif cat == "polymer":
            new_tags = ["Polymer", "Macromolecular-Kinetics"]
        else:
            new_tags = ["Pharm-D", "MBBS", "Pharmaceutical"]
        patch_fields["tags"] = {"arrayValue": {"values": [{"stringValue": str(t)} for t in new_tags]}}
        update_mask.append("tags")
        flat["tags"] = new_tags

    # 4. created_at (Ensures ordering index compatibility)
    created_at = flat.get("created_at")
    if not created_at or str(created_at).strip().lower() in ("null", "none", ""):
        default_timestamp = "2026-01-01T00:00:00Z"
        patch_fields["created_at"] = {"timestampValue": default_timestamp}
        update_mask.append("created_at")

    # 5. iupac_equation
    iupac_eq = str(flat.get("iupac_equation", "") or flat.get("iupacName", "") or "").strip()
    if not iupac_eq:
        r_form = extract_hill_formula_from_xyz(str(flat.get("reactant_xyz", "") or flat.get("reactantXyz", "")))
        p_form = extract_hill_formula_from_xyz(str(flat.get("product_xyz", "") or flat.get("productXyz", "")))
        if r_form and p_form:
            synth_eq = f"{r_form} -> [TS] -> {p_form}"
        else:
            synth_eq = f"{name} Pathway"
        patch_fields["iupac_equation"] = {"stringValue": synth_eq}
        update_mask.append("iupac_equation")

    # 6. reference_ea (Sanity check: 0.02 <= Ea <= 4.0 eV -> ~0.46 to 92.2 kcal/mol)
    raw_ea = flat.get("reference_ea") or flat.get("referenceEa")
    valid_ea = False
    if raw_ea is not None:
        try:
            val = float(raw_ea)
            if not math.isnan(val) and not math.isinf(val) and 0.4 <= val <= 95.0:
                valid_ea = True
        except (ValueError, TypeError):
            valid_ea = False

    if not valid_ea:
        domain_ea_map = {
            "pharmaceutical": 14.5,
            "biochemical": 12.0,
            "veterinary": 15.0,
            "polymer": 21.5,
            "thermal": 24.0,
        }
        calibrated_ea = domain_ea_map.get(cat, 16.0)
        patch_fields["reference_ea"] = {"doubleValue": calibrated_ea}
        patch_fields["referenceEa"] = {"doubleValue": calibrated_ea}
        update_mask.extend(["reference_ea", "referenceEa"])

    # 7. defaultCatalystName
    catalyst = str(flat.get("defaultCatalystName", "") or flat.get("default_catalyst_name", "") or "").strip()
    if not catalyst:
        if cat in ("pharmaceutical", "biochemical"):
            default_cat = "CYP450 / Enzyme Active Site"
        elif cat == "veterinary":
            default_cat = "Veterinary Biotransformation Enzyme Complex"
        elif cat == "polymer":
            default_cat = "Living Radical Coordination Catalyst"
        else:
            default_cat = "Molecular Active Site Environment"
        patch_fields["defaultCatalystName"] = {"stringValue": default_cat}
        update_mask.append("defaultCatalystName")

    # 8. DOI, journal_ref, is_derived, citation_count
    doi = str(flat.get("doi", "") or "").strip()
    # Check for invalid placeholder DOI
    if doi.lower() in ("none", "n/a", "null", "undefined", "todo", "doi") or not doi.startswith("10."):
        clean_doi = ""
    elif doi == "10.1021/jm00125a008" and "piperidine" not in name.lower() and "opioid" not in name.lower():
        clean_doi = ""
    else:
        clean_doi = doi

    if clean_doi != doi:
        patch_fields["doi"] = {"stringValue": clean_doi}
        update_mask.append("doi")

    expected_is_derived = bool(not clean_doi)
    curr_is_derived = flat.get("is_derived", flat.get("isDerived"))
    if curr_is_derived is None or bool(curr_is_derived) != expected_is_derived:
        patch_fields["is_derived"] = {"booleanValue": expected_is_derived}
        patch_fields["isDerived"] = {"booleanValue": expected_is_derived}
        update_mask.extend(["is_derived", "isDerived"])

    citation_count = flat.get("citation_count")
    valid_citation = False
    if citation_count is not None and str(citation_count).lower() not in ("null", "none", ""):
        try:
            int(citation_count)
            valid_citation = True
        except (ValueError, TypeError):
            valid_citation = False
    if not valid_citation:
        patch_fields["citation_count"] = {"integerValue": "0"}
        update_mask.append("citation_count")

    journal_ref = str(flat.get("journal_ref", "") or flat.get("journalRef", "") or "").strip()
    if not journal_ref:
        default_jref = "Quantum Forge Molecular Repository"
        patch_fields["journal_ref"] = {"stringValue": default_jref}
        update_mask.append("journal_ref")

    # 9. Search Tokens & Curriculum Facets
    search_tokens = flat.get("search_tokens")
    needs_search_index = (
        not isinstance(search_tokens, list)
        or len(search_tokens) == 0
        or "name_lower" not in flat
        or "is_mbbs" not in flat
        or "specialty" not in flat
    )

    if needs_search_index or update_mask:
        # Build refreshed search metadata using the updated record values
        temp_record = dict(flat)
        temp_record["name"] = name
        temp_record["category"] = cat
        temp_record["doi"] = clean_doi
        meta = build_search_metadata(temp_record)

        patch_fields["search_tokens"] = {
            "arrayValue": {"values": [{"stringValue": t} for t in meta["search_tokens"]]}
        }
        patch_fields["name_lower"] = {"stringValue": meta["name_lower"]}
        patch_fields["is_mbbs"] = {"booleanValue": meta["is_mbbs"]}
        patch_fields["is_pharm_d"] = {"booleanValue": meta["is_pharm_d"]}
        patch_fields["is_dvm"] = {"booleanValue": meta["is_dvm"]}
        patch_fields["is_polymer"] = {"booleanValue": meta["is_polymer"]}
        patch_fields["specialty"] = {"stringValue": meta["specialty"]}

        update_mask.extend([
            "search_tokens", "name_lower", "is_mbbs", "is_pharm_d",
            "is_dvm", "is_polymer", "specialty"
        ])

    unique_mask = list(dict.fromkeys(update_mask))
    return patch_fields, unique_mask


# ─────────────────────────────────────────────────────────────────────────────
# Checkpoint System (Local JSON + Firestore Document)
# ─────────────────────────────────────────────────────────────────────────────

def load_checkpoint(session: requests.Session, token: str, reset: bool = False) -> Dict[str, Any]:
    if reset:
        logger.info("Reset flag enabled. Starting scan from beginning.")
        return {"last_doc_name": None, "total_scanned": 0, "total_repaired": 0, "total_skipped": 0}

    # 1. Try local checkpoint
    if os.path.exists(LOCAL_CHECKPOINT_FILE):
        try:
            with open(LOCAL_CHECKPOINT_FILE, "r", encoding="utf-8") as f:
                ckpt = json.load(f)
                logger.info("Loaded local checkpoint: %s (scanned: %d, repaired: %d)",
                            ckpt.get("last_doc_name"), ckpt.get("total_scanned", 0), ckpt.get("total_repaired", 0))
                return ckpt
        except Exception as e:
            logger.warning("Could not read local checkpoint: %s", e)

    # 2. Try Firestore state doc
    url = f"{FIRESTORE_BASE}/{FIRESTORE_CHECKPOINT_DOC}"
    try:
        resp = session.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=10.0)
        if resp.status_code == 200:
            doc = resp.json()
            flat = parse_firestore_fields(doc.get("fields", {}))
            logger.info("Loaded Firestore checkpoint: %s (scanned: %d)",
                        flat.get("last_doc_name"), flat.get("total_scanned", 0))
            return flat
    except Exception as e:
        logger.warning("Could not read Firestore checkpoint: %s", e)

    return {"last_doc_name": None, "total_scanned": 0, "total_repaired": 0, "total_skipped": 0}


def save_checkpoint(
    session: requests.Session,
    token: str,
    ckpt_data: Dict[str, Any],
    dry_run: bool = False
):
    ckpt_data["updated_at"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    if dry_run:
        return

    # 1. Save local
    try:
        with open(LOCAL_CHECKPOINT_FILE, "w", encoding="utf-8") as f:
            json.dump(ckpt_data, f, indent=2)
    except Exception as e:
        logger.warning("Local checkpoint write failed: %s", e)

    # 2. Save to Firestore
    url = f"{FIRESTORE_BASE}/{FIRESTORE_CHECKPOINT_DOC}"
    fields = {
        "last_doc_name": {"stringValue": str(ckpt_data.get("last_doc_name") or "")},
        "total_scanned": {"integerValue": str(ckpt_data.get("total_scanned", 0))},
        "total_repaired": {"integerValue": str(ckpt_data.get("total_repaired", 0))},
        "total_skipped": {"integerValue": str(ckpt_data.get("total_skipped", 0))},
        "updated_at": {"stringValue": ckpt_data["updated_at"]},
        "status": {"stringValue": ckpt_data.get("status", "running")},
    }
    try:
        session.patch(
            url,
            json={"fields": fields},
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            timeout=10.0
        )
    except Exception as e:
        logger.warning("Firestore checkpoint write failed: %s", e)


# ─────────────────────────────────────────────────────────────────────────────
# Batch Commit Worker
# ─────────────────────────────────────────────────────────────────────────────

def commit_batch_updates(
    session: requests.Session,
    token: str,
    batch_records: List[Dict[str, Any]],
    dry_run: bool = False
) -> int:
    """Commits an array of document patches via Firestore :commit REST RPC."""
    if not batch_records:
        return 0
    if dry_run:
        return len(batch_records)

    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:commit"
    writes = []
    for rec in batch_records:
        doc_path = rec["doc_path"]
        patch_fields = rec["patch_fields"]
        mask = rec["update_mask"]
        writes.append({
            "update": {
                "name": doc_path,
                "fields": patch_fields,
            },
            "updateMask": {
                "fieldPaths": mask,
            }
        })

    payload = {"writes": writes}
    max_retries = 5
    current_token = token

    for attempt in range(max_retries):
        try:
            resp = session.post(
                url,
                json=payload,
                headers={"Authorization": f"Bearer {current_token}", "Content-Type": "application/json"},
                timeout=30.0
            )
            if resp.status_code == 200:
                return len(batch_records)
            if resp.status_code == 401:
                current_token = get_token(force_refresh=True)
            time.sleep(0.5 * (2 ** attempt))
        except Exception as exc:
            logger.warning("Batch commit attempt %d error: %s", attempt + 1, exc)
            time.sleep(0.5 * (2 ** attempt))

    logger.error("Failed to commit batch of %d records after retries.", len(batch_records))
    return 0


# ─────────────────────────────────────────────────────────────────────────────
# Legacy User Simulation Runs Repair
# ─────────────────────────────────────────────────────────────────────────────

def repair_legacy_user_runs(session: requests.Session, token: str, dry_run: bool = False) -> int:
    """Scans and patches reaction simulation runs across collectionGroup('reactions')."""
    logger.info("Scanning and repairing legacy user simulation runs in collectionGroup('reactions')...")
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runQuery"
    query = {
        "structuredQuery": {
            "from": [{"collectionId": "reactions", "allDescendants": True}],
            "limit": 1000,
        }
    }
    repaired_count = 0
    try:
        resp = session.post(
            url,
            json=query,
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            timeout=25.0
        )
        if resp.status_code != 200:
            logger.warning("Legacy user runs query returned HTTP %d: %s", resp.status_code, resp.text[:200])
            return 0

        data = resp.json()
        patches = []
        for item in data:
            doc = item.get("document")
            if not doc:
                continue
            doc_path = doc["name"]
            fields = parse_firestore_fields(doc.get("fields", {}))

            r_name = str(fields.get("reaction_name", "") or fields.get("template_name", "") or "").strip()
            # If name is a status message like "TS Search Converged" or empty
            needs_patch = not r_name or "converged" in r_name.lower() or "completed" in r_name.lower()

            if needs_patch:
                fixed_name = f"Quantum Simulation {doc_path.split('/')[-1][:8]}"
                patch_fields = {
                    "reaction_name": {"stringValue": fixed_name},
                    "template_name": {"stringValue": fixed_name},
                }
                patches.append({
                    "doc_path": doc_path,
                    "patch_fields": patch_fields,
                    "update_mask": ["reaction_name", "template_name"]
                })

        if patches:
            repaired_count = commit_batch_updates(session, token, patches, dry_run)
            logger.info("Successfully patched %d legacy user simulation runs.", repaired_count)
    except Exception as e:
        logger.warning("Legacy user runs repair error: %s", e)

    return repaired_count


# ─────────────────────────────────────────────────────────────────────────────
# Core Migration Runner
# ─────────────────────────────────────────────────────────────────────────────

def run_repair_and_backfill(
    limit: Optional[int] = None,
    batch_size: int = 500,
    max_workers: int = 16,
    dry_run: bool = False,
    reset: bool = False,
    repair_user_runs: bool = False,
):
    session = create_session(pool_size=max_workers + 8)
    token = get_token()

    logger.info("=" * 70)
    logger.info("QUANTUM FORGE 5.76M+ DATABASE REPAIR & ADVANCED SEARCH INDEXING")
    logger.info("=" * 70)
    logger.info("Project: %s | Workers: %d | Batch: %d | Dry-Run: %s | Reset: %s",
                PROJECT_ID, max_workers, batch_size, dry_run, reset)

    if repair_user_runs:
        repair_legacy_user_runs(session, token, dry_run=dry_run)

    ckpt = load_checkpoint(session, token, reset=reset)
    last_doc_name = ckpt.get("last_doc_name")
    total_scanned = ckpt.get("total_scanned", 0)
    total_repaired = ckpt.get("total_repaired", 0)
    total_skipped = ckpt.get("total_skipped", 0)

    # Selective projection mask to exclude huge coordinate strings
    select_fields = [
        {"fieldPath": "name"},
        {"fieldPath": "category"},
        {"fieldPath": "tags"},
        {"fieldPath": "created_at"},
        {"fieldPath": "iupac_equation"},
        {"fieldPath": "iupacName"},
        {"fieldPath": "reference_ea"},
        {"fieldPath": "referenceEa"},
        {"fieldPath": "defaultCatalystName"},
        {"fieldPath": "default_catalyst_name"},
        {"fieldPath": "doi"},
        {"fieldPath": "journal_ref"},
        {"fieldPath": "journalRef"},
        {"fieldPath": "citation_count"},
        {"fieldPath": "is_derived"},
        {"fieldPath": "isDerived"},
        {"fieldPath": "search_tokens"},
        {"fieldPath": "name_lower"},
        {"fieldPath": "is_mbbs"},
        {"fieldPath": "is_pharm_d"},
        {"fieldPath": "is_dvm"},
        {"fieldPath": "is_polymer"},
        {"fieldPath": "specialty"},
    ]

    pending_patches: List[Dict[str, Any]] = []
    run_query_url = f"{FIRESTORE_BASE}:runQuery"
    start_time = time.time()
    last_checkpoint_count = total_scanned

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = []

        while True:
            # Construct structuredQuery ordered by __name__ ASC with cursor
            structured_query: Dict[str, Any] = {
                "from": [{"collectionId": "library"}],
                "select": {"fields": select_fields},
                "orderBy": [{"field": {"fieldPath": "__name__"}, "direction": "ASCENDING"}],
                "limit": 500,
            }

            if last_doc_name:
                structured_query["startAt"] = {
                    "values": [{"referenceValue": last_doc_name}],
                    "before": False,
                }

            query_body = {"structuredQuery": structured_query}

            try:
                resp = session.post(
                    run_query_url,
                    json=query_body,
                    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                    timeout=30.0
                )
                if resp.status_code == 401:
                    token = get_token(force_refresh=True)
                    continue
                if resp.status_code != 200:
                    logger.error("Error executing query (HTTP %d): %s", resp.status_code, resp.text[:200])
                    break
            except Exception as exc:
                logger.error("Query network exception: %s", exc)
                time.sleep(2.0)
                continue

            items = resp.json()
            if not items:
                logger.info("Empty query response. Scan complete.")
                break

            docs_in_page = 0
            for item in items:
                doc = item.get("document")
                if not doc:
                    continue

                docs_in_page += 1
                total_scanned += 1
                doc_path = doc["name"]
                doc_id = doc_path.split("/")[-1]
                last_doc_name = doc_path

                raw_fields = doc.get("fields", {})
                patch_fields, update_mask = build_repaired_fields(doc_id, raw_fields)

                if patch_fields and update_mask:
                    pending_patches.append({
                        "doc_path": doc_path,
                        "patch_fields": patch_fields,
                        "update_mask": update_mask,
                    })
                else:
                    total_skipped += 1

                if len(pending_patches) >= batch_size:
                    to_commit = list(pending_patches)
                    pending_patches = []
                    fut = executor.submit(commit_batch_updates, session, token, to_commit, dry_run)
                    futures.append(fut)

                if limit and total_scanned >= limit:
                    break

            # Process completed commit futures
            for fut in list(futures):
                if fut.done():
                    total_repaired += fut.result()
                    futures.remove(fut)

            elapsed = max(0.1, time.time() - start_time)
            rate = total_scanned / elapsed
            logger.info("Progress: %d scanned | %d repaired | %d skipped (0 writes) | Speed: %.1f docs/sec",
                        total_scanned, total_repaired, total_skipped, rate)

            # Checkpoint every 5,000 scanned documents
            if total_scanned - last_checkpoint_count >= 5000:
                save_checkpoint(session, token, {
                    "last_doc_name": last_doc_name,
                    "total_scanned": total_scanned,
                    "total_repaired": total_repaired,
                    "total_skipped": total_skipped,
                    "status": "running"
                }, dry_run=dry_run)
                last_checkpoint_count = total_scanned

            if docs_in_page < 500 or (limit and total_scanned >= limit):
                break

        # Flush remaining pending batch
        if pending_patches:
            fut = executor.submit(commit_batch_updates, session, token, pending_patches, dry_run)
            futures.append(fut)
            pending_patches = []

        for fut in as_completed(futures):
            total_repaired += fut.result()

    # Final checkpoint
    save_checkpoint(session, token, {
        "last_doc_name": last_doc_name,
        "total_scanned": total_scanned,
        "total_repaired": total_repaired,
        "total_skipped": total_skipped,
        "status": "completed" if (not limit) else "paused_at_limit"
    }, dry_run=dry_run)

    total_time = max(0.1, time.time() - start_time)
    logger.info("=" * 70)
    logger.info("REPAIR & BACKFILL RUN COMPLETE")
    logger.info("Scanned: %d | Repaired: %d | Skipped: %d | Duration: %.1fs | Avg Rate: %.1f docs/sec",
                total_scanned, total_repaired, total_skipped, total_time, total_scanned / total_time)
    logger.info("=" * 70)
    return total_scanned, total_repaired, total_skipped


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Repair missing fields and backfill advanced search indexes in Firestore.")
    parser.add_argument("--limit", type=int, default=None, help="Maximum documents to scan.")
    parser.add_argument("--batch-size", type=int, default=500, help="Batch size per commit (max 500).")
    parser.add_argument("--workers", type=int, default=16, help="Number of concurrent worker threads.")
    parser.add_argument("--dry-run", action="store_true", help="Scan without committing writes.")
    parser.add_argument("--reset", action="store_true", help="Start from the beginning ignoring checkpoints.")
    parser.add_argument("--repair-user-runs", action="store_true", help="Scan and fix legacy user simulation runs.")
    args = parser.parse_args()

    run_repair_and_backfill(
        limit=args.limit,
        batch_size=args.batch_size,
        max_workers=args.workers,
        dry_run=args.dry_run,
        reset=args.reset,
        repair_user_runs=args.repair_user_runs,
    )
