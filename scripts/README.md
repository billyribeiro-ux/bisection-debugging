# Bisection Debugging Scripts

Real, runnable scripts extracted from the curriculum in `index.html`.
Each script is self-contained, has a header explaining inputs/outputs/exit
codes, and is exactly the version embedded in the corresponding lesson.

## Layout

| Folder                   | What's in it                                                                  |
| ------------------------ | ----------------------------------------------------------------------------- |
| `foundations/`           | The napkin method, hermetic & flake-resistant predicates, manual log sheet.   |
| `git-bisect/`            | Manual & automated `git bisect`, skip/replay, force-push & squash recovery.   |
| `file-bisect/`           | Binary file-halving (`find-leak-binary.sh`), Playwright + CDP heap leak hunt. |
| `dep-build/`             | `package.json` / lockfile / tsconfig / Vite-plugin bisectors.                 |
| `test-perf/`             | Flaky-test polluter finder, perf budget predicate, server leak detector.     |
| `bash/`                  | Bash toolkit, four levels — from one-liner to parallel & Delta Debugging.    |
| `zsh/`                   | Same problems solved idiomatically in zsh (glob qualifiers, `zpty` REPL).    |
| `ci/`                    | Fleet / CSV / env / flag bisectors, verify-the-verdict script.               |
| `../.github/workflows/`  | `auto-bisect.yml` — GitHub Actions auto-bisect on nightly failure.            |

## Quick start

```bash
# 1) Generic `git bisect run` predicate.
cp scripts/git-bisect/bisect-predicate.sh .
chmod +x bisect-predicate.sh
# Edit the three variables at the top, then:
git bisect start HEAD v2.3
git bisect run ./bisect-predicate.sh

# 2) Find which Svelte file fails `svelte-check`, in log(N) invocations.
./scripts/file-bisect/find-leak-binary.sh \
    "pnpm exec svelte-check --filter" "src/lib/**/*.svelte"

# 3) Find the test that pollutes global state.
./scripts/test-perf/flaky-test-bisect.sh tests/auth/session.test.ts

# 4) Find which Tailwind class in a long class="…" attribute broke layout.
node scripts/file-bisect/bisect-tailwind-classes.mjs src/lib/Header.svelte 0
```

## Conventions

- **Exit codes follow `git bisect run`:** `0` = good, `1` = bad,
  `125` = skip (environment problem, not the bug itself).
- **Bash scripts** assume bash 4+ (`mapfile`, `shopt -s globstar`, namerefs).
- **Zsh scripts** are idiomatic zsh, not POSIX shell — they use glob
  qualifiers, `${(f)…}` array splitting, and `zpty` for REPL bisection.
- **Node scripts** are ES modules (`.mjs`); run with Node 20+.
- **Cleanup is guaranteed.** Every script that stashes files or edits
  configs installs a `trap` (bash) / `process.on('exit')` (node) handler so
  Ctrl-C and crashes never leave your worktree in a half-modified state.

## Regenerating

If you edit `index.html`, regenerate the scripts in place with:

```bash
node extract-scripts.mjs
```

## Verification

The repo includes `verify-scripts.sh` which syntax-checks every script
without executing it.

```bash
./verify-scripts.sh
```
