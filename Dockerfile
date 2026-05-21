FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base deps + Tauri Linux requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git sudo jq \
    libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf libssl-dev \
    build-essential pkg-config \
    lib32gcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# pnpm
RUN npm install -g pnpm@latest

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install tauri-cli --version "^2" --locked

# GitHub Actions Runner
ARG RUNNER_VERSION=2.325.0
RUN mkdir -p /actions-runner && cd /actions-runner \
    && curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | tar xz \
    && ./bin/installdependencies.sh

COPY entrypoint.sh /actions-runner/entrypoint.sh
RUN chmod +x /actions-runner/entrypoint.sh

WORKDIR /actions-runner
ENTRYPOINT ["/actions-runner/entrypoint.sh"]
