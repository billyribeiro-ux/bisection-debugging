git bisect start --term-old=working --term-new=broken
git bisect broken           # equivalent to `bad`
git bisect working v2.3     # equivalent to `good v2.3`

# Or for performance regressions:
git bisect start --term-old=fast --term-new=slow
