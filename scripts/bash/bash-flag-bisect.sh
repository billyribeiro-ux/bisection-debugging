#!/usr/bin/env bash
# bash-flag-bisect.sh
# All N flags on → bug present. All off → bug absent.
# Find the SMALLEST subset of flags whose all-on state reproduces.
#
# Strategy: 1-minimal search via Delta Debugging-style halving:
#   1) Test lower half ON, upper half OFF. If reproduces → recurse into lower.
#   2) If not, test upper half ON. If reproduces → recurse into upper.
#   3) Else neither half alone reproduces → bug needs flags from BOTH halves;
#      keep upper half pinned ON and bisect within lower half for the partner.
#
set -euo pipefail
FLAGS=( "$@" )

reproduces() {
  local env=""
  for f in "$@"; do env+="$f=1 "; done
  eval "$env pnpm test --run >/dev/null 2>&1" && return 1 || return 0
}

# Δ-debug style recursive minimization.
ddmin() {
  local -a S=( "$@" )
  local n=2
  while (( ${#S[@]} > 1 )); do
    local size=$(( (${#S[@]} + n - 1) / n ))
    local found=0
    for (( i = 0; i < ${#S[@]}; i += size )); do
      local subset=( "${S[@]:i:size}" )
      local complement=( "${S[@]:0:i}" "${S[@]:i+size}" )
      if reproduces "${subset[@]}"; then S=( "${subset[@]}" ); n=2; found=1; break
      elif reproduces "${complement[@]}"; then S=( "${complement[@]}" ); n=$(( n > 2 ? n - 1 : 2 )); found=1; break  # clamp: n=1 would make subset==S
      fi
    done
    (( found )) || { (( n >= ${#S[@]} )) && break; n=$(( n * 2 )); (( n > ${#S[@]} )) && n=${#S[@]}; }
  done
  echo "Minimal failing set: ${S[*]}"
}

reproduces "${FLAGS[@]}" || { echo "All flags on does not reproduce."; exit 0; }
ddmin "${FLAGS[@]}"
