#!/usr/bin/env bash
declare -A config=([port]=3000 [host]=localhost)

# @Q — quote for safe re-evaluation
declare -p config              # → declare -A config=(["port"]="3000"...)
echo "${config[@]@Q}"          # quoted form, safe for eval

# @A — re-emit the assignment statement (for serialization)
echo "${config[@]@A}"          # → ([port]="3000"...) suitable for source

# @P — expand prompt sequences (for headers in logs)
PS4_PROMPT='+ \D{%H:%M:%S} ${BASH_SOURCE}:${LINENO}: '
echo "${PS4_PROMPT@P}"

# @U / @L — upper / lowercase
sha="$(git rev-parse HEAD)"
echo "${sha@U}"                # uppercase variant — useful for case-insensitive matching
