#!/usr/bin/env bash
# A manual bisection driver that prefers near-optimal midpoints with a
# pre-built CI artifact over the optimal midpoint that needs a 12-minute
# local build. The information loss is 1-2 eliminations; the time saved
# per round is the whole build.
set -euo pipefail
GOOD=$1 BAD=$2

have_artifact() { curl -sfIo /dev/null "https://ci.example.com/builds/$1.tgz"; }

while :; do
  n=$(git rev-list --count "$BAD" ^"$GOOD")
  if (( n <= 1 )); then echo "first bad commit: $(git rev-parse "$BAD")"; break; fi

  pick=""
  while read -r sha dist; do
    dist=${dist//[^0-9]/}            # "(dist=14)" → 14
    (( dist == 0 )) && continue      # zero-information candidates (e.g. BAD itself)
    if have_artifact "$sha"; then pick=$sha; break; fi
  done < <(git rev-list --bisect-all "$BAD" ^"$GOOD" | head -20)

  # No cached build near the top? Fall back to the optimal midpoint.
  [[ -z "$pick" ]] && pick=$(git rev-list --bisect "$BAD" ^"$GOOD")

  if ./predicate.sh "$pick"; then GOOD=$pick; else BAD=$pick; fi
done
