#!/usr/bin/env bash
# verify-scripts.sh
# Syntax-checks every extracted script. No script is executed.
# Exits non-zero on the first failure.
set -uo pipefail

fail=0
skipped=0
check() {
  local kind="$1" ; shift
  local f
  # A missing interpreter is a skip, not a failure. The old form
  # `command -v zsh >/dev/null && zsh -n "$f"` returns non-zero when zsh is
  # absent, so every .zsh file reported FAIL on machines without zsh — the
  # exact conditional-exit-status trap the error-handling pages warn about.
  if ! command -v "$kind" >/dev/null; then
    printf 'skip [%s]  %d file(s) — %s not installed\n' "$kind" "$#" "$kind"
    skipped=$((skipped + $#))
    return 0
  fi
  for f in "$@"; do
    [ -f "$f" ] || continue
    case "$kind" in
      bash) bash -n "$f" 2>/tmp/v.err ;;
      zsh)  zsh -n "$f" 2>/tmp/v.err ;;
      node) node --check "$f" 2>/tmp/v.err ;;
    esac
    if [ $? -ne 0 ]; then
      printf 'FAIL [%s]  %s\n' "$kind" "$f"
      cat /tmp/v.err
      fail=$((fail + 1))
    else
      printf 'ok   [%s]  %s\n' "$kind" "$f"
    fi
  done
}

shopt -s globstar nullglob

mapfile -t SH < <(find scripts -name '*.sh' | sort)
mapfile -t ZSH < <(find scripts/zsh -name '*.zsh' 2>/dev/null | sort)
mapfile -t MJS < <(find scripts -name '*.mjs' | sort)

check bash "${SH[@]}"
check zsh  "${ZSH[@]}"
check node "${MJS[@]}"

echo
if (( fail == 0 )); then
  if (( skipped > 0 )); then
    echo "All checkable scripts pass syntax checks ($skipped skipped: interpreter not installed)."
  else
    echo "All scripts pass syntax checks."
  fi
else
  echo "$fail file(s) failed."
  exit 1
fi
