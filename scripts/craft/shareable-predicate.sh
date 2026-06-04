#!/usr/bin/env bash
# ============================================================================
# checkout-latency-predicate.sh
# ----------------------------------------------------------------------------
# PURPOSE
#   Detects the commit at which p99 latency of GET /checkout exceeded 300 ms.
#   Originally written to find the regression introduced ~2026-04-15.
#
# CONTRACT
#   exit 0   → p99 of 20 sequential requests < 300 ms
#   exit 1   → p99 ≥ 300 ms
#   exit 125 → environment problem; commit is untestable (build/install failed,
#              server didn't start, > 25% of measurement requests failed)
#
# INPUTS (environment variables — all optional)
#   THRESHOLD_SEC   default 0.3 — the p99 threshold in seconds
#   N_SAMPLES       default 20  — how many request measurements per round
#   READY_TIMEOUT_S default 15  — how long to wait for server readiness
#
# EXAMPLE
#   git bisect start HEAD release-2026-04-15 -- services/checkout/
#   git bisect run ./checkout-latency-predicate.sh
#
# SELF-TEST
#   ./checkout-latency-predicate.sh --check
#     runs the predicate against known-good (a3f9c81) and known-bad (e7b2a91)
#     and verifies the expected exit codes. Exit 0 if predicate is calibrated.
#
# KNOWN FAILURE MODES
#   - If pnpm registry is unreachable, install fails → exit 125 (correct).
#   - If port 3000 was already in use by a stuck process, the server may
#     start on the random port but `kill` of the previous one may leak a
#     socket; rerun the bisection in a fresh shell.
#   - If you bisect across commits that pre-date the introduction of
#     /health, the readiness loop times out — set READY_TIMEOUT_S=60
#     and accept slower rounds.
#
# AUTHOR & HISTORY
#   alex.chen@example.com — initial — 2026-06-04
#   maintained by @perf-eng-team
# ============================================================================
set -uo pipefail

THRESHOLD_SEC="${THRESHOLD_SEC:-0.3}"
N_SAMPLES="${N_SAMPLES:-20}"
READY_TIMEOUT_S="${READY_TIMEOUT_S:-15}"

# --- Self-test mode -------------------------------------------------------
if [ "${1:-}" = "--check" ]; then
  declare -a CHECKS=( "a3f9c81:0" "e7b2a91:1" )
  for c in "${CHECKS[@]}"; do
    sha="${c%:*}" expected="${c#*:}"
    git checkout -q "$sha" || { echo "skip: can't checkout $sha"; continue; }
    "$0" >/dev/null 2>&1
    got=$?
    [ "$got" = "$expected" ] || { echo "FAIL $sha expected $expected got $got"; exit 1; }
  done
  echo "Calibration OK"; exit 0
fi

# --- Setup ---------------------------------------------------------------
pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1                                     || exit 125

# --- Cleanup registered first --------------------------------------------
PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("",0));print(s.getsockname()[1]);s.close()')
SERVER_PID=""
SCRATCH=$(mktemp -d)
cleanup() {
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$SCRATCH"
}
trap cleanup EXIT INT TERM

# --- Exercise ------------------------------------------------------------
PORT=$PORT node dist/server.js > "$SCRATCH/server.log" 2>&1 &
SERVER_PID=$!

READY=0
for _ in $(seq 1 $((READY_TIMEOUT_S * 2))); do
  curl -sf "http://localhost:$PORT/health" >/dev/null && { READY=1; break; }
  sleep 0.5
done
[ "$READY" = "0" ] && { echo "server failed to start"; cat "$SCRATCH/server.log"; exit 125; }

# --- Observation ---------------------------------------------------------
declare -a measurements=()
fails=0
for i in $(seq 1 "$N_SAMPLES"); do
  out=$(curl -sf -o /dev/null -m 5 -w '%{http_code} %{time_total}\n' \
        "http://localhost:$PORT/checkout" || echo "000 0")
  code=$(echo "$out" | awk '{print $1}')
  ms=$(echo "$out"   | awk '{print $2}')
  [ "$code" = "200" ] && measurements+=("$ms") || fails=$((fails + 1))
done

# --- Exit ----------------------------------------------------------------
if [ "$fails" -gt $((N_SAMPLES / 4)) ]; then
  echo "too many fails ($fails/$N_SAMPLES) — untestable"; exit 125
fi

p99=$(printf '%s\n' "${measurements[@]}" | sort -n \
      | awk -v n="$((${#measurements[@]} * 99 / 100))" 'NR==n+1')
echo "p99 = ${p99}s (threshold ${THRESHOLD_SEC}s, fails ${fails}/${N_SAMPLES})"

awk -v p="$p99" -v t="$THRESHOLD_SEC" 'BEGIN { exit (p < t ? 0 : 1) }'
