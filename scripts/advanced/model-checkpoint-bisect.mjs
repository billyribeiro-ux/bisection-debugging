#!/usr/bin/env node
// model-checkpoint-bisect.mjs
// Binary-search across checkpoints to find the one that introduced a regression.
//
// USAGE:
//   node model-checkpoint-bisect.mjs ./ckpts/step-* 0.72
//
import { glob } from 'node:fs/promises';
import { spawnSync } from 'child_process';

const pattern = process.argv[2];
const threshold = Number(process.argv[3] || 0.7);

const ckpts = [];
for await (const p of glob(pattern)) ckpts.push(p);
ckpts.sort((a, b) => {
  // Sort by step number embedded in path.
  const m = (s) => Number((s.match(/step-(\d+)/) || [, 0])[1]);
  return m(a) - m(b);
});

console.log(`Bisecting ${ckpts.length} checkpoints; threshold = ${threshold}`);

function passes(ckpt) {
  const r = spawnSync('node', ['checkpoint-eval-predicate.mjs'], {
    env: { ...process.env, CHECKPOINT: ckpt, THRESHOLD: String(threshold) },
    stdio: 'inherit',
  });
  return r.status === 0;
}

// Confirm endpoints.
if (!passes(ckpts[0])) { console.error('Earliest checkpoint already fails — regression predates this range.'); process.exit(0); }
if (passes(ckpts.at(-1))) { console.error('Latest checkpoint still passes — no regression.'); process.exit(0); }

let lo = 0, hi = ckpts.length - 1;
while (lo < hi) {
  const mid = (lo + hi) >> 1;
  if (passes(ckpts[mid])) lo = mid + 1; else hi = mid;
}

console.log('\nFirst regressed checkpoint:', ckpts[lo]);
console.log('Last good checkpoint:      ', ckpts[lo - 1]);
console.log('Training steps between:    ',
  Number(ckpts[lo].match(/step-(\d+)/)[1]) - Number(ckpts[lo - 1].match(/step-(\d+)/)[1]));
