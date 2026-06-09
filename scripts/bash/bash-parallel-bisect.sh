#!/usr/bin/env bash
# bash-parallel-bisect.sh
# Race both halves each round: modest latency gain (decide at the first
# FAILING finisher), 2× compute. Use only when each predicate call is
# independent and side-effect-free.
set -euo pipefail

PRED="${1:?usage: $0 <predicate> <list-cmd>}"
LIST="${2:?missing list cmd}"

mapfile -t F < <(eval "$LIST" | sort -u)
lo=0; hi=$(( ${#F[@]} - 1 ))

while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  L=( "${F[@]:lo:mid-lo+1}" )
  U=( "${F[@]:mid+1:hi-mid}" )

  # Run both in parallel; capture each return code.
  $PRED "${L[@]}" >/tmp/bi-L.log 2>&1 & PL=$!
  $PRED "${U[@]}" >/tmp/bi-U.log 2>&1 & PU=$!

  # Wait for the FIRST to finish.
  wait -n
  if ! kill -0 "$PL" 2>/dev/null; then
    wait "$PL"; rcL=$?
    # If lower is bad, we already know what to do — kill upper.
    if (( rcL != 0 )); then kill "$PU" 2>/dev/null; wait "$PU" 2>/dev/null; hi=$mid; continue; fi
    wait "$PU"; rcU=$?
  else
    wait "$PU"; rcU=$?
    if (( rcU != 0 )); then kill "$PL" 2>/dev/null; wait "$PL" 2>/dev/null; lo=$((mid + 1)); continue; fi
    wait "$PL"; rcL=$?
  fi

  # Both finished. By the bisection invariant exactly one is bad.
  if (( rcL != 0 && rcU == 0 )); then hi=$mid
  elif (( rcL == 0 && rcU != 0 )); then lo=$((mid + 1))
  else
    # NOT $(( rcL==0?good:bad )) — arithmetic expansion would treat good/bad
    # as variable names and print 0/0.
    vL=$([ "$rcL" -eq 0 ] && echo good || echo bad)
    vU=$([ "$rcU" -eq 0 ] && echo good || echo bad)
    echo "Invariant broken at round $mid — halves are $vL/$vU"; exit 2
  fi
done
echo "culprit: ${F[$lo]}"
