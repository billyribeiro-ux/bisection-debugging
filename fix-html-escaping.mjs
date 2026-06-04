#!/usr/bin/env node
// fix-html-escaping.mjs
// Escapes `<`, `>`, `&` inside every <pre class="code" …>…</pre> block in
// index.html so Monaco renders strings like `<bad-ref>` literally instead of
// the HTML parser interpreting them as unknown elements.
//
// IDEMPOTENT: decodes existing entities first, then re-encodes. So a block
// that was already correctly escaped on a previous run stays the same.

import fs from 'fs';

const src = fs.readFileSync('index.html', 'utf8');

const re = /(<pre class="code" data-lang="[^"]+" data-title="[^"]+">)([\s\S]*?)(<\/pre>)/g;

function decode(s) {
  // Decode in this order: &amp; LAST so we don't double-process e.g. `&amp;lt;`.
  return s
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&');
}
function encode(s) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

let blocks = 0;
const out = src.replace(re, (full, open, body, close) => {
  blocks++;
  // Decode first (undo any prior pass — even a double-escaped one needs two passes)
  // then re-encode cleanly. Apply decode twice to handle blocks that were
  // already double-escaped by an earlier buggy run (e.g. `&amp;amp;` → `&amp;` → `&`).
  let raw = decode(decode(body));
  return open + encode(raw) + close;
});

fs.writeFileSync('index.html', out);
console.log(`Re-encoded ${blocks} code blocks (idempotent: decode×2 → encode).`);
