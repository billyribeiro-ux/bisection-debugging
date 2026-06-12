#!/usr/bin/env bash
# Drop-in error handling for any bash predicate.
set -uEo pipefail
shopt -s nullglob extglob lastpipe inherit_errexit
(( BASH_VERSINFO[0] >= 5 )) || { echo "bash 5+ required"; exit 125; }

err() {
  # Snapshot $? and PIPESTATUS in the FIRST statement (they're volatile),
  # and note the braces: $BASH_LINENO[0] without ${…} would expand to
  # something like "42[0]".
  local rc=$? ps_copy="${PIPESTATUS[*]:-}"
  local line=${BASH_LINENO[0]} cmd=$BASH_COMMAND
  printf 'PREDICATE ERROR\n  file: %s\n  line: %s\n  cmd:  %s\n  rc:   %s\n  PIPESTATUS: %s\n' \
    "$BASH_SOURCE" "$line" "$cmd" "$rc" "$ps_copy" >&2
}
trap err ERR

declare -a CHILDREN=()
declare -A SCRATCH_PATHS=()
cleanup_all() {
  for pid in "${CHILDREN[@]:-}"; do kill "$pid" 2>/dev/null || true; done
  for path in "${!SCRATCH_PATHS[@]}"; do rm -rf "$path"; done
}
trap cleanup_all EXIT INT TERM

# ... predicate body uses CHILDREN+=("$pid") and SCRATCH_PATHS["$path"]=1 ...
