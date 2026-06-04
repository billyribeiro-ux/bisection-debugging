#!/usr/bin/env bash
# When you want to find ANY commit that has property X, not all of them.
# E.g. "find any commit where the test passes" or "find the first working
# version" — useful for hunting fixes, not bugs.

git rev-list --reverse last-known-bad..HEAD | parallel \
  --jobs 4 \
  --halt now,success=1 \
  '
    if ./predicate.sh; then
      echo "FOUND: {}"
      exit 0
    fi
  '
