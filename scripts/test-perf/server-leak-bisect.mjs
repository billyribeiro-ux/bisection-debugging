#!/usr/bin/env node
// server-leak-bisect.mjs
// Binary-search across routes to find the one that leaks memory under load.
//
// USAGE:
//   node server-leak-bisect.mjs '/api/users,/api/products,/api/orders,/api/auth,...'
//
import { spawn } from 'child_process';
import { setTimeout as sleep } from 'timers/promises';

const ROUTES = process.argv[2].split(',').filter(Boolean);
const LEAK_MB_PER_MIN = Number(process.env.LEAK_MB_PER_MIN || 25);

async function runOne(subset) {
  return new Promise((resolve, reject) => {
    const env = { ...process.env, ROUTES: subset.join(',') };
    const server = spawn('node', ['server-with-route-subset.mjs'], { env, stdio: 'pipe' });
    server.stderr.on('data', d => process.stderr.write(d));

    let samples = [];
    let load = null;

    (async () => {
      await sleep(1000); // let server boot
      load = spawn('autocannon', ['-c', '50', '-d', '60', '-R', '500', 'http://localhost:3000'],
                   { stdio: 'ignore' });

      // Sample heap every 5s for 60s via /__health-extended? Simpler: poll RSS via /proc.
      for (let t = 0; t < 60; t += 5) {
        await sleep(5000);
        try {
          const status = await import('fs').then(fs => fs.promises.readFile(`/proc/${server.pid}/status`, 'utf8'));
          const m = status.match(/VmRSS:\s+(\d+)/);
          if (m) samples.push(Number(m[1]) / 1024); // MB
        } catch {}
      }

      try { load.kill('SIGTERM'); } catch {}
      try { server.kill('SIGTERM'); } catch {}

      if (samples.length < 6) return reject(new Error('Not enough samples'));
      const slope = (samples.at(-1) - samples[0]) / (samples.length * 5 / 60); // MB / min
      resolve(slope);
    })().catch(reject);
  });
}

console.log(`Bisecting ${ROUTES.length} routes; leak threshold ${LEAK_MB_PER_MIN} MB/min`);

let lo = 0, hi = ROUTES.length - 1;
while (lo < hi) {
  const mid = (lo + hi) >> 1;
  const subset = ROUTES.slice(lo, mid + 1);
  console.log(`subset [${lo}..${mid}]: ${subset.join(',')}`);
  const slope = await runOne(subset);
  console.log(`  slope: ${slope.toFixed(1)} MB/min`);
  if (slope > LEAK_MB_PER_MIN) hi = mid; else lo = mid + 1;
}
console.log(`\nLeaking route: ${ROUTES[lo]}`);
