#!/usr/bin/env bash
# A grab-bag of Bash idioms that come up constantly in bisection scripts.

# 1) Read a list of files NUL-separated (handles spaces, newlines in names).
mapfile -d '' -t FILES < <(git ls-files -z '*.svelte')

# 2) Run a predicate against each file in parallel, fail-fast on first failure.
printf '%s\0' "${FILES[@]}" | xargs -0 -n 1 -P 8 \
  bash -c 'pnpm exec svelte-check --filter "$0" >/dev/null 2>&1 || { echo "FAIL: $0"; exit 1; }'

# 3) Compute a SHA of a set of files (for memoization keys).
KEY=$(printf '%s\n' "${FILES[@]}" | sort | sha256sum | cut -c1-12)

# 4) Difference between two arrays (e.g. "all files except suspect set").
all=( "${ALL_FILES[@]}" )
suspects=( "${SUSPECTS[@]}" )
others=()
declare -A in_suspects
for s in "${suspects[@]}"; do in_suspects["$s"]=1; done
for f in "${all[@]}"; do [[ -z "${in_suspects[$f]:-}" ]] && others+=( "$f" ); done

# 5) Run a command with a deadline.
timeout 30s "$PRED" "$@"
case $? in
  0)   echo "passed";;
  1)   echo "failed";;
  124) echo "TIMED OUT — count as bad? or skip?";;
esac

# 6) Save & restore git state around any bisection that edits the worktree.
trap 'git stash pop >/dev/null 2>&1 || true' EXIT
git stash push -u -m "bisect-runtime" >/dev/null
# … run experimental bisection that edits files …
