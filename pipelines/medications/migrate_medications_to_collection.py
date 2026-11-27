#!/usr/bin/env python3
"""
Migrate Medications to Dedicated /medications Collection.
---------------------------------------------------------
Copies all everyday doctor-prescribed medications (both rx_med_* and curated
MBBS/Pharm-D/DVM drug monographs) from Cloud Firestore /library into the dedicated
root collection /medications using batched REST commits.

Preserves all fields, 3D Cartesian coordinates, and 7-tab Clinical Dossiers.
"""

import os
import sys
import json
import urllib.request
import urllib.error
import logging
from typing import Any

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("medication_migrator")

PROJECT_ID = os.environ.get("GCP_PROJECT", "quantom-forge")

def get_auth_token() -> str | None:
    try:
        import google.auth
        import google.auth.transport.requests
        creds, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
        creds.refresh(google.auth.transport.requests.Request())
        return creds.token
    except Exception as e:
        logger.warning("google.auth unavailable (%s); attempting gcloud CLI...", e)
        try:
            import subprocess
            token = subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()
            return token
        except Exception as e2:
            logger.error("Failed to acquire token via gcloud: %s", e2)
            return None

def fetch_medication_documents_from_library(token: str) -> list[dict[str, Any]]:
    """Runs structured queries on /library to retrieve all rx_med_* and medical records."""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runQuery"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    docs_by_name = {}

    # Query 1: Direct ID prefix range for all rx_med_* documents
    rx_med_query = {
        "structuredQuery": {
            "from": [{"collectionId": "library"}],
            "where": {
                "compositeFilter": {
                    "op": "AND",
                    "filters": [
                        {
                            "fieldFilter": {
                                "field": {"fieldPath": "__name__"},
                                "op": "GREATER_THAN_OR_EQUAL",
                                "value": {"referenceValue": f"projects/{PROJECT_ID}/databases/(default)/documents/library/rx_med_"},
                            }
                        },
                        {
                            "fieldFilter": {
                                "field": {"fieldPath": "__name__"},
                                "op": "LESS_THAN",
                                "value": {"referenceValue": f"projects/{PROJECT_ID}/databases/(default)/documents/library/rx_med_\uffff"},
                            }
                        },
                    ],
                }
            },
            "limit": 5000,
        }
    }
    try:
        req = urllib.request.Request(url, data=json.dumps(rx_med_query).encode("utf-8"), headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=45) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            for item in data:
                if "document" in item:
                    d = item["document"]
                    docs_by_name[d["name"]] = d
        logger.info("Retrieved %d rx_med_* documents from /library", len(docs_by_name))
    except Exception as e:
        logger.warning("Error querying rx_med_* from /library: %s", e)

    # Query 2: All pharmaceutical records across /library (paginated in chunks of 1000)
    for offset in range(0, 5000, 1000):
        query = {
            "structuredQuery": {
                "from": [{"collectionId": "library"}],
                "where": {
                    "fieldFilter": {
                        "field": {"fieldPath": "category"},
                        "op": "EQUAL",
                        "value": {"stringValue": "pharmaceutical"}
                    }
                },
                "offset": offset,
                "limit": 1000
            }
        }
        try:
            req = urllib.request.Request(url, data=json.dumps(query).encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req, timeout=45) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                batch_count = 0
                for item in data:
                    if "document" in item:
                        d = item["document"]
                        docs_by_name[d["name"]] = d
                        batch_count += 1
                if batch_count == 0:
                    break
        except Exception as e:
            logger.error("Error querying /library at offset %d: %s", offset, e)
            break
        
    logger.info("Found total %d unique candidate pharmaceutical/medication documents in /library", len(docs_by_name))
    return list(docs_by_name.values())

def commit_batch_to_medications(docs: list[dict[str, Any]], token: str) -> int:
    """Writes documents to /medications using batched :commit endpoint."""
    if not docs:
        return 0

    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:commit"
    
    writes = []
    for doc in docs:
        full_name = doc["name"]
        doc_id = full_name.split("/")[-1]
        target_name = f"projects/{PROJECT_ID}/databases/(default)/documents/medications/{doc_id}"
        
        writes.append({
            "update": {
                "name": target_name,
                "fields": doc.get("fields", {})
            }
        })
        
    req = urllib.request.Request(
        url,
        data=json.dumps({"writes": writes}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            if resp.status == 200:
                logger.info("Successfully committed batch of %d documents to /medications", len(writes))
                return len(writes)
    except urllib.error.HTTPError as e:
        logger.error("HTTP error %d committing to /medications: %s", e.code, e.read().decode())
    except Exception as e:
        logger.error("Exception committing to /medications: %s", e)
        
    return 0

def run_migration():
    token = get_auth_token()
    if not token:
        logger.error("No authorization token. Aborting.")
        sys.exit(1)

    logger.info("Starting migration of medication records from /library to /medications in %s...", PROJECT_ID)
    docs = fetch_medication_documents_from_library(token)
    
    # Process in batches of 100
    batch_size = 100
    total_migrated = 0
    for i in range(0, len(docs), batch_size):
        chunk = docs[i:i + batch_size]
        total_migrated += commit_batch_to_medications(chunk, token)

    logger.info("Migration complete: %d documents placed in /medications.", total_migrated)

if __name__ == "__main__":
    run_migration()
