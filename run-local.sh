#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_NAME="tor-session-test"
PORT="${PORT:-6080}"
URL="${URL:-https://check.torproject.org}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required. Install Docker Desktop, then run this again."
  exit 1
fi

echo "Building ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" .

echo "Starting at http://localhost:${PORT}"
echo "Press Ctrl+C to stop."
docker run --rm -it \
  -p "${PORT}:${PORT}" \
  -e PORT="${PORT}" \
  -e URL="${URL}" \
  -e VNC_PASSWORD="${VNC_PASSWORD:-}" \
  "${IMAGE_NAME}"
