#!/usr/bin/env bash
# openapi-diff-bisect.sh
# Bisect across commits of an OpenAPI spec to find a breaking change.
#
# Uses oasdiff (https://github.com/oasdiff/oasdiff) — a CLI that classifies
# spec diffs as breaking, non-breaking, or info-level.
#
# Predicate: at this commit, does the spec contain ANY breaking change
# relative to the last known good?
LAST_GOOD="${1:?last-known-good SHA}"
SPEC="${2:-openapi.yaml}"

# Materialize the good baseline once.
git show "$LAST_GOOD:$SPEC" > /tmp/openapi.good.yaml

cat > predicate.sh <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
SPEC="${SPEC:-openapi.yaml}"
[ -f "$SPEC" ] || exit 125
# oasdiff returns nonzero if there are breaking changes.
oasdiff breaking /tmp/openapi.good.yaml "$SPEC" --format text
EOF
chmod +x predicate.sh

git bisect start HEAD "$LAST_GOOD"
git bisect run ./predicate.sh
git bisect reset
