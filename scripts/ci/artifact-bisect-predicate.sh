#!/usr/bin/env bash
# Predicate for `git bisect run` under --no-checkout: download the CI build
# for BISECT_HEAD instead of compiling it. Exit 125 when no artifact exists —
# a commit that never built in CI is UNTESTABLE, not bad.
set -euo pipefail

sha=$(git rev-parse BISECT_HEAD)
url="https://artifacts.example.com/myapp/$sha/myapp-linux-x64.tar.gz"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

curl -sfL "$url" -o "$tmp/app.tgz" || exit 125   # no build for this commit
tar -xzf "$tmp/app.tgz" -C "$tmp"

exec "$tmp/myapp" --selftest --timeout 30
