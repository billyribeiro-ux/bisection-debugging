# Incident: [one-line description]

**Date:** YYYY-MM-DD
**Duration:** XX minutes user-impact
**Severity:** SEV-1/2/3
**Authors:** @ic-during-incident, @on-call

## Summary
2–3 sentences a non-engineer can understand. What broke, who was affected, when it ended.

## Timeline (UTC)
- HH:MM — Alert fires.
- HH:MM — On-call paged.
- HH:MM — Hypothesis 1: ... (status: confirmed/rejected).
- HH:MM — Bisection started across deploys X..Y.
- HH:MM — Culprit identified: commit `a3f9c81`.
- HH:MM — Rollback initiated.
- HH:MM — Metrics confirm recovery.
- HH:MM — Postmortem started.

## What happened
Plain-English narrative. What the code/system did, why that produced the symptom.

## Why it happened (root cause)
The *contributing factors* — usually more than one. A bad commit AND a missing test AND a slow alert.

## Why our defenses didn't catch it
- The test that should have caught this was missing because: ...
- The metric that should have alerted earlier was: ...
- The code review on PR #X missed it because: ...

## What we're doing about it (action items)
| # | Action | Owner | Due | Status |
|---|--------|-------|-----|--------|
| 1 | Add regression test for X | @alice | YYYY-MM-DD | Open |
| 2 | Add alert on metric Y | @bob | YYYY-MM-DD | Open |
| 3 | Document deploy procedure Z | @carol | YYYY-MM-DD | Open |

## What went well
Yes, every postmortem has a "what went well" section. The team needs to learn from successes too.

## Lessons learned (org-wide)
What other teams should know. This is the section that compounds organizational value.

## Appendix: bisection log
[paste the actual bisection commands and output]
