#!/usr/bin/env bash
# session-replay-bisect.sh
# Replay the first N requests of a captured session; bisect N to find the
# request that triggers cumulative slowness.
#
# Capture format: a JSONL file where each line is { method, path, body, headers }.
set -euo pipefail

SESSION="${1:?usage: $0 <session.jsonl> <slowness-threshold-ms>}"
THRESHOLD="${2:-2000}"

N=$(wc -l < "$SESSION")
echo "Session has $N requests"

replay_and_measure() {
  local count="$1"
  # Spawn a fresh server, replay $count requests, then time the (count+1)th.
  pnpm start &> /tmp/svr.log & SVR=$!
  trap "kill $SVR 2>/dev/null" RETURN
  sleep 1
  head -n "$count" "$SESSION" | jq -c '.' | while read req; do
    curl -sf -X "$(echo "$req" | jq -r .method)" \
         -H "Content-Type: application/json" \
         -d "$(echo "$req" | jq -r .body)" \
         "http://localhost:3000$(echo "$req" | jq -r .path)" >/dev/null
  done
  # Measure the next request.
  local probe="$(sed -n "$((count + 1))p" "$SESSION")"
  local ms=$(curl -sf -o /dev/null -w '%{time_total}' \
       -X "$(echo "$probe" | jq -r .method)" \
       "http://localhost:3000$(echo "$probe" | jq -r .path)" \
       | awk '{print $1 * 1000}')
  echo "$ms"
}

lo=0; hi=$((N - 1))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  ms=$(replay_and_measure "$mid")
  echo "after $mid requests: probe=${ms%.*}ms"
  if (( ${ms%.*} > THRESHOLD )); then hi=$mid; else lo=$((mid + 1)); fi
done
echo "Slowness manifests after request #$lo:"
sed -n "${lo}p" "$SESSION"
