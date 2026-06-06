#!/usr/bin/env node
// extract-scripts.mjs
// Parses index.html, pulls every <pre class="code" data-lang data-title> block,
// decodes HTML entities, and writes each one to scripts/<category>/<title>.

import fs from 'fs';
import path from 'path';

const html = fs.readFileSync('index.html', 'utf8');

// Map every data-title to a target directory. Titles that match a path
// (contain '/') keep their own path; everything else is bucketed by topic.
const CATEGORY = {
  // Part I — Foundations
  'napkin-bisect.sh':            'foundations',
  'flake-resistant-predicate.sh':'foundations',
  'hermetic-predicate.sh':       'foundations',
  'bisection-log.md':            'foundations',
  'halve-and-test.sh':           'foundations',

  // Part II — git bisect
  'manual-git-bisect.sh':        'git-bisect',
  'git-bisect-extras.sh':        'git-bisect',
  'git-bisect-oneline.sh':       'git-bisect',
  'bisect-predicate.sh':         'git-bisect',
  'drive-bisect.sh':             'git-bisect',
  'bisect-output.txt':           'git-bisect',
  'bisect-skip-range.sh':        'git-bisect',
  'bisect-first-parent.sh':      'git-bisect',
  'bisect-fix-mistake.sh':       'git-bisect',
  'bisect-anomaly.txt':          'git-bisect',
  'bisect-portable.sh':          'git-bisect',
  'bisect-terms.sh':             'git-bisect',
  'squash-result.txt':           'git-bisect',
  'bisect-squashed-pr.sh':       'git-bisect',
  'bisect-survive-force-push.sh':'git-bisect',
  'bisect-reflog-rescue.sh':     'git-bisect',

  // Part III — File / module
  'find-leak-binary.sh':         'file-bisect',
  'find-leak-by-stashing.sh':    'file-bisect',
  'memoized-predicate.sh':       'file-bisect',
  'mem-leak-bisect.mjs':         'file-bisect',
  'snapshot-diff.mjs':           'file-bisect',
  'capture-baseline.mjs':        'file-bisect',
  'pixel-diff-predicate.mjs':    'file-bisect',
  'bisect-tailwind-classes.mjs': 'file-bisect',

  // Part IV — Dep & build
  'dep-bisect.mjs':              'dep-build',
  'build-bumps-json.sh':         'dep-build',
  'dep-bisect-transitive.sh':    'dep-build',
  'tsconfig-bisect.mjs':         'dep-build',
  'bisect-node-flags.sh':        'dep-build',
  'vite-plugin-bisect.mjs':      'dep-build',

  // Part V — Test & perf
  'flaky-test-bisect.sh':        'test-perf',
  'bisect-within-file.sh':       'test-perf',
  'perf-bisect-predicate.sh':    'test-perf',
  'drive-perf-bisect.sh':        'test-perf',
  'api-perf-predicate.sh':       'test-perf',
  'server-with-route-subset.mjs':'test-perf',
  'server-leak-bisect.mjs':      'test-perf',
  'clinic-heap.sh':              'test-perf',

  // Part VI — Bash (existing + new deep-dive scripts)
  'bash-l1-halve.sh':            'bash',
  'bash-l2-mapfile.sh':          'bash',
  'bash-l3-patterns.sh':         'bash',
  'bash-l4-resumable.sh':        'bash',
  'bash-bisect.sh':              'bash',
  'use-bash-bisect.sh':          'bash',
  'bash-parallel-bisect.sh':     'bash',
  'bash-flag-bisect.sh':         'bash',
  // Bash deep-dive (added Part VI pages 3-8)
  'bash-version-guard.sh':       'bash',
  'bash5-memo.sh':               'bash',
  'bash5-nameref.sh':            'bash',
  'bash5-mapfile.sh':            'bash',
  'bash5-epoch.sh':              'bash',
  'bash5-wait-n.sh':             'bash',
  'bash5-expansion-ops.sh':      'bash',
  'bash5-procsub.sh':            'bash',
  'bash5-rematch.sh':            'bash',
  'bash5-srandom.sh':            'bash',
  'bash5-coproc.sh':             'bash',
  'bash5-starter.sh':            'bash',
  'recommended-flags.sh':        'bash',
  'pipestatus.sh':               'bash',
  'err-trap.sh':                 'bash',
  'trap-chain.sh':               'bash',
  'subshell-rc.sh':              'bash',
  'error-handling-template.sh':  'bash',
  'job-basics.sh':               'bash',
  'alive-check.sh':              'bash',
  'process-groups.sh':           'bash',
  'timeout-handling.sh':         'bash',
  'signal-race.sh':              'bash',
  'forkbomb-protect.sh':         'bash',
  'zombie-reaping.sh':           'bash',
  'sigchld.sh':                  'bash',
  'parallel-bisect.sh':          'bash',
  'flock-bisect.sh':             'bash',
  'gnu-parallel-bisect.sh':      'bash',
  'winner-takes-all.sh':         'bash',
  'worker-isolation.sh':         'bash',
  'xtracefd.sh':                 'bash',
  'custom-ps4.sh':               'bash',
  'trap-debug.sh':               'bash',
  'conditional-trace.sh':        'bash',
  'predicate.bats':              'bash',
  'instrumented-predicate.sh':   'bash',
  'profile-bash.sh':             'bash',
  'benchmark-predicate.sh':      'bash',

  // Part VII — Zsh (existing + new deep-dive scripts)
  'zsh-l1-halve.zsh':            'zsh',
  'zsh-l2-qualifiers.zsh':       'zsh',
  'zsh-l3-clean.zsh':            'zsh',
  'zsh-bisect.zsh':              'zsh',
  'zsh-autosave.zsh':            'zsh',
  'zsh-zpty-bisect.zsh':         'zsh',
  'zsh-process-sub.zsh':         'zsh',
  // Zsh deep-dive (added Part VII pages 3-7)
  'repl-bisect.zsh':             'zsh',
  'zsh-glob-setup.zsh':          'zsh',
  'hybrid-shell.sh':             'zsh',
  'zsh-glob-recipes.zsh':        'zsh',
  'zsh-order-qualifiers.zsh':    'zsh',
  'zsh-flags-bisection.zsh':     'zsh',
  'zsh-flags-composed.zsh':      'zsh',
  'zsh-datetime.zsh':            'zsh',
  'zsh-system.zsh':              'zsh',
  'zsh-tcp.zsh':                 'zsh',
  'zsh-zselect.zsh':             'zsh',
  'zsh-parameter.zsh':           'zsh',
  'zsh-files.zsh':               'zsh',
  'zsh-starter-modules.zsh':     'zsh',
  'zsh-async-bisect.zsh':        'zsh',
  'zsh-coproc-pool.zsh':         'zsh',

  // Part VIII — CI / real world
  'local-nightly-bisect.sh':     'ci',
  'bisect-fleet.sh':             'ci',
  'confirm-fleet-culprit.sh':    'ci',
  'bisect-csv.sh':               'ci',
  'flag-ddmin.mjs':              'ci',
  'bisect-env.sh':               'ci',
  'verify-culprit.sh':           'ci',

  // Part IX — Advanced & theoretical
  'channel-capacity.md':         'advanced',
  'bisect-cost.mjs':             'advanced',
  'bayesian-bisect.mjs':         'advanced',
  'hdd.mjs':                     'advanced',
  'llvm-opt-bisect.sh':          'advanced',
  'cargo-bisect-rustc-driver.sh':'advanced',
  'rr-bisect.sh':                'advanced',
  'rr-reverse-bisect.sh':        'advanced',
  'chaos-bisect.sh':             'advanced',
  'checkpoint-eval-predicate.mjs':'advanced',
  'model-checkpoint-bisect.mjs': 'advanced',
  'data-shard-bisect.sh':        'advanced',
  'supply-chain-bisect-npm.sh':  'advanced',
  'supply-chain-bisect-pip.sh':  'advanced',
  'check-side-effects.mjs':      'advanced',
  'trace-span-bisect.mjs':       'advanced',
  'session-replay-bisect.sh':    'advanced',

  // Part X — Modern systems bisectors
  'k8s-bisect-predicate.sh':     'modern',
  'k8s-bisect-run.sh':           'modern',
  'helm-bisect-predicate.sh':    'modern',
  'kustomize-bisect-predicate.sh':'modern',
  'terraform-bisect-plan.sh':    'modern',
  'terraform-state-bisect.sh':   'modern',
  'flag-bisect.mjs':             'modern',
  'docker-stage-probe.sh':       'modern',
  'docker-size-bisect.sh':       'modern',
  'docker-crash-bisect.sh':      'modern',
  'dive-inspect.sh':             'modern',
  'base-image-bisect.sh':        'modern',
  'openapi-diff-bisect.sh':      'modern',
  'graphql-bisect.sh':           'modern',
  'contract-test-predicate.mjs': 'modern',
  'frontend-bisect-predicate.mjs':'modern',

  // Part XI — Principal-engineering operational artifacts
  'incident-timeline-bisect.sh': 'principal',
  'postmortem-template.md':      'principal',
  'bisectability-scorecard.md':  'principal',

  // Part XII — Frameworks, data, and future
  'bisection-cost-model.mjs':    'frameworks',
  'history-quality-index.sh':    'frameworks',
  'game-day-setup.sh':           'frameworks',
  'game-day-predicates.sh':      'frameworks',
  'game-day-retro.md':           'frameworks',
  'anti-pattern-checklist.md':   'frameworks',

  // Per-ecosystem bisection snippets (Part XII)
  'bisect-node.sh':              'ecosystems',
  'bisect-python-uv.sh':         'ecosystems',
  'bisect-python-pip.sh':        'ecosystems',
  'bisect-go.sh':                'ecosystems',
  'bisect-rust.sh':              'ecosystems',
  'bisect-java-gradle.sh':       'ecosystems',
  'bisect-ruby.sh':              'ecosystems',
  'bisect-php.sh':               'ecosystems',
  'bisect-dotnet.sh':            'ecosystems',

  // Part XIII — The Craft of Writing Predicates
  'predicate-skeleton.sh':       'craft',
  'worksheet-example.md':        'craft',
  'iter-5-final.sh':             'craft',
  'pattern-type-check.sh':       'craft',
  'pattern-smoke.sh':            'craft',
  'pattern-assert.mjs':          'craft',
  'pattern-perf.sh':             'craft',
  'pattern-golden.sh':           'craft',
  'composed-predicate.sh':       'craft',
  'predicate-audit.md':          'craft',
  'instrument-predicate.sh':     'craft',
  'meta-predicate.sh':           'craft',
  'ex-1-solution.mjs':           'craft',
  'ex-2-solution.sh':            'craft',
  'ex-3-solution.mjs':           'craft',
  'ex-4-solution.sh':            'craft',
  'ex-5-solution.mjs':           'craft',
  'shareable-predicate.sh':      'craft',
  'predicate-review.md':         'craft',

  // Part XIV — Companion tools, AI guide, references
  'pickaxe-S.sh':                'companion',
  'pickaxe-G.sh':                'companion',
  'log-L.sh':                    'companion',
  'pickaxe-then-bisect.sh':      'companion',
  'blame-reverse.sh':            'companion',
  'when-merged.sh':              'companion',
  'ai-verify-ritual.sh':         'companion',
  'prompt-worksheet.md':         'companion',
  'prompt-audit.md':             'companion',
  'prompt-which-tool.md':        'companion',
};

