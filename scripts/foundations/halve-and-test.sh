#!/usr/bin/env bash
# halve-and-test.sh — interactively halve a suspect file list.
# Moves files into .bisect-stash/, runs your predicate, restores on exit.
# Usage:  ./halve-and-test.sh 'pnpm exec svelte-check' src/lib/**/*.svelte
set -euo pipefail

PREDICATE="$1"; shift
ALL=("$@")
STASH=".bisect-stash"
mkdir -p "$STASH"

restore() {
  echo "Restoring stashed files…"
  if [ -d "$STASH" ]; then
    find "$STASH" -type f | while read -r f; do
      mv "$f" "${f#$STASH/}"
    done
    rm -rf "$STASH"
  fi
}
trap restore EXIT INT TERM

lo=0; hi=$(( ${#ALL[@]} - 1 ))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  echo
  echo "── Round: lo=$lo hi=$hi mid=$mid (testing lower half [lo..mid]) ──"

  # Stash the UPPER half so only [lo..mid] remain under test.
  for (( i = mid + 1; i <= hi; i++ )); do
    f="${ALL[$i]}"
    mkdir -p "$STASH/$(dirname "$f")"
    mv "$f" "$STASH/$f"
  done

  if eval "$PREDICATE" >/dev/null 2>&1; then
    echo "  → lower half GOOD; bad file is in upper half"
    # Restore upper, stash lower for next iteration.
    find "$STASH" -type f | while read -r f; do mv "$f" "${f#$STASH/}"; done
    lo=$((mid + 1))
  else
    echo "  → lower half BAD; narrowing"
    find "$STASH" -type f | while read -r f; do mv "$f" "${f#$STASH/}"; done
    hi=$mid
  fi
done

echo
echo "═══════════════════════════════════════════"
echo "Culprit: ${ALL[$lo]}"
echo "═══════════════════════════════════════════"
