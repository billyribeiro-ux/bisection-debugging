# Bisect only along the first-parent chain of main.
# This treats each PR merge as a single unit instead of descending into it.
git bisect start --first-parent
git bisect bad HEAD
git bisect good v2.3
git bisect run ./bisect-predicate.sh
