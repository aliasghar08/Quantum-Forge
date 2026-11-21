#!/usr/bin/env bash
# ============================================================================
# Quantum Forge — Build and Verify All Backend Docker Images
# ----------------------------------------------------------------------------
# Usage:
#   ./scripts/build-all-backends.sh
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKENDS=(
  "mace-backend"
  "ani2x-backend"
  "chgnet-backend"
  "gfn2-xtb-backend"
  "tx1-fastapi-backend"
)

echo "Starting sequential build and verification for all backends..."
echo ""

for backend in "${BACKENDS[@]}"; do
  echo "------------------------------------------------------------"
  echo "Processing: $backend"
  echo "------------------------------------------------------------"
  "$SCRIPT_DIR/build-backend.sh" "$backend"
  echo ""
done

echo "============================================================"
echo "All backend images built and verified successfully!"
echo "============================================================"
