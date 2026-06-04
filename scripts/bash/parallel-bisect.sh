#!/usr/bin/env bash
# parallel-bisect.sh
# Splits the remaining bisection interval into N chunks; runs the predicate
# in parallel on the endpoints of each chunk. The first verdict that's
# inconsistent with monotonicity tells us which chunk contains the culprit.
#
# Faster than serial when:
#   - Predicates are expensive (> 30s)
#   - You have idle cores
#   - The build is parallelizable (each worker has its own worktree)

set -uEo pipefail
LO="${1:?good SHA}"
HI="${2:?bad SHA}"
WORKERS="${WORKERS:-8}"
PREDICATE="${3:?path to predicate}"

# Materialize the candidate set in linear-history order
mapfile -t CANDIDATES < <(git rev-list --reverse "$LO..$HI")
TOTAL=${#CANDIDATES[@]}

while (( TOTAL > 1 )); do
  # Pick W evenly-spaced commits inside the current interval
  PROBES=()
  STEP=$(( TOTAL / (WORKERS + 1) ))
  (( STEP == 0 )) && STEP=1
  for ((i = STEP; i < TOTAL; i += STEP)); do
    PROBES+=("${CANDIDATES[$i]}")
  done

  # Run each probe in a separate worktree, in parallel
  RESULTS=()
  declare -A PID2IDX=()
  for j in "${!PROBES[@]}"; do
    sha="${PROBES[$j]}"
    wt="/tmp/wt-$j"
    git worktree add -f "$wt" "$sha" >/dev/null
    ( cd "$wt"; "$PREDICATE" >/dev/null 2>&1; echo "$?" > "/tmp/rc-$j" ) &
    PID2IDX[$!]=$j
  done
  wait    # all probes finish

  # Collect results in probe order
  RESULTS=()
  for j in "${!PROBES[@]}"; do
    RESULTS+=("$(< /tmp/rc-$j)")
    git worktree remove --force "/tmp/wt-$j" >/dev/null
  done

  # Find the monotonicity boundary: where 0 → 1 transition is
  for ((k = 0; k < ${#RESULTS[@]}; k++)); do
    if (( RESULTS[k] == 1 )); then
      # culprit is between PROBES[k-1] and PROBES[k]
      NEW_LO_IDX=$(( STEP * (k) ))         # PROBES[k-1] is somewhere here
      NEW_HI_IDX=$(( STEP * (k+1) ))
      CANDIDATES=("${CANDIDATES[@]:$NEW_LO_IDX:$((NEW_HI_IDX - NEW_LO_IDX))}")
      TOTAL=${#CANDIDATES[@]}
      break
    fi
  done
done

echo "Culprit: ${CANDIDATES[0]}"
