#!/usr/bin/env bash
# Run a predicate N times and report stats. Catches predicates whose
# wall-clock varies wildly across rounds.

N="${1:-10}"
declare -a TIMES=()

for ((i=1; i<=N; i++)); do
  t0=$EPOCHREALTIME
  ./predicate.sh >/dev/null 2>&1
  t1=$EPOCHREALTIME
  TIMES+=("$(awk -v a="$t0" -v b="$t1" 'BEGIN { print b - a }')")
done

printf '%s\n' "${TIMES[@]}" | gawk '
  { n++; sum += $1; if ($1 > max || NR == 1) max = $1; if ($1 < min || NR == 1) min = $1; a[NR] = $1 }
  END {
    asort(a)   # gawk extension — pre-sort with sort -n for mawk/BSD awk
    p50 = a[int(n * 0.5) + 1]
    p95 = a[int(n * 0.95) + 1]
    printf "n=%d  min=%.3fs  p50=%.3fs  p95=%.3fs  max=%.3fs  mean=%.3fs\n",
           n, min, p50, p95, max, sum/n
  }
'
