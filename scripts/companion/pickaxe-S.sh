# Find every commit that CHANGED THE NUMBER of occurrences of "fooBar"
# (introduced it, removed it, or moved instances around).
git log -S 'fooBar'

# Restrict to specific files:
git log -S 'fooBar' -- 'src/**/*.ts'

# With patches shown, so you see what each commit did:
git log -S 'fooBar' -p

# Include parent SHA + summary for each hit:
git log -S 'fooBar' --pretty=format:'%h %ai %an: %s'
