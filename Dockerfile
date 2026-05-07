FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    chromium \
    fonts-liberation \
    git \
    netcat-openbsd \
    tor \
    x11vnc \
    xvfb \
    python3 \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/novnc/noVNC.git /noVNC \
    && git clone --depth 1 https://github.com/novnc/websockify.git /noVNC/utils/websockify

COPY torrc /etc/tor/torrc
COPY start.sh /usr/local/bin/start.sh
COPY index.html /noVNC/index.html

RUN chmod +x /usr/local/bin/start.sh

EXPOSE 6080

CMD ["/usr/local/bin/start.sh"]
