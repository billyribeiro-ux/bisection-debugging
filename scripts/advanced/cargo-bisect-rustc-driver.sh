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

# --regress chooses WHAT counts as "regressed" when no --script is given:
#   --regress=ice       → an internal compiler error appears
#   --regress=error     → the crate stops compiling (the common case)
#   --regress=success   → the crate STARTS compiling (find a fix)
#   --regress=non-ice / non-error → the inverses
# With --script, keep the DEFAULT (--regress=error): script exit != 0 marks
# the commit as regressed — which is exactly what a failing runtime test does.
cargo bisect-rustc \
  --start "$GOOD" --end "$BAD" \
  --script /tmp/bisect-script.sh \
  --preserve --preserve-target

# Once you have a nightly, narrow to a single rustc merge commit
# (cargo-bisect-rustc downloads the per-merge CI artifacts — no compiling):
cargo bisect-rustc \
  --start "$(date -d "$BAD - 1 day" +%Y-%m-%d)" --end "$BAD" \
  --by-commit \
  --script /tmp/bisect-script.sh
