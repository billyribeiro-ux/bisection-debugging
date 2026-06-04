#!/usr/bin/env bash
# Memoize predicate results across rounds. The same commit may be tested
# multiple times during a bisection (when good/bad endpoints overlap with
# a previous round). Cache results to skip the predicate.
declare -A RESULT_CACHE

check_commit() {
  local sha="$1"
  if [[ -n "${RESULT_CACHE[$sha]:-}" ]]; then
    echo "cache hit: $sha → ${RESULT_CACHE[$sha]}"
    return "${RESULT_CACHE[$sha]}"
  fi
  # ... expensive predicate work ...
  pnpm test >/dev/null 2>&1
  local rc=$?
  RESULT_CACHE[$sha]=$rc
  return $rc
}
