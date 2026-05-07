# Tor Session Test

A minimal Docker app that runs Chromium through Tor and exposes the browser through noVNC.

## What changed

- Replaced the broken/empty Python path.
- Made the Dockerfile simpler and more portable by using Debian Chromium.
- Copied the real `index.html` into noVNC instead of duplicating HTML inside the Dockerfile.
- Added a one-command local runner.
- Added a clean dark landing page.
- Added a direct local launcher: `open-local.html`.
- Kept Render deployment support with `render.yaml`.

## Run locally

Install Docker Desktop first.

Then run:

```bash
./run-local.sh
```

Open:

```text
http://localhost:6080
```

Or double-click:

```text
open-local.html
```

The local launcher only works after the Docker container is running.

## Change the starting page

```bash
URL="https://example.com" ./run-local.sh
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
