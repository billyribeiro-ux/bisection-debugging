# Restrict candidates to commits touching the given paths. In a monorepo
# this can shrink N from 40,000 to 300 before the first test runs —
# that's log2(40000)=16 steps down to log2(300)=9.
git bisect start HEAD v2.0 -- packages/checkout/ packages/payments/

# Verify how much it helped before committing to the session:
git rev-list --count HEAD ^v2.0                                       # all
git rev-list --count HEAD ^v2.0 -- packages/checkout/ packages/payments/

git bisect run pnpm --filter checkout test
