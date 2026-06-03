# Drop into ~/.zshrc to auto-save bisection state at every prompt.
typeset -g BISECT_AUTOSAVE=/tmp/bisect-autosave-$UID.state

_bisect_autosave_precmd() {
  [[ -n ${BISECT_LO:-} && -n ${BISECT_HI:-} ]] || return
  print "$BISECT_LO $BISECT_HI" > $BISECT_AUTOSAVE
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _bisect_autosave_precmd
