#!/usr/bin/env bash
# Slow, classic approach:
files=()
while IFS= read -r line; do files+=("$line"); done < suspect-files.txt

# Faster + safer (no IFS gotchas):
mapfile -t files < suspect-files.txt

# With a callback to process each line as it arrives (streaming):
mapfile -t -c 100 -C 'show_progress' files < huge-list.txt
