#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_NAME="tor-session-interactive"
PORT="${PORT:-6080}"
URL="${URL:-https://check.torproject.org}"
SCREEN_SIZE="${SCREEN_SIZE:-1365x768x24}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required. Install Docker Desktop, then run this again."
  exit 1
fi

if command -v open >/dev/null 2>&1; then
  (sleep 5 && open "http://localhost:${PORT}/vnc.html?autoconnect=true&resize=scale&reconnect=true&show_dot=true&view_only=false&quality=9&compression=2") >/dev/null 2>&1 &
fi

echo "Building ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" .

echo "Starting interactive browser at http://localhost:${PORT}"
echo "After the noVNC page opens, click inside the browser once before typing."
echo "Press Ctrl+C to stop."

docker run --rm -it \
  -p "${PORT}:${PORT}" \
  -e PORT="${PORT}" \
  -e URL="${URL}" \
  -e SCREEN_SIZE="${SCREEN_SIZE}" \
  -e VNC_PASSWORD="${VNC_PASSWORD:-}" \
  "${IMAGE_NAME}"
