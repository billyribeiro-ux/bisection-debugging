#!/usr/bin/env bash
# game-day-setup.sh
# Generates a practice repo with three known-bad commits planted in a
# history of harmless commits. Use this as the warm-up before a bisection
# workshop.
#
# Output: ./game-day-repo (a git repo ready to clone for each participant)
#
# THE THREE BUGS:
#   Bug A — single-commit, in-source: ~commit 47 of ~100, simple regression
#   Bug B — single-commit, requires a predicate: ~commit 73, asymptotic perf
#   Bug C — multi-flag interaction: only fires with FLAG_X + FLAG_Y both on
#
set -euo pipefail
DEST="${1:-./game-day-repo}"
rm -rf "$DEST" && mkdir "$DEST" && cd "$DEST"

git init -q
git config user.name "Game Day"
git config user.email "gameday@example.com"

# Initial commit.
cat > calculator.mjs <<'EOF'
export function add(a, b) { return a + b; }
export function sub(a, b) { return a - b; }
export function mul(a, b) { return a * b; }
export function div(a, b) { return a / b; }
EOF
cat > test.mjs <<'EOF'
import { add, sub, mul, div } from './calculator.mjs';
console.assert(add(2, 3) === 5);
console.assert(sub(5, 2) === 3);
console.assert(mul(4, 5) === 20);
console.assert(div(10, 2) === 5);
console.log('OK');
EOF
git add . && git commit -q -m "feat: initial calculator"

# 99 noise commits + 3 bugs planted at predictable positions.
for i in $(seq 1 99); do
  echo "// noise $i" >> calculator.mjs
  case $i in
    47)  # BUG A: regression in sub
      sed -i 's/return a - b/return a + b/' calculator.mjs
      MSG="refactor: tidy up sub"   # innocent-looking
      ;;
    73)  # BUG B: O(n) → O(n²) regression in a 'sum' function
      cat >> calculator.mjs <<'EOF'
export function sum(xs) {
  let total = 0;
  for (const x of xs) for (const y of xs) total += (x === y ? x : 0);  // BUG: nested
  return total;
}
EOF
      MSG="feat: add sum function"
      ;;
    *)
      MSG="chore: tidy commit $i"
      ;;
  esac
  git add . && git commit -q -m "$MSG"
done

# Bug C — multi-flag, last commit.
cat >> calculator.mjs <<'EOF'
export function multiply(a, b) {
  if (process.env.FLAG_X && process.env.FLAG_Y) return a * b + 1;   // BUG when both
  return a * b;
}
EOF
git add . && git commit -q -m "feat: refactor multiply with flags"

echo "=== Game Day repo ready at $DEST ==="
echo "Bug A — sub regression: introduced around commit ~47"
echo "Bug B — quadratic sum:  introduced around commit ~73"
echo "Bug C — flag interaction: requires FLAG_X + FLAG_Y both on"
