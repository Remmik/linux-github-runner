# GitHub Actions Runner

Self-hosted GitHub Actions runner image with Tauri build dependencies.

Based on Ubuntu 22.04 with Node 24, pnpm, Rust (stable), Tauri CLI v2, and WebKit/GTK development libraries.

## What's included

- Ubuntu 22.04 (Jammy)
- Node.js 24 + pnpm
- Rust stable + Tauri CLI v2
- libwebkit2gtk-4.1-dev and other Tauri Linux deps
- GitHub Actions Runner

## Usage (Kubernetes)

```yaml
containers:
  - name: runner
    image: ghcr.io/saturate/github-runner:latest
    env:
      - name: GITHUB_TOKEN
        value: "ghp_..."
      - name: GITHUB_REPOSITORY
        value: "Saturate/overhead"
      - name: RUNNER_NAME
        value: "k3s-linux"
      - name: RUNNER_LABELS
        value: "self-hosted,Linux,X64"
```

## Usage (Docker)

```bash
docker run -d \
  -e GITHUB_TOKEN=ghp_... \
  -e GITHUB_REPOSITORY=Saturate/overhead \
  -e RUNNER_NAME=my-runner \
  ghcr.io/saturate/github-runner:latest
```
