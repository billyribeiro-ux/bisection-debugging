#!/usr/bin/env bash
# verify-culprit.sh
# Given the SHA the bisector returned, confirm it really is the culprit.
set -euo pipefail
CULPRIT="$1"

# Record the starting point: after two checkouts below, `git checkout -`
# would bounce to the PREVIOUS checkout (the culprit), not back here.
START="$(git rev-parse --abbrev-ref HEAD)"

# 1) Predicate must FAIL at the culprit.
git checkout "$CULPRIT"
./bisect-predicate.sh && { echo "WAT: culprit passes the predicate"; exit 2; }

# 2) Predicate must PASS at the culprit's PARENT.
git checkout "$CULPRIT^"
./bisect-predicate.sh || { echo "WAT: parent already failing — bisection was off"; exit 2; }

# 3) Reverting the culprit on top of HEAD must make HEAD pass.
git checkout "$START"
git revert --no-edit "$CULPRIT"
./bisect-predicate.sh && echo "CONFIRMED: revert fixes HEAD" || echo "Revert does NOT fix — interaction bug"
git reset --hard HEAD^   # undo the revert
