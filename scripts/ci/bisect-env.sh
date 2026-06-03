#!/usr/bin/env bash
# bisect-env.sh
# Capture a working env and a broken env, find which variable broke things.
#
# To capture: `env > good.env`  on a healthy machine; `env > bad.env` on a sick one.
set -euo pipefail

GOOD="$1"; BAD="$2"; PRED="$3"

# Variables that DIFFER between the two envs.
diff_keys=$(comm -13 <(sort "$GOOD") <(sort "$BAD") | awk -F= '{print $1}' | sort -u)
mapfile -t VARS < <(echo "$diff_keys")
echo "Differing env vars: ${#VARS[@]}"

declare -A BAD_VAL
while IFS='=' read -r k v; do BAD_VAL["$k"]="$v"; done < "$BAD"

# Bisect: start from GOOD env, progressively apply BAD overrides.
run_with() {
  local -a apply=( "$@" )
  ( set -a
    while IFS='=' read -r k v; do export "$k=$v"; done < "$GOOD"
    for k in "${apply[@]}"; do export "$k=${BAD_VAL[$k]}"; done
    bash -c "$PRED"
  )
}

lo=0; hi=$(( ${#VARS[@]} - 1 ))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  apply=( "${VARS[@]:0:mid+1}" )
  if run_with "${apply[@]}" >/dev/null 2>&1; then
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo "Culprit env var: ${VARS[$lo]}"
echo "  good value: $(grep -E "^${VARS[$lo]}=" "$GOOD" | head -n1)"
echo "  bad value:  ${VARS[$lo]}=${BAD_VAL[${VARS[$lo]}]}"
