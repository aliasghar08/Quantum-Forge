#!/bin/bash
set -euo pipefail
mkdir -p data/raw
cd data/raw

MIN_SIZE=15000000000
if [ ! -f transition1x.db ] || [ "$(stat -f%z transition1x.db 2>/dev/null || echo 0)" -lt "$MIN_SIZE" ]; then
    echo "Downloading transition1x.db (~20GB)..."
    rm -f transition1x.db
    curl -L --retry 5 --retry-delay 10 -o transition1x.db \
        "https://ndownloader.figshare.com/files/43599573"
fi

echo "Verifying..."
PYTHON_BIN="../../.venv/bin/python"
if [ ! -f "$PYTHON_BIN" ]; then
    PYTHON_BIN="python3"
fi
"$PYTHON_BIN" - <<'PY'
from ase.db import connect
try:
    db = connect('transition1x.db')
    n = db.count()
    assert n > 9_000_000, f"Only {n} rows — download incomplete"
    print(f"PASS: {n} rows")
except Exception as e:
    print(f"FAIL: {e}")
    raise SystemExit(1)
PY
