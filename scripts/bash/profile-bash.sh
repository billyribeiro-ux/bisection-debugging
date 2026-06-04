# Trace with timestamps to find the slow steps.
export PS4='+ $EPOCHREALTIME ${BASH_SOURCE##*/}:${LINENO}: '
set -x
./predicate.sh 2> /tmp/trace.log
set +x

# Now compute per-line time deltas:
awk '
  /^\+ [0-9]+\.[0-9]+ / {
    t = $2
    if (prev_t != 0) print (t - prev_t) "s  " $0
    prev_t = t
  }
' /tmp/trace.log | sort -rn | head -20
