#!/usr/bin/env bash
# Find the commit that broke the deployment.
LAST_GOOD="${1:?usage: $0 <last-known-good-sha>}"

git bisect start HEAD "$LAST_GOOD" -- k8s/    # restrict bisection to k8s/
chmod +x k8s-bisect-predicate.sh
git bisect run ./k8s-bisect-predicate.sh
git bisect reset
