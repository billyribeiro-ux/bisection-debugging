# Every checkout git has done during this session is in the reflog.
git reflog --date=iso | grep -E "checkout|bisect" | head -40

# Recover a specific SHA you saw earlier in bisection:
git checkout HEAD@{42}
# or
git checkout abc1234

# Pin it before it expires (default expiry: 90 days for unreachable objects).
git update-ref refs/recovered/possibly-bad HEAD
