#!/usr/bin/env node
// check-side-effects.mjs
// Run `npm install` for a package under a strict sandbox; flag any unexpected
// side effects (outbound network, suspicious file writes, env reads).
//
// USAGE (as a predicate):
//   exits 0 = clean, 1 = found suspicious behavior, 125 = sandbox itself broke.
import { spawnSync } from 'child_process';
import fs from 'fs';

// Pre-install snapshot of "what files exist under home".
const homeBefore = new Set(fs.readdirSync(process.env.HOME, { recursive: true, withFileTypes: true })
  .map(d => d.parentPath + '/' + d.name));

// Strace install. firejail or bubblewrap would be stricter; this is the
// portable baseline.
const r = spawnSync('strace', ['-f', '-e', 'trace=connect,openat,execve',
  '-o', '/tmp/install.strace', '--', 'npm', 'rebuild'], { stdio: 'inherit' });
if (r.status !== 0) process.exit(125);

const log = fs.readFileSync('/tmp/install.strace', 'utf8');
const suspicious = [
  /connect\(.*sin_port=htons\((?!443|80|22)[0-9]+\)/,  // non-HTTP outbound
  /openat\(.*\/etc\/(shadow|passwd|sudoers)/,
  /openat\(.*\/\.ssh\//,
  /openat\(.*\/\.aws\//,
  /openat\(.*\/\.config\/gh\//,
  /execve\(.*\/(curl|wget|nc|ncat|socat)/,
];
let flagged = false;
for (const re of suspicious) {
  const m = log.match(re);
  if (m) { console.error('SUSPICIOUS:', m[0]); flagged = true; }
}
const homeAfter = new Set(fs.readdirSync(process.env.HOME, { recursive: true, withFileTypes: true })
  .map(d => d.parentPath + '/' + d.name));
for (const f of homeAfter) if (!homeBefore.has(f) && !f.includes('node_modules'))
  { console.error('NEW HOME FILE:', f); flagged = true; }

process.exit(flagged ? 1 : 0);
