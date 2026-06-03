#!/usr/bin/env bash
# bash-l1-halve.sh
# The smallest useful bisector. Halve a glob, run a predicate, narrow.
# Bash 4+ required (for `shopt -s globstar`).

set -euo pipefail
shopt -s globstar nullglob

PRED="${1:?usage: $0 <predicate> <glob>}"
GLOB="${2:?missing glob}"

# Bash's `**/` requires globstar; word-split on whitespace into an array.
mapfile -t FILES < <(printf '%s\n' $GLOB | sort)
echo "candidates: ${#FILES[@]}"

lo=0; hi=$(( ${#FILES[@]} - 1 ))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  half=("${FILES[@]:lo:mid-lo+1}")
  if $PRED "${half[@]}" >/dev/null 2>&1; then
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo "culprit: ${FILES[$lo]}"
