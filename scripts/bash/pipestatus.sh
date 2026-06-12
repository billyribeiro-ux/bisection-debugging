#!/usr/bin/env bash
set -uo pipefail
some_setup_command | tee setup.log | grep -q READY
# Copy PIPESTATUS in ONE statement: every command — including the first
# assignment below — overwrites it. Three sequential assignments would
# read garbage from the second one on.
ps=( "${PIPESTATUS[@]}" )
rc_setup="${ps[0]}"   # exit code of some_setup_command
rc_tee="${ps[1]}"     # exit code of tee
rc_grep="${ps[2]}"    # exit code of grep

if (( rc_setup != 0 )); then
  echo "setup failed (rc=$rc_setup) — skipping commit"
  exit 125
fi
if (( rc_grep != 0 )); then
  echo "setup never reached READY state"
  exit 1
fi
