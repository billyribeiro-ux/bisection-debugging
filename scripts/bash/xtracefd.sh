#!/usr/bin/env bash
# Redirect trace to a file (or fd) instead of stderr. Now your predicate's
# actual stderr stays clean for bisection's reading.

exec {trace_fd}>"/tmp/predicate-trace-$$.log"   # open fd, bash 4.1+
export BASH_XTRACEFD=$trace_fd
set -x

# ... predicate body ...

set +x
exec {trace_fd}>&-       # close the fd
