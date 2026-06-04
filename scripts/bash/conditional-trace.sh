#!/usr/bin/env bash
# Tracing the entire predicate is overwhelming. Trace only the section
# where you suspect the bug.

before_observe() {
  exec {trace_fd}>"/tmp/trace-observe.log"
  export BASH_XTRACEFD=$trace_fd
  set -x
}
after_observe() {
  set +x
  exec {trace_fd}>&-
}

# ... setup ...

before_observe
# === OBSERVATION block ===
RESULT=$(curl -sf -w '%{http_code}' "http://localhost:$PORT/checkout")
[ "$RESULT" = "200" ] && rc=0 || rc=1
# === end ===
after_observe

exit $rc
