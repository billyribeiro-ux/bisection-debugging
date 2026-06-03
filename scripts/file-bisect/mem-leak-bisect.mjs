#!/usr/bin/env node
// mem-leak-bisect.mjs
// Binary-search across a set of components to find the one that leaks memory.
//
// HOW IT WORKS:
//   1. Boot a Playwright Chromium instance, navigate to a harness URL.
//   2. The harness exposes a `mount(name)` and `unmount()` function via window.
//   3. For each suspect subset: mount every component in sequence, unmount,
//      force GC via CDP, take a heap snapshot, record retained size.
//   4. Compare against baseline. Above threshold = "leak in this subset".
//   5. Recurse.
//
// USAGE:
//   node mem-leak-bisect.mjs http://localhost:5173/__leak-harness "Button,Card,Chart,Modal,..."
//
// HARNESS REQUIREMENT (drop into your SvelteKit dev server):
//   src/routes/__leak-harness/+page.svelte:
//   <script>
//     import { mount, unmount } from 'svelte';
//     const components = import.meta.glob('/src/lib/components/**/*.svelte', { eager: true });
//     let current = null;
//     window.__mount = async (name) => {
//       const mod = Object.entries(components).find(([k]) => k.endsWith('/' + name + '.svelte'))?.[1];
//       if (!mod) throw new Error('Unknown component: ' + name);
//       current = mount(mod.default, { target: document.getElementById('host') });
//     };
//     window.__unmount = async () => { if (current) { await unmount(current); current = null; } };
//   </script>
//   <div id="host"></div>

import { chromium } from 'playwright';

const HARNESS_URL = process.argv[2];
const SUSPECTS   = (process.argv[3] || '').split(',').filter(Boolean);
const LEAK_BYTES = Number(process.env.LEAK_BYTES_THRESHOLD || 512 * 1024); // 512 KB

if (!HARNESS_URL || !SUSPECTS.length) {
  console.error('usage: mem-leak-bisect.mjs <harness-url> <comp1,comp2,...>');
  process.exit(2);
}

const browser = await chromium.launch();
const ctx = await browser.newContext();
const page = await ctx.newPage();
const cdp = await ctx.newCDPSession(page);

await page.goto(HARNESS_URL, { waitUntil: 'networkidle' });
await cdp.send('HeapProfiler.enable');

async function forceGC() {
  await cdp.send('HeapProfiler.collectGarbage');
  await page.evaluate(() => new Promise(r => setTimeout(r, 100)));
  await cdp.send('HeapProfiler.collectGarbage');
}

async function retainedHeap() {
  await forceGC();
  const { usedSize } = await cdp.send('Runtime.getHeapUsage');
  return usedSize;
}

async function mountCycle(names) {
  for (const name of names) {
    await page.evaluate((n) => window.__mount(n), name);
    await page.evaluate(() => new Promise(r => setTimeout(r, 50)));
    await page.evaluate(() => window.__unmount());
  }
}

async function leakSize(subset) {
  const baseline = await retainedHeap();
  await mountCycle(subset);
  const after = await retainedHeap();
  return after - baseline;
}

// Stabilize the page; do a warm-up cycle that we discard.
console.log('Warming up…');
await mountCycle(SUSPECTS.slice(0, Math.min(3, SUSPECTS.length)));
await forceGC();

console.log(`Bisecting ${SUSPECTS.length} components, leak threshold = ${LEAK_BYTES} bytes`);

let lo = 0, hi = SUSPECTS.length - 1, round = 0;
while (lo < hi) {
  round++;
  const mid = (lo + hi) >> 1;
  const subset = SUSPECTS.slice(lo, mid + 1);
  const leaked = await leakSize(subset);
  const verdict = leaked > LEAK_BYTES ? 'LEAK' : 'clean';
  console.log(`round ${round}: subset [${lo}..${mid}] (${subset.length} comps) → ${leaked} bytes ${verdict}`);

  if (leaked > LEAK_BYTES) {
    hi = mid;
  } else {
    lo = mid + 1;
  }
}

console.log('\n═══════════════════════════════════════════');
console.log(`Leaking component: ${SUSPECTS[lo]}`);
console.log('═══════════════════════════════════════════');

await browser.close();
