#!/usr/bin/env bash
# Wraps a predicate with rich logging — write everything that affects the
# decision to a log file. Indispensable for post-mortem analysis.

LOGFILE="/tmp/predicate-$(git rev-parse --short HEAD).log"
exec > >(tee "$LOGFILE") 2>&1

echo "=== START $(date -Iseconds) ==="
echo "PWD: $PWD"
echo "GIT HEAD: $(git rev-parse HEAD)"
echo "GIT STATUS:"
git status --short
echo "ENV (filtered):"
env | grep -E '^(PORT|DB|NODE_|PNPM_|CI)' | sort

echo "=== PREDICATE BODY ==="
# ... your predicate ...
EXIT_CODE=$?

echo "=== END (exit $EXIT_CODE) ==="
exit $EXIT_CODE
