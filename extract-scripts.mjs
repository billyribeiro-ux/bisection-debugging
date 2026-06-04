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

  // Part VI — Bash
  'bash-l1-halve.sh':            'bash',
  'bash-l2-mapfile.sh':          'bash',
  'bash-l3-patterns.sh':         'bash',
  'bash-l4-resumable.sh':        'bash',
  'bash-bisect.sh':              'bash',
  'use-bash-bisect.sh':          'bash',
  'bash-parallel-bisect.sh':     'bash',
  'bash-flag-bisect.sh':         'bash',

  // Part VII — Zsh
  'zsh-l1-halve.zsh':            'zsh',
  'zsh-l2-qualifiers.zsh':       'zsh',
  'zsh-l3-clean.zsh':            'zsh',
  'zsh-bisect.zsh':              'zsh',
  'zsh-autosave.zsh':            'zsh',
  'zsh-zpty-bisect.zsh':         'zsh',
  'zsh-process-sub.zsh':         'zsh',

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
};

// Titles whose target path is special (lives outside scripts/).
const SPECIAL_PATH = {
  '.github/workflows/auto-bisect.yml': '.github/workflows/auto-bisect.yml',
};

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
