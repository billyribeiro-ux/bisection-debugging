#!/usr/bin/env bash
# Boot the server in the background, fire k6 against it, threshold p95.
set -uo pipefail

# Start the server.
pnpm start &>/tmp/server.log &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT

# Wait for readiness (10s timeout).
for i in {1..20}; do
  curl -sf http://localhost:3000/health >/dev/null && break
  sleep 0.5
done

# Run a 20-second k6 test.
k6 run --quiet --duration 20s --vus 50 --summary-export=/tmp/k6.json - <<'JS'
import http from 'k6/http';
import { sleep } from 'k6';
export default function () {
  http.get('http://localhost:3000/api/products');
  sleep(0.1);
}
JS

P95_MS=$(jq '.metrics.http_req_duration["p(95)"] | round' /tmp/k6.json)
BUDGET_MS="${API_BUDGET_MS:-200}"
echo "p95 ${P95_MS}ms (budget ${BUDGET_MS}ms)"

(( P95_MS > BUDGET_MS )) && exit 1 || exit 0
