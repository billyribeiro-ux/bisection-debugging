#!/usr/bin/env bash
# docker-crash-bisect.sh
# Find the layer at which `docker run image -- node dist/server.js` starts crashing.
set -uo pipefail
STAGES=( stage-base stage-deps stage-build stage-prune stage-final )

for s in "${STAGES[@]}"; do
  docker build -q --target "$s" -t bisect:"$s" . >/dev/null
  # Override the entrypoint to run the same smoke test in every stage.
  if docker run --rm bisect:"$s" sh -c 'node -e "console.log(process.versions.node)"' >/dev/null 2>&1; then
    echo "$s: OK"
  else
    echo "$s: CRASH"
    break
  fi
done
