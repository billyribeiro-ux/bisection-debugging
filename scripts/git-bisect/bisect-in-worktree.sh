#!/usr/bin/env bash
# Run the whole bisection in a linked worktree. Your main checkout — and
# your IDE, dev server, and node_modules — never notice it happening.
set -euo pipefail

git worktree add --detach ../bisect-wt HEAD
cd ../bisect-wt

git bisect start HEAD v3.1.0
git bisect run ./scripts/predicate.sh
git bisect log > /tmp/bisect-result.log
git bisect reset

cd - && git worktree remove ../bisect-wt

# Bisect state (refs/bisect/*, BISECT_HEAD) is per-worktree. Two worktrees
# can therefore bisect two DIFFERENT bugs in the same repo simultaneously:
#   git worktree add --detach ../bisect-bug-1124 HEAD
#   git worktree add --detach ../bisect-bug-1187 HEAD
