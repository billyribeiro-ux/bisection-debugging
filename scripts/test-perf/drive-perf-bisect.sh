#!/usr/bin/env bash
# Find the commit that crossed the performance budget.
set -euo pipefail

BAD="${1:-HEAD}"
GOOD="${2:?usage: $0 <bad> <good> [budget-ms] [command]}"
BUDGET_MS="${3:-10000}"
COMMAND="${4:-pnpm build}"

export BUDGET_MS COMMAND

git bisect start "$BAD" "$GOOD"
git bisect run ./perf-bisect-predicate.sh | tee /tmp/perf-bisect.log
git bisect reset
