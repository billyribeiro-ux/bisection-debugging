#!/usr/bin/env bash
set -uo pipefail
pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1 || exit 125

PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("",0));print(s.getsockname()[1]);s.close()')
PORT=$PORT pnpm start &
PID=$!
trap "kill $PID 2>/dev/null || true" EXIT

# Wait for readiness
for i in $(seq 1 30); do
  curl -sf "http://localhost:$PORT/health" >/dev/null && break
  sleep 0.5
done

# The one smoke check
curl -sf -o /dev/null -m 5 "http://localhost:$PORT/api/users/1"
