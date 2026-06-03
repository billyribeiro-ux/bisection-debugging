# bash-bisect.sh — reusable bisection library.
# Source it: `source ./bash-bisect.sh`
# Then call: `bisect_array MY_ARRAY my_predicate`
#
# Predicate contract: receives the candidate subset as positional args.
#   Returns 0 = good (subset clean), nonzero = bad (subset contains culprit).
#
# Saves state to a per-session temp file so SIGINT is recoverable.

bisect_array() {
  # Bash 4.3+ namerefs let the caller pass the array by name.
  local -n _arr="$1"
  local _pred="$2"
  local _state="${BISECT_TMP:-/tmp}/bisect-$$-${1}.state"

  local lo=0 hi=$(( ${#_arr[@]} - 1 )) mid round=0
  if [ -f "$_state" ]; then
    read lo hi < "$_state"
    echo "resuming from saved state: lo=$lo hi=$hi"
  fi

  trap 'echo "$lo $hi" > "$_state"; echo "Saved state to $_state"; return 130' INT

  while (( lo < hi )); do
    round=$((round + 1))
    mid=$(( (lo + hi) / 2 ))
    local half=( "${_arr[@]:lo:mid-lo+1}" )
    if "$_pred" "${half[@]}" >/dev/null 2>&1; then
      lo=$((mid + 1))
    else
      hi=$mid
    fi
    printf '\rround %d  lo=%d hi=%d  ' "$round" "$lo" "$hi"
  done
  echo
  echo "culprit: ${_arr[$lo]}"
  rm -f "$_state"
  trap - INT
  printf '%s' "${_arr[$lo]}"
}
