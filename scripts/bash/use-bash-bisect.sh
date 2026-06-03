#!/usr/bin/env bash
set -euo pipefail
source ./bash-bisect.sh

mapfile -t FILES < <(git ls-files '*.svelte' | sort)

# Define your predicate as a function. The subset is in "$@".
check() { pnpm exec svelte-check --filter "$@" >/dev/null 2>&1; }

CULPRIT=$(bisect_array FILES check)
echo "Will now fix: $CULPRIT"