// Titles whose target path is special (lives outside scripts/).
const SPECIAL_PATH = {
  '.github/workflows/auto-bisect.yml': '.github/workflows/auto-bisect.yml',
};

// Pedagogical / illustrative code blocks in the curriculum that should NOT be
// extracted to disk. These exist to teach patterns inside the curriculum HTML,
// not as artifacts. The real package.json is committed at the repo root.
const SKIP_NAMES = new Set([
  'package.json',
  'build-pipeline.txt',
  'reserved-scripts.txt',
  'serial.json',
  'parallel.json',
  'prepost.json',
  'forward-args.json',
  'npm-env.json',
  'setup-githooks.sh',
  'setup-husky.sh',
  '.github/workflows/ci.yml',
  'onboarding-60s.sh',
  'workspaces.json',
  'cheatsheet.sh',
  // Part 0 — beginner pedagogical examples (none extract)
  'what-terminal-looks-like.txt',
  'first-session.sh',
  'run-a-script.sh',
  'git-history.txt',
  'git-essentials.sh',
  'reading-bash.sh',
  'reading-js.mjs',
  'reading-json.json',
  'reading-yaml.yml',
  'binary-search-game.txt',
  'binary-search-shrinking.txt',
  'example-stack-trace.txt',
  'print-debug-example.mjs',
  'which-tool.txt',
  // Part X / XI — illustrative diagrams and templates that aren't tools
  'instrumented-Dockerfile',
  'signed-change.tf',
  'observability-vs-bisection.txt',
  'bug-cost-math.txt',
  'decision-matrix.txt',
  'incident-update.md',
  'pnpm-workspace.yaml',
  'npmrc.ini',
  'day-9-npmrc.ini',
  'day-1-npmrc.ini',
  // Part XII — illustrative blocks not extracted
  'cost-model.txt',
  'worked-examples.txt',
  'phs-example-good.sh',
  'phs-example-bad.sh',

  // Part VI/VII — illustrative comparison snippets (not standalone tools)
  'set-e-traps.sh',
  'set-x-basics.sh',
  'bashdb-session.sh',
  'shellcheck.sh',
  'perf-date.sh',
  'perf-arith.sh',
  'perf-regex.sh',
  'perf-printf.sh',
  'perf-awk.sh',
  'perf-lastpipe.sh',
  'perf-memoize.sh',
  'bash-vs-zsh-pipeline.txt',
  'zsh-async-install.sh',
  // Conceptual zsh snippets with pseudo-code placeholders
  'zsh-coproc-pool.zsh',
  'zsh-zselect.zsh',
  'zsh-flags-composed.zsh',

  // Part XIII — illustrative iteration steps and anti-patterns (not extracted)
  'naive-vs-correct.sh',
  'iter-1-naive.sh',
  'iter-2-setup-cleanup.sh',
  'iter-3-loop.sh',
  'iter-4-signal.sh',
  'anti-1.sh', 'anti-2.sh', 'anti-3.sh', 'anti-4.sh', 'anti-5.sh',
  'anti-6.sh', 'anti-7.sh', 'anti-8.sh', 'anti-9.sh', 'anti-10.sh',
  'ci-predicate-check.yml',

  // Part XIV — illustrative diagrams (not extracted)
  'when-which-tool.txt',
  'ai-bisect-workflow.txt',
]);
// Anything matching one of these patterns is also illustrative-only.
const SKIP_PATTERNS = [
  /^day-\d+/,        // day-0.sh, day-15-final.json, etc.
];
function shouldSkip(title) {
  if (SKIP_NAMES.has(title)) return true;
  return SKIP_PATTERNS.some(re => re.test(title));
}

