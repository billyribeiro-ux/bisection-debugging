#!/usr/bin/env bash
# A helper that accumulates measurements into a caller-provided array.
# Without namerefs, you'd have to use globals or pass-by-string.

measure_n_times() {
  declare -n out=$1     # nameref to caller's array
  local cmd="$2"
  local n="$3"
  for ((i=0; i<n; i++)); do
    local t
    t=$( { time -p sh -c "$cmd" ; } 2>&1 | awk '/real/ {print $2}' )
    out+=("$t")
  done
}

declare -a timings
measure_n_times timings "curl -sf http://localhost:3000/health" 10
echo "Got ${#timings[@]} measurements: ${timings[*]}"
