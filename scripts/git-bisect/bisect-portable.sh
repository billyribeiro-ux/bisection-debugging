# Save current state.
git bisect log > bisect-state.log
git bisect reset

# On another machine (after cloning the same repo):
git bisect start
git bisect replay bisect-state.log
# Now continue from where you left off.
