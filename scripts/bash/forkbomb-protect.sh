#!/usr/bin/env bash
# A naive parallel bisection can fork unbounded workers if the loop doesn't
# back-pressure. Use ulimit + explicit job counting.

ulimit -u 1024              # max user processes — kernel-level cap
MAX_JOBS=8
declare -A JOBS

start_job() {
  if (( ${#JOBS[@]} >= MAX_JOBS )); then
    # wait -n: block until any job finishes
    wait -n
    for pid in "${!JOBS[@]}"; do
      kill -0 "$pid" 2>/dev/null || unset 'JOBS[$pid]'
    done
  fi
  ( predicate-for "$1" ) &
  JOBS[$!]="$1"
}

for sha in "$@"; do start_job "$sha"; done
wait    # let stragglers finish
