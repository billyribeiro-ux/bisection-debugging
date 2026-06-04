#!/usr/bin/env bash
# docker-size-bisect.sh
# Bisect Dockerfile instructions to find which line bloated the image.
#
# Strategy: comment out lines from the BOTTOM up, rebuild, measure size.
# Binary search the cutoff line.
set -uo pipefail

THRESHOLD_MB="${THRESHOLD_MB:?expected acceptable size in MB}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
LINES=$(grep -cE '^(RUN|COPY|ADD)' "$DOCKERFILE")

size_at_line() {
  local cutoff="$1"
  awk -v c="$cutoff" 'NR<=c { print; next } /^(RUN|COPY|ADD)/ { print "# CUT: "$0; next } { print }' \
    "$DOCKERFILE" > /tmp/Dockerfile.bisect
  docker build -q -f /tmp/Dockerfile.bisect -t bisect:probe . >/dev/null 2>&1 || return 125
  docker image inspect bisect:probe --format '{{.Size}}'
}

lo=1; hi=$LINES
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  bytes=$(size_at_line "$mid")
  mb=$(( bytes / 1024 / 1024 ))
  echo "lines 1..$mid: $mb MB"
  if (( mb < THRESHOLD_MB )); then lo=$((mid + 1)); else hi=$mid; fi
done

echo "Bloat-introducing instruction is on line $lo (or just before)."
awk "NR==$lo" "$DOCKERFILE"
