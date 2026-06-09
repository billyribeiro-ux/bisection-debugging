#!/usr/bin/env bash
# terraform-bisect-plan.sh
# Bisects without ever applying. Looks for the commit at which `terraform plan`
# starts producing a specific diff signature — e.g. "creating an open S3 bucket"
# or "destroying RDS database".
#
# Exit 0 = good (diff signature absent), 1 = bad (signature present).
set -uo pipefail

WORKSPACE="${WORKSPACE:-bisect}"
SIGNATURE="${SIGNATURE:?set SIGNATURE — a string that uniquely identifies the bad change in a plan output}"

# Sanity: skip if the commit doesn't even initialize.
terraform init -input=false -no-color >/dev/null 2>&1 || exit 125
terraform workspace select "$WORKSPACE" 2>/dev/null || terraform workspace new "$WORKSPACE"

# Run a non-destructive plan.
terraform plan -no-color -input=false -refresh=false -out=/tmp/tfplan >/tmp/plan.out 2>&1
RC=$?

# Provider errors (e.g. AWS credentials expired) — skip, not the bug.
grep -qE "Error:|InvalidClientToken|AccessDenied" /tmp/plan.out && [ $RC -ne 0 ] && exit 125

# ANY other failed plan is also unjudgeable: without this, a commit whose
# plan didn't even run would fall through and be scored "good".
[ $RC -ne 0 ] && exit 125

if grep -qF "$SIGNATURE" /tmp/plan.out; then
  exit 1   # the bad change is present
else
  exit 0   # not yet
fi
