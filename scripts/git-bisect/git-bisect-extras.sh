# Skip the current commit (build broken, can't decide).
git bisect skip

# Save the bisection log for later (e.g. resume after a crash, or for review).
git bisect log > /tmp/bisect.log
git bisect reset                 # end session
# Later:
git bisect start
git bisect replay /tmp/bisect.log

# Visualize the remaining search space.
git bisect visualize             # uses gitk if installed
# or, simpler:
git bisect view --stat
