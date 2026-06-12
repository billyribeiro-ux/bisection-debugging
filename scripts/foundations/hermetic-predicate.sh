#!/usr/bin/env bash
# hermetic-predicate.sh — pin every variable that could shift under us.
set -euo pipefail

# Pin locale, timezone, and runtime flags.
export LC_ALL=C.UTF-8
export TZ=UTC
export NODE_OPTIONS="--no-warnings"

# Pin the toolchain by ASSERTING, not by configuring. Version managers like
# nvm are shell FUNCTIONS — they don't exist inside a script, so `nvm use`
# here would silently do nothing. Check the versions you actually got, and
# refuse to judge (125) if they're wrong: never judge in the wrong env.
WANT_NODE="v20.18.0"
WANT_PNPM="9.12.0"
[[ "$(node --version)" == "$WANT_NODE" ]] \
  || { echo "Wrong Node: $(node --version), want $WANT_NODE" >&2; exit 125; }
[[ "$(pnpm --version)" == "$WANT_PNPM" ]] \
  || { echo "Wrong pnpm: $(pnpm --version), want $WANT_PNPM" >&2; exit 125; }

# Clean every byproduct cache — caches lie under bisection.
rm -rf node_modules/.vite node_modules/.cache .svelte-kit dist

pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125

# Deterministic ordering and seed — these are CLI flags, not env vars.
pnpm exec vitest run --sequence.shuffle=false --sequence.seed=42
