#!/usr/bin/env zsh

# Recipe 1: Read a multi-line command output into an array, deduplicate, sort
COMMITS_SUSPECT=( ${(fou)"$(git log --format=%h v1.2..HEAD)"} )
#                  └─┬─┘ └──────────────┬─────────────────┘
#                    │                  │
#                    ├ f = split on newlines
#                    ├ o = sort ascending
#                    └ u = unique

# Recipe 2: Quote every element of an array for safe re-evaluation
declare -a FILES=( "file with spaces.ts" "another file.js" )
SAFE_ARGS=( "${(q)FILES[@]}" )
eval "ls ${SAFE_ARGS[@]}"          # safe even though filenames have spaces

# Recipe 3: Indirect reference — read a variable named after a SHA
declare RESULT_a3f9c81="0"
SHA="a3f9c81"
echo "${(P)${:-RESULT_$SHA}}"      # → "0"
# Note the inner ${:-…}: it builds the NAME first, then (P) dereferences
# it. The tempting ${(P)$:-RESULT_$SHA} expands $$ (the PID) instead.

# Recipe 4: Convert array to comma-separated string for an SQL IN clause
declare -a IDS=( 1 2 3 4 5 )
csv="${(j:,:)IDS}"                 # → "1,2,3,4,5"
psql -c "SELECT * FROM users WHERE id IN ($csv);"

# Recipe 5: Read measurement-by-newline output, sort numerically descending
declare -a MEASUREMENTS=( ${(fOn)"$(./measure-once-per-line)"} )
P99=$MEASUREMENTS[$((${#MEASUREMENTS}*1/100 + 1))]
echo "p99 = $P99"

# Recipe 6: Split a colon-separated PATH and find duplicates
declare -a PATH_PARTS=( ${(s.:.)PATH} )
declare -a UNIQUE_PARTS=( ${(u)PATH_PARTS} )
if (( $#PATH_PARTS != $#UNIQUE_PARTS )); then
  echo "PATH has duplicate entries"
fi

# Recipe 7: Escape a value for use in a PATTERN match (==, not =~).
# (b) escapes glob metacharacters only — '.' is NOT regex-escaped, so
# using it to build an =~ ERE is unsafe ("1.2.3" would match "1x2x3").
USER_INPUT='1.2.3 (test)'
SAFE_PAT="${(b)USER_INPUT}"
[[ "$line" == *$~SAFE_PAT* ]] && echo match
