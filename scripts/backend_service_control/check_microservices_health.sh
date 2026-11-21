#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Quantum Forge — Backend Health Check
# ----------------------------------------------------------------------------
# Usage:
#   ./scripts/health-backends.sh
# ============================================================================

BACKENDS=(
  "mace-backend:8001"
  "chgnet-backend:8002"
  "ani2x-backend:8003"
  "gfn2-xtb-backend:8004"
  "tx1-fastapi-backend:8005"
)

for entry in "${BACKENDS[@]}"; do
  backend="${entry%%:*}"
  port="${entry##*:}"

  response=$(curl -s --connect-timeout 1 --max-time 2 "http://127.0.0.1:$port/health" 2>/dev/null || true)

  if [[ -z "$response" ]]; then
    printf "%-19s (%s): not running\n" "$backend" "$port"
  else
    parsed=$(python3 -c "
import json, sys

raw = sys.argv[1]
try:
    data = json.loads(raw)
    status = data.get('status', 'unknown')
    msg = data.get('message', '')
    dev = data.get('device', '')

    parts = []
    if msg:
        parts.append(msg.rstrip('.'))
    if dev:
        parts.append(f'(device: {dev})')

    if parts:
        print(f\"{status:<8} — {' '.join(parts)}\")
    else:
        print(status)
except Exception:
    print(f'unrecognized response: {raw[:60]}')
" "$response" 2>/dev/null || echo "unrecognized response")

    printf "%-19s (%s): %s\n" "$backend" "$port" "$parsed"
  fi
done
