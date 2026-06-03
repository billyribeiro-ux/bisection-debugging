#!/usr/bin/env bash
# napkin-bisect.sh — the absolute simplest bisection.
# Usage:  ./napkin-bisect.sh "svelte-check --filter {}" src/lib/**/*.svelte
#
# {} is replaced with the file being tested.

predicate="$1"; shift
files=("$@")

lo=0; hi=$((${#files[@]} - 1))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  half=("${files[@]:lo:mid-lo+1}")
  echo "Testing files [$lo..$mid] (${#half[@]} files)"
  cmd="${predicate//\{\}/${half[*]}}"
  if eval "$cmd" >/dev/null 2>&1; then
    lo=$((mid + 1))   # this half is good → bad must be in upper half
  else
    hi=$mid           # this half is bad → keep narrowing
  fi
done
echo "Culprit: ${files[$lo]}"
