#!/usr/bin/env bash
# Bisect across PyPI publish times.
# Resolves "latest as of DATE" via PyPI's JSON API into a constraints file.
# (uv has this built in: `uv pip install --exclude-newer DATE`; plain pip
# does not, hence the manual resolution below.)
set -euo pipefail
PKG="$1"; AT="$2"

# Fetch publish history and pick the most recent version on/before AT.
python - "$PKG" "$AT" <<'PY' > /tmp/c.txt
import json, sys, urllib.request, datetime as dt
pkg, at = sys.argv[1], dt.datetime.fromisoformat(sys.argv[2])
data = json.load(urllib.request.urlopen(f'https://pypi.org/pypi/{pkg}/json'))
best = None
for v, files in data['releases'].items():
    for f in files:
        t = dt.datetime.fromisoformat(f['upload_time_iso_8601'].rstrip('Z'))
        if t <= at and (best is None or t > best[1]): best = (v, t)
print(f'{pkg}=={best[0]}  # uploaded {best[1].isoformat()}')
PY
pip install -c /tmp/c.txt "$PKG"
