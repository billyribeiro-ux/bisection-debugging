#!/usr/bin/env zsh
# Drive a node REPL to test "does evaluating this expression hang?"
zmodload zsh/zpty

zpty NODE 'node --experimental-vm-modules'
zpty -w NODE 'const result = await import("./src/buggy.mjs"); console.log(result.value);'
zpty -r -t NODE OUTPUT 5    # read with 5-second timeout
zpty -d NODE                # close the pty

if (( $#OUTPUT == 0 )); then
  exit 1                    # hung — predicate says "bad"
elif [[ "$OUTPUT" == *"42"* ]]; then
  exit 0                    # got the expected value
else
  exit 1
fi
