# Bisect across test names inside one polluter file.
POLLUTER="$1"; SUSPECT="$2"
VFLAGS=(--no-file-parallelism --no-isolate --reporter=dot)

# -t is a regex; test names with (, ), ?, + etc. must be escaped.
esc() { sed 's/[][\\.|$(){}?+*^]/\\&/g' <<< "$1"; }

mapfile -t NAMES < <(pnpm exec vitest list --json "$POLLUTER" | jq -r '.[].name')
# -t filters EVERY selected file, so always include the suspect's tests.
SUSPECT_PAT=$(pnpm exec vitest list --json "$SUSPECT" | jq -r '.[].name' \
  | while read -r n; do esc "$n"; done | paste -sd'|' -)

lo=0; hi=$((${#NAMES[@]} - 1))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  subset_pat=$(for n in "${NAMES[@]:lo:mid-lo+1}"; do esc "$n"; done | paste -sd'|' -)
  if pnpm exec vitest run "${VFLAGS[@]}" "$POLLUTER" "$SUSPECT" \
       -t "$subset_pat|$SUSPECT_PAT" >/dev/null 2>&1; then
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo "Polluting test case: ${NAMES[$lo]}"
