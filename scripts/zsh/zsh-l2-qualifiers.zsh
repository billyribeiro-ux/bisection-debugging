#!/usr/bin/env zsh
# zsh-l2-qualifiers.zsh
# Glob qualifiers (in parens after the glob) filter the result set
# WITHOUT needing find/xargs. Composable, very fast.

# Every .svelte file:
files=( src/lib/**/*.svelte(.) )

# Only files modified in the last hour:
recent=( src/lib/**/*.svelte(.mh-1) )

# Only files larger than 50KB:
big=( src/lib/**/*.svelte(.Lk+50) )

# Only files in directories whose name ends in /components/:
comps=( src/lib/**/components/*.svelte(.) )

# Sorted oldest-first, exclude tests, limit to first 200:
candidates=( src/lib/**/*.svelte(.om^*.test.*[1,200]) )

# Files NOT containing 'TODO' (uses zsh's `e` qualifier with a code expr):
clean=( src/lib/**/*.svelte(.e:'! grep -q TODO $REPLY':) )

print -l ${#files} ${#recent} ${#big} ${#comps} ${#candidates} ${#clean}
