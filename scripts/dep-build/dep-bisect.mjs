#!/usr/bin/env node
// dep-bisect.mjs
// Binary-search across recently-bumped dependencies to find the one that broke
// the app. Uses pnpm overrides to pin halves of the set back to known-good versions.
//
// PRECONDITIONS:
//   • A list of (name, oldVersion, newVersion) tuples. Build it from a diff
//     of `pnpm.lock` between the last green commit and HEAD, or pipe in
//     `pnpm outdated --json` from before the update.
//   • A predicate command (default: `pnpm build && pnpm test --run`).
//
// USAGE:
//   node dep-bisect.mjs bumps.json "pnpm build && pnpm test --run"
//
// bumps.json:
//   [
//     {"name": "vite", "old": "5.4.10", "new": "6.0.0"},
//     {"name": "svelte", "old": "5.0.0", "new": "5.1.4"},
//     ...
//   ]

import fs from 'fs';
import { spawnSync } from 'child_process';

const BUMPS = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const PREDICATE = process.argv[3] || 'pnpm build';
const PKG = './package.json';

const originalPkg = fs.readFileSync(PKG, 'utf8');
process.on('exit', () => {
  fs.writeFileSync(PKG, originalPkg);
  spawnSync('pnpm', ['install', '--silent'], { stdio: 'inherit' });
});

function withOverrides(pinNames) {
  const pkg = JSON.parse(originalPkg);
  pkg.pnpm = pkg.pnpm || {};
  pkg.pnpm.overrides = Object.fromEntries(
    BUMPS.filter(b => pinNames.has(b.name)).map(b => [b.name, b.old])
  );
  fs.writeFileSync(PKG, JSON.stringify(pkg, null, 2));
  const r = spawnSync('pnpm', ['install', '--no-frozen-lockfile', '--silent'], { stdio: 'inherit' });
  if (r.status !== 0) throw new Error('install failed');
}

function runPredicate() {
  const r = spawnSync('sh', ['-c', PREDICATE], { stdio: 'inherit' });
  return r.status === 0;
}

console.log(`Bisecting ${BUMPS.length} dependency bumps`);

// Invariant we're searching for:
//   Pinning bump set S to their OLD versions makes the build work.
//   Smallest such S includes the culprit.
//
// Strategy: classical binary search across an ordered list of bumps.
// If pinning lower half WORKS, the culprit is in the lower half (one of those
// pins is necessary). If pinning lower half DOES NOT work, the culprit is in
// the upper half (and we'd need to also pin one of those).

let lo = 0, hi = BUMPS.length - 1, round = 0;
while (lo < hi) {
  round++;
  const mid = (lo + hi) >> 1;
  const pinNames = new Set(BUMPS.slice(lo, mid + 1).map(b => b.name));
  console.log(`\nround ${round}: pinning [${lo}..${mid}] (${pinNames.size} pkgs)`);
  withOverrides(pinNames);
  if (runPredicate()) {
    // Pinning lower half fixed it → culprit is in lower half.
    hi = mid;
  } else {
    lo = mid + 1;
  }
}

console.log(`\nCulprit bump: ${BUMPS[lo].name}  ${BUMPS[lo].old} → ${BUMPS[lo].new}`);
