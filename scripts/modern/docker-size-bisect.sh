#!/usr/bin/env bash
# docker-size-bisect.sh
# Bisect Dockerfile instructions to find which line bloated the image.
#
# Strategy: comment out lines from the BOTTOM up, rebuild, measure size.
# Binary search the cutoff line.
set -uo pipefail

THRESHOLD_MB="${THRESHOLD_MB:?expected acceptable size in MB}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
# Count INSTRUCTIONS, and cut by instruction index throughout — mixing
# instruction counts with raw file line numbers (comments, FROM, WORKDIR…)
# would make the binary search walk a meaningless axis.
INSTR=$(grep -cE '^(RUN|COPY|ADD)' "$DOCKERFILE")

size_with_first() {  # keep the first $1 RUN/COPY/ADD instructions, cut the rest
  local cutoff="$1"
  awk -v c="$cutoff" '
    /^(RUN|COPY|ADD)/ { n++; if (n > c) { print "# CUT: " $0; next } }
    { print }
  ' "$DOCKERFILE" > /tmp/Dockerfile.bisect
  docker build -q -f /tmp/Dockerfile.bisect -t bisect:probe . >/dev/null 2>&1 || return 125
  docker image inspect bisect:probe --format '{{.Size}}'
}

lo=1; hi=$INSTR
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  if ! bytes=$(size_with_first "$mid"); then
    # Truncated Dockerfile didn't build (a later RUN needed a cut COPY).
    # Crude skip: assume the bloat is past the cutoff. A thorough version
    # probes neighboring cutoffs, like git's skip machinery (II.5).
    echo "instr 1..$mid: build failed — skipping"
    lo=$((mid + 1)); continue
  fi
  mb=$(( bytes / 1024 / 1024 ))
  echo "instr 1..$mid: $mb MB"
  if (( mb < THRESHOLD_MB )); then lo=$((mid + 1)); else hi=$mid; fi
done

echo "Bloat-introducing instruction (#$lo):"
awk -v n="$lo" '/^(RUN|COPY|ADD)/ { c++; if (c == n) { print; exit } }' "$DOCKERFILE"
