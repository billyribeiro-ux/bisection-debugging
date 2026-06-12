#!/usr/bin/env bash
# Phase 1: bisect DATES over nightly artifacts (cheap, day-granular).
# Phase 2: git bisect the one remaining day (expensive, commit-granular).
# Uses GNU date; on macOS: brew install coreutils and use gdate.
set -euo pipefail

to_epoch() { date -d "$1" +%s; }
to_date()  { date -d "@$1" +%F; }
day=86400

test_nightly() {  # $1 = YYYY-MM-DD → 0 good, 1 bad, 125 no build that day
  local url="https://nightlies.example.com/myapp-$1.tgz" t
  t=$(mktemp -d) || return 1
  curl -sfL "$url" -o "$t/n.tgz" || { rm -rf "$t"; return 125; }
  tar -xzf "$t/n.tgz" -C "$t" && "$t/myapp" --selftest
  local rc=$?; rm -rf "$t"; return $rc
}

g=$(to_epoch 2026-03-01)   # last known-good nightly
b=$(to_epoch 2026-05-30)   # first known-bad nightly

while (( b - g > day )); do
  mid=$(( (g + b) / 2 / day * day ))
  rc=0
  for off in 0 -1 1 -2 2; do        # nightlies have gaps; probe neighbors
    d=$(to_date $(( mid + off * day )))
    rc=0; test_nightly "$d" || rc=$?
    (( rc != 125 )) && break
  done
  (( rc == 125 )) && { echo "no builds near $(to_date "$mid")" >&2; exit 1; }
  if (( rc == 0 )); then g=$(to_epoch "$d"); else b=$(to_epoch "$d"); fi
done
echo "regressed between $(to_date "$g") and $(to_date "$b")"

# Phase 2 — commit-granular, but only one day of commits to build:
git bisect start \
  "$(git rev-list -1 --before="$(to_date "$b") 23:59" origin/main)" \
  "$(git rev-list -1 --before="$(to_date "$g") 23:59" origin/main)"
git bisect run ./predicate.sh
