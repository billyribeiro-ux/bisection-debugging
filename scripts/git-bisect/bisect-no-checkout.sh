#!/usr/bin/env bash
# Bisect without a single checkout. The working tree never changes; git
# only moves the ref BISECT_HEAD to the next commit to test.
set -euo pipefail

git bisect start --no-checkout HEAD v8.2.0

git bisect run bash -c '
  set -euo pipefail
  sha=$(git rev-parse BISECT_HEAD)
  tmp=$(mktemp -d)
  trap "rm -rf \"$tmp\"" EXIT

  # Materialize the tree to test WITHOUT touching your worktree, your
  # node_modules, or your editor file-watchers.
  git archive "$sha" | tar -x -C "$tmp"
  cd "$tmp" && ./run-fast-check.sh
'
git bisect reset
