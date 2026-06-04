#!/usr/bin/env bash
# Default: signals interrupt the running command but trap fires AFTER the
# current command completes. This creates a race: cleanup might run before
# you wrote your important measurement.

declare -a MEASUREMENTS=()
interrupted=0

handle_sigint() {
  interrupted=1
  echo "SIGINT received; finishing current measurement..."
}
trap handle_sigint INT

for i in {1..100}; do
  if (( interrupted == 1 )); then
    echo "exiting cleanly with ${#MEASUREMENTS[@]} measurements" >&2
    break
  fi
  MEASUREMENTS+=("$(measure-once)")
done

# Now we exit cleanly with results, even if interrupted.
echo "${MEASUREMENTS[*]}"
