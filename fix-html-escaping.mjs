#!/usr/bin/env node
// fix-html-escaping.mjs
// Escapes `<`, `>`, `&` inside every <pre class="code" …>…</pre> block in
// index.html so Monaco renders strings like `<bad-ref>` literally instead of
// the HTML parser interpreting them as unknown elements.
//
// Idempotent: skips blocks that already contain `&lt;` or `&gt;`.

import fs from 'fs';

const src = fs.readFileSync('index.html', 'utf8');

const re = /(<pre class="code" data-lang="[^"]+" data-title="[^"]+">)([\s\S]*?)(<\/pre>)/g;

let blocks = 0;
let escaped = 0;
const out = src.replace(re, (full, open, body, close) => {
  blocks++;
  // Skip if already escaped (presence of an HTML entity is the signal).
  if (/&lt;|&gt;|&amp;[a-z]+;/.test(body)) return full;
  escaped++;
  const fixed = body
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
  return open + fixed + close;
});

fs.writeFileSync('index.html', out);
console.log(`Processed ${blocks} code blocks; escaped ${escaped}, skipped ${blocks - escaped}.`);
