#!/usr/bin/env python3
"""
Upload a derived-variant JSONL corpus (from tool/generate_derived_corpus_test.dart)
into Firestore /library until the live collection reaches --target documents.

* Full-fidelity: every field of ReactionTemplate.toJson() is written with its
  correct Firestore type (maps, nulls, booleans, arrays), unlike the legacy
  seed_massive_firebase.py stub writer.
* Idempotent: document ids are deterministic, so re-running never duplicates.
* Resumable: the next line offset is stored in <jsonl>.progress.
* Quota-aware: backs off on 429/RESOURCE_EXHAUSTED and resumes automatically.

Usage:
  python3 scripts/upload_derived_jsonl.py path/to/derived.jsonl --target 100000
"""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import seed_massive_firebase as base  # noqa: E402  (auth + count helpers)

PROJECT = base.PROJECT_ID
DOCS = f"projects/{PROJECT}/databases/(default)/documents"
COMMIT_URL = f"https://firestore.googleapis.com/v1/{DOCS}:commit"
CONFIGSTORE = os.path.expanduser("~/.config/configstore/firebase-tools.json")
# Optional Node preload (e.g. a DNS workaround) for the firebase CLI.
CLI_NODE_OPTIONS = os.environ.get("QF_FIREBASE_NODE_OPTIONS", "")


def _stored_tokens():
    with open(CONFIGSTORE, encoding="utf-8") as f:
        return json.load(f).get("tokens", {})


def refresh_via_cli():
    """Any authenticated firebase CLI call refreshes and persists the token."""
    env = dict(os.environ)
    if CLI_NODE_OPTIONS:
        env["NODE_OPTIONS"] = CLI_NODE_OPTIONS
    subprocess.run(["firebase", "projects:list", "--json"], env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)


def get_token():
    tokens = _stored_tokens()
    if time.time() * 1000 > tokens.get("expires_at", 0) - 5 * 60 * 1000:
        refresh_via_cli()
        tokens = _stored_tokens()
    return tokens["access_token"]


def to_value(v):
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, str):
        return {"stringValue": v}
    if isinstance(v, list):
        return {"arrayValue": {"values": [to_value(x) for x in v]}}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: to_value(x) for k, x in v.items()}}}
    raise TypeError(f"unsupported type {type(v)}")


def commit(token, docs):
    writes = []
    for d in docs:
        doc_id = d.pop("id")
        # referenceEa must stay a double even when it is integral (e.g. 15.0).
        if isinstance(d.get("referenceEa"), int):
            d["referenceEa"] = float(d["referenceEa"])
        writes.append({
            "update": {
                "name": f"{DOCS}/library/{doc_id}",
                "fields": {k: to_value(v) for k, v in d.items()},
            }
        })
    req = urllib.request.Request(
        COMMIT_URL,
        data=json.dumps({"writes": writes}).encode(),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.status == 200


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("jsonl")
    ap.add_argument("--target", type=int, default=100_000)
    ap.add_argument("--batch-size", type=int, default=400)
    args = ap.parse_args()

    progress_path = args.jsonl + ".progress"
    offset = int(open(progress_path).read()) if os.path.exists(progress_path) else 0
    with open(args.jsonl, encoding="utf-8") as f:
        lines = f.readlines()

    token = get_token()
    live = base.get_total_count(token)
    print(f"live={live:,} target={args.target:,} corpus={len(lines):,} resume_offset={offset:,}", flush=True)

    backoff = 5
    batches = 0
    while offset < len(lines):
        if live >= args.target:
            break
        chunk = [json.loads(l) for l in lines[offset: offset + args.batch_size]]
        try:
            token = get_token()
            commit(token, chunk)
            offset += len(chunk)
            open(progress_path, "w").write(str(offset))
            batches += 1
            backoff = 5
            # Re-read the authoritative count every 10 batches (ids may overlap
            # with documents that already exist, so offset != growth).
            if batches % 10 == 0:
                live = base.get_total_count(token)
            else:
                live += len(chunk)
            print(f"  uploaded through line {offset:,} | live~{live:,}", flush=True)
            time.sleep(0.2)
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")[:300]
            print(f"  HTTP {e.code}: {body}", flush=True)
            if e.code in (429, 503) or "RESOURCE_EXHAUSTED" in body:
                print(f"  quota/rate limit - sleeping {backoff}s", flush=True)
                time.sleep(backoff)
                backoff = min(backoff * 2, 600)
            elif e.code == 401:
                refresh_via_cli()
            else:
                time.sleep(10)
        except Exception as e:  # network
            print(f"  network error {e} - retrying in 10s", flush=True)
            time.sleep(10)

    live = base.get_total_count(get_token())
    print(f"DONE live={live:,}", flush=True)


if __name__ == "__main__":
    main()
