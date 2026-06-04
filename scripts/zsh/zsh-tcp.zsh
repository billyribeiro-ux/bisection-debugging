#!/usr/bin/env zsh
zmodload zsh/net/tcp

# Open a TCP connection to a service — no curl, no nc, no fork.
ztcp localhost 3000 || { print "service not reachable"; exit 125 }
FD=$REPLY                          # the file descriptor

# Send a minimal HTTP request
print -u $FD "GET /health HTTP/1.0\r\nHost: localhost\r\n\r\n"

# Read the response (first line only)
read -u $FD response

# Close
ztcp -c $FD

# Predicate decision
[[ "$response" == *"200 OK"* ]] && exit 0 || exit 1
