#!/usr/bin/env bash
# Bash predicate that delegates the REPL-driving step to a zsh helper.
set -uo pipefail
command -v zsh >/dev/null || exit 125    # zsh required for this step

# ... setup in bash ...

zsh ./drive-repl.zsh   # zsh subshell handles the zpty work
