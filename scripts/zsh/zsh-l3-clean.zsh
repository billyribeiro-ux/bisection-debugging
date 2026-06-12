#!/usr/bin/env zsh
# zsh-l3-clean.zsh
# Idiomatic zsh bisector. Uses 1-indexed slicing for readability.
set -eu

bisect() {
  local pred="$1"
  shift
  local -a F
  F=( "$@" )

  local lo=1 hi=${#F} mid round=0
  while (( lo < hi )); do
    (( round++ ))
    (( mid = (lo + hi) / 2 ))
    local -a half
    half=( $F[lo,mid] )
    printf 'round %2d  [%4d..%4d]  %3d items  ' $round $lo $mid ${#half}
    if ${=pred} $half >/dev/null 2>&1; then
      print good
      (( lo = mid + 1 ))
    else
      print bad
      hi=$mid
    fi
  done
  print -r -- "culprit: $F[lo]"
}

# Read newline-delimited input into an array via the (f) parameter flag.
files=( ${(f)"$(git ls-files '*.svelte')"} )
bisect "./svelte-check-subset.sh" $files
