#!/usr/bin/env bash
# Predicates in repos with submodules MUST sync them per step: bisect
# moves the submodule POINTERS but never updates their working trees.
set -euo pipefail
git submodule update --init --recursive --quiet
exec ./run-tests.sh
