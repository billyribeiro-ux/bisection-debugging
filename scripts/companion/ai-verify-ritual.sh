#!/usr/bin/env bash
# Always run after an AI generates a predicate. Do not skip.
set -uo pipefail

GOOD_SHA="${1:?known-good SHA}"
BAD_SHA="${2:?known-bad SHA}"

echo "=== Verifying AI predicate against known endpoints ==="

# Test at good (should exit 0)
git checkout -q "$GOOD_SHA"
./predicate.sh >/dev/null 2>&1
[ $? -eq 0 ] || { echo "FAIL: predicate exits non-zero at good SHA"; exit 1; }

# Test at bad (should exit 1)
git checkout -q "$BAD_SHA"
./predicate.sh >/dev/null 2>&1
[ $? -eq 1 ] || { echo "FAIL: predicate exits non-1 at bad SHA"; exit 1; }

# Stability: run 5 times at good, expect all 0
git checkout -q "$GOOD_SHA"
for i in {1..5}; do
  ./predicate.sh >/dev/null 2>&1
  [ $? -eq 0 ] || { echo "FAIL: instability at good SHA on iteration $i"; exit 1; }
done

# Stability: run 5 times at bad, expect all 1
git checkout -q "$BAD_SHA"
for i in {1..5}; do
  ./predicate.sh >/dev/null 2>&1
  [ $? -eq 1 ] || { echo "FAIL: instability at bad SHA on iteration $i"; exit 1; }
done

git checkout -q -
echo "VERIFIED: predicate is calibrated and stable."
