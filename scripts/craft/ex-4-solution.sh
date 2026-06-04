#!/usr/bin/env bash
# ex-4-solution.sh — Exercise 4 model.
set -uo pipefail
THRESHOLD_KB="${THRESHOLD_KB:-300}"

pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125

# Build to dist/
rm -rf dist
pnpm build >/dev/null 2>&1 || exit 125

# Sum up gzipped sizes of all .js files in dist/
TOTAL_BYTES=$(find dist -name '*.js' -exec sh -c 'gzip -c "$1" | wc -c' _ {} \; | awk '{s+=$1} END {print s}')
TOTAL_KB=$((TOTAL_BYTES / 1024))
echo "Gzipped JS total: ${TOTAL_KB} KB (threshold ${THRESHOLD_KB} KB)"

[ "$TOTAL_KB" -lt "$THRESHOLD_KB" ] && exit 0 || exit 1
