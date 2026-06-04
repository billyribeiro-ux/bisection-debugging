#!/usr/bin/env bash
# Bisects across terraform state snapshots (backed up by remote state versioning,
# e.g. S3 versioning or Terraform Cloud state history).
#
# For each historical state, run `terraform plan` AGAINST IT and check whether
# the drift signature is present. The "good" version is the last one without drift.
STATES_DIR="${1:?path to versioned state files}"
SIGNATURE="$2"

for state in $(ls "$STATES_DIR"/*.tfstate | sort); do
  cp "$state" terraform.tfstate
  terraform plan -no-color -refresh=true >/tmp/p.out 2>&1
  if grep -qF "$SIGNATURE" /tmp/p.out; then
    echo "DRIFT first appears in state: $state"
    break
  fi
done
