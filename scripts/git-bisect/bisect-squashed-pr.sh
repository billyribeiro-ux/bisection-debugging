#!/usr/bin/env bash
# bisect-squashed-pr.sh — bisect inside a squashed PR by replaying its branch.
set -euo pipefail

PR_NUMBER="${1:?usage: bisect-squashed-pr.sh <pr-number>}"
SQUASH_COMMIT="${2:?<squash-commit-sha>}"

# 1) Most providers (GitHub, GitLab) keep the original PR branch reachable via
#    a special ref. For GitHub:  refs/pull/<n>/head
git fetch origin "refs/pull/$PR_NUMBER/head:bisect-pr-$PR_NUMBER"

PR_TIP="bisect-pr-$PR_NUMBER"
PR_BASE="$(git merge-base "$PR_TIP" "$SQUASH_COMMIT^")"

echo "PR branch tip: $PR_TIP"
echo "PR branch base: $PR_BASE"

# 2) Cherry-pick the PR onto a known-good base so bisection has a linear history.
git checkout -b bisect-replay "$PR_BASE"
git cherry-pick "$PR_BASE..$PR_TIP" || {
  echo "Cherry-pick conflicts — resolve and run 'git cherry-pick --continue'"
  exit 1
}

# 3) Now bisect inside the cherry-picked range.
git bisect start
git bisect bad HEAD            # bug present after the whole PR
git bisect good "$PR_BASE"     # bug absent before the PR
git bisect run ./bisect-predicate.sh

git bisect reset
git checkout -
git branch -D bisect-replay bisect-pr-$PR_NUMBER
