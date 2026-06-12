# zsh-bisect.zsh — sourceable bisection library for zsh.
#
# Usage:
#   source ./zsh-bisect.zsh
#   files=( ${(f)"$(git ls-files '*.svelte')"} )
#   check() { ./svelte-check-subset.sh "$@" >/dev/null 2>&1; }
#   bisect_array files check

bisect_array() {
  local _name="$1" _pred="$2"
  # (P)name = expand "name" indirectly. The ${(@P)…} keeps array semantics.
  local -a _arr
  _arr=( "${(@P)_name}" )

  local _state="${BISECT_TMP:-/tmp}/zbisect-$$-${_name}.state"
  local lo=1 hi=${#_arr} mid round=0

  if [[ -f $_state ]]; then
    read lo hi < $_state
    print "resuming: lo=$lo hi=$hi"
  fi

  # On SIGINT, persist state AND push the resume command into history/ZLE so
  # pressing Up + Enter continues the session.
  TRAPINT() {
    print "$lo $hi" > $_state
    print -s "bisect_array $_name $_pred  # resume saved at $_state"
    print "\nSaved state. Press Up-arrow to recall the resume command."
    return 130
  }

  while (( lo < hi )); do
    (( round++ ))
    (( mid = (lo + hi) / 2 ))
    local -a half
    half=( $_arr[lo,mid] )
    if $_pred $half >/dev/null 2>&1; then
      (( lo = mid + 1 ))
    else
      hi=$mid
    fi
    printf '\rround %2d  lo=%-4d hi=%-4d ' $round $lo $hi
  done
  print
  print -r -- "culprit: $_arr[lo]"
  rm -f $_state
  unfunction TRAPINT
}
