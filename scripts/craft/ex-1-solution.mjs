#!/usr/bin/env node
// ex-1-solution.mjs — Exercise 1 model.
import { spawnSync } from 'child_process';
import fs from 'fs';
import { performance } from 'perf_hooks';

if (spawnSync('pnpm', ['install', '--frozen-lockfile', '--prefer-offline'], { stdio: 'ignore' }).status !== 0) process.exit(125);

let formatReport;
try { ({ formatReport } = await import('./src/report.mjs')); }
catch { process.exit(125); }                                       // unimportable = skip

const rows = JSON.parse(fs.readFileSync('fixtures/10k-rows.json'));

// Warm-up to let JIT settle
for (let i = 0; i < 3; i++) formatReport(rows);

// Measure k=5; use median
const times = [];
for (let i = 0; i < 5; i++) {
  const t = performance.now();
  formatReport(rows);
  times.push(performance.now() - t);
}
times.sort((a, b) => a - b);
const median = times[2];

console.log(`median = ${median.toFixed(1)} ms`);
process.exit(median < 200 ? 0 : 1);
