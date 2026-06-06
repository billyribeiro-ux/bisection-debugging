# Normal blame: "who last edited this line?"
git blame src/file.ts -L 42,42

# REVERSE blame: "what's the FIRST commit where this line had this content?"
# Equivalent to bisecting the line's history forward in time.
git blame --reverse v1.2..HEAD src/file.ts -L 42,42
