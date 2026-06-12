#!/usr/bin/env zsh
# Imagine a predicate that runs the test suite, but only for tests modified
# in the last 7 days. In bash you'd write a find pipeline. In zsh:

modified_tests=(tests/**/*.test.ts(.m-7))
#                                  └─┬─┘
#                                    │
#                                    ├ . = regular files only
#                                    └ m-7 = mtime within 7 DAYS (the default
#                                      unit is days; mw-1 would be one week,
#                                      mh-12 twelve hours)

print "Running ${#modified_tests} recent tests"
pnpm exec vitest run "${modified_tests[@]}" || exit 1
