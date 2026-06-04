#!/usr/bin/env bash
# GNU parallel: test a list of candidate SHAs in parallel, with a joblog
# for resumability.

git rev-list --reverse last-good..HEAD | parallel \
  --jobs 8 \
  --joblog /tmp/parallel.log \
  --keep-order \
  --tagstring "[{}]" \
  --halt now,fail=1 \
  '
    sha={};
    git worktree add -f "/tmp/wt-$sha" "$sha" 2>/dev/null
    ( cd "/tmp/wt-$sha" && ./predicate.sh )
    rc=$?
    git worktree remove -f "/tmp/wt-$sha" 2>/dev/null
    echo "$sha:$rc"
  '

cat /tmp/parallel.log    # see runtime per task
