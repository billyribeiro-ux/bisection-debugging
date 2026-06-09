#!/usr/bin/env bash
# svelte-check-subset.sh — run svelte-check against ONLY the given files.
# svelte-check has no per-file CLI mode; it diagnoses whatever its tsconfig
# matches. So: write a throwaway tsconfig whose "files" list is exactly the
# subset, and point --tsconfig at it.
set -euo pipefail

CFG="tsconfig.bisect.json"     # must live in the project root so that
trap 'rm -f "$CFG"' EXIT       # "extends": "./tsconfig.json" resolves

{
  printf '{ "extends": "./tsconfig.json", "files": ['
  printf '"%s",' "$@" | sed 's/,$//'
  printf '] }\n'
} > "$CFG"

exec pnpm exec svelte-check --tsconfig "./$CFG"
