#!/usr/bin/env bash
# perf-bisect-predicate.sh
# Returns 0 (good) if benchmark p50 ≤ BUDGET_MS, 1 (bad) if over, 125 if can't run.
# Designed for `git bisect run`.
#
# REQUIREMENTS: hyperfine, jq.
set -uo pipefail

BUDGET_MS="${BUDGET_MS:-10000}"
COMMAND="${COMMAND:-pnpm build}"
WARMUPS=3
RUNS=5

# Skip if install/build can't even start.
pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125

# Run the benchmark; emit JSON for jq.
if ! hyperfine --warmup "$WARMUPS" --runs "$RUNS" --export-json /tmp/bench.json \
     "$COMMAND" >/tmp/bench.log 2>&1; then
  exit 125
fi

# hyperfine reports mean/median in seconds.
P50_MS=$(jq '.results[0].median * 1000 | round' /tmp/bench.json)
echo "median: ${P50_MS} ms (budget ${BUDGET_MS} ms)"

if (( P50_MS > BUDGET_MS )); then exit 1; else exit 0; fi
