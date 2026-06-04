#!/usr/bin/env bash
set -uEo pipefail   # -E: ERR traps inherit into functions and subshells

report_failure() {
  local exit_code=$?
  local line=$BASH_LINENO
  local cmd=$BASH_COMMAND
  echo "PREDICATE FAILURE at line $line"
  echo "  command: $cmd"
  echo "  exit code: $exit_code"
  echo "  PIPESTATUS: ${PIPESTATUS[*]:-}"
  echo "  callstack:"
  local i=0
  while caller $i; do ((i++)); done
}

trap report_failure ERR
# ... rest of predicate ...
