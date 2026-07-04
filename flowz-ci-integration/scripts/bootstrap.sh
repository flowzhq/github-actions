#!/usr/bin/env bash
# Pull the pinned flowz toolchain from GHCR (oras) and install it on PATH.
#
# Inputs via env (set by action.yml):
#   REGISTRY_USER / REGISTRY_TOKEN  — flowzhq-issued GHCR creds (read:packages)
#   FLOWZ_CI_VERSION                — tag of ghcr.io/flowzhq/flowz-ci
#   SCANNER_VERSION                 — tag of ghcr.io/flowzhq/flowz-cli
#   ENRICHER_VERSION                — tag of ghcr.io/flowzhq/fsg-enricher
#                                     (pulled as the -linux-amd64 platform tag)
#   DRY_RUN                         — "true" skips the scanner/enricher pulls
#                                     (a dry-run never invokes them)
#
# GitHub-hosted linux/amd64 runners only for now — binary selection is hardcoded.
set -euo pipefail

err()  { echo -e "\033[0;31m[bootstrap]\033[0m $*" >&2; }
info() { echo -e "\033[0;34m[bootstrap]\033[0m $*" >&2; }

REGISTRY=${REGISTRY:-ghcr.io}
BIN_DIR=${BIN_DIR:-"$HOME/.local/bin"}
mkdir -p "$BIN_DIR"

command -v oras >/dev/null 2>&1 || { err "oras not found (action.yml installs it via oras-project/setup-oras)"; exit 1; }
: "${REGISTRY_USER:?REGISTRY_USER is required (flowzhq GHCR username)}"
: "${REGISTRY_TOKEN:?REGISTRY_TOKEN is required (flowzhq read:packages token)}"

echo "$REGISTRY_TOKEN" | oras login "$REGISTRY" -u "$REGISTRY_USER" --password-stdin >/dev/null
info "logged in to $REGISTRY"

# pull_binary <package:tag> <file-glob> <install-name>
# The flowz OCI artifacts hold platform binaries as plain octet-stream blobs
# (flowz-app ADR-026); pull, pick the linux/amd64 file, install.
pull_binary() {
  local ref="$1" glob="$2" name="$3" tmp bin
  tmp=$(mktemp -d)
  info "oras pull $ref"
  oras pull "$ref" -o "$tmp" || { err "oras pull $ref failed — check the tag exists and your token has read:packages on it"; exit 1; }
  bin=$(find "$tmp" -maxdepth 1 -type f -name "$glob" | head -1)
  [ -n "$bin" ] || { err "no file matching '$glob' in $ref"; ls -la "$tmp" >&2; exit 1; }
  install -m 0755 "$bin" "$BIN_DIR/$name"
  info "installed $name  ← $(basename "$bin")"
}

: "${FLOWZ_CI_VERSION:?FLOWZ_CI_VERSION is required}"
pull_binary "$REGISTRY/flowzhq/flowz-ci:$FLOWZ_CI_VERSION" "flowz-ci_*_linux_amd64" "flowz-ci"

if [ "${DRY_RUN:-false}" = "true" ]; then
  info "dry-run: skipping scanner/enricher pulls"
else
  : "${SCANNER_VERSION:?SCANNER_VERSION is required for real runs — pin a ghcr.io/flowzhq/flowz-cli tag}"
  : "${ENRICHER_VERSION:?ENRICHER_VERSION is required for real runs — pin a ghcr.io/flowzhq/fsg-enricher tag}"
  pull_binary "$REGISTRY/flowzhq/flowz-cli:$SCANNER_VERSION" "flowz_*_linux_amd64" "flowz"
  # fsg-enricher per-platform tag holds a single ~98MB binary (its ADR-002) —
  # never pull the fat tag in CI.
  pull_binary "$REGISTRY/flowzhq/fsg-enricher:${ENRICHER_VERSION}-linux-amd64" "fsg-enricher*" "fsg-enricher"
fi

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$BIN_DIR" >> "$GITHUB_PATH"
  info "$BIN_DIR added to GITHUB_PATH"
fi
