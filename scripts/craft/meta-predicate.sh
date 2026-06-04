#!/usr/bin/env bash
# Tests the predicate itself, not the code.
# Runs the predicate at 5 known points; verifies expected behavior.
set -uo pipefail

declare -a CHECKS=(
  "a3f9c81:0"    # known-good → should exit 0
  "b1c2d3e:0"    # also known-good → should exit 0
  "e7b2a91:1"    # known-bad → should exit 1
  "f9a8b7c:1"    # also known-bad → should exit 1
  "deadbeef:125" # known-broken (won't build) → should exit 125
)

for check in "${CHECKS[@]}"; do
  sha="${check%:*}"
  expected="${check#*:}"
  git checkout -q "$sha"
  ./predicate.sh >/dev/null 2>&1
  got=$?
  if [ "$got" != "$expected" ]; then
    echo "FAIL: $sha expected $expected, got $got"
    exit 1
  fi
done
echo "All 5 checks pass — predicate is calibrated."
