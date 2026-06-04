#!/usr/bin/env zsh
# Order matters when bisecting — you want a deterministic sort.

newest_first=( **/*(om)  )    # mtime descending
oldest_first=( **/*(Om)  )    # mtime ascending
largest_first=( **/*(oL) )    # size descending
alphabetical=( **/*(on)   )   # by name (default)

# Take the first 10 most recently modified .test.ts files:
recent10=( **/*.test.ts(.om[1,10]) )
#                            └──┬──┘
#                              └── subscript: items 1 through 10
