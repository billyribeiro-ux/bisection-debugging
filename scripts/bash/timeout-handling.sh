#!/usr/bin/env bash
# timeout sends SIGTERM, then SIGKILL after --kill-after. Capture the
# distinction so timeout doesn't get conflated with the bug.

timeout --kill-after=5 30 some-long-command
case $? in
  0)   exit 0 ;;
  124) echo "timed out (SIGTERM)" ; exit 125 ;;   # not the bug, probably env
  137) echo "hard-killed (SIGKILL after 5s grace)"; exit 125 ;;
  *)   exit 1 ;;
esac
