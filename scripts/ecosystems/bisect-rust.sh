export CARGO_INCREMENTAL=1
export RUSTC_WRAPPER=sccache
cargo test --offline --frozen 2>&1
