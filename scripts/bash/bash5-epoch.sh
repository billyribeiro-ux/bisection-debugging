#!/usr/bin/env bash
# No more `date +%s` subshells in tight loops.
start=$EPOCHREALTIME          # seconds.microseconds since epoch, no fork
# ... do work ...
end=$EPOCHREALTIME
echo "elapsed: $(awk -v s="$start" -v e="$end" 'BEGIN { print e - s }') s"
