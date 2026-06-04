#!/usr/bin/env bash
set -uo pipefail

# Subshells exit silently by default. The parent shell continues.
( some_command_in_subshell )
echo "rc was $?"   # captures the subshell exit code

# When you need the subshell's failure to abort the script:
( some_command_in_subshell ) || exit 1

# Or via `inherit_errexit` (bash 4.4+) which makes set -e propagate into subshells.
shopt -s inherit_errexit
