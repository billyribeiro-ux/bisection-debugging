#!/usr/bin/env bash
# predicate.sh — <one-line description of what this judges>
# Exit codes follow `git bisect run`: 0=good, 1=bad, 125=skip.
set -uo pipefail   # strict but NOT -e (we handle errors deliberately)

# === 1. SETUP =========================================================
# Restore deps, fixtures, env. Exit 125 on any
# "this commit isn't testable" condition (missing dep, broken build).
pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm build >/dev/null 2>&1                                     || exit 125

# === 2. CLEANUP (registered FIRST, before exercise) ===================
# Whatever we set up below must be torn down even on Ctrl-C.
SERVER_PID=""
cleanup() {
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
  rm -rf /tmp/predicate-scratch.*
}
trap cleanup EXIT INT TERM

# === 3. EXERCISE ======================================================
# Do the thing we're judging.
node dist/server.js &
SERVER_PID=$!
sleep 1   # let server bind

# === 4. OBSERVE =======================================================
# Capture the signal — the one thing that decides pass/fail.
# (-o /dev/null matters: otherwise the body precedes the status code.)
RESPONSE=$(curl -sf -o /dev/null -m 5 -w '%{http_code}' http://localhost:3000/checkout || echo "fail")

# === 5. EXIT ==========================================================
# Translate observation into git bisect's expected codes.
[ "$RESPONSE" = "200" ] && exit 0 || exit 1
