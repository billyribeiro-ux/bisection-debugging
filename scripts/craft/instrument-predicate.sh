#!/usr/bin/env bash
# Wrap your predicate with verbose tracing.
exec > >(tee "/tmp/predicate-$(git rev-parse --short HEAD).log") 2>&1

# Print everything that might affect behavior.
echo "=== ENV ==="
env | sort

echo "=== CWD ==="
pwd
ls -la

echo "=== GIT STATE ==="
git rev-parse HEAD
git status --short

echo "=== UNTRACKED FILES (these don't get checked out) ==="
git status --short --untracked-files | head -20

echo "=== STARTING PREDICATE ==="
set -x   # bash trace mode: prints every command before running it

# ... your predicate code ...

set +x
echo "=== EXIT $? ==="
