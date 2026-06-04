#!/usr/bin/env bats
# bats-core: a test framework for bash scripts.
# Install: apt-get install bats / brew install bats-core
# Run: bats predicate.bats

@test "predicate returns 0 at known-good SHA" {
  git checkout -q a3f9c81
  run ./predicate.sh
  [ "$status" -eq 0 ]
}

@test "predicate returns 1 at known-bad SHA" {
  git checkout -q e7b2a91
  run ./predicate.sh
  [ "$status" -eq 1 ]
}

@test "predicate returns 125 on missing dependency" {
  mv pnpm-lock.yaml pnpm-lock.yaml.bak
  run ./predicate.sh
  [ "$status" -eq 125 ]
  mv pnpm-lock.yaml.bak pnpm-lock.yaml
}

@test "predicate handles SIGINT cleanly" {
  ./predicate.sh &
  sleep 1
  kill -INT $!
  wait $!
  [ ! -e /tmp/predicate-leftover ]
}
