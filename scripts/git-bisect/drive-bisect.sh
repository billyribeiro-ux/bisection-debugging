#!/usr/bin/env bash
# drive-bisect.sh — end-to-end automated bisection between two refs.
set -euo pipefail

BAD="${1:-HEAD}"
GOOD="${2:?usage: drive-bisect.sh <bad-ref> <good-ref>}"
PREDICATE="${3:-./bisect-predicate.sh}"

chmod +x "$PREDICATE"

# Whatever happens — including `git bisect run` itself failing under
# set -e (predicate exit ≥128, inconsistent marks) — leave the repo clean.
# Without the trap, a failed run would abort BEFORE the reset and strand
# you mid-bisection on a detached HEAD.
cleanup() {
  git bisect log > /tmp/bisect-history.log 2>/dev/null || true
  git bisect reset
}
trap cleanup EXIT

git bisect start
git bisect bad "$BAD"
git bisect good "$GOOD"
git bisect run "$PREDICATE" | tee /tmp/bisect-output.log

# Surface the verdict.
grep -E "is the first bad commit" /tmp/bisect-output.log || \
  echo "Bisection inconclusive — check /tmp/bisect-output.log"
