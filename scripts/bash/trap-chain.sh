#!/usr/bin/env bash
# Multiple cleanup steps. Don't replace traps — chain them.

cleanup_db()     { dropdb "$TMPDB" 2>/dev/null || true; }
cleanup_server() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null; }
cleanup_files()  { rm -rf "$SCRATCH"; }

# Compose them with a master trap. NOT three separate `trap … EXIT` calls,
# because each `trap` REPLACES the previous one for that signal.
cleanup_all() {
  cleanup_server   # in reverse order of setup
  cleanup_db
  cleanup_files
}
trap cleanup_all EXIT INT TERM

# Setup steps (in the order they depend on each other)
SCRATCH=$(mktemp -d)
TMPDB=$(mktemp -u | sed 's|/.*/||')
createdb "$TMPDB"
SERVER_PID=$( pnpm start >/dev/null 2>&1 & echo $! )
