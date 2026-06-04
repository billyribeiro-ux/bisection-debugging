#!/usr/bin/env bash
# Required at the top of any predicate that uses bash 5 features.
if (( BASH_VERSINFO[0] < 5 )); then
  echo "This predicate requires bash 5+; you have ${BASH_VERSION}" >&2
  exit 125   # untestable in this environment
fi
