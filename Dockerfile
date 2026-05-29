FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base deps + Tauri Linux requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg git sudo jq zip \
    libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf libssl-dev \
    build-essential pkg-config \
    lib32gcc-s1 \
    uidmap \
    && rm -rf /var/lib/apt/lists/*

# Buildah from Kubic (v1.30+, supports --isolation chroot without CLONE_NEWUSER)
RUN . /etc/os-release && \
    curl -fsSL "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_${VERSION_ID}/Release.key" \
      | gpg --dearmor -o /usr/share/keyrings/kubic.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubic.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_${VERSION_ID}/ /" \
      > /etc/apt/sources.list.d/kubic.list && \
    apt-get update && apt-get install -y --no-install-recommends buildah && \
    rm -rf /var/lib/apt/lists/*

# Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# pnpm (global, available to all users)
RUN npm install -g pnpm@latest

# Runner user (UID 1000, passwordless sudo for buildah)
RUN useradd -m -s /bin/bash -u 1000 runner && \
    echo "runner:100000:65536" >> /etc/subuid && \
    echo "runner:100000:65536" >> /etc/subgid && \
    echo "runner ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/runner

# Buildah config for unprivileged k3s pods (no CLONE_NEWUSER available).
# Uses vfs storage (no overlayfs) and chroot isolation (no user namespaces).
RUN mkdir -p /home/runner/.config/containers && \
    printf '[storage]\ndriver = "vfs"\n' > /home/runner/.config/containers/storage.conf && \
    chown -R runner:runner /home/runner/.config
ENV BUILDAH_ISOLATION=chroot

# Rust (installed as runner user)
USER runner
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/runner/.cargo/bin:${PATH}"
RUN cargo install tauri-cli --version "^2" --locked

# GitHub Actions Runner (as root for installdependencies, then chown)
USER root
ARG RUNNER_VERSION=2.334.0
RUN mkdir -p /actions-runner && cd /actions-runner \
    && curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | tar xz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner /actions-runner

COPY --chown=runner:runner entrypoint.sh /actions-runner/entrypoint.sh
RUN chmod +x /actions-runner/entrypoint.sh

WORKDIR /actions-runner
ENTRYPOINT ["/actions-runner/entrypoint.sh"]
