#!/usr/bin/env bash
# graphql-bisect.sh — find the commit that introduced a breaking schema change.
LAST_GOOD="${1:?last-known-good SHA}"
SCHEMA="${2:-schema.graphql}"

git show "$LAST_GOOD:$SCHEMA" > /tmp/schema.good.graphql

cat > predicate.sh <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
SCHEMA="${SCHEMA:-schema.graphql}"
[ -f "$SCHEMA" ] || exit 125
# The CLI exits non-zero when breaking changes are detected — that IS the
# predicate. (There's no --fail-on-breaking CLI flag; that name belongs to
# the GitHub Action's inputs.)
pnpm dlx @graphql-inspector/cli diff \
  /tmp/schema.good.graphql "$SCHEMA"
EOF
chmod +x predicate.sh

git bisect start HEAD "$LAST_GOOD"
git bisect run ./predicate.sh
git bisect reset
