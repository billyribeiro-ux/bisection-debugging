Here's a bash predicate I wrote for git bisect run. Audit it against the
ten anti-patterns:
1. Exit-1 for environment errors
2. Combining exercise and observation
3. Hitting external services
4. No cleanup trap
5. Implicit time/locale/timezone dependency
6. Mutating shared state between rounds
7. Treating compile errors as test failures
8. Using set -e alone (without explicit error handling)
9. Counting tests instead of asserting outcomes
10. Forgetting timeouts

For each anti-pattern present, show the specific line and the fix.

[paste predicate here]
