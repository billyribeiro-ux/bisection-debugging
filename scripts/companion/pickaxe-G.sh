# Find every commit where any added or removed line matched the regex.
git log -G 'fooBar\(.*\)'

# Combine with patches:
git log -G 'console\.log\(.*password' -p

# Useful when -S misses moves and reformats
git log -G 'CACHE_KEY_PREFIX'
