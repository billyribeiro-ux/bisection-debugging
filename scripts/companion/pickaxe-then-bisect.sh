# Step 1: pickaxe — "what commits touched our cache key?"
SUSPECTS=( $(git log --format=%h -S 'CACHE_KEY_PREFIX') )
echo "Pickaxe candidates: ${SUSPECTS[*]}"

# Step 2: for each candidate, run the predicate to see if it actually breaks
for sha in "${SUSPECTS[@]}"; do
  git checkout -q "$sha"
  ./predicate.sh >/dev/null 2>&1 && echo "$sha OK" || echo "$sha BAD"
done
git checkout -q -

# If the bug appears in commit X but not its predecessor, X is the culprit.
# log₂(N) became O(small constant).
