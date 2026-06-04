#!/usr/bin/env bash
# ex-2-solution.sh — Exercise 2 model.
set -uo pipefail

pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1 || exit 125

PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("",0));print(s.getsockname()[1]);s.close()')
PORT=$PORT pnpm start & PID=$!
trap "kill $PID 2>/dev/null || true" EXIT

# Wait for readiness
for i in $(seq 1 30); do
  curl -sf "http://localhost:$PORT/health" >/dev/null && break
  sleep 0.5
done

# Check the header (not the body)
CACHE_HEADER=$(curl -sf -I "http://localhost:$PORT/users" | tr -d '\r' | awk -F': ' 'tolower($1)=="cache-control" {print $2}')
echo "Cache-Control: $CACHE_HEADER"

[ "$CACHE_HEADER" = "no-store" ] && exit 0 || exit 1
