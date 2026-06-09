#!/usr/bin/env bash
# BUG A — simple correctness regression. Easy to spot.
node -e "import('./calculator.mjs').then(m=> process.exit(m.sub(5,2)===3 ? 0 : 1))"

# BUG B — performance regression. Predicate measures time on a 1k array.
# NOTE the typeof guard: on commits BEFORE sum() existed, calling it would
# throw → exit 1 → every early commit scored "bad" and the bisection lies.
# Missing-function = untestable = 125 (Exercise 1 teaches the same lesson).
node -e "
import('./calculator.mjs').then(m => {
  if (typeof m.sum !== 'function') process.exit(125);
  const xs = Array.from({length:1000}, (_,i)=>i);
  const t = Date.now();
  m.sum(xs);
  process.exit(Date.now() - t < 50 ? 0 : 1);
});"

# BUG C — flag interaction. Must enable both flags in the predicate to reveal.
FLAG_X=1 FLAG_Y=1 node -e "
import('./calculator.mjs').then(m => process.exit(m.multiply(2,3)===6 ? 0 : 1));"
