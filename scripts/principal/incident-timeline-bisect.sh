#!/usr/bin/env bash
# Bisect the incident's timeline window — what changed in the period before
# things broke? Pull every change from every system that touches production.
START="${1:?incident start time, ISO format}"
END="${2:?incident end time}"

echo "=== Code deploys in window ==="
git log --since="$START" --until="$END" --oneline

echo "=== Infrastructure changes ==="
terraform-cloud-cli runs list --workspace prod --since "$START" --until "$END"

echo "=== Feature flag changes ==="
ld-cli audit-log list --start "$START" --end "$END"

echo "=== Database schema changes ==="
psql -c "SELECT * FROM schema_migrations WHERE applied_at BETWEEN '$START' AND '$END';"

echo "=== Upstream package versions installed in this window ==="
git log --since="$START" --until="$END" --diff-filter=M -p -- pnpm-lock.yaml
