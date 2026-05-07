#!/usr/bin/env bash
set -Eeuo pipefail

PORT="${PORT:-6080}"
URL="${URL:-https://check.torproject.org}"
DISPLAY_NUM="${DISPLAY:-:99}"
VNC_PASSWORD="${VNC_PASSWORD:-}"
SCREEN_SIZE="${SCREEN_SIZE:-1280x800x24}"

cleanup() {
  local code=$?
  jobs -pr | xargs -r kill 2>/dev/null || true
  exit "$code"
}
trap cleanup EXIT INT TERM

wait_for_port() {
  local host="$1"
  local port="$2"
  local name="$3"
  local max_wait="${4:-60}"

  echo "Waiting for ${name} on ${host}:${port}..."
  for _ in $(seq 1 "$max_wait"); do
    if nc -z "$host" "$port" >/dev/null 2>&1; then
      echo "${name} is ready."
      return 0
    fi
    sleep 1
  done

  echo "${name} did not become ready in time."
  return 1
}

echo "Starting Tor..."
tor -f /etc/tor/torrc &
wait_for_port 127.0.0.1 9050 "Tor SOCKS proxy" 90

echo "Starting virtual display ${DISPLAY_NUM}..."
Xvfb "${DISPLAY_NUM}" -screen 0 "${SCREEN_SIZE}" -ac +extension GLX +render -noreset &
sleep 1

echo "Starting VNC server..."
if [[ -n "${VNC_PASSWORD}" ]]; then
  x11vnc -display "${DISPLAY_NUM}" -forever -shared -rfbport 5900 -passwd "${VNC_PASSWORD}" -xkb -quiet &
else
  echo "WARNING: VNC_PASSWORD is not set. This is okay for local testing, but unsafe on a public URL."
  x11vnc -display "${DISPLAY_NUM}" -forever -shared -rfbport 5900 -nopw -xkb -quiet &
fi
wait_for_port 127.0.0.1 5900 "VNC" 30

echo "Starting noVNC on 0.0.0.0:${PORT}..."
/noVNC/utils/novnc_proxy --vnc 127.0.0.1:5900 --listen "0.0.0.0:${PORT}" --web /noVNC &
sleep 1

echo "Launching Chromium through Tor proxy..."
mkdir -p /tmp/chromium-profile
DISPLAY="${DISPLAY_NUM}" chromium \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --disable-software-rasterizer \
  --proxy-server="socks5://127.0.0.1:9050" \
  --host-resolver-rules="MAP * ~NOTFOUND, EXCLUDE 127.0.0.1, EXCLUDE localhost" \
  --user-data-dir=/tmp/chromium-profile \
  --no-first-run \
  --disable-infobars \
  --disable-extensions \
  --window-size=1280,800 \
  --window-position=0,0 \
  "${URL}" &

wait -n
