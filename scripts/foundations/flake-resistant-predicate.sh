#!/usr/bin/env bash
# flake-resistant-predicate.sh
# Runs the test up to 5 times. Calls it "good" only if it passes ≥4 times.
# Exit codes follow `git bisect run` convention:
#   0   = good
#   1   = bad
#   125 = skip (cannot determine — e.g. build itself broken)
set -uo pipefail

RUNS=5
THRESHOLD=4
passes=0

# Refuse to judge if the build is broken — that's a "skip", not a "bad".
if ! pnpm install --frozen-lockfile >/dev/null 2>&1; then exit 125; fi
if ! pnpm build >/dev/null 2>&1; then exit 125; fi

for i in $(seq 1 "$RUNS"); do
  if pnpm test --run --bail 1 >/dev/null 2>&1; then
    passes=$((passes + 1))
  fi
done

if (( passes >= THRESHOLD )); then exit 0; else exit 1; fi
