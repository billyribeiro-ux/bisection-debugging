#!/usr/bin/env zsh
# Capture predicate stdout to a temp file via process substitution, then
# extract the salient line for the bisection log.

predicate() {
  pnpm exec svelte-check --output machine "$@"
}

bisect_with_diag() {
  local -a F=( "$@" )
  local lo=1 hi=${#F} mid
  while (( lo < hi )); do
    (( mid = (lo + hi) / 2 ))
    local half=( $F[lo,mid] )

    # =(predicate "$half") expands to a tmpfile path containing the stdout.
    local diag=$(awk -F$'\t' '$1=="ERROR"' =(predicate $half))

    if [[ -z $diag ]]; then
      (( lo = mid + 1 ))
    else
      print "round at [$lo..$mid]: $diag"
      hi=$mid
    fi
  done
  print "culprit: $F[lo]"
}
