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

# CRITICAL: pin ordering and state-sharing for every run.
#   --no-file-parallelism  → one worker, files run sequentially in CLI order
#   --no-isolate           → files share the environment (only if your CI
#                            does the same; drop it for out-of-process
#                            pollution like databases or the filesystem)
VFLAGS=(--no-file-parallelism --no-isolate --reporter=dot)

# Enumerate the suite's test files, excluding the suspect.
mapfile -t SUITE < <(
  pnpm exec vitest list --filesOnly --json 2>/dev/null \
    | jq -r '.[]' \
    | grep -v -F "$SUSPECT"
)
N="${#SUITE[@]}"
echo "Suite has $N files besides $SUSPECT"

# Confirm: running suspect ALONE passes.
if ! pnpm exec vitest run "${VFLAGS[@]}" "$SUSPECT" >/dev/null 2>&1; then
  echo "Suspect fails in isolation — not a pollution flake. Stopping."
  exit 1
fi
# Confirm: running suite + suspect together FAILS.
if pnpm exec vitest run "${VFLAGS[@]}" "${SUITE[@]}" "$SUSPECT" >/dev/null 2>&1; then
  echo "Suite + suspect passes — not reproducible with pinned order. Stopping."
  exit 0
fi

lo=0; hi=$((N - 1)); round=0
while (( lo < hi )); do
  round=$((round + 1))
  mid=$(( (lo + hi) / 2 ))
  before=("${SUITE[@]:lo:mid-lo+1}")
  echo "round $round: running ${#before[@]} files before suspect (indices $lo..$mid)"
  if pnpm exec vitest run "${VFLAGS[@]}" "${before[@]}" "$SUSPECT" >/dev/null 2>&1; then
    # Lower half didn't reproduce → polluter is in upper half.
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo
echo "Polluter: ${SUITE[$lo]}"
