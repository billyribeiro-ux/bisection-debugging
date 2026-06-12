# Normal blame: "who last edited this line?"
git blame src/file.ts -L 42,42

# REVERSE blame: "what's the LAST commit where this line still existed
# as-is?" — i.e. when did this line disappear or get rewritten.
git blame --reverse v1.2..HEAD src/file.ts -L 42,42
