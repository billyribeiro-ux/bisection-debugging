#!/usr/bin/env node
// bayesian-bisect.mjs
// Sequential Bayesian bisection under a binary-symmetric-channel predicate.
//
// MAINTAINS:  posterior P(H = i) over candidate indices i ∈ [0, N).
// QUERY:      always picks the index that maximizes expected entropy reduction
//             of the posterior — typically near the posterior median.
// STOPS:      when the posterior is sufficiently concentrated (e.g. max P ≥ 0.95).
//
// USAGE:
//   node bayesian-bisect.mjs <N> <p> "<oracle-cmd-template>"
//
// Oracle template: any "$Q" tokens get replaced by the index being queried.
// Oracle exit 0 = "good", nonzero = "bad". The bisector tolerates noise.
//
import { spawnSync } from 'child_process';

const N = Number(process.argv[2]);
const p = Number(process.argv[3]);     // predicate flake probability
const ORACLE = process.argv[4];
const STOP_CONFIDENCE = Number(process.env.STOP_CONFIDENCE || 0.95);
const MAX_ROUNDS = Number(process.env.MAX_ROUNDS || 60);

let post = new Array(N).fill(1 / N);

function entropy(d) {
  let h = 0;
  for (const x of d) if (x > 0) h -= x * Math.log2(x);
  return h;
}

// P(observation = "good" | H = i, queried Q) under the BSC model.
function likelihoodGood(i, Q) { return Q < i ? (1 - p) : p; }
function likelihoodBad(i, Q)  { return Q < i ? p : (1 - p); }

function expectedEntropyAfterQuery(Q) {
  let pGood = 0;
  for (let i = 0; i < N; i++) pGood += post[i] * likelihoodGood(i, Q);
  const pBad = 1 - pGood;
  // Posterior under each outcome.
  const postG = new Array(N), postB = new Array(N);
  for (let i = 0; i < N; i++) {
    postG[i] = pGood > 0 ? post[i] * likelihoodGood(i, Q) / pGood : 0;
    postB[i] = pBad  > 0 ? post[i] * likelihoodBad(i,  Q) / pBad  : 0;
  }
  return pGood * entropy(postG) + pBad * entropy(postB);
}

function pickNextQuery() {
  // Optimal Q is the candidate index minimizing expected posterior entropy.
  // For BSC noise this is provably near the posterior median.
  let bestQ = 0, bestE = Infinity;
  for (let Q = 0; Q < N; Q++) {
    const e = expectedEntropyAfterQuery(Q);
    if (e < bestE) { bestE = e; bestQ = Q; }
  }
  return bestQ;
}

function runOracle(Q) {
  const cmd = ORACLE.replaceAll('$Q', String(Q));
  return spawnSync('sh', ['-c', cmd], { stdio: 'ignore' }).status === 0 ? 'good' : 'bad';
}

for (let round = 0; round < MAX_ROUNDS; round++) {
  const maxP = Math.max(...post);
  const argmax = post.indexOf(maxP);
  console.log(`round ${round}: H(post)=${entropy(post).toFixed(3)} bits, argmax=${argmax} (P=${maxP.toFixed(3)})`);
  if (maxP >= STOP_CONFIDENCE) {
    console.log(`\nConverged. First bad candidate: ${argmax} (P ≥ ${STOP_CONFIDENCE})`);
    process.exit(0);
  }
  const Q = pickNextQuery();
  const obs = runOracle(Q);
  console.log(`  queried Q=${Q}, observed: ${obs}`);
  // Bayes update.
  const lik = obs === 'good' ? likelihoodGood : likelihoodBad;
  let z = 0;
  for (let i = 0; i < N; i++) { post[i] = post[i] * lik(i, Q); z += post[i]; }
  for (let i = 0; i < N; i++) post[i] /= z;
}
console.log('Max rounds reached without convergence — predicate may be too noisy.');
