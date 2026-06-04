#!/usr/bin/env bash
# supply-chain-bisect-npm.sh
# Bisect across npm publish times to find the date a package began misbehaving.
#
# USAGE:
#   ./supply-chain-bisect-npm.sh <package> <good-date> <bad-date> "<predicate-cmd>"
#
#   ./supply-chain-bisect-npm.sh lodash 2025-12-01 2026-06-01 "node check-side-effects.mjs"
#
set -euo pipefail

PKG="$1"; GOOD="$2"; BAD="$3"; PRED="$4"

iso_to_epoch() { date -u -d "$1" +%s; }
epoch_to_iso() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ; }

LO=$(iso_to_epoch "$GOOD")
HI=$(iso_to_epoch "$BAD")

install_at() {
  local ts="$1"
  local iso="$(epoch_to_iso "$ts")"
  rm -rf node_modules package-lock.json
  # npm --before installs the latest version available at that timestamp.
  # Pinning the cache prevents leakage.
  npm install --before="$iso" --no-fund --no-audit --silent "$PKG"
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
