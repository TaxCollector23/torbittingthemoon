# Tor Session Interactive Test

A minimal Docker app that runs Chromium through Tor and exposes the browser through noVNC.

This version is configured for normal interaction: mouse, keyboard, clicking, typing, searching, and browsing.

## What was fixed

- Added Openbox so Chromium has a real window manager and can reliably receive focus.
- Set noVNC links to interactive mode, not view-only mode.
- Strengthened x11vnc input flags for keyboard repeat, XKB, cursor, and reduced X damage/input glitches.
- Added a local launcher that opens the noVNC session directly.
- Kept the clean dark landing page.

## Run locally

Install Docker Desktop first.

Then run:

```bash
./run-local.sh
```

It should open your browser automatically. If not, open:

```text
http://localhost:6080/vnc.html?autoconnect=true&resize=scale&reconnect=true&show_dot=true&view_only=false&quality=9&compression=2
```

## How to interact

1. Wait until Chromium appears.
2. Click once inside the noVNC screen.
3. Click the Chromium address bar.
4. Type normally.

## Change the starting page

```bash
URL="https://duckduckgo.com" ./run-local.sh
```

## Change screen size

```bash
SCREEN_SIZE="1440x900x24" ./run-local.sh
```

## Deploy on Render

1. Push this folder to GitHub.
2. In Render, create a new Blueprint or Web Service.
3. Use Docker environment.
4. Render will use `render.yaml`.

## Security warning

This is for testing. If deployed publicly, protect it. Without access controls, anyone with the URL may be able to use the browser session.

For slightly safer testing, set a VNC password:

```bash
VNC_PASSWORD="change-this" ./run-local.sh
```

If you set a password on Render, noVNC will prompt for it when connecting.
