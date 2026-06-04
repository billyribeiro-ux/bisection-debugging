#!/usr/bin/env bash
# For Kustomize, render with `kubectl kustomize` (or kustomize build).
set -uo pipefail
kubectl -n "$NS" apply -k ./overlays/staging || exit 1
# ... same wait/check ...
