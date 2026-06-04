#!/usr/bin/env bash
set -uo pipefail
some_setup_command | tee setup.log | grep -q READY
rc_setup="${PIPESTATUS[0]}"   # exit code of some_setup_command
rc_tee="${PIPESTATUS[1]}"     # exit code of tee
rc_grep="${PIPESTATUS[2]}"    # exit code of grep

if (( rc_setup != 0 )); then
  echo "setup failed (rc=$rc_setup) — skipping commit"
  exit 125
fi
if (( rc_grep != 0 )); then
  echo "setup never reached READY state"
  exit 1
fi
