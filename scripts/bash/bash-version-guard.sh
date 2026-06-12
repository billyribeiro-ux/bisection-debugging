#!/usr/bin/env bash
# Required at the top of any predicate that uses the features on this page.
# Requiring 5.x wholesale beats tracking which feature needs 4.0/4.3/4.4/5.1.
if (( BASH_VERSINFO[0] < 5 )); then
  echo "This predicate requires bash 5+; you have ${BASH_VERSION}" >&2
  exit 125   # untestable in this environment
fi
