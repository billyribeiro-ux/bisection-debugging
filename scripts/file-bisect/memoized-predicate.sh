# Run the predicate, but cache pass/fail keyed by the file CONTENTS.
# Keying on names alone would serve stale verdicts after you edit a file —
# precisely the moment you'll re-run the bisection.
predicate_memo() {
  local key
  key="$( { printf '%s\n' "$@" | sort; sha256sum "$@" | sort; } \
          | sha256sum | cut -d' ' -f1)"
  local cache=".bisect-cache/$key"
  mkdir -p .bisect-cache
  if [ -f "$cache" ]; then
    return "$(cat "$cache")"
  fi
  ./svelte-check-subset.sh "$@" >/dev/null 2>&1
  local rc=$?
  echo "$rc" > "$cache"
  return "$rc"
}
