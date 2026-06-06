I need a `git bisect run` predicate for this project. Here's my
pre-flight worksheet — generate the predicate following the five-section
structure (setup with exit 125 on env errors, cleanup registered before
exercise, exercise, observe, exit) and the perf-budget pattern.

**Candidate set:** 340 commits since release-2026-04-15
**Monotonic property:** p99 of 20 GET /checkout requests < 300 ms
**Confirmed good:** SHA a3f9c81 — p99 = 280 ms ± 30 ms over 8 runs
**Confirmed bad:** SHA e7b2a91 — p99 = 1.65 s ± 200 ms over 8 runs
**Project conventions:** pnpm + node 24.16.0, `pnpm build` produces
dist/server.js, server listens on $PORT, /health endpoint exists.

Constraints:
- Use random port, not 3000
- Use `--frozen-lockfile --prefer-offline` for install
- Include readiness wait (not arbitrary sleep)
- Distinguish env failures (exit 125) from real failures (exit 1)
- Exit 125 if > 5 of 20 measurement requests fail

Generate the predicate and a bats test that verifies it returns 0 at
a3f9c81 and 1 at e7b2a91.
