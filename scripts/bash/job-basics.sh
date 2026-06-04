#!/usr/bin/env bash
some-server &          # start in background
SERVER=$!              # capture pid
jobs                   # list background jobs
jobs -p                # list pids only
disown                 # forget job; survives shell exit
wait "$SERVER"         # block until SERVER exits
wait                   # block until ALL background jobs exit
