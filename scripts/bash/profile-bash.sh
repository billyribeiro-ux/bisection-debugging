# Trace with timestamps to find the slow steps.
# NOTE: `set -x` here would NOT trace into a child script launched via its
# shebang — the trace must be enabled IN the child: run it as `bash -x`.
export PS4='+ $EPOCHREALTIME ${BASH_SOURCE##*/}:${LINENO}: '
bash -x ./predicate.sh 2> /tmp/trace.log

# Now compute per-line time deltas:
awk '
  /^\+ [0-9]+\.[0-9]+ / {
    t = $2
    if (prev_t != 0) print (t - prev_t) "s  " $0
    prev_t = t
  }
' /tmp/trace.log | sort -rn | head -20
