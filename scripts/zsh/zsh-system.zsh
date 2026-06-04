#!/usr/bin/env zsh
zmodload zsh/system

# Atomic file locking (without flock binary)
{
  zsystem flock -t 5 /tmp/bisect.lock
  # critical section
  echo "round $1: $2" >> /tmp/results.log
} always {
  zsystem flock -u /tmp/bisect.lock
}

# Binary IO without a subshell
exec 3< some-binary-file
sysread -i 3 -o data -s 1024     # read up to 1024 bytes into $data
exec 3<&-

# Get the kernel version (POSIX uname builtin)
zmodload zsh/system
print "Running on $sysparams[host]"

# Sleep with subsecond resolution, no `sleep` fork
zselect -t 50    # wait 500 ms (units = centiseconds)
