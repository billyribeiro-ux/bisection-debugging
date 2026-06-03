#!/usr/bin/env bash
# bash-l2-mapfile.sh
# Source the candidate list from any command — git, find, etc.
#
# USAGE:
#   ./bash-l2-mapfile.sh "git ls-files '*.svelte'" "pnpm exec svelte-check"
set -euo pipefail

LIST_CMD="${1:?usage: $0 <list-cmd> <predicate>}"
PRED="${2:?missing predicate}"

mapfile -t FILES < <(eval "$LIST_CMD" | sort -u)
N="${#FILES[@]}"
echo "Candidates: $N"

# Process substitution `< <(…)` keeps the variables in the parent shell — a
# pipeline `cmd | while read` would not, because the loop runs in a subshell
# and its variable assignments would be lost. This is the most-asked Bash
# bisection bug. Use < <(…), not | while.

lo=0; hi=$((N - 1)); round=0
while (( lo < hi )); do
  round=$((round + 1))
  mid=$(( (lo + hi) / 2 ))
  half=("${FILES[@]:lo:mid-lo+1}")
  printf 'round %2d  [%4d..%4d]  %d files  ' "$round" "$lo" "$mid" "${#half[@]}"
  if $PRED "${half[@]}" >/dev/null 2>&1; then
    echo "good"
    lo=$((mid + 1))
  else
    echo "bad"
    hi=$mid
  fi
done
echo "==> culprit: ${FILES[$lo]}"
