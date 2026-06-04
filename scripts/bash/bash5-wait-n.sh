#!/usr/bin/env bash
# Spawn 4 parallel predicate workers; collect results as each finishes.
declare -A WORKERS         # pid → commit-sha
for sha in "$@"; do
  ( predicate-for "$sha" ) &
  WORKERS[$!]="$sha"
done

while (( ${#WORKERS[@]} > 0 )); do
  # wait -n: blocks until ANY child finishes. wait -p: captures the pid.
  if wait -n -p finished_pid; then
    rc=$?
    sha="${WORKERS[$finished_pid]}"
    echo "$sha → $rc"
    unset 'WORKERS[$finished_pid]'
  fi
done
