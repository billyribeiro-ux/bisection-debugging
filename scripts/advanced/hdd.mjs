#!/usr/bin/env node
// hdd.mjs
// Hierarchical Delta Debugging on JSON trees.
//
// USAGE:
//   node hdd.mjs failing-input.json "./predicate.sh"
//
// PREDICATE CONTRACT:
//   Reads the candidate JSON on stdin. Exits 0 = bug REPRODUCES, nonzero = does not.
//   (Inverse of normal "test passed" semantics; ddmin needs "does this minimal
//    candidate still trigger the bug?".)
//
import fs from 'fs';
import { spawnSync } from 'child_process';

const input = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const PRED  = process.argv[3];

function reproduces(tree) {
  const r = spawnSync('sh', ['-c', PRED], { input: JSON.stringify(tree), stdio: ['pipe', 'ignore', 'ignore'] });
  return r.status === 0;
}

// Generic "get/set children" — works on arrays and objects.
function getChildren(node) {
  if (Array.isArray(node)) return node.map((v, i) => ({ key: i, value: v }));
  if (node && typeof node === 'object') return Object.entries(node).map(([k, v]) => ({ key: k, value: v }));
  return [];
}
function setChildren(node, kids) {
  if (Array.isArray(node)) return kids.map(c => c.value);
  if (node && typeof node === 'object') return Object.fromEntries(kids.map(c => [c.key, c.value]));
  return node;
}

// 1-minimization (Zeller's ddmin) over an array of children.
// Tries to find the smallest subset of `kids` that still reproduces when
// substituted at this position. `materialize(subset)` rebuilds the whole tree
// with this subset at the current path.
function ddmin(kids, materialize) {
  let S = kids;
  let n = 2;
  while (S.length >= 2) {
    const sz = Math.ceil(S.length / n);
    let progressed = false;
    for (let i = 0; i < S.length; i += sz) {
      const subset = S.slice(i, i + sz);
      const complement = [...S.slice(0, i), ...S.slice(i + sz)];
      if (reproduces(materialize(subset)))      { S = subset;     n = 2;            progressed = true; break; }
      if (reproduces(materialize(complement))) { S = complement; n = Math.max(n-1, 2); progressed = true; break; }
    }
    if (!progressed) {
      if (n >= S.length) break;
      n = Math.min(n * 2, S.length);
    }
  }
  return S;
}

// HDD: BFS levels, ddmin children at each level, then descend into survivors.
function hdd(root) {
  let frontier = [{ path: [], node: root }];
  let tree = root;
  while (frontier.length) {
    const next = [];
    for (const { path, node } of frontier) {
      const kids = getChildren(node);
      if (kids.length < 2) { for (const c of kids) next.push({ path: [...path, c.key], node: c.value }); continue; }

      // Rebuild whole tree given a subset of these children.
      const materialize = (subset) => {
        let rebuilt = JSON.parse(JSON.stringify(tree));
        let cursor = rebuilt;
        for (let i = 0; i < path.length - 1; i++) cursor = cursor[path[i]];
        const target = path.length ? cursor[path[path.length - 1]] : rebuilt;
        const newNode = setChildren(target, subset);
        if (path.length === 0) return newNode;
        cursor[path[path.length - 1]] = newNode;
        return rebuilt;
      };

      const survivors = ddmin(kids, materialize);
      tree = materialize(survivors);
      for (const c of survivors) next.push({ path: [...path, c.key], node: c.value });
    }
    frontier = next;
  }
  return tree;
}

if (!reproduces(input)) { console.error('Initial input does not reproduce.'); process.exit(2); }
const minimized = hdd(input);
console.log(JSON.stringify(minimized, null, 2));
console.error(`\nOriginal nodes: ${JSON.stringify(input).length}`);
console.error(`Minimized:      ${JSON.stringify(minimized).length}`);
