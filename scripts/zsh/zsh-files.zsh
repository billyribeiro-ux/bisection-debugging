#!/usr/bin/env zsh
zmodload -F zsh/files b:chmod b:chown b:mkdir b:rm b:ln

# These all run in-process, no fork:
mkdir -p /tmp/bisect-scratch
chmod 0755 /tmp/bisect-scratch
ln -sf /path/to/target /tmp/bisect-scratch/link

# Compare to bash, which would fork each command
