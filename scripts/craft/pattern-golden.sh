#!/usr/bin/env bash
# Compares the current commit's output to a frozen "golden" file.
# Use when you can't reduce the bug to a single assertion.
set -uo pipefail

GOLDEN="${GOLDEN:?path to golden file from a known-good commit}"

pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1 || exit 125

# Produce output for THIS commit, normalize (strip timestamps, sort lines, etc.)
pnpm exec node dist/produce-report.mjs --input fixture.json \
  | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z/[TIME]/g' \
  | sort > /tmp/actual.txt

# Compare. diff returns 0 if files match.
diff -q /tmp/actual.txt "$GOLDEN" >/dev/null
