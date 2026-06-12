#!/usr/bin/env bash
# Perf-budget predicate. Returns 0 if p99 of N measurements is under THRESHOLD.
set -uo pipefail
THRESHOLD_SEC="${THRESHOLD:-0.5}"
SAMPLES="${SAMPLES:-20}"

pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1 || exit 125

# Use hyperfine for warm-cache statistical perf measurement.
# hyperfine is a Rust binary (brew/apt/cargo install hyperfine) — it is
# NOT on npm, so no pnpm dlx here.
command -v hyperfine >/dev/null || exit 125
hyperfine -m "$SAMPLES" --warmup 3 --export-json /tmp/perf.json \
  "node dist/run-benchmark.mjs" >/dev/null

p99=$(node -e "
  const d = JSON.parse(require('fs').readFileSync('/tmp/perf.json'));
  const t = d.results[0].times.sort((a,b)=>a-b);
  console.log(t[Math.floor(t.length * 0.99)]);
")
echo "p99 = ${p99}s threshold=${THRESHOLD_SEC}s"
awk -v p="$p99" -v t="$THRESHOLD_SEC" 'BEGIN { exit (p < t ? 0 : 1) }'
