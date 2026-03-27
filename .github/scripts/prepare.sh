#!/usr/bin/env bash
set -euo pipefail

# prepare.sh for stryker-mutator/stryker-mutator.github.io
# Docusaurus 3.9.2, pnpm@10.32.1, Node 24
# Clones the repo and installs dependencies. Does NOT run write-translations or build.

REPO_URL="https://github.com/stryker-mutator/stryker-mutator.github.io"
BRANCH="develop"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    echo "[INFO] Cloning repository..."
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
else
    echo "[INFO] source-repo already exists, skipping clone."
fi

cd "$REPO_DIR"

# --- Dependencies ---
echo "[INFO] Installing dependencies (postinstall will run clone_docs.sh)..."
pnpm install --frozen-lockfile

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."
