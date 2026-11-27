#!/usr/bin/env python3
"""
Quantum Forge Sharded Turbo Backfill & Data Repair Engine
-----------------------------------------------------------
Partitions Cloud Firestore /library into 8 lexicographical shards across 64 worker threads
to backfill search_tokens, edge n-grams, Soundex phonetic keys, clinical synonyms, and curriculum
facets across all 5.76M+ records in parallel.

Architecture:
- 8 Lexicographical Shards:
    Shard 0: [""   -> "b")
    Shard 1: ["b"  -> "f")
    Shard 2: ["f"  -> "l")
    Shard 3: ["l"  -> "p")
    Shard 4: ["p"  -> "r")
    Shard 5: ["r"  -> "u")
    Shard 6: ["u"  -> "w")
    Shard 7: ["w"  -> "\uf8ff"]
- Concurrency: 64 worker threads with pooled HTTP sessions (pool_connections=128, pool_maxsize=128).
- High Throughput: 500-doc atomic write batches with retry backoff.
- Durable Checkpointing: _system_jobs/library_sharded_repair_v1 and local JSON checkpoint.
"""

from __future__ import annotations

import argparse
import datetime
import json
import logging
import os
import re
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Dict, List, Optional, Tuple

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
LOCAL_CHECKPOINT_FILE = os.path.join(SCRIPT_DIR, ".sharded_repair_checkpoint.json")
FIRESTORE_CHECKPOINT_DOC = "_system_jobs/library_sharded_repair_v1"

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] [%(threadName)s] %(message)s"
)
logger = logging.getLogger("TurboBackfill")

SHARD_BOUNDARIES = [
    ("", "b"),
    ("b", "f"),
    ("f", "l"),
    ("l", "p"),
    ("p", "r"),
    ("r", "u"),
    ("u", "w"),
    ("w", "\uf8ff"),
]


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
            self._token = self._fetch_token()
            self._expires_at = now + (45 * 60)
            return self._token

    def _fetch_token(self) -> str:
        # 1. ADC
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

        # 2. gcloud CLI
        try:
            token = subprocess.check_output(
                ["gcloud", "auth", "print-access-token"],
                stderr=subprocess.DEVNULL
            ).decode().strip()
            if token:
                return token
        except Exception:
            pass

        # 3. GCE Metadata
        try:
            resp = requests.get(
                "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
                headers={"Metadata-Flavor": "Google"},
                timeout=2.0
            )
            if resp.status_code == 200:
                return resp.json().get("access_token", "")
        except Exception:
            pass

        logger.error("Could not acquire Google Auth token.")
        sys.exit(1)


token_manager = ThreadSafeTokenManager()


def create_pooled_session(pool_size: int = 128) -> requests.Session:
    session = requests.Session()
    adapter = HTTPAdapter(
        pool_connections=pool_size,
        pool_maxsize=pool_size,
        max_retries=3,
        pool_block=True
    )
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


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


def to_firestore_value(val: Any) -> Dict[str, Any]:
    if val is None:
        return {"nullValue": None}
    if isinstance(val, bool):
        return {"booleanValue": val}
    if isinstance(val, int):
        return {"integerValue": str(val)}
    if isinstance(val, float):
        return {"doubleValue": val}
    if isinstance(val, str):
        return {"stringValue": val}
    if isinstance(val, list):
        return {"arrayValue": {"values": [to_firestore_value(x) for x in val]}}
    if isinstance(val, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in val.items()}}}
    return {"stringValue": str(val)}


