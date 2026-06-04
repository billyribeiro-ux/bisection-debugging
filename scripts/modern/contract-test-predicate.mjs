#!/usr/bin/env node
// contract-test-predicate.mjs
// Boots the server, runs a small set of contract assertions, exits 0/1.
import { spawn, spawnSync } from 'child_process';

const server = spawn('node', ['dist/server.js'], { stdio: 'inherit' });
await new Promise(r => setTimeout(r, 1500));

try {
  // Replace with your contract assertions.
  const cases = [
    ['GET', '/users/1',     { ok: r => r.id === 1 && r.email } ],
    ['GET', '/orders/42',   { ok: r => r.total > 0 && r.items.length } ],
    ['POST','/checkout',    { ok: r => r.transactionId } ],
  ];
  for (const [method, path, { ok }] of cases) {
    const res = await fetch('http://localhost:3000' + path, { method });
    if (!res.ok) process.exit(1);
    const body = await res.json();
    if (!ok(body)) process.exit(1);
  }
  process.exit(0);
} finally {
  server.kill();
}
