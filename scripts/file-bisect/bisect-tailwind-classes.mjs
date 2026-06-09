#!/usr/bin/env node
// bisect-tailwind-classes.mjs
// Bisects which Tailwind class in a component's `class` attribute causes a regression.
// Rewrites the component in place each round, restores on exit.
//
// USAGE:
//   node bisect-tailwind-classes.mjs ./src/lib/Header.svelte
//   (script will prompt you to pick which `class="…"` attribute to bisect)
//
import fs from 'fs';
import { spawnSync } from 'child_process';

const file = process.argv[2];
const orig = fs.readFileSync(file, 'utf8');

// Find every class="…" occurrence.
const re = /class="([^"]+)"/g;
const matches = [...orig.matchAll(re)];
if (!matches.length) { console.error('No class attributes found.'); process.exit(2); }
matches.forEach((m, i) => console.log(`[${i}] ${m[1].slice(0, 80)}${m[1].length > 80 ? '…' : ''}`));

const which = Number(process.argv[3] || 0);
const target = matches[which];
const classes = target[1].split(/\s+/).filter(Boolean);
console.log(`Bisecting ${classes.length} classes in attribute #${which}`);

process.on('exit', () => fs.writeFileSync(file, orig));
process.on('SIGINT', () => process.exit(130));

function applyKeep(keep) {
  // Splice by match POSITION, not string replace: an identical earlier
  // class="…" attribute would otherwise get rewritten instead of ours.
  const patched = orig.slice(0, target.index)
    + `class="${keep.join(' ')}"`
    + orig.slice(target.index + target[0].length);
  fs.writeFileSync(file, patched);
}

function predicateFails() {
  const r = spawnSync('node', ['pixel-diff-predicate.mjs'], { stdio: 'inherit' });
  return r.status !== 0;
}

let lo = 0, hi = classes.length - 1;
while (lo < hi) {
  const mid = (lo + hi) >> 1;
  const keepLower = classes.slice(0, mid + 1);
  applyKeep(keepLower);
  console.log(`testing classes [0..${mid}]`);
  if (predicateFails()) hi = mid; else lo = mid + 1;
}
applyKeep(classes); // restore full set before reporting
console.log(`\nCulprit class: "${classes[lo]}"`);
