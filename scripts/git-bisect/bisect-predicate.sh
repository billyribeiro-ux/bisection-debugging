#!/usr/bin/env bash
# bisect-predicate.sh — generic predicate for `git bisect run`.
#
# WHAT TO EDIT:  the THREE variables below + the SUSPECT_TEST.
# WHY EXIT 125: build/install failure isn't the bug; it's an environment problem.
#               Skipping lets bisection continue around the broken commits.
# USAGE:
#   git bisect start HEAD v2.3
#   git bisect run ./bisect-predicate.sh

set -uo pipefail

INSTALL_CMD="pnpm install --frozen-lockfile --prefer-offline"
BUILD_CMD="pnpm build"
SUSPECT_TEST="pnpm vitest run tests/auth/login.test.ts"
FLAKE_RETRIES=3            # run the suspect test N times before declaring bad

# 1) Reset known-dirty caches that survive checkouts.
rm -rf node_modules/.vite .svelte-kit .turbo dist 2>/dev/null || true

# 2) Hermetic install. If the lockfile or registry rejects this commit, SKIP.
if ! $INSTALL_CMD >/tmp/bisect-install.log 2>&1; then
  echo "::skip:: install failed at $(git rev-parse --short HEAD)"
  exit 125
fi

# 3) Build. Broken build isn't necessarily the bug — but it might be.
#    If the bug you're hunting is "the build broke", change exit 125 → exit 1 here.
if ! $BUILD_CMD >/tmp/bisect-build.log 2>&1; then
  echo "::skip:: build failed at $(git rev-parse --short HEAD)"
  exit 125
fi

# 4) Run the suspect test multiple times, declare bad only on a clear majority.
fails=0
for i in $(seq 1 "$FLAKE_RETRIES"); do
  if ! $SUSPECT_TEST >/tmp/bisect-test.$i.log 2>&1; then
    fails=$((fails + 1))
  fi
done

if (( fails > FLAKE_RETRIES / 2 )); then
  echo "::bad:: $(git rev-parse --short HEAD) failed $fails/$FLAKE_RETRIES"
  exit 1
fi

echo "::good:: $(git rev-parse --short HEAD)"
exit 0
