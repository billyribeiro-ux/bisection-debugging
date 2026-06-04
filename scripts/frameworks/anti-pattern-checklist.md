# Anti-Bisection Pattern Audit

For each repo you maintain, check:

[ ] Average PR size below 500 LOC?
[ ] Squash-merge used judiciously, not universally?
[ ] main branch protected from force-push?
[ ] Environment variables logged at predicate start?
[ ] Tests pass under randomized order?
[ ] Generated files NOT committed (except lockfiles)?
[ ] Two builds of the same commit are bitwise identical?
[ ] Frontend can run against multiple backend versions?
[ ] Every migration has a tested rollback?
[ ] Tests don't rely on inherited state?

Each unchecked box ≈ one future bisection that will mislead you.
