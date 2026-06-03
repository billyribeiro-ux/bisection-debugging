#!/usr/bin/env bash
# Reproduce the CI bisection locally. Keeps logs in ~/.cache/bisect/.
set -euo pipefail

BAD="${1:-HEAD}"
GOOD="${2:?usage: $0 <bad> <good>}"
LOG=~/.cache/bisect/run-$(date +%Y%m%d-%H%M%S)
mkdir -p "$LOG"

git bisect start "$BAD" "$GOOD"
git bisect run bash -c '
  set -uo pipefail
  pnpm install --frozen-lockfile --prefer-offline > "'"$LOG"'/install.$(git rev-parse --short HEAD).log" 2>&1 || exit 125
  pnpm build > "'"$LOG"'/build.$(git rev-parse --short HEAD).log" 2>&1 || exit 125
  pnpm e2e --reporter=line > "'"$LOG"'/e2e.$(git rev-parse --short HEAD).log" 2>&1
' 2>&1 | tee "$LOG/bisect.log"
git bisect reset
echo "Logs: $LOG"
