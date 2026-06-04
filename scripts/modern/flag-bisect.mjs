#!/usr/bin/env node
// flag-bisect.mjs
// Bisect across N feature flags to find which one(s) cause a regression.
//
// USAGE:
//   FLAGS=flagA,flagB,flagC,...  node flag-bisect.mjs "<test command>"
//
// The test command should exit 0 if the bug is NOT present, nonzero if it IS.
//
import { spawnSync } from 'child_process';

const ALL = (process.env.FLAGS || '').split(',').filter(Boolean);
const TEST = process.argv[2];

if (!ALL.length || !TEST) {
  console.error('Set FLAGS and pass a test command');
  process.exit(2);
}

function reproduces(enabled) {
  // Apply the chosen flag set via env var (or your flag system's API).
  const envFlags = Object.fromEntries(
    ALL.map(f => [`FLAG_${f.toUpperCase()}`, enabled.includes(f) ? '1' : '0'])
  );
  const r = spawnSync('sh', ['-c', TEST], {
    env: { ...process.env, ...envFlags },
    stdio: 'inherit',
  });
  return r.status !== 0;   // nonzero = bug present
}

// Confirm endpoints.
if (!reproduces(ALL)) { console.error('No bug when ALL flags on — repro broken'); process.exit(2); }
if (reproduces([]))  { console.error('Bug present with NO flags — not a flag issue'); process.exit(2); }

// Standard ddmin-style narrowing.
let suspects = ALL.slice();
while (suspects.length > 1) {
  const mid = Math.floor(suspects.length / 2);
  const left = suspects.slice(0, mid);
  const right = suspects.slice(mid);
  if (reproduces(left))       suspects = left;
  else if (reproduces(right)) suspects = right;
  else {
    // Bug needs flags from BOTH halves — proper Delta Debugging time.
    console.error('Multi-flag interaction detected; switching to ddmin');
    suspects = ddmin(suspects);
    break;
  }
  console.log(`narrowed to ${suspects.length} flags: ${suspects.join(', ')}`);
}

console.log('Culprit flag(s):', suspects.join(', '));

// Delta Debugging fallback when single bisection isn't enough.
function ddmin(input) {
  let S = input;
  let n = 2;
  while (S.length >= 2) {
    const sz = Math.ceil(S.length / n);
    let progressed = false;
    for (let i = 0; i < S.length; i += sz) {
      const complement = [...S.slice(0, i), ...S.slice(i + sz)];
      if (reproduces(complement)) { S = complement; n = Math.max(n - 1, 2); progressed = true; break; }
    }
    if (!progressed) {
      if (n >= S.length) break;
      n = Math.min(n * 2, S.length);
    }
  }
  return S;
}
