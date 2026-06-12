#!/usr/bin/env zsh
zmodload zsh/system

# Atomic file locking (without flock binary).
# Two gotchas: the lock FILE must already exist, and -u unlocks by file
# DESCRIPTOR — capture it at lock time with -f.
: >> /tmp/bisect.lock
{
  zsystem flock -t 5 -f lockfd /tmp/bisect.lock
  # critical section
  echo "round $1: $2" >> /tmp/results.log
} always {
  zsystem flock -u $lockfd
}

# Binary IO without a subshell. The parameter name is the trailing
# argument; -o would mean an output FD, not a variable.
exec 3< some-binary-file
sysread -i 3 -s 1024 data        # read up to 1024 bytes into $data
exec 3<&-

# Host/OS facts come from plain zsh parameters — $sysparams only holds
# pid/ppid/procsubstpid:
print "Running on $HOST ($OSTYPE, $MACHTYPE)"

# Sleep with subsecond resolution, no `sleep` fork — zselect lives in its
# OWN module:
zmodload zsh/zselect
zselect -t 50    # wait 500 ms (units = centiseconds)
