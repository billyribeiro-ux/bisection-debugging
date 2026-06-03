# Skip a known-broken range so bisection avoids it.
git bisect skip $(git rev-list abc123^..def456)

# Or skip the merges from a noisy upstream branch.
git bisect skip $(git rev-list --merges --first-parent HEAD~50..HEAD)
