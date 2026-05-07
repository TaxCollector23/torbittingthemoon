#!/usr/bin/env bash
set -Eeuo pipefail

PORT="${PORT:-6080}"
URL="${URL:-https://check.torproject.org}"
DISPLAY_NUM="${DISPLAY:-:99}"
VNC_PASSWORD="${VNC_PASSWORD:-}"
SCREEN_SIZE="${SCREEN_SIZE:-1365x768x24}"
CHROME_PROFILE="${CHROME_PROFILE:-/tmp/chromium-profile}"

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

wait_for_x() {
  echo "Waiting for X display ${DISPLAY_NUM}..."
  for _ in $(seq 1 40); do
    if DISPLAY="${DISPLAY_NUM}" xdpyinfo >/dev/null 2>&1; then
      echo "X display is ready."
      return 0
    fi
    sleep 0.25
  done
  echo "X display did not become ready."
  return 1
}

width="${SCREEN_SIZE%%x*}"
rest="${SCREEN_SIZE#*x}"
height="${rest%%x*}"

export DISPLAY="${DISPLAY_NUM}"
export NO_AT_BRIDGE=1
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-/dev/null}"

mkdir -p "${CHROME_PROFILE}"
mkdir -p /root/.config/openbox

cat > /root/.config/openbox/rc.xml <<'OPENBOXRC'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
  </focus>
</openbox_config>
OPENBOXRC

printf "Starting Tor...\n"
tor -f /etc/tor/torrc &
wait_for_port 127.0.0.1 9050 "Tor SOCKS proxy" 90

printf "Starting virtual display %s at %s...\n" "${DISPLAY_NUM}" "${SCREEN_SIZE}"
Xvfb "${DISPLAY_NUM}" -screen 0 "${SCREEN_SIZE}" -ac +extension GLX +render -noreset &
wait_for_x

printf "Starting Openbox window manager...\n"
openbox >/tmp/openbox.log 2>&1 &
sleep 1

printf "Starting VNC server with keyboard and mouse input enabled...\n"
if [[ -n "${VNC_PASSWORD}" ]]; then
  x11vnc \
    -display "${DISPLAY_NUM}" \
    -forever \
    -shared \
    -rfbport 5900 \
    -listen 0.0.0.0 \
    -passwd "${VNC_PASSWORD}" \
    -xkb \
    -repeat \
    -noxrecord \
    -noxfixes \
    -noxdamage \
    -cursor arrow \
    -quiet &
else
  echo "WARNING: VNC_PASSWORD is not set. This is okay for local testing only."
  x11vnc \
    -display "${DISPLAY_NUM}" \
    -forever \
    -shared \
    -rfbport 5900 \
    -listen 0.0.0.0 \
    -nopw \
    -xkb \
    -repeat \
    -noxrecord \
    -noxfixes \
    -noxdamage \
    -cursor arrow \
    -quiet &
fi
wait_for_port 127.0.0.1 5900 "VNC" 30

printf "Starting noVNC on 0.0.0.0:%s...\n" "${PORT}"
/noVNC/utils/novnc_proxy --vnc 127.0.0.1:5900 --listen "0.0.0.0:${PORT}" --web /noVNC &
wait_for_port 127.0.0.1 "${PORT}" "noVNC" 30

printf "Launching Chromium through Tor proxy...\n"
chromium \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --disable-features=TranslateUI \
  --proxy-server="socks5://127.0.0.1:9050" \
  --host-resolver-rules="MAP * ~NOTFOUND, EXCLUDE 127.0.0.1, EXCLUDE localhost" \
  --user-data-dir="${CHROME_PROFILE}" \
  --no-first-run \
  --disable-infobars \
  --window-size="${width},${height}" \
  --window-position=0,0 \
  --start-maximized \
  "${URL}" >/tmp/chromium.log 2>&1 &

cat <<EOF2

Ready.
Open this in Chrome:
  http://localhost:${PORT}/vnc.html?autoconnect=true&resize=scale&reconnect=true&show_dot=true&view_only=false&quality=9&compression=2

Click inside the noVNC screen once before typing.
EOF2

wait -n