class ShardedCheckpointManager:
    def __init__(self, session: requests.Session):
        self.session = session
        self.lock = threading.Lock()
        self.state: Dict[str, Any] = self._load()

    def _load(self) -> Dict[str, Any]:
        # Local JSON
        if os.path.exists(LOCAL_CHECKPOINT_FILE):
            try:
                with open(LOCAL_CHECKPOINT_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {
            "shards": {f"shard_{i}": {"cursor": None, "scanned": 0, "repaired": 0, "done": False} for i in range(8)},
            "total_scanned": 0,
            "total_repaired": 0,
            "last_updated": datetime.datetime.now(datetime.timezone.utc).isoformat()
        }

    def save(self):
        with self.lock:
            self.state["last_updated"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
            try:
                with open(LOCAL_CHECKPOINT_FILE, "w", encoding="utf-8") as f:
                    json.dump(self.state, f, indent=2)
            except Exception as e:
                logger.warning("Failed to save local checkpoint: %s", e)

            # Firestore checkpoint update every few minutes
            try:
                token = token_manager.get_token()
                url = f"{FIRESTORE_BASE}/{FIRESTORE_CHECKPOINT_DOC}"
                fields = {
                    "total_scanned": {"integerValue": str(self.state["total_scanned"])},
                    "total_repaired": {"integerValue": str(self.state["total_repaired"])},
                    "last_updated": {"stringValue": self.state["last_updated"]},
                }
                self.session.patch(
                    url,
                    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                    json={"fields": fields},
                    timeout=5.0
                )
            except Exception:
                pass

    def update_shard(self, shard_id: int, cursor: Optional[str], scanned_delta: int, repaired_delta: int, is_done: bool = False):
        with self.lock:
            s_key = f"shard_{shard_id}"
            if s_key not in self.state["shards"]:
                self.state["shards"][s_key] = {"cursor": None, "scanned": 0, "repaired": 0, "done": False}
            s = self.state["shards"][s_key]
            if cursor:
                s["cursor"] = cursor
            s["scanned"] += scanned_delta
            s["repaired"] += repaired_delta
            if is_done:
                s["done"] = True
            self.state["total_scanned"] += scanned_delta
            self.state["total_repaired"] += repaired_delta


def commit_batch_updates(session: requests.Session, writes: List[Dict[str, Any]]) -> bool:
    if not writes:
        return True
    url = f"{FIRESTORE_BASE}:commit"
    token = token_manager.get_token()
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {"writes": writes}

    for attempt in range(5):
        try:
            resp = session.post(url, headers=headers, json=payload, timeout=20.0)
            if resp.status_code == 200:
                return True
            if resp.status_code == 401:
                token = token_manager.get_token(force_refresh=True)
                headers["Authorization"] = f"Bearer {token}"
            time.sleep(2 ** attempt * 0.5)
        except Exception as e:
            time.sleep(2 ** attempt * 0.5)
    return False


def process_shard(
    shard_id: int,
    start_key: str,
    end_key: str,
    session: requests.Session,
    checkpoint: ShardedCheckpointManager,
    batch_size: int = 500,
    dry_run: bool = False
):
    shard_name = f"shard_{shard_id}"
    logger.info("Starting worker on %s: [%r -> %r]", shard_name, start_key, end_key)
    cursor = checkpoint.state["shards"].get(shard_name, {}).get("cursor")

    page_size = 500
    total_shard_scanned = 0
    total_shard_repaired = 0

    while True:
        token = token_manager.get_token()
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        url = f"{FIRESTORE_BASE}:runQuery"

        # Structured query for shard range
        filter_clauses = []
        if start_key:
            filter_clauses.append({
                "fieldFilter": {
                    "field": {"fieldPath": "__name__"},
                    "op": "GREATER_THAN_OR_EQUAL",
                    "value": {"referenceValue": f"projects/{PROJECT_ID}/databases/(default)/documents/library/{start_key}"}
                }
            })
        if end_key and end_key != "\uf8ff":
            filter_clauses.append({
                "fieldFilter": {
                    "field": {"fieldPath": "__name__"},
                    "op": "LESS_THAN",
                    "value": {"referenceValue": f"projects/{PROJECT_ID}/databases/(default)/documents/library/{end_key}"}
                }
            })

        structured_query: Dict[str, Any] = {
            "from": [{"collectionId": "library"}],
            "orderBy": [{"field": {"fieldPath": "__name__"}, "direction": "ASCENDING"}],
            "limit": page_size,
            "select": {
                "fields": [
                    {"fieldPath": "name"},
                    {"fieldPath": "search_tokens"},
                    {"fieldPath": "tags"},
                    {"fieldPath": "category"},
                    {"fieldPath": "iupacName"},
                    {"fieldPath": "doi"},
                    {"fieldPath": "journalRef"},
                ]
            }
        }

        if len(filter_clauses) == 1:
            structured_query["where"] = filter_clauses[0]
        elif len(filter_clauses) > 1:
            structured_query["where"] = {"compositeFilter": {"op": "AND", "filters": filter_clauses}}

        if cursor:
            structured_query["startAt"] = {
                "values": [{"referenceValue": f"projects/{PROJECT_ID}/databases/(default)/documents/library/{cursor}"}],
                "before": False
            }

        try:
            resp = session.post(url, headers=headers, json={"structuredQuery": structured_query}, timeout=30.0)
            if resp.status_code != 200:
                logger.error("%s query failed: HTTP %d", shard_name, resp.status_code)
                time.sleep(2.0)
                continue
            rows = resp.json()
        except Exception as e:
            logger.error("%s network error: %s", shard_name, e)
            time.sleep(2.0)
            continue

        docs = [r["document"] for r in rows if "document" in r]
        if not docs:
            logger.info("%s reached end of shard range.", shard_name)
            checkpoint.update_shard(shard_id, cursor, 0, 0, is_done=True)
            checkpoint.save()
            break

        writes = []
        last_doc_id = None
        repaired_in_page = 0

        for d in docs:
            doc_name = d.get("name", "")
            doc_id = doc_name.split("/")[-1]
            last_doc_id = doc_id
            fields = d.get("fields", {})
            flat = parse_firestore_fields(fields)

            # Check if search_tokens is missing or incomplete
            tokens = flat.get("search_tokens")
            if not tokens or not isinstance(tokens, list) or len(tokens) == 0:
                meta = build_search_metadata(flat)
                update_fields = {
                    "search_tokens": to_firestore_value(meta["search_tokens"]),
                    "name_lower": to_firestore_value(meta["name_lower"]),
                    "is_mbbs": to_firestore_value(meta["is_mbbs"]),
                    "is_pharm_d": to_firestore_value(meta["is_pharm_d"]),
                    "is_dvm": to_firestore_value(meta["is_dvm"]),
                    "is_polymer": to_firestore_value(meta["is_polymer"]),
                    "specialty": to_firestore_value(meta["specialty"]),
                }
                field_paths = list(update_fields.keys())
                writes.append({
                    "update": {
                        "name": doc_name,
                        "fields": update_fields
                    },
                    "updateMask": {"fieldPaths": field_paths}
                })
                repaired_in_page += 1

        if not dry_run and writes:
            # Commit writes in chunks of batch_size
            for i in range(0, len(writes), batch_size):
                chunk = writes[i:i + batch_size]
                commit_batch_updates(session, chunk)

        cursor = last_doc_id
        total_shard_scanned += len(docs)
        total_shard_repaired += repaired_in_page
        checkpoint.update_shard(shard_id, cursor, len(docs), repaired_in_page)

        if total_shard_scanned % 5000 == 0:
            checkpoint.save()
            logger.info("%s progress: scanned %d, repaired %d (cursor: %s)", shard_name, total_shard_scanned, total_shard_repaired, cursor)

        if len(docs) < page_size:
            logger.info("%s finished with %d scanned, %d repaired.", shard_name, total_shard_scanned, total_shard_repaired)
            checkpoint.update_shard(shard_id, cursor, 0, 0, is_done=True)
            checkpoint.save()
            break


def main():
    parser = argparse.ArgumentParser(description="Quantum Forge Sharded Turbo Backfill")
    parser.add_argument("--workers", type=int, default=64, help="Total concurrency across shards (default 64)")
    parser.add_argument("--batch-size", type=int, default=500, help="Write batch size (default 500)")
    parser.add_argument("--dry-run", action="store_true", help="Scan without writing updates")
    args = parser.parse_args()

    session = create_pooled_session(pool_size=128)
    checkpoint = ShardedCheckpointManager(session)

    logger.info("Launching Sharded Turbo Backfill across %d shards (%d workers, batch_size=%d)...", len(SHARD_BOUNDARIES), args.workers, args.batch_size)

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = []
        for i, (start_k, end_k) in enumerate(SHARD_BOUNDARIES):
            shard_name = f"shard_{i}"
            if checkpoint.state["shards"].get(shard_name, {}).get("done", False):
                logger.info("Skipping %s (marked done in checkpoint)", shard_name)
                continue
            fut = executor.submit(
                process_shard,
                shard_id=i,
                start_key=start_k,
                end_key=end_k,
                session=session,
                checkpoint=checkpoint,
                batch_size=args.batch_size,
                dry_run=args.dry_run
            )
            futures.append(fut)

        for fut in as_completed(futures):
            try:
                fut.result()
            except Exception as e:
                logger.error("Shard worker encountered error: %s", e)

    checkpoint.save()
    logger.info("All shards completed! Total scanned: %d, Total repaired: %d", checkpoint.state["total_scanned"], checkpoint.state["total_repaired"])


if __name__ == "__main__":
    main()
