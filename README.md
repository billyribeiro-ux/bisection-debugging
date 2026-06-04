# Bisection Debugging — Principal Engineer's Curriculum

A 34-page curriculum that teaches bisection debugging from "what is binary
search applied to bugs" through to the Shannon-information-theoretic lower
bound, Bayesian bisection under noise, hierarchical delta debugging, compiler
pass bisection, AI model checkpoint bisection, supply-chain time bisection,
and distributed trace bisection.

## Quickstart (60 seconds)

```bash
git clone https://github.com/billyribeiro-ux/bisection-debugging
cd bisection-debugging
npm run build        # escape → extract → verify
npm run dev          # serves at http://localhost:8080
```

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

All operations are wired through `npm` scripts with explicit pre/post lifecycle
composition. See Part IX's "Build Orchestration Layer" page for the teaching.

| Command          | What it does                                                                 |
|------------------|------------------------------------------------------------------------------|
| `npm run build`  | `prebuild` (escape HTML) → `build` (extract scripts) → `postbuild` (verify). |
| `npm test`       | `pretest` (extract) → `test` (verify). Convention-aligned.                    |
| `npm run dev`    | Serves `index.html` at `http://localhost:8080` via `npx serve` (no install). |
| `npm start`      | Alias for `npm run dev`.                                                     |
| `npm run check`  | Alias for `npm run build`. Used as the pre-push gate.                         |
| `npm run clean`  | Removes `scripts/*` so the next `build` regenerates from scratch.            |

The primitives can also be invoked directly: `npm run escape`, `npm run extract`,
`npm run verify`.

## Curriculum outline

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

## Requirements

- Node ≥ 20 (declared in `engines.node` and `.nvmrc`).
- Bash, Zsh available on PATH (for `verify-scripts.sh`).
- No other dependencies — the dev server runs via `npx --yes serve@14`, the
  rest is pure-Node.

## CI integration

Three lines of YAML, because all logic lives in `package.json`:

```yaml
- uses: actions/setup-node@v4
  with: { node-version-file: '.nvmrc' }
- run: npm ci
- run: npm run check
```
