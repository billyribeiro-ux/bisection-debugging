#!/usr/bin/env node
// vite-plugin-bisect.mjs
// Edits vite.config.js to binary-halve the plugins array, runs `pnpm build`,
// and reports the culprit. Restores the file on exit.
//
// REQUIRED MARKER in your vite.config.js:
//   plugins: [
//     /* @bisect:begin */
//     pluginA(),
//     pluginB(),
//     pluginC(),
//     /* @bisect:end */
//   ],
//
import fs from 'fs';
import { spawnSync } from 'child_process';

const FILE = 'vite.config.js';
const original = fs.readFileSync(FILE, 'utf8');
process.on('exit', () => fs.writeFileSync(FILE, original));

const begin = original.indexOf('/* @bisect:begin */');
const end   = original.indexOf('/* @bisect:end */');
if (begin === -1 || end === -1) {
  console.error('Add /* @bisect:begin */ … /* @bisect:end */ markers around the plugins array.');
  process.exit(2);
}

const head = original.slice(0, begin + '/* @bisect:begin */'.length);
const tail = original.slice(end);
const middle = original.slice(begin + '/* @bisect:begin */'.length, end);

// Split on commas at depth 0.
const plugins = [];
let depth = 0, current = '';
for (const ch of middle) {
  if (ch === '(' || ch === '[' || ch === '{') depth++;
  if (ch === ')' || ch === ']' || ch === '}') depth--;
  if (ch === ',' && depth === 0) {
    if (current.trim()) plugins.push(current.trim());
    current = '';
  } else current += ch;
}
if (current.trim()) plugins.push(current.trim());

console.log(`Found ${plugins.length} plugins to bisect.`);

function withPlugins(list) {
  fs.writeFileSync(FILE, head + '\n' + list.join(',\n') + (list.length ? ',\n' : '') + tail);
}

function buildOk() {
  return spawnSync('pnpm', ['build'], { stdio: 'inherit' }).status === 0;
}

let lo = 0, hi = plugins.length - 1;
while (lo < hi) {
  const mid = (lo + hi) >> 1;
  withPlugins(plugins.slice(lo, mid + 1));
  console.log(`testing plugins [${lo}..${mid}]`);
  if (buildOk()) lo = mid + 1; else hi = mid;
}
console.log(`\nCulprit plugin: ${plugins[lo]}`);
