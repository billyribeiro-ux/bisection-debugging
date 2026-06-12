#!/usr/bin/env bash
# git's midpoint machinery, exposed as plumbing. BAD and GOOD are any revs.
set -euo pipefail
BAD=${1:-HEAD} GOOD=${2:-HEAD~200}

# How big is the candidate set right now?
git rev-list --count "$BAD" ^"$GOOD"

# The commit `git bisect` would test next — no session required.
git rev-list --bisect "$BAD" ^"$GOOD"

# Shell-evaluable stats about the upcoming step.
eval "$(git rev-list --bisect-vars "$BAD" ^"$GOOD")"
echo "next to test:          $bisect_rev"
echo "candidates now:        $bisect_all"
echo "left if it tests good: $bisect_good"
echo "left if it tests bad:  $bisect_bad"
echo "steps after this one:  $bisect_steps"

# EVERY candidate, ranked. dist = the min() weight from the algorithm:
# the number of candidates guaranteed to be eliminated by testing it.
git rev-list --bisect-all "$BAD" ^"$GOOD" | head -8
#   3fb1a9e2… (dist=68)     ← what --bisect returns
#   91c04d77… (dist=67)     ← nearly as informative
#   …                       ← dist decays slowly near the top
