#!/usr/bin/env bash
# Trace every function entry/exit, not just every command.

trace_function() {
  local depth=${#FUNCNAME[@]}
  printf '%*s→ %s()\n' "$((depth * 2))" '' "${FUNCNAME[1]}" >&2
}
trap 'trace_function' DEBUG    # fires before each simple command

set -o functrace               # functions inherit DEBUG trap
set -o errtrace                # functions inherit ERR trap

my_function() { echo "hello"; }
my_function
# →   → my_function()
# → hello
