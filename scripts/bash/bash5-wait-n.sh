#!/usr/bin/env bash
# Spawn 4 parallel predicate workers; collect results as each finishes.
declare -A WORKERS         # pid → commit-sha
for sha in "$@"; do
  ( predicate-for "$sha" ) &
  WORKERS[$!]="$sha"
done

while (( ${#WORKERS[@]} > 0 )); do
  # wait -n: blocks until ANY child finishes. wait -p: captures the pid.
  # Capture rc OUTSIDE an if: `if wait -n …; then rc=$?` would (a) always
  # set rc=0 inside the then-branch and (b) never enter the branch for a
  # FAILING child — failed workers would stay in WORKERS forever.
  rc=0; wait -n -p finished_pid || rc=$?
  [[ -n "${finished_pid:-}" ]] || break   # no children left
  sha="${WORKERS[$finished_pid]}"
  echo "$sha → $rc"
  unset 'WORKERS[$finished_pid]'
done
