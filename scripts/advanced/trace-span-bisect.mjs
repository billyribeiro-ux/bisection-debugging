#!/usr/bin/env node
// trace-span-bisect.mjs
// Walks an OTel trace JSON, identifies the longest hot-path subtree at each
// level, and reports the leaf span where the time is actually going.
//
// USAGE:
//   node trace-span-bisect.mjs trace.json
//
import fs from 'fs';

const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

// Flatten OTel resource→scope→span structure into a single list.
const all = [];
for (const r of (data.resourceSpans || data.data || [])) {
  for (const ss of (r.scopeSpans || r.instrumentationLibrarySpans || [])) {
    for (const s of (ss.spans || [])) all.push(s);
  }
}

// Build parent → children map.
const byId = new Map(all.map(s => [s.spanId, s]));
const kids = new Map();
for (const s of all) {
  if (!s.parentSpanId) continue;
  if (!kids.has(s.parentSpanId)) kids.set(s.parentSpanId, []);
  kids.get(s.parentSpanId).push(s);
}

function durMs(s) {
  // OTel start/end are nanosecond strings.
  const start = BigInt(s.startTimeUnixNano);
  const end   = BigInt(s.endTimeUnixNano);
  return Number(end - start) / 1e6;
}

function pretty(s, depth) {
  const pad = '  '.repeat(depth);
  const name = s.name + (s.attributes?.find?.(a => a.key === 'http.target')?.value?.stringValue ?? '');
  return `${pad}${name.padEnd(60 - depth*2)} ${durMs(s).toFixed(1).padStart(8)} ms`;
}

// Find root(s).
const roots = all.filter(s => !s.parentSpanId || !byId.has(s.parentSpanId));
console.log('=== Trace hot path (longest-child descent) ===');
for (const root of roots) {
  let cur = root, depth = 0;
  while (cur) {
    console.log(pretty(cur, depth));
    const cs = (kids.get(cur.spanId) || []).slice().sort((a,b) => durMs(b) - durMs(a));
    if (!cs.length) break;
    const total = cs.reduce((a, s) => a + durMs(s), 0);
    const longest = cs[0];
    // If the longest child accounts for ≥ 50% of the parent's duration, it's
    // worth descending. Otherwise the time is spread across siblings.
    if (durMs(longest) / durMs(cur) < 0.5) {
      console.log('  '.repeat(depth + 1) + `[time distributed across ${cs.length} children, sum=${total.toFixed(1)}ms]`);
      break;
    }
    cur = longest;
    depth++;
  }
  console.log();
}
