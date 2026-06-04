#!/usr/bin/env zsh
# Diff between two dynamically-generated outputs without writing tempfiles
# manually. The =(...) creates a temp file behind your back.

diff -u =(produce-baseline-output) =(produce-current-output)
#       └────────────┬─────────────┘ └────────────┬───────────┘
#                    │                            │
#         materialized to /tmp/...     materialized to /tmp/...

# Bash's <(...) creates a named pipe — works for most tools but breaks for tools
# that mmap or seek. =(...) creates a real file, no caveats.
