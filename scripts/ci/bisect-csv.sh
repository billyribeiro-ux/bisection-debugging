#!/usr/bin/env bash
# bisect-csv.sh
# Find the row in a CSV that crashes your ingest job.
# Preserves the header row; bisects only the data rows.
set -euo pipefail

CSV="${1:?usage: $0 <csv> <ingest-cmd>}"
INGEST="${2:?missing ingest command}"

HEADER=$(head -n 1 "$CSV")
mapfile -t ROWS < <(tail -n +2 "$CSV")
N="${#ROWS[@]}"
echo "CSV has $N data rows"

slice_to_file() {
  local from="$1" to="$2"
  printf '%s\n' "$HEADER" > /tmp/bisect.csv
  for (( i = from; i <= to; i++ )); do printf '%s\n' "${ROWS[$i]}" >> /tmp/bisect.csv; done
}

# Sanity check: full file fails, empty file succeeds.
slice_to_file 0 $((N - 1))
$INGEST /tmp/bisect.csv && { echo "Full file passes; not reproducing"; exit 0; }
slice_to_file 0 -1
$INGEST /tmp/bisect.csv || { echo "Empty file fails; ingest is broken regardless"; exit 2; }

lo=0; hi=$((N - 1))
while (( lo < hi )); do
  mid=$(( (lo + hi) / 2 ))
  slice_to_file "$lo" "$mid"
  if $INGEST /tmp/bisect.csv >/dev/null 2>&1; then
    lo=$((mid + 1))
  else
    hi=$mid
  fi
done
echo
echo "Culprit row $lo:"
echo "$HEADER"
echo "${ROWS[$lo]}"
