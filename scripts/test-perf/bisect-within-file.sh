# Bisect across test names inside one polluter file.
POLLUTER="$1"; SUSPECT="$2"
mapfile -t NAMES < <(
  pnpm exec vitest list --reporter=json "$POLLUTER" \
    | jq -r '.testModules[0].tasks[].name'
)
lo=0; hi=$((${#NAMES[@]} - 1))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  pattern=$(IFS='|'; echo "${NAMES[*]:lo:mid-lo+1}")
  if pnpm exec vitest run "$POLLUTER" -t "$pattern" "$SUSPECT" >/dev/null 2>&1; then
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo "Polluting test case: ${NAMES[$lo]}"
