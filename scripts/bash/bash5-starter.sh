#!/usr/bin/env bash
# Drop-in header for any modern bash predicate.
(( BASH_VERSINFO[0] >= 5 )) || { echo "bash 5+ required"; exit 125; }
shopt -s nullglob extglob globstar lastpipe inherit_errexit
set -uo pipefail

# Useful timestamps without subshells
start_time=$EPOCHREALTIME

# Trap & cleanup before anything that needs cleanup
declare -a CHILDREN=()
cleanup() {
  for pid in "${CHILDREN[@]}"; do kill "$pid" 2>/dev/null || true; done
}
trap cleanup EXIT INT TERM
