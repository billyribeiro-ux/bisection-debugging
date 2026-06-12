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

# 2) That trace is your DEBUGGING artifact: replay it forever, byte-exact,
#    and reverse-execute through it (next section). It is NOT a bisection
#    predicate — replaying re-runs the RECORDED binary; checking out other
#    commits changes nothing about a replay.

# 3) To bisect commits, the predicate RE-RECORDS at every step: rebuild,
#    hammer under chaos mode, report bad if any run bites. Chaos mode is
#    what makes the per-commit repro probability high enough to vote on.
cat > /tmp/rr-predicate.sh <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
make -s build || exit 125            # can't build → can't judge
for i in {1..30}; do
  if ! rr record --chaos -o "/tmp/rr-bisect-run" ./prog --selftest \
       >/dev/null 2>&1; then
    exit 1                           # captured a failing run AT THIS COMMIT
  fi
  rm -rf /tmp/rr-bisect-run          # passing traces are disposable
done
exit 0
EOF
chmod +x /tmp/rr-predicate.sh

echo "Starting git bisect with a re-record-per-commit chaos predicate."
LAST_GOOD="${LAST_GOOD:?set LAST_GOOD to the last-known-good SHA}"
git bisect start HEAD "$LAST_GOOD"
git bisect run /tmp/rr-predicate.sh
git bisect reset
# Bonus: when bisect stops, /tmp/rr-bisect-run holds a recording of the
# CULPRIT COMMIT failing — reverse-debug it immediately (next section).
