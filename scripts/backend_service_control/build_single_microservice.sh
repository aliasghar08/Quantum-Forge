#!/usr/bin/env bash
# ============================================================================
# Quantum Forge — Build and Verify Backend Docker Image
# ----------------------------------------------------------------------------
# Usage:
#   ./scripts/build-backend.sh <backend-folder>
#
# Examples:
#   ./scripts/build-backend.sh mace-backend
#   ./scripts/build-backend.sh tx1-fastapi-backend
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKEND="$1"

if [[ -z "$BACKEND" ]]; then
  echo "Usage: $0 <backend-folder>"
  echo ""
  echo "Available backends:"
  echo "  - mace-backend"
  echo "  - ani2x-backend"
  echo "  - chgnet-backend"
  echo "  - gfn2-xtb-backend"
  echo "  - tx1-fastapi-backend"
  exit 1
fi

BACKEND_DIR="$REPO_ROOT/$BACKEND"

# 1. Verify folder exists and contains a Dockerfile
if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Error: Backend folder '$BACKEND' does not exist under $REPO_ROOT."
  exit 1
fi

if [[ ! -f "$BACKEND_DIR/Dockerfile" ]]; then
  echo "Error: No Dockerfile found in '$BACKEND_DIR'."
  exit 1
fi

# Verify Docker availability
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: 'docker' command is not available on PATH."
  echo "Docker is required to build and verify backend container images."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon is not running. Please start Docker first."
  exit 1
fi

# Determine host port
resolve_port() {
  local target="$1"
  case "$target" in
    mace-backend) echo 8001 ;;
    ani2x-backend) echo 8002 ;;
    chgnet-backend) echo 8003 ;;
    gfn2-xtb-backend) echo 8004 ;;
    tx1-fastapi-backend) echo 8005 ;;
    *) echo 8000 ;;
  esac
}

PORT=$(resolve_port "$BACKEND")
IMAGE_TAG="quantum-forge/${BACKEND}:local"

echo "============================================================"
echo "Building $IMAGE_TAG from $BACKEND/"
echo "Target port: $PORT (mapped to container port 8000)"
echo "============================================================"

# 2. Build the Docker image
docker build -t "$IMAGE_TAG" "$BACKEND_DIR"

# 3. Run the image in background
echo "Starting container for verification on port $PORT..."
CONTAINER_ID=$(docker run --rm -d -p "${PORT}:8000" "$IMAGE_TAG")

cleanup() {
  if [[ -n "$CONTAINER_ID" ]] && docker ps -q --no-trunc | grep -q "$CONTAINER_ID"; then
    echo "Stopping verification container $CONTAINER_ID..."
    docker stop -t 5 "$CONTAINER_ID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

# 4. Wait up to 90 seconds for /health to return "status":"ok"
TIMEOUT=90
ELAPSED=0
SUCCESS=false

echo "Waiting up to ${TIMEOUT}s for http://127.0.0.1:${PORT}/health to report ok..."

while [[ $ELAPSED -lt $TIMEOUT ]]; do
  # Check if container died unexpectedly
  if ! docker ps -q --no-trunc | grep -q "$CONTAINER_ID"; then
    echo "Error: Container stopped unexpectedly before becoming ready."
    echo "Container logs:"
    docker logs "$CONTAINER_ID" 2>&1 || true
    exit 1
  fi

  RESPONSE=$(curl -s --connect-timeout 2 --max-time 3 "http://127.0.0.1:${PORT}/health" 2>/dev/null || true)

  if echo "$RESPONSE" | grep -qE '"status"[[:space:]]*:[[:space:]]*"ok"'; then
    SUCCESS=true
    break
  fi

  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

if [[ "$SUCCESS" == false ]]; then
  echo ""
  echo "Error: Backend '$BACKEND' failed to become ready within ${TIMEOUT} seconds."
  echo "Last response from /health: $RESPONSE"
  echo ""
  echo "Last 30 lines of container logs:"
  docker logs --tail 30 "$CONTAINER_ID" 2>&1 || true
  exit 1
fi

echo "Backend '$BACKEND' is healthy!"

# 5. Grep container logs for the [MLIP] line and print it
echo "Verifying weight source in container stdout..."
MLIP_LOG=$(docker logs "$CONTAINER_ID" 2>&1 | grep "\[MLIP\]" || true)

if [[ -n "$MLIP_LOG" ]]; then
  echo "$MLIP_LOG"
else
  echo "Notice: No [MLIP] log line found. Full container logs:"
  docker logs --tail 20 "$CONTAINER_ID" 2>&1
fi

# 6. Stop the container
echo "Stopping container..."
docker stop -t 5 "$CONTAINER_ID" >/dev/null 2>&1 || true
CONTAINER_ID="" # Clear so trap doesn't repeat

echo "Container $IMAGE_TAG stopped cleanly."
