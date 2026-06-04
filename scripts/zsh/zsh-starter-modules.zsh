#!/usr/bin/env zsh
# Load every useful module at predicate startup
zmodload zsh/datetime
zmodload zsh/system
zmodload zsh/net/tcp
zmodload -F zsh/files b:chmod b:chown b:mkdir b:rm b:ln

# Now $EPOCHREALTIME, ztcp, zsystem flock, in-process mkdir/chmod/rm
# are all available without external command overhead.
