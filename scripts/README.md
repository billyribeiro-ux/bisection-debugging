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
| `advanced/`              | Part IX — info-theory calculator, Bayesian bisect, HDD, compiler-pass bisect, rr/chaos, AI checkpoint bisect, supply-chain time bisect, distributed-trace bisect. |
| `modern/`                | Part X — Kubernetes / Helm / Kustomize, Terraform / Pulumi / CDK, feature-flag bisect (ddmin), Docker layer / image-size / crash bisect, OpenAPI / GraphQL contract bisect. |
| `principal/`             | Part XI — incident timeline bisect, postmortem template, bisectability scorecard.|
| `frameworks/`            | Part XII — bisection cost-model calculator, history-quality-index scorer, game-day workshop kit, anti-pattern audit checklist.|
| `ecosystems/`            | Part XII — minimal bisection predicate snippets per language ecosystem (Node, Python, Go, Rust, Java, Ruby, PHP, .NET). |
| `craft/`                 | Part XIII — predicate-craft pedagogy artifacts: skeleton template, pre-flight worksheet example, the 5 predicate patterns, debugging instrumentation, meta-predicate calibration, the 5 exercise model solutions, the canonical shareable-predicate template, audit + review checklists. |
| `companion/`             | Part XIV — pickaxe + git log -L recipes, AI verification ritual + prompt templates (worksheet, audit, which-tool). |
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
#    (svelte-check takes no file args; the subset wrapper scopes it via a
#    generated tsconfig — see Part III.)
./scripts/file-bisect/find-leak-binary.sh \
    "./scripts/file-bisect/svelte-check-subset.sh" "src/lib/**/*.svelte"

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

If you edit `index.html`, regenerate the scripts in place via the wired
pnpm pipeline (escape → extract → verify) in one shot:

```bash
pnpm build
```

Or invoke the steps individually:

```bash
pnpm escape     # idempotent HTML entity normalization
pnpm extract    # regenerate scripts/ from index.html
pnpm verify     # bash -n / zsh -n / node --check every extracted file
```

## Verification only

```bash
pnpm verify
# or: ./verify-scripts.sh
```
