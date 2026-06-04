#!/usr/bin/env bash
# k8s-bisect-predicate.sh
# Apply the current commit's manifests to a disposable namespace and check
# whether the deployment becomes ready within a deadline.
#
# Exit codes follow `git bisect run`: 0 = good, 1 = bad, 125 = skip.
set -uo pipefail

NS="bisect-$(git rev-parse --short HEAD)"
TIMEOUT="${TIMEOUT:-180s}"

cleanup() { kubectl delete namespace "$NS" --wait=false 2>/dev/null || true; }
trap cleanup EXIT

kubectl create namespace "$NS"             || exit 125  # cluster issue, not the bug

# Apply the whole manifest folder for THIS commit.
kubectl -n "$NS" apply -f ./k8s/            || exit 1

# Wait for every Deployment in this namespace to become Available.
kubectl -n "$NS" wait --for=condition=Available \
        --timeout="$TIMEOUT" deployment --all
RC=$?

# Optional functional check: hit a smoke endpoint inside the pod.
if [ $RC -eq 0 ]; then
  kubectl -n "$NS" exec deploy/api -- curl -sf http://localhost:8080/healthz \
    || RC=1
fi

exit $RC
