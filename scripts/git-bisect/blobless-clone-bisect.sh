#!/usr/bin/env bash
# Bisect a giant repo from a fresh, cheap clone. --filter=blob:none pulls
# commits+trees only; file contents are fetched on demand per checkout.
set -euo pipefail

git clone --filter=blob:none https://github.com/big/monorepo.git
cd monorepo

# Materialize only what the predicate needs at each step.
git sparse-checkout set services/api libs/shared

git bisect start origin/main v14.0.0 -- services/api libs/shared
git bisect run ./services/api/predicate.sh
