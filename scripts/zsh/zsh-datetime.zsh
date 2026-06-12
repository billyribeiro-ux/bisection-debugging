#!/usr/bin/env zsh
zmodload zsh/datetime

# $EPOCHREALTIME is a builtin — seconds.microseconds since epoch, no fork.
start=$EPOCHREALTIME
./expensive-step.sh
end=$EPOCHREALTIME
print "Elapsed: $((end - start)) s"

# strftime builtin — no `date` fork either. (No %N: strftime(3) has no
# sub-second field; take fractions from $EPOCHREALTIME or $epochtime.)
strftime '%Y-%m-%d %H:%M:%S UTC' $EPOCHSECONDS
zmodload zsh/datetime   # also provides $epochtime: (seconds, nanoseconds)
print "frac: ${epochtime[2]}"
