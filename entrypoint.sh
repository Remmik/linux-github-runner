#!/bin/bash
set -e

if [ -z "$GITHUB_TOKEN" ]; then echo "GITHUB_TOKEN required"; exit 1; fi
if [ -z "$GITHUB_REPOSITORY" ]; then echo "GITHUB_REPOSITORY required"; exit 1; fi

RUNNER_NAME="${RUNNER_NAME:-k3s-linux}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,Linux,X64}"

# Get registration token
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq -r .token)

export RUNNER_ALLOW_RUNASROOT=1

# Configure
./config.sh --url "https://github.com/${GITHUB_REPOSITORY}" \
  --token "$REG_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended --replace

# Cleanup on exit
cleanup() {
  echo "Removing runner..."
  ./config.sh remove --token "$REG_TOKEN" || true
}
trap cleanup EXIT

# Run
./run.sh
