#!/usr/bin/env bash
# Read two streams in parallel and pair their outputs — useful for
# diff-style observation (current vs baseline).
while IFS= read -r baseline_line && IFS= read -r current_line <&3; do
  if [[ "$baseline_line" != "$current_line" ]]; then
    echo "DIFF: $baseline_line | $current_line"
  fi
done < <(produce-baseline) 3< <(produce-current)
