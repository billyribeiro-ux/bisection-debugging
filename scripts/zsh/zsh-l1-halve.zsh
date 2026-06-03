#!/usr/bin/env zsh
# zsh-l1-halve.zsh
# Zsh has `**/` as a builtin recursive glob — no `shopt` needed.
# Glob qualifiers (the (.) below) restrict to regular files; very handy.

set -eu

local pred="${1:?usage: $0 <predicate> <glob>}"
local glob="${2:?missing glob}"

# Expand the glob into an array. (.) = only regular files.
local -a files
files=(${~glob}(.N))   # ~ enables glob expansion of a variable; N = nullglob
files=(${(o)files})    # sort alphabetically (the (o) parameter expansion flag)

echo "candidates: ${#files}"

# Zsh arrays are 1-indexed by default. $files[1,$mid] is a slice.
local lo=1 hi=${#files} mid
while (( lo < hi )); do
  (( mid = (lo + hi) / 2 ))
  if ${=pred} ${files[lo,mid]} >/dev/null 2>&1; then
    (( lo = mid + 1 ))
  else
    hi=$mid
  fi
done
print -r -- "culprit: ${files[lo]}"
