#!/usr/bin/env bash
# A server may fork helpers. Killing only the parent leaves orphans.
# Start it in its own process group so you can kill the whole tree.

setsid some-server &       # creates new session + process group
SERVER_PGID=$!
# Caveat: $! equals the new PGID only because in a non-interactive shell
# the child isn't already a group leader, so util-linux setsid doesn't
# fork. With `setsid --fork` (or from an interactive shell) the PIDs
# diverge — read the pgid back with ps -o pgid= if in doubt.

# To kill the whole tree:
cleanup() {
  # Negative pid means "kill the process group". Critical.
  kill -- "-$SERVER_PGID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM
