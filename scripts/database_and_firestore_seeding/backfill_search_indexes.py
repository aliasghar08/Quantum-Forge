#!/usr/bin/env python3
"""
Quantum Forge Parallel Firestore Search Index Backfill Utility
--------------------------------------------------------------
Scans Firestore /library documents missing search_tokens and writes
inverted search tokens, phonetic Soundex keys, edge n-grams, and
curriculum facets (is_mbbs, is_pharm_d, is_dvm, is_polymer, specialty)
in 500-doc atomic :commit batches using a multi-threaded ThreadPoolExecutor.
"""

import argparse
import json
import logging
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Dict, List, Optional

import requests
from requests.adapters import HTTPAdapter

# Import shared search tokenizer
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from search_tokenizer import build_search_metadata

PROJECT_ID = "quantom-forge"
CHECKPOINT_FILE = os.path.join(SCRIPT_DIR, "backfill_checkpoint.json")

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("SearchIndexBackfill")


def create_session() -> requests.Session:
    sess = requests.Session()
    adapter = HTTPAdapter(pool_connections=16, pool_maxsize=16, max_retries=2)
    sess.mount("https://", adapter)
    sess.mount("http://", adapter)
    return sess


def get_token() -> str:
    """Retrieves an active OAuth2 token using gcloud CLI or environment."""
    import subprocess
    try:
        token = subprocess.check_output(
            ["gcloud", "auth", "print-access-token"],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        if token:
            return token
    except Exception as e:
        logger.warning("gcloud auth token failed: %s", e)
    env_token = os.environ.get("FIREBASE_TOKEN") or os.environ.get("GCLOUD_TOKEN")
    if env_token:
        return env_token
    raise RuntimeError("No valid authentication token found. Run 'gcloud auth login' first.")


def parse_firestore_fields(fields_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Flattens a Firestore document fields dictionary into standard Python types."""
    res = {}
    for k, v in fields_dict.items():
        if "stringValue" in v:
            res[k] = v["stringValue"]
        elif "integerValue" in v:
            res[k] = int(v["integerValue"])
        elif "doubleValue" in v:
            res[k] = float(v["doubleValue"])
        elif "booleanValue" in v:
            res[k] = v["booleanValue"]
        elif "arrayValue" in v:
            vals = v["arrayValue"].get("values", [])
            res[k] = [
                sub.get("stringValue") or sub.get("integerValue") or sub.get("booleanValue")
                for sub in vals
            ]
        elif "mapValue" in v:
            res[k] = parse_firestore_fields(v["mapValue"].get("fields", {}))
    return res


def commit_patch_batch(
    session: requests.Session,
    token: str,
    records: List[Dict[str, Any]],
    dry_run: bool = False
) -> int:
    """Commits a batch of search metadata updates using Firestore updateMask."""
    if not records:
        return 0
    if dry_run:
        logger.info("[DRY-RUN] Would patch %d documents with search_tokens & facets.", len(records))
        return len(records)

    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:commit"
    writes = []
    mask_fields = ["search_tokens", "name_lower", "is_mbbs", "is_pharm_d", "is_dvm", "is_polymer", "specialty"]

    for rec in records:
        doc_path = rec["name"]  # Full Firestore resource path
        meta = rec["meta"]

        fields = {
            "search_tokens": {
                "arrayValue": {"values": [{"stringValue": t} for t in meta["search_tokens"]]}
            },
            "name_lower": {"stringValue": meta["name_lower"]},
            "is_mbbs": {"booleanValue": meta["is_mbbs"]},
            "is_pharm_d": {"booleanValue": meta["is_pharm_d"]},
            "is_dvm": {"booleanValue": meta["is_dvm"]},
            "is_polymer": {"booleanValue": meta["is_polymer"]},
            "specialty": {"stringValue": meta["specialty"]},
        }

        writes.append({
            "update": {
                "name": doc_path,
                "fields": fields,
            },
            "updateMask": {
                "fieldPaths": mask_fields
            }
        })

    payload = {"writes": writes}
    max_retries = 4
    for attempt in range(max_retries):
        try:
            resp = session.post(
                url,
                json=payload,
                headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                timeout=25.0
            )
            if resp.status_code == 200:
                return len(records)
            if resp.status_code == 401:
                token = get_token()
            time.sleep(1.0 * (2 ** attempt))
        except Exception as exc:
            logger.warning("Commit attempt %d failed: %s", attempt + 1, exc)
            time.sleep(1.0 * (2 ** attempt))

    logger.error("Failed to commit batch of %d records after retries.", len(records))
    return 0


def run_backfill(limit: Optional[int] = None, batch_size: int = 500, max_workers: int = 12, dry_run: bool = False):
    session = create_session()
    token = get_token()

    logger.info("Starting Parallel Search Index Backfill on Firestore /library...")
    logger.info("Target Limit: %s | Batch Size: %d | Workers: %d | Dry-Run: %s", limit, batch_size, max_workers, dry_run)

    # Load checkpoint if resuming
    page_token = None
    if os.path.exists(CHECKPOINT_FILE):
        try:
            with open(CHECKPOINT_FILE, "r", encoding="utf-8") as f:
                ckpt = json.load(f)
                page_token = ckpt.get("page_token")
                logger.info("Resuming from checkpoint pageToken: %s", page_token)
        except Exception as e:
            logger.warning("Could not load checkpoint: %s", e)

    base_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/library"
    mask_params = [
        ("mask.fieldPaths", "name"),
        ("mask.fieldPaths", "category"),
        ("mask.fieldPaths", "tags"),
        ("mask.fieldPaths", "doi"),
        ("mask.fieldPaths", "journalRef"),
        ("mask.fieldPaths", "defaultCatalystName"),
        ("mask.fieldPaths", "iupacName"),
        ("mask.fieldPaths", "search_tokens"),
    ]

    total_scanned = 0
    total_patched = 0
    pending_batch: List[Dict[str, Any]] = []

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = []

        while True:
            params = [
                ("pageSize", "300"),
            ] + mask_params

            if page_token:
                params.append(("pageToken", page_token))

            try:
                resp = session.get(
                    base_url,
                    params=params,
                    headers={"Authorization": f"Bearer {token}"},
                    timeout=20.0
                )
                if resp.status_code == 401:
                    token = get_token()
                    continue
                if resp.status_code != 200:
                    logger.error("Error fetching library documents (HTTP %d): %s", resp.status_code, resp.text[:200])
                    break
            except Exception as e:
                logger.error("Exception fetching documents: %s", e)
                break

            data = resp.json()
            docs = data.get("documents", [])
            page_token = data.get("nextPageToken")

            if not docs:
                logger.info("No more documents returned from Firestore.")
                break

            for doc in docs:
                total_scanned += 1
                raw_fields = doc.get("fields", {})

                # Check if search_tokens is already populated and non-empty
                has_tokens = "search_tokens" in raw_fields and raw_fields["search_tokens"].get("arrayValue", {}).get("values")
                if has_tokens:
                    continue

                flat_record = parse_firestore_fields(raw_fields)
                meta = build_search_metadata(flat_record)

                pending_batch.append({
                    "name": doc["name"],
                    "meta": meta
                })

                if len(pending_batch) >= batch_size:
                    batch_to_submit = list(pending_batch)
                    pending_batch = []
                    fut = executor.submit(commit_patch_batch, session, token, batch_to_submit, dry_run)
                    futures.append(fut)

                if limit and total_scanned >= limit:
                    break

            # Process completed write futures
            for fut in list(futures):
                if fut.done():
                    total_patched += fut.result()
                    futures.remove(fut)

            logger.info("Progress: %d scanned | ~%d queued/patched | Next pageToken: %s",
                        total_scanned, total_patched + len(pending_batch), bool(page_token))

            # Save checkpoint
            if page_token:
                try:
                    with open(CHECKPOINT_FILE, "w", encoding="utf-8") as f:
                        json.dump({"page_token": page_token, "scanned": total_scanned, "patched": total_patched}, f)
                except Exception:
                    pass

            if (limit and total_scanned >= limit) or not page_token:
                break

        # Flush remaining pending batch
        if pending_batch:
            fut = executor.submit(commit_patch_batch, session, token, pending_batch, dry_run)
            futures.append(fut)
            pending_batch = []

        for fut in as_completed(futures):
            total_patched += fut.result()

    logger.info("🎉 Backfill Completed! Total Documents Scanned: %d | Total Patched: %d", total_scanned, total_patched)
    return total_patched


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Backfill Firestore /library search tokens and facets.")
    parser.add_argument("--limit", type=int, default=None, help="Maximum documents to scan.")
    parser.add_argument("--batch-size", type=int, default=500, help="Batch size per commit (max 500).")
    parser.add_argument("--workers", type=int, default=12, help="Number of concurrent worker threads.")
    parser.add_argument("--dry-run", action="store_true", help="Scan without writing to Firestore.")
    args = parser.parse_args()

    run_backfill(limit=args.limit, batch_size=args.batch_size, max_workers=args.workers, dry_run=args.dry_run)
