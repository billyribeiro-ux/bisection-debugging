#!/usr/bin/env bash
# verify-scripts.sh
# Syntax-checks every extracted script. No script is executed.
# Exits non-zero on the first failure.
set -uo pipefail

fail=0
check() {
  local kind="$1" ; shift
  local f
  for f in "$@"; do
    [ -f "$f" ] || continue
    case "$kind" in
      bash) bash -n "$f" 2>/tmp/v.err ;;
      zsh)  command -v zsh >/dev/null && zsh -n "$f" 2>/tmp/v.err ;;
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
  echo "All scripts pass syntax checks."
else
  echo "$fail file(s) failed."
  exit 1
fi
