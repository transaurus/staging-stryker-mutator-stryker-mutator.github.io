#!/usr/bin/env bash
set -euo pipefail

# rebuild.sh for stryker-mutator/stryker-mutator.github.io
# Docusaurus 3.9.2, pnpm@10.32.1, Node 24
# Runs on existing source tree (no clone). Installs deps and builds.
# Does NOT run write-translations.

# --- Node version ---
echo "[INFO] Setting up Node 24 via n..."
export N_PREFIX="/tmp/n-stryker"
n install 24
export PATH="/tmp/n-stryker/bin:$PATH"
echo "[INFO] Node version: $(node -v)"

# --- Package manager ---
echo "[INFO] Setting up pnpm@10.32.1 via corepack..."
corepack enable
corepack prepare pnpm@10.32.1 --activate
echo "[INFO] pnpm version: $(pnpm --version)"

# --- Dependencies ---
echo "[INFO] Installing dependencies..."
pnpm install --frozen-lockfile

# --- Build ---
echo "[INFO] Running build..."
pnpm run build

echo "[DONE] Build complete."
