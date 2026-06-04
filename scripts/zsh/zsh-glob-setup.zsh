#!/usr/bin/env zsh
# Imagine a predicate that runs the test suite, but only for tests modified
# in the last 7 days. In bash you'd write a find pipeline. In zsh:

modified_tests=(tests/**/*.test.ts(.mw-7))
#                                  └─┬─┘
#                                    │
#                                    ├ . = regular files only
#                                    └ mw-7 = modified within 7 days (m = mtime, w = weeks)

print "Running ${#modified_tests} recent tests"
pnpm exec vitest run "${modified_tests[@]}" || exit 1
