#!/usr/bin/env bash
# When parallel workers must coordinate (e.g. share a result cache), use flock.
LOCKFILE=/tmp/bisect-state.lock
STATEFILE=/tmp/bisect-state.json

# Atomic update of shared state
update_state() {
  local sha="$1" result="$2"
  ( flock -w 5 200 && \
    jq --arg sha "$sha" --arg rc "$result" \
       '.results[$sha] = ($rc | tonumber)' "$STATEFILE" > "$STATEFILE.new" && \
    mv "$STATEFILE.new" "$STATEFILE"
  ) 200> "$LOCKFILE"
}

# Race-free check of whether a sha was already tested
check_cached() {
  local sha="$1"
  ( flock -s 200 && \
    jq -e --arg sha "$sha" '.results[$sha]' "$STATEFILE" 2>/dev/null
  ) 200< "$LOCKFILE"
}
