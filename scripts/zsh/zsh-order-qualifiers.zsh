#!/usr/bin/env zsh
# Order matters when bisecting — you want a deterministic sort.

# Mnemonic: lowercase o = "most X first" for time/size (om = newest,
# oL = SMALLEST); uppercase O reverses it. Easy to get backwards — test
# with `print -l` before trusting a bisection to it.
newest_first=( **/*(om)  )    # mtime: newest first
oldest_first=( **/*(Om)  )    # mtime: oldest first
largest_first=( **/*(OL) )    # size descending (oL would be ascending!)
alphabetical=( **/*(on)   )   # by name (default)

# Take the first 10 most recently modified .test.ts files:
recent10=( **/*.test.ts(.om[1,10]) )
#                            └──┬──┘
#                              └── subscript: items 1 through 10
