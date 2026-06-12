#!/usr/bin/env bash
# Bash reaps terminated children continuously (its SIGCHLD handler), so
# true zombies don't accumulate. What DOES accumulate: unread exit
# statuses and jobs-table entries. Periodic `wait` collects the statuses
# you still care about and keeps the bookkeeping bounded.

declare -a CHILDREN=()
for sha in "$@"; do
  ( predicate-for "$sha" ) &
  CHILDREN+=($!)
  if (( ${#CHILDREN[@]} % 50 == 0 )); then
    # reap finished ones every 50 spawns
    for pid in "${CHILDREN[@]}"; do
      kill -0 "$pid" 2>/dev/null || wait "$pid"
    done
  fi
done
wait
