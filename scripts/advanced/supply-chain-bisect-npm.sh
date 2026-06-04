#!/usr/bin/env bash
# supply-chain-bisect-npm.sh
# Bisect across npm-registry publish times to find the date a package began
# misbehaving. Uses the npm CLI's --before flag as a resolver only; the
# eventual install is via pnpm to stay consistent with the rest of the project.
#
# USAGE:
#   ./supply-chain-bisect-npm.sh <package> <good-date> <bad-date> "<predicate-cmd>"
#
#   ./supply-chain-bisect-npm.sh lodash 2025-12-01 2026-06-01 "node check-side-effects.mjs"
#
set -euo pipefail

PKG="$1"; GOOD="$2"; BAD="$3"; PRED="$4"

command -v npm >/dev/null || { echo "npm CLI required for --before resolution"; exit 2; }
command -v pnpm >/dev/null || { echo "pnpm required for the actual install"; exit 2; }

iso_to_epoch() { date -u -d "$1" +%s; }
epoch_to_iso() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ; }

LO=$(iso_to_epoch "$GOOD")
HI=$(iso_to_epoch "$BAD")

install_at() {
  local ts="$1"
  local iso="$(epoch_to_iso "$ts")"
  rm -rf node_modules pnpm-lock.yaml
  # Resolve "latest as of $iso" via npm view, then install that exact version via pnpm.
  local version
  version=$(npm view "$PKG" time --json \
    | jq -r --arg at "$iso" 'to_entries | map(select(.value <= $at and (.key | test("^[0-9]")))) | sort_by(.value) | last | .key')
  [ -z "$version" ] || [ "$version" = "null" ] && { echo "no version <= $iso"; return 1; }
  pnpm add --no-fund --silent "$PKG@$version"
}

while (( HI - LO > 86400 )); do  # narrow to a 24-hour window
  MID=$(( (LO + HI) / 2 ))
  install_at "$MID"
  if eval "$PRED" >/dev/null 2>&1; then
    LO=$MID
  else
    HI=$MID
  fi
  echo "narrowed to [$(epoch_to_iso "$LO")..$(epoch_to_iso "$HI")]"
done

# At ±1 day, list every publish in that window and identify the exact one.
npm view "$PKG" time --json | jq -r 'to_entries[] | select(.value > "'"$(epoch_to_iso "$LO")"'" and .value < "'"$(epoch_to_iso "$HI")"'") | "\(.value)  \(.key)"'
