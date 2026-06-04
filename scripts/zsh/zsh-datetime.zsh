#!/usr/bin/env zsh
zmodload zsh/datetime

# $EPOCHREALTIME is a builtin — seconds.microseconds since epoch, no fork.
start=$EPOCHREALTIME
./expensive-step.sh
end=$EPOCHREALTIME
print "Elapsed: $((end - start)) s"

# strftime builtin — no `date` fork either
strftime '%Y-%m-%d %H:%M:%S.%6N UTC' $EPOCHSECONDS
