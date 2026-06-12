export CARGO_INCREMENTAL=0   # sccache does NOT cache incremental artifacts —
                             # leaving this on would defeat the wrapper below
export RUSTC_WRAPPER=sccache
cargo test --offline --frozen 2>&1
