FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    git \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install bats-core
RUN git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core

# Install Chromium (supports both amd64 and arm64)
RUN apt-get update \
    && apt-get install -y --no-install-recommends chromium chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Copy shellnium
WORKDIR /opt/shellnium
COPY lib/ ./lib/
COPY tests/ ./tests/
COPY demo.sh demo2.sh demo3.sh ./

# Copy entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default to headless mode in container
ENV SHELLNIUM_CHROME_OPTS="--headless --no-sandbox --disable-dev-shm-usage --disable-gpu"

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["demo.sh"]
