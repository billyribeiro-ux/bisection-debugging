#!/usr/bin/env bash
# Bash auto-reaps zombies when it exits, but a long-running predicate that
# spawns many backgrounds accumulates them. Explicit `wait` periodically clears.

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
