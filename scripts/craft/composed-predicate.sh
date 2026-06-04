#!/usr/bin/env bash
# Smoke + assertion composed.
set -uo pipefail
pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1 || exit 125

PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("",0));print(s.getsockname()[1]);s.close()')
PORT=$PORT pnpm start & PID=$!
trap "kill $PID 2>/dev/null || true" EXIT
for i in $(seq 1 30); do curl -sf "http://localhost:$PORT/health" && break; sleep 0.5; done

# Smoke: did the endpoint return 200?
HTTP=$(curl -sf -o /tmp/body -w '%{http_code}' "http://localhost:$PORT/api/checkout?amount=100" || echo 000)
[ "$HTTP" = "200" ] || exit 1

# Assertion: did the body match the expected shape?
jq -e '.tax == 8.5 and .total == 108.5' /tmp/body >/dev/null
