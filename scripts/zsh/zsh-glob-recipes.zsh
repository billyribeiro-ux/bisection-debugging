#!/usr/bin/env zsh

# Recipe 1: Test only the files modified this week
recent=( **/*.test.ts(.mw-1) )

# Recipe 2: Find world-writable files in the repo (security bisection)
risky=( **/*(W) )
(( $#risky == 0 )) || { echo "world-writable files appeared: ${risky[@]}"; exit 1 }

# Recipe 3: Find large files added recently (bundle-bloat investigation)
bloat=( dist/**/*(.Lm+1mw-1) )    # > 1MB and modified within the last week

# Recipe 4: Bisect tests in dependency order (by mtime)
tests_oldest_first=( **/*.test.ts(.Om) )    # Om = oldest first (om = newest!)

# Recipe 5: Only files owned by current user (skip vendor dirs owned by root)
mine=( **/*(.u${UID}) )

# Recipe 6: Find symlinks that point to nonexistent targets.
# (-@) = follow links, keep what is STILL a symlink → only the broken ones.
# ((@-) would match every symlink — the trailing - toggles nothing.)
broken=( **/*(-@) )

# Recipe 7: Combine — large recent files OWNED by a specific user
suspect=( **/*(.Lm+1mw-1u:alice:) )   # u: filters by owner, not last editor

# Recipe 8: Files matching pattern AND containing "deprecated" via (e:...)
files=( **/*.ts(e:'grep -q deprecated $REPLY':) )
