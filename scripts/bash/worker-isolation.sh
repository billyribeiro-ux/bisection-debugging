#!/usr/bin/env bash
# Each worker needs its own DB, port, scratch dir, etc. The cheapest way:
# parametrize by worker ID, derive everything from it.

parallel --jobs 4 '
  WORKER_ID={%}
  PORT=$((30000 + WORKER_ID))
  DB="bisect_w${WORKER_ID}"
  SCRATCH="/tmp/bisect-w${WORKER_ID}"
  export PORT DB SCRATCH

  # Now the predicate uses these unique-per-worker resources.
  ./predicate.sh "{}"
' ::: $(git rev-list --reverse last-good..HEAD)
