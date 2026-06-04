#!/usr/bin/env bash
# data-shard-bisect.sh
# When the model is fine, but adding a new dataset shard regresses an eval,
# bisect across shards to find which one is "poisoning" the model.
#
# REQUIRES: A retrain loop that accepts a SHARDS env var (list of shard paths).
set -euo pipefail

mapfile -t SHARDS < shards.txt
THRESHOLD=0.72

train_and_eval() {
  local shards=( "$@" )
  rm -rf /tmp/exp-ckpt
  SHARDS="${shards[*]}" OUTPUT=/tmp/exp-ckpt ./retrain.sh
  CHECKPOINT=/tmp/exp-ckpt THRESHOLD="$THRESHOLD" node checkpoint-eval-predicate.mjs
}

lo=0; hi=$(( ${#SHARDS[@]} - 1 ))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  subset=( "${SHARDS[@]:0:mid+1}" )
  if train_and_eval "${subset[@]}"; then
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo "Poisoning shard: ${SHARDS[$lo]}"
