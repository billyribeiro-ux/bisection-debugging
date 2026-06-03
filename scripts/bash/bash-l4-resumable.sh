#!/usr/bin/env bash
# bash-l4-resumable.sh
# A bisector that persists its (lo, hi) state to /tmp/bisect.state so you can
# Ctrl-C, drink coffee, fix your predicate, and continue.
#
# USAGE:
#   ./bash-l4-resumable.sh start "<list-cmd>" "<predicate>"
#   ./bash-l4-resumable.sh continue
#   ./bash-l4-resumable.sh status
#   ./bash-l4-resumable.sh abort

set -euo pipefail
STATE="${BISECT_STATE:-/tmp/bisect.state}"

cmd_start() {
  local list_cmd="$1" pred="$2"
  mapfile -t FILES < <(eval "$list_cmd" | sort -u)
  printf '%s\n' "$pred"  > "$STATE.pred"
  printf '%s\n' "${FILES[@]}" > "$STATE.files"
  echo "0 $(( ${#FILES[@]} - 1 ))" > "$STATE.range"
  echo "Started bisection over ${#FILES[@]} candidates."
}

cmd_continue() {
  local pred=$(< "$STATE.pred")
  mapfile -t FILES < "$STATE.files"
  read lo hi < "$STATE.range"
  while (( lo < hi )); do
    local mid=$(( (lo + hi) / 2 ))
    local half=("${FILES[@]:lo:mid-lo+1}")
    if $pred "${half[@]}" >/dev/null 2>&1; then
      lo=$((mid + 1))
    else
      hi=$mid
    fi
    echo "$lo $hi" > "$STATE.range"
    printf '\rprogress: lo=%d hi=%d   ' "$lo" "$hi"
  done
  echo
  echo "Culprit: ${FILES[$lo]}"
  cmd_abort
}

cmd_status() {
  [ -f "$STATE.range" ] || { echo "no active bisection"; return; }
  read lo hi < "$STATE.range"
  mapfile -t FILES < "$STATE.files"
  echo "lo=$lo hi=$hi  remaining $((hi - lo + 1))/${#FILES[@]}"
}

cmd_abort() {
  rm -f "$STATE".pred "$STATE".files "$STATE".range
}

"cmd_${1:?usage: start|continue|status|abort}" "${@:2}"
