#!/usr/bin/env bash
# checkout-latency-bisect.sh
# Identifies the commit at which p99 of GET /checkout exceeded 300 ms.
# Exit: 0 = good (p99 < 300ms), 1 = bad (p99 ≥ 300ms), 125 = untestable.
set -uo pipefail

# --- SETUP ---
pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1                                     || exit 125

# --- CLEANUP (registered before exercise) ---
PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("",0));print(s.getsockname()[1]);s.close()')
SERVER_PID=""
SCRATCH=$(mktemp -d)
cleanup() {
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$SCRATCH"
}
trap cleanup EXIT INT TERM

# --- EXERCISE: spin up server ---
PORT=$PORT node dist/server.js > "$SCRATCH/server.log" 2>&1 &
SERVER_PID=$!

# Wait for readiness
READY=0
for i in $(seq 1 30); do
  curl -sf "http://localhost:$PORT/health" >/dev/null && { READY=1; break; }
  sleep 0.5
done
if [ "$READY" = "0" ]; then
  echo "Server failed to start; logs:"; cat "$SCRATCH/server.log"
  exit 125
fi

# --- EXERCISE + OBSERVE: 20 measurements ---
declare -a measurements=()
fails=0
for i in $(seq 1 20); do
  out=$(curl -sf -o /dev/null -m 5 -w '%{http_code} %{time_total}\n' \
        "http://localhost:$PORT/checkout" || echo "000 0")
  code=$(echo "$out" | awk '{print $1}')
  ms=$(echo "$out"   | awk '{print $2}')
  [ "$code" = "200" ] && measurements+=("$ms") || fails=$((fails + 1))
done

# --- EXIT ---
[ "$fails" -gt 5 ] && { echo "Too many failures ($fails/20) — skip"; exit 125; }

p99=$(printf '%s\n' "${measurements[@]}" | sort -n | tail -n 2 | head -n 1)
echo "p99 = ${p99}s  fails = ${fails}/20"

awk -v p="$p99" 'BEGIN { exit (p < 0.3 ? 0 : 1) }'
