# Bisection Debugging — Principal Engineer's Curriculum

A 24-page curriculum that teaches bisection debugging from "what is binary
search applied to bugs" through advanced patterns like memory-leak isolation,
CI auto-bisection, and distributed-systems version bisection.

## What's in this repo

```
index.html                 — open in any browser; the entire course
scripts/                   — every code block in the course, extracted as a real file
.github/workflows/         — `auto-bisect.yml`: GitHub Actions CI auto-bisection
extract-scripts.mjs        — regenerates scripts/ from index.html
fix-html-escaping.mjs      — idempotently escapes <,>,& inside code blocks
verify-scripts.sh          — syntax-checks every script
```

## Running the curriculum

```bash
open index.html              # macOS
xdg-open index.html          # Linux
start index.html             # Windows
# or just drag it onto a browser tab
```

No build step. Monaco Editor loads from CDN.

### Features

- **24 pages**, simple → advanced, with sidebar TOC grouped by part.
- **Monaco Editor** per code block, with a Copy button on each.
- **Search**: type in the sidebar input — `/` focuses it.
- **Light & dark themes**: toggle in the footer; respects `prefers-color-scheme`
  on first load, then remembers your choice in `localStorage`.
- **Navigation**: prev/next buttons, left/right arrow keys, `#page-N` hash routing.

## Running the scripts

See [scripts/README.md](scripts/README.md). Quick examples:

```bash
# Find which Svelte file fails svelte-check, in log(N) checks instead of N.
./scripts/file-bisect/find-leak-binary.sh \
    "pnpm exec svelte-check --filter" "src/lib/**/*.svelte"

# Auto-bisect a regression in a git range with a custom predicate.
chmod +x scripts/git-bisect/bisect-predicate.sh
git bisect start HEAD v2.3
git bisect run ./scripts/git-bisect/bisect-predicate.sh

# Find which earlier test pollutes global state and breaks a suspect test.
./scripts/test-perf/flaky-test-bisect.sh tests/auth/session.test.ts
```

## Verifying script integrity

```bash
./verify-scripts.sh
```

Runs `bash -n`, `zsh -n`, and `node --check` against every extracted script.
Exits 0 if all pass.

## Regenerating the scripts

If you edit a code block inside `index.html`, regenerate the matching script
file:

```bash
node extract-scripts.mjs
```

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
