#!/usr/bin/env bash
# chaos-bisect.sh
# Predicate that runs the target 100 times under stress and declares a commit
# "bad" if the bug appears even once. Combine with `git bisect run`.
#
# Why it works: under high contention, the buggy interleaving dominates;
# good commits virtually never fail; bad commits fail repeatedly.
set -uo pipefail

RUNS=100
THREADS=$(nproc)

# Make sure baseline tools exist.
command -v stress-ng >/dev/null || { echo "Need stress-ng"; exit 125; }

# Apply contention for the WHOLE test loop (100 runs × up to 5 s each);
# --timeout 0 = run until we kill it via the trap. A short fixed timeout
# would expire mid-loop and silently remove the contention.
stress-ng --cpu "$THREADS" --io 4 --vm 2 --vm-bytes 256M --timeout 0 &
STRESSOR=$!
trap 'kill "$STRESSOR" 2>/dev/null || true' EXIT

failures=0
for i in $(seq 1 "$RUNS"); do
  timeout 5s ./run-target.sh || failures=$((failures + 1))
done

echo "$failures / $RUNS runs failed"
[ "$failures" -gt 0 ] && exit 1 || exit 0
