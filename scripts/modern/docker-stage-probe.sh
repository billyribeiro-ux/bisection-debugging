#!/usr/bin/env bash
# Build a target stage and inspect its size.
STAGE="${1:-stage-final}"
docker build --target "$STAGE" -t bisect:"$STAGE" .
docker image ls bisect:"$STAGE" --format '{{.Size}}'
