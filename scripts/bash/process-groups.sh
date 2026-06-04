#!/usr/bin/env bash
# A server may fork helpers. Killing only the parent leaves orphans.
# Start it in its own process group so you can kill the whole tree.

setsid some-server &       # creates new session + process group
SERVER_PGID=$!

# To kill the whole tree:
cleanup() {
  # Negative pid means "kill the process group". Critical.
  kill -- "-$SERVER_PGID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM
