# Bisectability Scorecard — score each system you maintain

## Commit hygiene
[ ] Conventional-commit format enforced in CI
[ ] Linear history (rebase-merge or squash-merge, not true merges)
[ ] Average commit size < 200 lines added

## Reproducibility
[ ] Same commit + same input → bitwise-identical artifact
[ ] Lockfile committed and honored in CI
[ ] Build cache invalidates correctly on dependency changes

## Test hermeticity
[ ] All HTTP mocked
[ ] Time mockable
[ ] Random seeded per test
[ ] DB per-test isolation
[ ] No test depends on test order

## Feedback speed
[ ] Single commit → CI in < 5 minutes for the common case
[ ] Incremental builds working
[ ] Parallelism in test runner

## Observability
[ ] Structured logs (JSON) for every non-trivial event
[ ] Metrics on every public endpoint
[ ] Distributed tracing in production

## Interface stability
[ ] API versioning policy in place
[ ] Schema diff blocking on breaking changes
[ ] Deprecation window enforced

## Data versioning
[ ] Numbered migrations
[ ] Reversible migrations
[ ] Migration state queryable

Score = boxes checked / total. Below 50% = bisection will be painful.
