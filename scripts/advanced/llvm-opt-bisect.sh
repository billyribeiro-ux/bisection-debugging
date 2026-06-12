#!/usr/bin/env bash
# llvm-opt-bisect.sh
# Find the LLVM optimization pass that miscompiles a program.
#
# USAGE:
#   ./llvm-opt-bisect.sh ./build.sh ./run-and-check.sh
#
# build.sh must accept CFLAGS env var and propagate it to clang.
# run-and-check.sh must exit 0 if the program produces correct output, 1 if not.
#
set -euo pipefail
BUILD="${1:?usage: $0 <build-cmd> <run-cmd>}"
RUN="${2:?missing run cmd}"

# 1) Discover the upper bound: how many passes LLVM ran at full -O2?
CFLAGS="-O2 -mllvm -opt-bisect-limit=-1" $BUILD 2>/tmp/passes.log
MAX_PASS=$(awk '/BISECT: running pass / { n++ } END { print n }' /tmp/passes.log)
echo "LLVM ran $MAX_PASS passes at -O2"

# 2) Confirm endpoints.
CFLAGS="-O2 -mllvm -opt-bisect-limit=0" $BUILD >/dev/null 2>&1
$RUN && echo "0 passes → correct (baseline)" || { echo "Even 0 passes miscompiles — bug isn't a pass."; exit 2; }

CFLAGS="-O2 -mllvm -opt-bisect-limit=$MAX_PASS" $BUILD >/dev/null 2>&1
$RUN && { echo "Full -O2 produces correct output; not reproducing."; exit 0; }

# 3) Bisect.
lo=0; hi=$MAX_PASS
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  CFLAGS="-O2 -mllvm -opt-bisect-limit=$mid" $BUILD >/dev/null 2>&1
  if $RUN >/dev/null 2>&1; then
    lo=$((mid + 1))
  else
    hi=$mid
  fi
  echo "limit=$mid → narrowing to [$lo..$hi]"
done

# 4) Report the culprit pass.
CFLAGS="-O2 -mllvm -opt-bisect-limit=$lo" $BUILD 2>/tmp/culprit.log >/dev/null
PASS_NAME=$(awk -v n=$lo '/BISECT: running pass / { c++ } c==n { sub(/.*BISECT: running pass /, ""); print; exit }' /tmp/culprit.log)
echo
echo "Culprit pass #$lo: $PASS_NAME"
# Recent LLVM can disable a single pass by name (-opt-disable); on older
# releases, look for that pass's own -disable-* flag, or report the bug
# with the pass name and the IR before/after it.
echo "Try disabling just this pass: -mllvm -opt-disable=\"$PASS_NAME\""
