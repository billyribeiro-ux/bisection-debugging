# mozregression: bisect Firefox between two dates without compiling once.
# Phase 1 walks nightlies (one per day); phase 2 walks per-push CI builds.
pipx install mozregression

mozregression --good 2025-11-01 --bad 2026-02-15 \
  -a https://bug-demo.example.com/repro.html
# ...each downloaded build opens; you answer good/bad at each prompt...
#   Last good revision:  0b3ecf8e0e2c
#   First bad revision:  9d1c40e0a1b4
#   Pushlog: https://hg.mozilla.org/integration/autoland/pushloghtml?...

# Chromium's equivalent ships in the source tree and walks snapshot builds
# by commit position (run from a chromium checkout; see --help for archives):
python3 tools/bisect-builds.py -a linux64 -g 1313161 -b 1315115 --use-local-cache
