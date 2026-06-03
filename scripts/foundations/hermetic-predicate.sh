#!/usr/bin/env bash
# hermetic-predicate.sh — pin every variable that could shift under us.
set -euo pipefail

# Pin Node, pnpm, locale, timezone, random seed.
export NODE_VERSION="20.18.0"
export PNPM_VERSION="9.12.0"
export LC_ALL=C.UTF-8
export TZ=UTC
export NODE_OPTIONS="--no-warnings"
export VITEST_SEED=42

# Use a deterministic ordering for tests.
export VITEST_SEQUENCE_SHUFFLE=false

# Honor .nvmrc only if it matches the pin; otherwise fail loudly.
if command -v nvm >/dev/null 2>&1; then
  nvm use "$NODE_VERSION" >/dev/null 2>&1 || { echo "Wrong Node"; exit 125; }
fi

# Clean every byproduct cache — caches lie under bisection.
rm -rf node_modules/.vite node_modules/.cache .svelte-kit dist

pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm test --run
