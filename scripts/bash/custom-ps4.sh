#!/usr/bin/env bash
# Default PS4 is "+ ". Replace with timestamps, file:line, and elapsed time.

# $EPOCHREALTIME for sub-second precision — \D{…} goes through strftime,
# which has no %N, so \D{%H:%M:%S.%N} would print a literal "%N".
export PS4='+ $EPOCHREALTIME ${BASH_SOURCE##*/}:${LINENO}: '
set -x

# Trace now looks like:
#   + 14:23:17.123456789 predicate.sh:42: curl http://localhost:3000/checkout
#   + 14:23:18.041582763 predicate.sh:43: grep -q OK
