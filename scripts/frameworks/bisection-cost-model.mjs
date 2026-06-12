#!/usr/bin/env node
// bisection-cost-model.mjs
// Predicts wall-clock + engineer cost for a bisection before you run it.
//
//   node bisection-cost-model.mjs --N=1024 --predicate=120 --setup=30 --flake=0.05
//
// Outputs: rounds, wall-clock, dollar cost, and a recommendation:
//   "DO IT" / "FIX FLAKE FIRST" / "SPEED UP CI FIRST" / "READ DIFFS INSTEAD"
//
const args = Object.fromEntries(process.argv.slice(2).map(a => {
  const [k, v] = a.replace(/^--/, '').split('=');
  return [k, Number(v)];
}));

const N        = args.N        ?? 1024;
const T_pred   = args.predicate ?? 60;
const T_setup  = args.setup    ?? 20;
const p        = args.flake    ?? 0;
const k        = args.k        ?? (p > 0.05 ? Math.max(3, Math.ceil(Math.log2(1 / 0.01) / Math.log2(1 / (2 * p)))) : 1);
const C_eng    = args.cost_per_hour ?? 100;       // $/hr fully loaded
const W_idle   = args.blocked  ?? 1.5;            // multiplier

function H2(q)        { return q === 0 || q === 1 ? 0 : -q * Math.log2(q) - (1-q) * Math.log2(1-q); }
function binom(n, i)  { let r = 1; for (let j = 0; j < i; j++) r = r * (n-j) / (j+1); return r; }
function pEff(k, p)   { let acc = 0; for (let i = Math.ceil(k/2); i <= k; i++) acc += binom(k,i) * Math.pow(p,i) * Math.pow(1-p, k-i); return acc; }

const capacity   = 1 - H2(pEff(k, p));
const rounds     = Math.ceil(Math.log2(N) / capacity);
const wallSec    = rounds * (T_setup + k * T_pred);
const engineerHr = wallSec / 3600;
const dollars    = engineerHr * C_eng * W_idle;

console.log(`N        = ${N} candidates`);
console.log(`p        = ${p}   (majority-of-k voting: k=${k}, effective p=${pEff(k,p).toExponential(2)})`);
console.log(`Rounds   = ${rounds}   (lower bound was ${Math.ceil(Math.log2(N))})`);
console.log(`Wall     = ${(wallSec / 60).toFixed(1)} min`);
console.log(`Cost     = $${dollars.toFixed(0)}`);
console.log();

// Recommendation engine.
if (p > 0.4)        { console.log('→ FIX FLAKE FIRST.  Capacity too low for bisection to converge cheaply.'); process.exit(0); }
if (T_pred > 600)   { console.log('→ SPEED UP CI FIRST. A 10-minute predicate makes any bisection painful.'); process.exit(0); }
if (rounds * (T_setup + k*T_pred) > 4 * 3600) { console.log('→ READ DIFFS INSTEAD. Bisection will cost more than a focused code review.'); process.exit(0); }
if (Math.log2(N) < 4) { console.log('→ READ DIFFS INSTEAD. With ' + N + ' candidates the linear scan IS the bisection.'); process.exit(0); }
console.log('→ DO IT.  Bisection is the cheapest path given these parameters.');
