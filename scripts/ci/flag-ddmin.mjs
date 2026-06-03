#!/usr/bin/env node
// flag-ddmin.mjs
// Delta-debugging over feature flags. Finds the smallest flag set whose
// "on" state reproduces the bug. Works even when the bug requires several
// flags together (not a clean monotonic switch).
//
// PREDICATE: a shell command that exits 0 iff the bug REPRODUCES under the
//            flags exported as FF_<name>=1.
//
// USAGE:
//   node flag-ddmin.mjs '["FF_NEW_CART","FF_FAST_CHECKOUT","FF_ML_RANK", ...]' "./run-bug-check.sh"

import { spawnSync } from 'child_process';

const FLAGS = JSON.parse(process.argv[2]);
const PRED = process.argv[3];

function reproduces(subset) {
  const env = { ...process.env };
  for (const f of FLAGS) delete env[f];
  for (const f of subset) env[f] = '1';
  return spawnSync('sh', ['-c', PRED], { env, stdio: 'ignore' }).status === 0;
}

if (!reproduces(FLAGS)) { console.log('Full set does not reproduce.'); process.exit(0); }

let S = [...FLAGS];
let n = 2;
while (S.length >= 2) {
  const chunkSize = Math.ceil(S.length / n);
  let found = false;
  for (let i = 0; i < S.length; i += chunkSize) {
    const subset = S.slice(i, i + chunkSize);
    const complement = [...S.slice(0, i), ...S.slice(i + chunkSize)];
    if (reproduces(subset))      { S = subset;     n = 2;          found = true; break; }
    if (reproduces(complement))  { S = complement; n = Math.max(n - 1, 2); found = true; break; }
  }
  if (!found) {
    if (n >= S.length) break;
    n = Math.min(n * 2, S.length);
  }
}
console.log('1-minimal failing flag set:', S);
