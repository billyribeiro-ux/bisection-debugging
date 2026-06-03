#!/usr/bin/env bash
# flaky-test-bisect.sh
# Find which earlier test pollutes global state and makes a suspect test flake.
#
# USAGE:
#   ./flaky-test-bisect.sh tests/auth/session.test.ts
#
# OUTPUT:
#   Path of the polluting test file.
#
set -euo pipefail

SUSPECT="${1:?usage: $0 <suspect-test-file>}"

# Get the canonical order vitest uses, excluding the suspect.
mapfile -t SUITE < <(
  pnpm exec vitest list --reporter=json 2>/dev/null \
    | jq -r '.testModules[].moduleId' \
    | grep -v -F "$SUSPECT"
)
N="${#SUITE[@]}"
echo "Suite has $N tests before $SUSPECT"

# Confirm: running suspect ALONE passes.
if ! pnpm exec vitest run "$SUSPECT" --reporter=dot >/dev/null 2>&1; then
  echo "Suspect fails in isolation — not a pollution flake. Stopping."
  exit 1
fi
# Confirm: running suite + suspect together FAILS.
if pnpm exec vitest run "${SUITE[@]}" "$SUSPECT" --reporter=dot >/dev/null 2>&1; then
  echo "Suite + suspect passes — not reproducible. Stopping."
  exit 0
fi

lo=0; hi=$((N - 1)); round=0
while (( lo < hi )); do
  round=$((round + 1))
  mid=$(( (lo + hi) / 2 ))
  before=("${SUITE[@]:lo:mid-lo+1}")
  echo "round $round: running ${#before[@]} tests before suspect (indices $lo..$mid)"
  if pnpm exec vitest run "${before[@]}" "$SUSPECT" --reporter=dot >/dev/null 2>&1; then
    # Lower half didn't reproduce → polluter is in upper half.
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo
echo "Polluter: ${SUITE[$lo]}"
