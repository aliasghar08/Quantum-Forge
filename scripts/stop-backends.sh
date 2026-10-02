#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Quantum Forge — Stop Backend Services
# ----------------------------------------------------------------------------
# Usage:
#   ./scripts/stop-backends.sh [--all | <backend-folder>]
# ============================================================================

BACKENDS=(
  "mace-backend:8001"
  "chgnet-backend:8002"
  "ani2x-backend:8003"
  "gfn2-xtb-backend:8004"
  "tx1-fastapi-backend:8005"
)

TARGET="${1:---all}"

stop_target() {
  local backend="$1"
  local port="$2"

  local pids
  pids=$(lsof -ti :"$port" 2>/dev/null || true)

  if [[ -n "$pids" ]]; then
    # Kill processes listening on this port
    echo "$pids" | xargs kill -9 2>/dev/null || true
    echo "stopped $backend (port $port)"
  else
    echo "no process on port $port"
  fi
}

if [[ "$TARGET" == "--all" || "$TARGET" == "-a" || "$TARGET" == "all" ]]; then
  for entry in "${BACKENDS[@]}"; do
    backend="${entry%%:*}"
    port="${entry##*:}"
    stop_target "$backend" "$port"
  done
else
  matched=false
  for entry in "${BACKENDS[@]}"; do
    backend="${entry%%:*}"
    port="${entry##*:}"
    if [[ "$backend" == "$TARGET" ]]; then
      stop_target "$backend" "$port"
      matched=true
      break
    fi
  done

  if [[ "$matched" == false ]]; then
    echo "Error: Unknown backend '$TARGET'."
    echo "Known backends:"
    for entry in "${BACKENDS[@]}"; do
      echo "  - ${entry%%:*} (port ${entry##*:})"
    done
    exit 1
  fi
fi
