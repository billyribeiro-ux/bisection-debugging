# I told git this commit was good; now I think it was bad. Fix the log.
git bisect log > /tmp/bisect-log

# Edit /tmp/bisect-log in your editor. Change `good abc123` to `bad abc123`,
# or delete the line entirely if you can't tell.

git bisect reset
git bisect replay /tmp/bisect-log
# Bisection resumes with the corrected history.
