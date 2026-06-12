#!/usr/bin/env node
// tsconfig-bisect.mjs
// Bisects which of a list of compiler options is responsible for a build failure.
//
// USAGE:
//   node tsconfig-bisect.mjs '["noImplicitAny","strictNullChecks","strictFunctionTypes",...]'
//
import fs from 'fs';
import { spawnSync } from 'child_process';

const OPTIONS = JSON.parse(process.argv[2]);
const CFG = './tsconfig.json';

const original = fs.readFileSync(CFG, 'utf8');
process.on('exit', () => fs.writeFileSync(CFG, original));
process.on('SIGINT',  () => process.exit(130));   // 'exit' alone won't fire on Ctrl-C
process.on('SIGTERM', () => process.exit(143));

function apply(enabled) {
  // NOTE: tsconfig.json is JSONC — comments and trailing commas are legal.
  // JSON.parse will throw on them; strip comments first (or use a JSONC
  // parser like jsonc-parser) if your config has any.
  const cfg = JSON.parse(original);
  cfg.compilerOptions = cfg.compilerOptions || {};
  // Reset every option in OPTIONS to false, then enable only `enabled`.
  for (const o of OPTIONS) cfg.compilerOptions[o] = false;
  for (const o of enabled) cfg.compilerOptions[o] = true;
  // Make sure umbrella `strict` isn't masking us.
  cfg.compilerOptions.strict = false;
  fs.writeFileSync(CFG, JSON.stringify(cfg, null, 2));
}

function buildFails() {
  const r = spawnSync('pnpm', ['exec', 'tsc', '--noEmit'], { stdio: 'pipe' });
  return r.status !== 0;
}

console.log(`Bisecting ${OPTIONS.length} compiler options`);

// Confirm: enabling ALL options fails; enabling NONE passes.
apply(OPTIONS);
if (!buildFails()) { console.log('All options on → still passes. Nothing to find.'); process.exit(0); }
apply([]);
if (buildFails())  { console.log('No options on → still fails. The bug is elsewhere.'); process.exit(0); }

let lo = 0, hi = OPTIONS.length - 1;
while (lo < hi) {
  const mid = (lo + hi) >> 1;
  apply(OPTIONS.slice(lo, mid + 1));
  console.log(`testing [${OPTIONS.slice(lo, mid + 1).join(', ')}]`);
  if (buildFails()) hi = mid; else lo = mid + 1;
}
console.log(`\nCulprit option: ${OPTIONS[lo]}`);
