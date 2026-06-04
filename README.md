# Bisection Debugging — Principal Engineer's Curriculum

A **76-page curriculum** designed to take someone from "I've never coded
before" to the full L7+ principal-engineer mental model — including the
hands-on craft of writing bisection predicates from scratch. Starts with
the terminal and binary search, builds through git bisect, advanced bisection
(Shannon-information-theoretic lower bound, Bayesian bisection under noise,
hierarchical delta debugging, compiler-pass bisection, supply-chain time
bisection, distributed trace bisection), modern-systems bisection
(Kubernetes, Terraform, feature flags, Docker layers, API contracts), the
principal-engineer concerns (designing for bisectability, incident response,
the business case, mentoring, postmortems), original frameworks + benchmark
data (the Bisection Cost Model, History Quality Index, Predicate Hermeticity
Score, ecosystem comparisons, runnable game-day workshop, 2030 forward look),
and the craft of writing predicates (the five-section anatomy, a pre-flight
worksheet, a fully-narrated step-by-step build, the five reusable patterns,
ten anti-patterns to avoid, predicate-debugging techniques, five practice
exercises with model solutions, and how to make predicates survive their
author).

## Quickstart (60 seconds)

```bash
corepack enable                          # Node 16.9+ has corepack built in
git clone https://github.com/billyribeiro-ux/bisection-debugging
cd bisection-debugging
pnpm install                             # honors packageManager pin
pnpm build                               # escape → extract → verify
pnpm dev                                 # serves at http://localhost:8080
```

This project uses **pnpm** (never npm). The `preinstall` hook will refuse
`npm install` outright via [`only-allow`](https://github.com/pnpm/only-allow);
the `packageManager` field locks the exact pnpm version via corepack.

## What's in this repo

```
index.html                 — open in any browser; the entire 34-page course
scripts/                   — every code block in the course, extracted as a real file
.github/workflows/         — auto-bisect.yml: GitHub Actions CI auto-bisection
package.json               — wired build orchestration (see "Build commands" below)
extract-scripts.mjs        — regenerates scripts/ from index.html
fix-html-escaping.mjs      — idempotently escapes <,>,& inside code blocks
verify-scripts.sh          — syntax-checks every script
```

## Build commands

All operations are wired through `pnpm` scripts in `package.json` with
explicit pre/post lifecycle composition. The `.npmrc` at the repo root sets
`enable-pre-post-scripts=true` — pnpm's auto-fired pre/post hooks are
disabled by default, and the curriculum's day-by-day page teaches why. See
Part IX's "Building package.json from pnpm init to Production" and "The
Build Orchestration Layer" pages.

| Command          | What it does                                                                 |
|------------------|------------------------------------------------------------------------------|
| `pnpm build`  | `prebuild` (escape HTML) → `build` (extract scripts) → `postbuild` (verify). |
| `pnpm test`       | `pretest` (extract) → `test` (verify). Convention-aligned.                    |
| `pnpm dev`    | Serves `index.html` at `http://localhost:8080` via `pnpm dlx serve` (no install). |
| `pnpm start`      | Alias for `pnpm dev`.                                                     |
| `pnpm check`  | Alias for `pnpm build`. Used as the pre-push gate.                         |
| `pnpm clean`  | Removes `scripts/*` so the next `build` regenerates from scratch.            |

The primitives can also be invoked directly: `pnpm escape`, `pnpm extract`,
`pnpm verify`.

## Curriculum outline

**Part 0 — Before You Start** (10 pages, accessible to absolute beginners) ·
what is a bug, really · the terminal in 10 minutes · git in 10 minutes ·
how to read code in this curriculum · binary search visualized · scientific
method for debugging · reading error messages and stack traces · writing
minimal reproductions · the debugging tool hierarchy · rubber-duck and pair
debugging.

**Part I — Foundations** · what bisection is · the monotonicity invariant ·
manual halving by hand.

**Part II — git bisect** · basics · automated `bisect run` · skips & flakes ·
rebases / squash-merges / force-pushes.

**Part III — Files & components** · binary file halving · Playwright + CDP
heap-snapshot leak finder · Tailwind class bisection with pixel diffs.

**Part IV — Dependencies & builds** · `package.json` bisector via pnpm
overrides · `tsconfig.json` flag bisection · Vite plugin bisection.

**Part V — Tests & performance** · flaky-test polluter finder · `hyperfine`
perf budget predicate · long-running Node server leak detection.

**Part VI — Bash toolkit** · four levels from one-liner to Delta Debugging.

**Part VII — Zsh toolkit** · glob qualifiers, `${(f)…}`, `zpty` REPL bisection.

**Part VIII — Real-world** · GitHub Actions auto-bisect workflow ·
multi-service version bisection · CSV / feature-flag / env bisection ·
anti-patterns and when not to bisect.

**Part IX — Advanced & Theoretical** · Shannon information-theoretic lower
bound · Bayesian bisection under noise · Hierarchical Delta Debugging ·
compiler-pass bisection (LLVM, rustc, gcc) · rr record/replay for races ·
AI model checkpoint bisection · supply-chain time bisection · distributed
trace bisection · package.json build-orchestration patterns · case studies
and further reading.

**Part X — Modern Systems** · bisecting Kubernetes manifests ·
infrastructure-as-code (Terraform / Pulumi / CDK) · feature flag
configurations · Docker image layers · API contracts and GraphQL schemas.

**Part XI — Principal Engineering** (the L7+ chapters) · designing systems
to be bisectable · bisection in production incident response · bisection
vs. observability as complementary tools · the cost of un-bisectable bugs
and how to build the business case · when NOT to bisect (the decision
framework) · mentoring debugging skill on your team · building a culture
of reproducibility · postmortems, blameless culture, and continuous
improvement.

**Part XII — Frameworks, Data & Future** · the Bisection Cost Model (with
working calculator) · real-world benchmark tables · the History Quality
Index (HQI) — a 100-point scoring rubric for repo bisectability · the
Predicate Hermeticity Score (PHS) — 70-point predicate quality rubric ·
seven hard-won composite incident stories · the debugging-skill calibration
rubric (L3–L7) for hiring & leveling · the anti-bisection patterns catalog
(10 patterns) · a runnable three-hour game-day workshop · bisection across
language ecosystems (Node, Python, Go, Rust, Java, Ruby, PHP, .NET, C/C++) ·
bisection in 2030 (opinionated forward look).

**Part XIII — The Craft of Writing Predicates** · the five-section anatomy
of every predicate · the pre-flight worksheet you fill in before opening
a text editor · a fully-narrated five-iteration build of a real predicate
(naive 5 lines → bullet-proof 35 lines) · the five reusable predicate
patterns (type-check, smoke, behavioral assertion, perf-budget, golden-file)
· the ten predicate anti-patterns that make bisections lie · how to debug
a broken predicate (four symptoms, four diagnostic procedures) · five
hands-on practice exercises with worksheet sketches and model solutions ·
how to make predicates survive their author (sharing, CI integration,
review checklists).

## Requirements

- Node ≥ 20 (declared in `engines.node` and `.nvmrc`).
- Bash, Zsh available on PATH (for `verify-scripts.sh`).
- No other dependencies — the dev server runs via `pnpm dlx serve@14`, the
  rest is pure-Node.

## CI integration

Four lines of YAML, because all logic lives in `package.json`:

```yaml
- uses: pnpm/action-setup@v4               # reads packageManager from package.json
- uses: actions/setup-node@v4
  with:
    node-version-file: '.nvmrc'
    cache: 'pnpm'
- run: pnpm install --frozen-lockfile
- run: pnpm check
```
