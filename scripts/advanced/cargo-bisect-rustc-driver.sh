#!/usr/bin/env bash
# cargo-bisect-rustc-driver.sh
# Find the rustc nightly that introduced a regression in your crate.
#
# Install once: cargo install cargo-bisect-rustc
#
# This script wraps cargo-bisect-rustc with a predicate that runs your test
# AND filters out compiler ICEs (which cargo-bisect-rustc reports separately).
set -euo pipefail

# Start broad: from the last known-good nightly to today.
GOOD="${1:?usage: $0 <good-nightly> <bad-nightly> [test-cmd]}"
BAD="${2:?missing bad nightly}"
TEST_CMD="${3:-cargo test --release}"

cat > /tmp/bisect-script.sh <<EOF
#!/usr/bin/env bash
set -uo pipefail
cd "\$1" 2>/dev/null || true   # cargo-bisect-rustc passes the project dir
$TEST_CMD
EOF
chmod +x /tmp/bisect-script.sh

# --regress=ice         → bisect ICEs
# --regress=error       → bisect new compile errors (the common case)
# --regress=success     → bisect commits that started PASSING
# --regress=non-error   → bisect runtime regressions when build still succeeds
cargo bisect-rustc \
  --start "$GOOD" --end "$BAD" \
  --regress=non-error \
  --script /tmp/bisect-script.sh \
  --preserve --preserve-target

# Once you have a nightly, narrow to a single rustc commit:
cargo bisect-rustc \
  --start "$(date -d "$BAD - 1 day" +%Y-%m-%d)" --end "$BAD" \
  --by-commit \
  --regress=non-error \
  --script /tmp/bisect-script.sh
