#!/usr/bin/env zsh
# zsh-zpty-bisect.zsh
# Bisect which line in a REPL transcript causes a leak/error.
# Uses zsh's `zpty` to drive the REPL non-interactively.

zmodload zsh/zpty
zmodload zsh/datetime

setopt extendedglob

transcript=( ${(f)"$(< $1)"} )       # commands, one per line
N=${#transcript}

mem_after_lines() {
  # Spawn node --repl in a pty, feed it $1 lines, query process.memoryUsage().
  local -a lines
  lines=( "$@" )
  zpty -d repl 2>/dev/null
  zpty repl 'node --interactive --no-warnings'
  zpty -w repl ".clear"
  for cmd in $lines; do
    zpty -w repl "$cmd"
  done
  # Sentinel.
  zpty -w repl 'console.log("__MEM__", process.memoryUsage().heapUsed)'
  local out=""
  zpty -r repl out '*__MEM__ *'
  zpty -d repl
  print -r -- "$out" | awk '/__MEM__/ { print $NF; exit }'
}

baseline=$(mem_after_lines)        # empty REPL baseline
LEAK_BYTES=${LEAK_BYTES:-50_000_000}

lo=1; hi=$N
while (( lo < hi )); do
  (( mid = (lo + hi) / 2 ))
  half=( $transcript[lo,mid] )
  bytes=$(mem_after_lines $half)
  growth=$(( bytes - baseline ))
  print "[$lo..$mid] heap: ${(l:12:)bytes}  growth ${(l:10:)growth}"
  if (( growth > LEAK_BYTES )); then hi=$mid; else (( lo = mid + 1 )); fi
done
print "leaking command: $transcript[lo]"
