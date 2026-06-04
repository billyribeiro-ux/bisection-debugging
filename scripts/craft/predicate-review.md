# Predicate PR Review Checklist

## Documentation
[ ] Header explains PURPOSE in 1–3 sentences
[ ] CONTRACT section lists exit codes and their meanings
[ ] INPUTS lists every env var with defaults and descriptions
[ ] EXAMPLE shows a copy-pasteable invocation
[ ] KNOWN FAILURE MODES lists 1+ failure with its remediation

## Structure (Part XIII.1)
[ ] Five sections clearly delineated (or equivalent in another language)
[ ] Cleanup registered before exercise

## Correctness (Part XIII.5 anti-patterns)
[ ] Env errors → exit 125
[ ] Random port if a server is involved
[ ] No external services (or explicitly documented exception)
[ ] Time / locale / TZ pinned
[ ] Hard timeouts on long operations
[ ] Threshold chosen with documented good/bad measurements

## Calibration
[ ] `--check` mode verifies known endpoints
[ ] At least one good SHA and one bad SHA in the self-test

## Sustainability
[ ] Committed to a discoverable location
[ ] Referenced from regression CI
