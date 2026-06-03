#!/usr/bin/env bash
# find-leak-by-stashing.sh
# Binary-halves by moving non-suspect files into .bisect-stash/, then running
# a project-wide predicate (e.g. `pnpm build`).
# Guarantees full restoration even on Ctrl-C, error, or kill.
set -euo pipefail
shopt -s globstar nullglob

PREDICATE="${1:?usage: $0 <predicate-cmd> <glob>}"
GLOB="${2:?missing glob}"
STASH="$(mktemp -d -p . .bisect-stash-XXXXXX)"

mapfile -t FILES < <(printf '%s\n' $GLOB | sort)

cleanup() {
  echo "Restoring stash…"
  if [ -d "$STASH" ]; then
    (cd "$STASH" && find . -type f -print) | while read -r rel; do
      mkdir -p "$(dirname "${rel#./}")"
      mv "$STASH/${rel#./}" "${rel#./}"
    done
    rm -rf "$STASH"
  fi
}
trap cleanup EXIT INT TERM

stash() {
  local f="$1"
  mkdir -p "$STASH/$(dirname "$f")"
  mv "$f" "$STASH/$f"
}
unstash() {
  local f="$1"
  mkdir -p "$(dirname "$f")"
  mv "$STASH/$f" "$f"
}

lo=0; hi=$(( ${#FILES[@]} - 1 ))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  # Stash UPPER half; predicate runs against [lo..mid].
  for (( i = mid + 1; i <= hi; i++ )); do stash "${FILES[$i]}"; done

  if $PREDICATE >/dev/null 2>&1; then
    # Lower half is clean → culprit is in upper half.
    for (( i = mid + 1; i <= hi; i++ )); do unstash "${FILES[$i]}"; done
    lo=$((mid + 1))
  else
    # Restore upper, then stash lower-upper for next round.
    for (( i = mid + 1; i <= hi; i++ )); do unstash "${FILES[$i]}"; done
    hi=$mid
  fi
done

echo "Culprit: ${FILES[$lo]}"
