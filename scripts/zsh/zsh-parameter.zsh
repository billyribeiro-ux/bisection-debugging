#!/usr/bin/env zsh
zmodload zsh/parameter

# $commands → assoc array of all commands in PATH and their resolved paths
[[ -n "${commands[pnpm]}" ]] || exit 125    # pnpm not installed

# $functions → assoc array of all defined functions
print "Defined functions: ${(k)functions}"

# $jobtexts → text of currently-running background jobs
print "Background work: ${(v)jobtexts}"

# $modules → currently loaded modules
print "Modules: ${(k)modules}"
