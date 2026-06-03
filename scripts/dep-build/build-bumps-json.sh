#!/usr/bin/env bash
# Captures what `pnpm update` changed so dep-bisect.mjs can drive it.
set -euo pipefail

# 1) Snapshot current versions BEFORE updating.
node -e '
  const pkg = require("./package.json");
  const all = {...pkg.dependencies, ...pkg.devDependencies};
  process.stdout.write(JSON.stringify(all, null, 2));
' > /tmp/versions-before.json

# 2) Update.
pnpm update --latest

# 3) Snapshot AFTER, diff.
node -e '
  const before = require("/tmp/versions-before.json");
  const pkg = require("./package.json");
  const after = {...pkg.dependencies, ...pkg.devDependencies};
  const bumps = Object.keys(after)
    .filter(n => before[n] && before[n] !== after[n])
    .map(n => ({ name: n, old: before[n].replace(/^[~^]/, ""), new: after[n].replace(/^[~^]/, "") }));
  process.stdout.write(JSON.stringify(bumps, null, 2));
' > bumps.json

echo "Wrote bumps.json with $(jq length bumps.json) entries"
