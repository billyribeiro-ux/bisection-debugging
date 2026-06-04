#!/usr/bin/env bash
# rr-bisect.sh
# Workflow for using rr to make a race condition deterministic, then bisecting
# across git commits to find the one that introduced it.
#
# Prereq: sudo apt install rr  (Linux; kernel.perf_event_paranoid must be ≤1).
set -euo pipefail

PROG="${1:?usage: $0 <prog> <args...>}"; shift

# 1) Record runs until we capture one that exhibits the bug.
echo "Recording $PROG until we catch the race…"
for i in {1..50}; do
  rr record --chaos -o "/tmp/rr-trace-$i" "$PROG" "$@" \
    && echo "Run $i: PASS" \
    || { echo "Run $i: BUG! Trace saved to /tmp/rr-trace-$i"; SAVED="/tmp/rr-trace-$i"; break; }
done
[ -z "${SAVED:-}" ] && { echo "Could not reproduce in 50 chaos-mode runs."; exit 1; }

# 2) Build a deterministic predicate: replay the trace, exit with prog's status.
cat > /tmp/replay-predicate.sh <<EOF
#!/usr/bin/env bash
rr replay "$SAVED" -a 2>/dev/null >/dev/null
EOF
chmod +x /tmp/replay-predicate.sh

# 3) Now the bug is deterministic — bisect git history with `git bisect run`.
echo "Starting git bisect against the recorded trace."
LAST_GOOD="${LAST_GOOD:?set LAST_GOOD to the last-known-good SHA}"
git bisect start HEAD "$LAST_GOOD"
git bisect run /tmp/replay-predicate.sh
git bisect reset
