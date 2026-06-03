# Run the predicate, but cache pass/fail by the SHA of the input file list.
predicate_memo() {
  local key
  key="$(printf '%s\n' "$@" | sort | sha256sum | cut -d' ' -f1)"
  local cache=".bisect-cache/$key"
  mkdir -p .bisect-cache
  if [ -f "$cache" ]; then
    return "$(cat "$cache")"
  fi
  pnpm exec svelte-check --filter "$@" >/dev/null 2>&1
  local rc=$?
  echo "$rc" > "$cache"
  return "$rc"
}
