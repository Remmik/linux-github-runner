#!/bin/bash
set -e

if [ -z "$GITHUB_TOKEN" ]; then echo "GITHUB_TOKEN required"; exit 1; fi
if [ -z "$GITHUB_REPOSITORY" ]; then echo "GITHUB_REPOSITORY required"; exit 1; fi

RUNNER_NAME="${RUNNER_NAME:-k3s-linux}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,Linux,X64}"

# Ensure runner user owns the work directory
chown -R runner:runner /actions-runner

# Get registration token
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq -r .token)

# Configure as runner user (runner refuses root)
su runner -c "./config.sh --url 'https://github.com/${GITHUB_REPOSITORY}' \
  --token '$REG_TOKEN' \
  --name '$RUNNER_NAME' \
  --labels '$RUNNER_LABELS' \
  --unattended --replace"

# Cleanup on exit
cleanup() {
  echo "Removing runner..."
  su runner -c "./config.sh remove --token '$REG_TOKEN'" || true
}
trap cleanup EXIT

# Run as runner user (workflow steps inherit this UID, but sudo is available for buildah)
su runner -c "./run.sh"
