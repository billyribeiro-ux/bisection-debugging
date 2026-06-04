#!/usr/bin/env bash
set -uo pipefail
pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || exit 125
pnpm exec tsc --noEmit
