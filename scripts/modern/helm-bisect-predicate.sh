#!/usr/bin/env bash
# For Helm-rendered manifests, materialize the chart first, then apply.
set -uo pipefail
helm template ./charts/api --values ./values.yaml | kubectl -n "$NS" apply -f - \
  || exit 1
# ... same wait/check as before ...
