#!/usr/bin/env node
// bisect-cost.mjs
// Given N candidates and a per-query error rate p, computes the minimum
// expected number of queries (Shannon bound) and the actual rounds needed
// when wrapping the predicate in a k-out-of-N voting scheme.
//
//   node bisect-cost.mjs 1024 0.15
//
const N = Number(process.argv[2] || 1024);
const p = Number(process.argv[3] || 0.05);

function H2(q) { return q === 0 || q === 1 ? 0 : -q * Math.log2(q) - (1 - q) * Math.log2(1 - q); }
function capacity(q) { return 1 - H2(q); }

const Hx = Math.log2(N);
const C  = capacity(p);

console.log(`H(X)    = ${Hx.toFixed(3)} bits  (entropy of unknown over ${N} candidates)`);
console.log(`C(p=${p}) = ${C.toFixed(3)} bits/query`);
console.log(`Lower bound on expected queries: ${(Hx / C).toFixed(2)}`);

// Voting: run the predicate k times, majority wins.
// Per-call error becomes the binomial tail Pr[≥k/2 wrong].
function binom(n, k) { let r = 1; for (let i = 0; i < k; i++) r = r * (n - i) / (i + 1); return r; }
function majorityWrongP(k, p) {
  let acc = 0;
  for (let i = Math.ceil(k / 2); i <= k; i++) acc += binom(k, i) * Math.pow(p, i) * Math.pow(1 - p, k - i);
  return acc;
}

console.log('\nMajority-of-k voting (drives p down at k× cost):');
for (const k of [1, 3, 5, 7, 9, 11]) {
  const pEff = majorityWrongP(k, p);
  const cEff = capacity(pEff);
  const queries = Hx / cEff;
  console.log(`  k=${k}: p_eff=${pEff.toExponential(2)}  C=${cEff.toFixed(3)}  queries≈${queries.toFixed(1)}  total runs≈${(queries * k).toFixed(0)}`);
}
