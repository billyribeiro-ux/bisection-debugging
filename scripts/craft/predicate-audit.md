# Predicate Audit (do this before `git bisect run`)

For each section of your predicate, check:

## Setup
[ ] Install / build failures exit 125, not 1
[ ] Lockfile is committed and the install uses --frozen-lockfile
[ ] External services are mocked or containerized — NOT staging

## Exercise
[ ] Random port (not hard-coded :3000)
[ ] Wait-for-ready loop, not arbitrary `sleep`
[ ] Environment pinned: TZ=UTC LC_ALL=C SOURCE_DATE_EPOCH=...
[ ] Timeouts on every potentially-long operation

## Observe
[ ] Captures the actual signal (HTTP code, value, file diff)
[ ] Does NOT conflate "failed assertion" with "test runner crashed"
[ ] Validates BOTH that work happened AND that it produced correct output

## Cleanup
[ ] `trap cleanup EXIT INT TERM` registered BEFORE any state is created
[ ] Removes temp files and dirs
[ ] Kills any backgrounded processes
[ ] Drops temporary databases / cleans up volumes

## Exit
[ ] Three-way: 0 (good), 1 (bad), 125 (skip)
[ ] No silent `exit 0` paths
[ ] Last line is the explicit exit decision, not an accident
