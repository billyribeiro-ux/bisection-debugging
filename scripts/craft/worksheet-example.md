# Pre-Flight Worksheet — checkout latency regression

**Date:** 2026-06-04
**Author:** Alex Chen
**Bug:** GET /checkout p99 latency went from ~200 ms (April) to ~1.8 s (June).

## 1. Candidate set
- Commits from `release-2026-04-15` (~340 commits) through `HEAD`.
- Restricted to commits touching `services/checkout/**` using `git bisect start -- services/checkout/`.

## 2. Monotonic property
- Before culprit: p99 of 20 sequential `GET /checkout` calls is < 300 ms.
- After culprit: p99 is > 1 s.
- We've verified at the endpoints that the threshold is unambiguous.

## 3. Good endpoint (confirmed)
- `release-2026-04-15` → SHA `a3f9c81`.
- Manual measurement: 8 runs, p99 = 280 ms ± 30 ms.

## 4. Bad endpoint (confirmed)
- `HEAD` → SHA `e7b2a91`.
- Manual measurement: 8 runs, p99 = 1.65 s ± 200 ms.

## 5. Predicate cost
- Setup (pnpm install --prefer-offline, build cached): ~30 s.
- Exercise: spin up server (1s), 20 curls (10s), shutdown (1s): ~12 s.
- Cleanup: ~2 s.
- Per round: ~45 s. Total bisection: 9 rounds × 45 s ≈ 7 min.

## 6. What could go wrong
- (a) **Port collision** between rounds. Mitigate: use random port; pass via env.
- (b) **Stale connection pool** in DB driver. Mitigate: fresh container each round.
- (c) **Network flake** in healthcheck. Mitigate: 5× retry with 1s backoff.

## 7. Recovery plan
- After bisection completes, run the predicate 10× on the alleged culprit.
- If < 8/10 say "bad", the predicate is noisy — increase k-of-k from 1 to 5.
- If the culprit looks innocent (e.g., only touches comments), reverse-verify
  by reverting the suspect on HEAD and re-running the predicate; should pass.
