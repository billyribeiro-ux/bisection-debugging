#!/usr/bin/env node
// ex-5-solution.mjs — Exercise 5 model.
// Race conditions are inherently noisy. We exercise the suspected race many
// times, then use a binomial threshold to decide "this commit is bad."
import { spawnSync } from 'child_process';

if (spawnSync('pnpm', ['install', '--frozen-lockfile', '--prefer-offline'], { stdio: 'ignore' }).status !== 0) process.exit(125);

let chargeCard, resetCardState;
try { ({ chargeCard, resetCardState } = await import('./src/payments.mjs')); } catch { process.exit(125); }

const N_TRIALS    = 50;          // run the race-prone code path 50 times
const FAIL_THRESH = 3;           // 3+ double-charges = predicate says "bad"

let doubleCharges = 0;
for (let i = 0; i < N_TRIALS; i++) {
  resetCardState();
  // Two concurrent calls — race the lock.
  const [r1, r2] = await Promise.all([chargeCard('card_x', 100), chargeCard('card_x', 100)]);
  if (r1.charged + r2.charged > 100) doubleCharges++;     // bug fires
}

console.log(`double-charges: ${doubleCharges} / ${N_TRIALS}`);
if (doubleCharges >= FAIL_THRESH) process.exit(1);

// Even with the right behavior, sometimes the race never fires. To avoid
// returning "good" when we just got lucky, require enough trials with at
// least one near-race detected. (For complex races, k-of-k voting is
// the right answer at the bisection level — see Part IX Bayesian.)
process.exit(0);
