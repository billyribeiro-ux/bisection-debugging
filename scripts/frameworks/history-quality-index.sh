#!/usr/bin/env bash
# history-quality-index.sh
# Score the current repo for bisectability. Run from the repo root.
#
# Some axes (build / test reproducibility, migration reversibility) require
# external observation — the script awards their points if it finds the
# CI artifacts or scripts that signal the practice exists.
#
# Output: a 0–100 integer + per-axis breakdown.
set -uo pipefail

SCORE=0
echo "=== History Quality Index ==="

# --- 1. Commit atomicity (20 pts) ---
TOTAL=$(git rev-list --count HEAD)
SMALL=$(git log --shortstat --format='' | awk '/files? changed/ {
  ins=0; del=0;
  for (i=1;i<=NF;i++) { if ($i~/insertions?/) ins=$(i-1); if ($i~/deletions?/) del=$(i-1) }
  if (ins+del < 200) c++
} END { print c }')
PCT=$(( SMALL * 100 / TOTAL ))
ATOM=$(( PCT * 20 / 100 ))
echo "  atomicity:        $ATOM / 20  ($PCT% of commits < 200 LOC)"
SCORE=$(( SCORE + ATOM ))

# --- 2. Commit-message quality (10 pts) ---
CONV=$(git log --pretty=format:'%s' | grep -cE '^(feat|fix|chore|docs|test|refactor|perf|build|ci)(\([^)]+\))?: ')
WITH_BODY=$(git log --pretty=format:'%H::%b' | awk -F:: 'length($2) > 20 {c++} END {print c}')
MSG=$(( (CONV * 100 / TOTAL) * 6 / 100 + (WITH_BODY * 100 / TOTAL) * 4 / 100 ))
echo "  msg quality:      $MSG / 10  ($(( CONV*100/TOTAL ))% conv, $(( WITH_BODY*100/TOTAL ))% w/body)"
SCORE=$(( SCORE + MSG ))

# --- 3. Linear history (15 pts) ---
MERGES=$(git rev-list --count --merges HEAD)
LIN_PCT=$(( (TOTAL - MERGES) * 100 / TOTAL ))
LIN=$(( LIN_PCT * 15 / 100 ))
echo "  linear ratio:     $LIN / 15  (${LIN_PCT}% non-merge)"
SCORE=$(( SCORE + LIN ))

# --- 4. Build reproducibility (15 pts) — heuristic: lockfile committed and CI uses --frozen-lockfile ---
BUILD=0
[ -f pnpm-lock.yaml ] || [ -f package-lock.json ] || [ -f yarn.lock ] || [ -f Cargo.lock ] || [ -f go.sum ] && BUILD=$((BUILD+8))
grep -rqE '(npm ci|pnpm install --frozen-lockfile|cargo build --locked)' .github/ && BUILD=$((BUILD+7))
echo "  build reproducibility: $BUILD / 15"
SCORE=$(( SCORE + BUILD ))

# --- 5. Test reproducibility (15 pts) — heuristic: a CI workflow runs tests twice or has flake-detection ---
TEST=0
grep -rqE 'retry|flakiness|jest --runInBand|vitest.*--retry' .github/ && TEST=$((TEST+5))
[ -d tests ] || [ -d test ] || [ -d __tests__ ] || [ -d spec ] && TEST=$((TEST+5))
grep -rqE '(mock|stub|seed|faketimers|vi.useFakeTimers|sinon.useFakeTimers)' . && TEST=$((TEST+5))
echo "  test reproducibility: $TEST / 15"
SCORE=$(( SCORE + TEST ))

# --- 6. Migration reversibility (10 pts) ---
MIG=0
find . -path '*/migrations/*' -type f 2>/dev/null | head -1 >/dev/null && MIG=$((MIG+5))
grep -rqE 'down\(|--rollback|reverse_sql' --include='*.py' --include='*.ts' --include='*.rb' --include='*.sql' . && MIG=$((MIG+5))
echo "  migration reversibility: $MIG / 10"
SCORE=$(( SCORE + MIG ))

# --- 7. CI wall-time (10 pts) — heuristic from cached actions metadata if present, else penalize ---
CI=5   # default: we can't measure without API access; awarded as benefit of doubt
[ -f .github/workflows/ci.yml ] && CI=$((CI+3))
grep -rqE 'cache:|actions/cache@' .github/ && CI=$((CI+2))
echo "  CI wall-time (heuristic): $CI / 10"
SCORE=$(( SCORE + CI ))

# --- 8. Documented invariants (5 pts) ---
DOC=0
[ -f ARCHITECTURE.md ] || [ -f docs/INVARIANTS.md ] && DOC=$((DOC+3))
grep -lq 'invariant\|must hold\|always true' README.md 2>/dev/null && DOC=$((DOC+2))
echo "  documented invariants: $DOC / 5"
SCORE=$(( SCORE + DOC ))

echo "============================"
echo "TOTAL HQI:        $SCORE / 100"
case $SCORE in
  9[0-9]|100) echo "  → World-class. Teach others." ;;
  7[0-9]|8[0-9]) echo "  → Solid. Bisection will work reliably." ;;
  5[0-9]|6[0-9]) echo "  → Workable, but every bisection has friction." ;;
  3[0-9]|4[0-9]) echo "  → Fragile. Bisections will fail half the time." ;;
  *) echo "  → Broken. Fix the foundations before relying on bisection." ;;
esac
