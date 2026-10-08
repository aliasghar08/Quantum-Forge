"""Upsert the corrected templates into the Firestore `library` collection.

Auth: gcloud access token (bypasses Firestore security rules, which are
IAM-authenticated at this layer and require an admin claim only for
client-SDK writes).

Run from the repo root with a gcloud session active:

    gcloud auth login           # if not already authenticated
    python3 tx1-fastapi-backend/scripts/seed_library.py

Idempotent: running this twice updates the same documents in place.
"""

import json
import subprocess
import sys
import urllib.request
from pathlib import Path

PROJECT = "quantom-forge"
COLLECTION = "library"


def auth_token() -> str:
    return subprocess.check_output(
        ["gcloud", "auth", "print-access-token"]
    ).decode().strip()


def to_firestore_value(value):
    """Convert a Python value to Firestore REST API value shape."""
    if isinstance(value, str):
        return {"stringValue": value}
    if isinstance(value, bool):
        return {"booleanValue": value}
    if isinstance(value, int):
        return {"integerValue": str(value)}
    if isinstance(value, float):
        return {"doubleValue": value}
    if isinstance(value, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in value]}}
    if isinstance(value, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in value.items()}}}
    raise TypeError(f"Unsupported Firestore value type: {type(value)}")


def upsert(template_id: str, fields: dict) -> None:
    token = auth_token()
    # Explicitly specify updateMask for each field so existing fields in Firestore
    # (defaults, tags, description, referenceEa, etc.) are preserved.
    mask_params = "&".join(f"updateMask.fieldPaths={k}" for k in fields.keys())
    url = (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT}"
        f"/databases/(default)/documents/{COLLECTION}/{template_id}?{mask_params}"
    )
    body = {"fields": {k: to_firestore_value(v) for k, v in fields.items()}}
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        method="PATCH",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req) as resp:
        if resp.status not in (200, 201):
            raise RuntimeError(f"Upsert failed for {template_id}: HTTP {resp.status}")


def main() -> None:
    src = Path("tx1-fastapi-backend/scripts/group_a_output.json")
    if not src.exists():
        sys.exit(f"Missing {src}. Run regen_group_a.py first.")

    data = json.loads(src.read_text())
    for tid, cfg in data.items():
        doc = {
            "reactantXyz": cfg["reactant_xyz"],
            "productXyz": cfg["product_xyz"],
            "reactant_xyz_inline": cfg["reactant_xyz"],
            "product_xyz_inline": cfg["product_xyz"],
            "formula": cfg["formula"],
        }
        upsert(tid, doc)
        print(f"✔ {tid} → {COLLECTION}/{tid}")


if __name__ == "__main__":
    main()
