#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Quantum Forge — Start Local MLIP Backend
# ----------------------------------------------------------------------------
# Usage:
#   ./scripts/start-backend.sh <backend-folder>
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KNOWN_BACKENDS=(
  "mace-backend"
  "chgnet-backend"
  "ani2x-backend"
  "gfn2-xtb-backend"
  "tx1-fastapi-backend"
)

print_known_backends() {
  echo "Known backends:"
  for b in "${KNOWN_BACKENDS[@]}"; do
    echo "  - $b"
  done
}

if [[ $# -lt 1 ]] || [[ -z "${1:-}" ]]; then
  echo "Error: Backend folder name required."
  echo "Usage: $0 <backend-folder>"
  echo ""
  print_known_backends
  exit 1
fi

BACKEND="$1"

# 1. Verify folder exists
BACKEND_DIR="$REPO_ROOT/$BACKEND"
if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Error: Backend folder '$BACKEND' does not exist under $REPO_ROOT."
  echo ""
  print_known_backends
  exit 1
fi

# 2. Map folder name to port
case "$BACKEND" in
  mace-backend)        PORT=8001 ;;
  chgnet-backend)      PORT=8002 ;;
  ani2x-backend)       PORT=8003 ;;
  gfn2-xtb-backend)    PORT=8004 ;;
  tx1-fastapi-backend) PORT=8005 ;;
  *)
    echo "Error: Unrecognized backend '$BACKEND'."
    echo ""
    print_known_backends
    exit 1
    ;;
esac

# 3. Check whether port is already in use
if lsof -ti :"$PORT" >/dev/null 2>&1; then
  echo "Error: Port $PORT is already in use by:"
  lsof -i :"$PORT"
  echo ""
  echo "To stop running backends, run:"
  echo "  $REPO_ROOT/scripts/stop-backends.sh $BACKEND"
  exit 1
fi

# 4. cd into repo root, then backend folder
cd "$REPO_ROOT"

# 5. Choose the right Python environment based on the backend
if [[ "$BACKEND" == "gfn2-xtb-backend" ]]; then
  CONDA_SH="$HOME/miniconda3/etc/profile.d/conda.sh"
  if [[ -f "$CONDA_SH" ]]; then
    # shellcheck disable=SC1090
    source "$CONDA_SH"
    conda activate xtb-env
  elif command -v conda >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate xtb-env
  else
    echo "Error: Conda not found at $CONDA_SH. Please install Miniconda and create 'xtb-env'."
    exit 1
  fi
else
  VENV_PATH="$REPO_ROOT/.venv"
  if [[ -d "$VENV_PATH" ]]; then
    # shellcheck disable=SC1091
    source "$VENV_PATH/bin/activate"
  else
    echo "Error: Shared virtual environment not found at $VENV_PATH."
    echo "To create it, run: cd $REPO_ROOT && python3.11 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
    exit 1
  fi
fi

cd "$BACKEND_DIR"

# 6. Export PYTORCH_ENABLE_MPS_FALLBACK=1
export PYTORCH_ENABLE_MPS_FALLBACK=1

# 8. Print banner
PYTHON_PATH="$(command -v python || command -v python3)"
echo "Starting $BACKEND on port $PORT (python: $PYTHON_PATH)"

# 9. Trap SIGINT and SIGTERM and run uvicorn without --reload
UVICORN_PID=""
cleanup() {
  if [[ -n "$UVICORN_PID" ]] && kill -0 "$UVICORN_PID" 2>/dev/null; then
    kill -TERM "$UVICORN_PID" 2>/dev/null || true
    wait "$UVICORN_PID" 2>/dev/null || true
  fi
}
trap cleanup INT TERM EXIT

python -m uvicorn main:app --host 0.0.0.0 --port "$PORT" &
UVICORN_PID=$!
wait "$UVICORN_PID"
