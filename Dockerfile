FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base deps + Tauri Linux requirements + buildah for container builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git sudo jq zip \
    libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf libssl-dev \
    build-essential pkg-config \
    lib32gcc-s1 \
    buildah fuse-overlayfs \
    && rm -rf /var/lib/apt/lists/*

# Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# pnpm (global, available to all users)
RUN npm install -g pnpm@latest

# Runner user (UID 1000 to match k8s securityContext)
RUN useradd -m -s /bin/bash -u 1000 runner

# Buildah rootless config
RUN mkdir -p /home/runner/.config/containers && \
    echo '[storage]' > /home/runner/.config/containers/storage.conf && \
    echo 'driver = "overlay"' >> /home/runner/.config/containers/storage.conf && \
    echo '[storage.options.overlay]' >> /home/runner/.config/containers/storage.conf && \
    echo 'mount_program = "/usr/bin/fuse-overlayfs"' >> /home/runner/.config/containers/storage.conf && \
    chown -R runner:runner /home/runner/.config

# Rust (installed as runner user)
USER runner
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/runner/.cargo/bin:${PATH}"
RUN cargo install tauri-cli --version "^2" --locked

# GitHub Actions Runner (as root for installdependencies, then chown)
USER root
ARG RUNNER_VERSION=2.325.0
RUN mkdir -p /actions-runner && cd /actions-runner \
    && curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | tar xz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner /actions-runner

COPY --chown=runner:runner entrypoint.sh /actions-runner/entrypoint.sh
RUN chmod +x /actions-runner/entrypoint.sh

USER runner
WORKDIR /actions-runner
ENTRYPOINT ["/actions-runner/entrypoint.sh"]
