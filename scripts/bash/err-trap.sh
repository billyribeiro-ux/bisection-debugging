#!/usr/bin/env bash
set -uEo pipefail   # -E: ERR traps inherit into functions and subshells

report_failure() {
  # FIRST statement: snapshot $? and PIPESTATUS together — any command,
  # including a `local` assignment, overwrites both.
  local exit_code=$? pipestatus_copy="${PIPESTATUS[*]:-}"
  local line=${BASH_LINENO[0]}
  local cmd=$BASH_COMMAND
  echo "PREDICATE FAILURE at line $line"
  echo "  command: $cmd"
  echo "  exit code: $exit_code"
  echo "  PIPESTATUS: $pipestatus_copy"
  echo "  callstack:"
  local i=0
  while caller $i; do ((i++)); done
}

trap report_failure ERR
# ... rest of predicate ...
