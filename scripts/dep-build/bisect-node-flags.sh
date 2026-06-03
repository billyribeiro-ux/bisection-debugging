#!/usr/bin/env bash
# Bisect which V8/Node flag in a long NODE_OPTIONS string causes a regression.
set -euo pipefail

FLAGS=(--experimental-vm-modules --enable-source-maps --no-warnings \
       --max-old-space-size=8192 --experimental-fetch --trace-deprecation \
       --inspect-publish-uid=stderr)

PREDICATE="pnpm test --run"

lo=0; hi=$(( ${#FLAGS[@]} - 1 ))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  subset=("${FLAGS[@]:lo:mid-lo+1}")
  NODE_OPTIONS="${subset[*]}" $PREDICATE >/dev/null 2>&1 \
    && lo=$((mid + 1)) || hi=$mid
  echo "narrowed to [$lo..$hi]"
done
echo "Culprit flag: ${FLAGS[$lo]}"
