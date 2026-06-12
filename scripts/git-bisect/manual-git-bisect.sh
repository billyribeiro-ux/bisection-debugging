# 1. Start the session.
git bisect start

# 2. Tell git the current state is bad.
git bisect bad HEAD

# 3. Tell git which earlier commit was known good.
git bisect good v2.3

# Git replies with something like:
#   Bisecting: 30 revisions left to test after this (roughly 5 steps)
#   [a1b2c3d] Refactor session store
# It has checked out the middle commit and is waiting for you.

# 4. Test the checked-out commit. Manually run login. Did it work?
#    If yes:
git bisect good
#    If no:
git bisect bad
#    Git checks out the next midpoint and repeats.

# 5. Repeat step 4 until git tells you:
#   a1b2c3d is the first bad commit
#   commit a1b2c3d
#   Author: someone
#   Date:   Tue May 27 14:02:31 2026 +0000
#       Refactor session store to use signed cookies

# 6. End the session and go back to your branch.
git bisect reset
