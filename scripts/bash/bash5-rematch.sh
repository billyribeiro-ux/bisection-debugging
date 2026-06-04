#!/usr/bin/env bash
# Parse "p99=43.7ms fails=2/20" without invoking awk/sed.
line="p99=43.7ms fails=2/20"
if [[ "$line" =~ ^p99=([0-9.]+)ms\ fails=([0-9]+)/([0-9]+)$ ]]; then
  p99="${BASH_REMATCH[1]}"
  fails="${BASH_REMATCH[2]}"
  total="${BASH_REMATCH[3]}"
  echo "parsed: p99=$p99 fails=$fails/$total"
fi
