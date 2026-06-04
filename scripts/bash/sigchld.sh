#!/usr/bin/env bash
# For event-driven parallel bisection: notice as soon as ANY child finishes.
# Set a SIGCHLD handler that records the death and triggers further work.

declare -A PENDING=()
declare -a COMPLETED=()

handle_sigchld() {
  local pid rc
  for pid in "${!PENDING[@]}"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid"; rc=$?
      COMPLETED+=("${PENDING[$pid]}:$rc")
      unset 'PENDING[$pid]'
    fi
  done
}
trap handle_sigchld CHLD

for sha in "$@"; do
  ( predicate-for "$sha" ) &
  PENDING[$!]="$sha"
done
wait
echo "All done. Results:"
printf '%s\n' "${COMPLETED[@]}"
