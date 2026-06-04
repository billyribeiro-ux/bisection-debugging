#!/usr/bin/env bash
# rr-reverse-bisect.sh
# Reverse-bisect: given a corrupted memory address at end-of-run, find the
# last write that put a bad value there.

TRACE="$1"      # /tmp/rr-trace-X
ADDR="$2"       # e.g. 0x7fffd0001a40 — the address you saw corrupted in gdb

rr replay "$TRACE" --serve-files <<EOF
break main
continue
# Run to the end first to confirm the bug.
continue
# Set a hardware watchpoint and reverse-continue.
watch *(uint64_t*)$ADDR
reverse-continue
# Now we're at the last write. Print the stack.
backtrace
EOF
