#!/usr/bin/env bash
# bisect-fleet.sh
# Find which service's image bump broke a multi-service environment.
#
# INPUT FILES:
#   old-tags.env, new-tags.env — each like:
#       checkout=ghcr.io/acme/checkout:1.4.2
#       payments=ghcr.io/acme/payments:2.0.0
#       ...
#
# USAGE:
#   ./bisect-fleet.sh old-tags.env new-tags.env "./run-e2e.sh"
#
set -euo pipefail
OLD_FILE="$1"; NEW_FILE="$2"; PREDICATE="$3"

mapfile -t SERVICES < <(awk -F= '{print $1}' "$OLD_FILE" | sort)
N="${#SERVICES[@]}"
declare -A OLD NEW
while IFS='=' read -r k v; do OLD["$k"]="$v"; done < "$OLD_FILE"
while IFS='=' read -r k v; do NEW["$k"]="$v"; done < "$NEW_FILE"

apply_tags() {
  local -a chosen_new=( "$@" )
  declare -A is_new
  for s in "${chosen_new[@]}"; do is_new["$s"]=1; done
  # Build a values.yaml override with one image per service.
  : > /tmp/overrides.yaml
  for s in "${SERVICES[@]}"; do
    local tag="${OLD[$s]}"; [[ -n "${is_new[$s]:-}" ]] && tag="${NEW[$s]}"
    cat >> /tmp/overrides.yaml <<YAML
$s:
  image: ${tag%:*}
  tag: ${tag##*:}
YAML
  done
  helm upgrade --install platform ./chart -f /tmp/overrides.yaml --wait --timeout 5m
}

# Confirm endpoints of the search:
apply_tags                          # all OLD → should pass
$PREDICATE || { echo "Baseline broken; not a bump regression"; exit 2; }
apply_tags "${SERVICES[@]}"         # all NEW → should fail
$PREDICATE && { echo "All-new passes; nothing to find"; exit 0; }

# Bisect.
lo=0; hi=$((N - 1))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  new_set=( "${SERVICES[@]:0:mid+1}" )
  apply_tags "${new_set[@]}"
  echo "applying NEW for [0..$mid] (${#new_set[@]} services)"
  if $PREDICATE; then
    lo=$((mid + 1))    # this prefix is fine; bad bump is later
  else
    hi=$mid            # bad bump is within or before mid
  fi
done
echo "Culprit service: ${SERVICES[$lo]}"
echo "Old: ${OLD[${SERVICES[$lo]}]}"
echo "New: ${NEW[${SERVICES[$lo]}]}"
