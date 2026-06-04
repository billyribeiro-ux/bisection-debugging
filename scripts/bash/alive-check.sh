#!/usr/bin/env bash
# kill -0 sends no signal — just checks if the process exists and is signal-able.
if kill -0 "$SERVER" 2>/dev/null; then
  echo "still alive"
else
  echo "dead — collecting exit code"
  wait "$SERVER"; rc=$?
fi
