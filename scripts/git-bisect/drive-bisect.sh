#!/usr/bin/env bash
# drive-bisect.sh — end-to-end automated bisection between two refs.
set -euo pipefail

BAD="${1:-HEAD}"
GOOD="${2:?usage: drive-bisect.sh <bad-ref> <good-ref>}"
PREDICATE="${3:-./bisect-predicate.sh}"

chmod +x "$PREDICATE"

git bisect start
git bisect bad "$BAD"
git bisect good "$GOOD"
git bisect run "$PREDICATE" | tee /tmp/bisect-output.log

# Whatever happened, leave the repo clean.
git bisect log > /tmp/bisect-history.log
git bisect reset

# Surface the verdict.
grep -E "is the first bad commit" /tmp/bisect-output.log || \
  echo "Bisection inconclusive — check /tmp/bisect-output.log"
