#!/usr/bin/env bash
# Some predicates spin up a DB, run dozens of queries, tear down. The fork
# cost dominates. Use a coprocess: start the helper once, pipe queries to it.

coproc PSQL { psql -A -t -d testdb 2>/dev/null; }
trap 'kill "$PSQL_PID" 2>/dev/null' EXIT

ask() {
  echo "$1" >& "${PSQL[1]}"
  IFS= read -r -u "${PSQL[0]}" answer
  echo "$answer"
}

for sha in "$@"; do
  count=$(ask "SELECT COUNT(*) FROM users WHERE created_sha = '$sha';")
  echo "$sha → $count users"
done
