#!/usr/bin/env bash
# find-leak-binary.sh
# Binary-halves a set of files to find the one that breaks the checker.
# Works with any check command that accepts a file list as arguments.
#
# WHY THIS WORKS:
#   tsc, eslint, and biome accept multiple files at once. If we hand the
#   checker half the project and it passes, the bad file is in the other
#   half. Recurse. log₂(N) invocations instead of N.
#
#   svelte-check is the exception: it has NO per-file CLI mode. Wrap it
#   with the --tsconfig trick (svelte-check-subset.sh, below) first.
#
# USAGE:
#   ./find-leak-binary.sh "pnpm exec eslint"          "src/lib/**/*.svelte"
#   ./find-leak-binary.sh "pnpm exec tsc --noEmit"    "src/**/*.ts"
#   ./find-leak-binary.sh "./svelte-check-subset.sh"  "src/lib/**/*.svelte"
#
# CAVEAT (tsc): when files are passed on the CLI, tsc IGNORES tsconfig.json.
#   If your project relies on compilerOptions to typecheck cleanly, use a
#   generated tsconfig with a "files" list instead (same trick as the
#   svelte-check wrapper below).
#
# OUTPUT:
#   The exact file that, in isolation, fails the predicate.
#
set -euo pipefail
shopt -s globstar nullglob

CHECK_CMD="${1:?usage: $0 \"<check-cmd>\" \"<glob>\"}"
GLOB="${2:?missing glob}"

# Expand glob → array. Sorted for deterministic, resumable runs.
mapfile -t FILES < <(printf '%s\n' $GLOB | sort)
N="${#FILES[@]}"
echo "Bisecting $N files with: $CHECK_CMD"

# Sanity check: the FULL set must actually fail. Otherwise nothing to find.
if $CHECK_CMD "${FILES[@]}" >/dev/null 2>&1; then
  echo "Predicate passes on full set — nothing to bisect."
  exit 0
fi

lo=0
hi=$((N - 1))
round=0

while (( lo < hi )); do
  round=$((round + 1))
  mid=$(( (lo + hi) / 2 ))
  lower=("${FILES[@]:lo:mid-lo+1}")

  printf "round %2d: testing %d files (indices %d..%d)\n" \
    "$round" "${#lower[@]}" "$lo" "$mid"

  if $CHECK_CMD "${lower[@]}" >/dev/null 2>&1; then
    # Lower half is clean → culprit is in upper half.
    lo=$((mid + 1))
  else
    # Lower half fails → culprit is in lower half.
    hi=$mid
  fi
done

echo
echo "═══════════════════════════════════════════"
echo "Culprit file: ${FILES[$lo]}"
echo "═══════════════════════════════════════════"

# Show the actual error for the culprit.
echo
echo "Reproducing error:"
$CHECK_CMD "${FILES[$lo]}" || true