function decodeEntities(s) {
  return s
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&');
}

// Match every <pre class="code" data-lang="X" data-title="Y">…</pre>.
// We use a non-greedy body capture. Source content may contain raw `<` from
// shell placeholders; those don't appear as element-like sequences (`<bad>`
// is fine because the regex only cares about `</pre>`).
const re = /<pre class="code" data-lang="([^"]+)" data-title="([^"]+)">([\s\S]*?)<\/pre>/g;

const written = [];
let m;
while ((m = re.exec(html)) !== null) {
  const [, lang, title, rawBody] = m;
  const body = decodeEntities(rawBody).replace(/^\n/, '').replace(/\s+$/, '') + '\n';

  if (shouldSkip(title)) continue;

  let target;
  if (SPECIAL_PATH[title]) {
    target = SPECIAL_PATH[title];
  } else {
    const category = CATEGORY[title];
    if (!category) {
      console.error(`No category for: ${title} — skipping`);
      continue;
    }
    target = path.join('scripts', category, title);
  }

  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, body);

  // Make shell scripts executable.
  if (/\.(sh|zsh|mjs)$/.test(target)) {
    fs.chmodSync(target, 0o755);
  }

  written.push(target);
}

console.log(`Wrote ${written.length} files:`);
for (const f of written) console.log('  ' + f);
