#!/usr/bin/env node
// pixel-diff-predicate.mjs — exit 0 if current page matches baseline, 1 if not.
// Used both standalone and inside a bisection loop.
import { chromium } from 'playwright';
import pixelmatch from 'pixelmatch';
import { PNG } from 'pngjs';
import fs from 'fs';

const URL = process.env.URL || 'http://localhost:5173/';
const TOL_PIXELS = Number(process.env.TOL_PIXELS || 200);

const browser = await chromium.launch();
const page = await (await browser.newContext({ viewport: { width: 1280, height: 800 }})).newPage();
await page.goto(URL); await page.waitForLoadState('networkidle');
const current = await page.screenshot({ fullPage: true });
await browser.close();

const a = PNG.sync.read(fs.readFileSync('baseline.png'));
const b = PNG.sync.read(current);
const diff = new PNG({ width: a.width, height: a.height });
const changed = pixelmatch(a.data, b.data, diff.data, a.width, a.height, { threshold: 0.1 });

fs.writeFileSync('diff.png', PNG.sync.write(diff));
console.log(`changed pixels: ${changed} (tolerance: ${TOL_PIXELS})`);
process.exit(changed > TOL_PIXELS ? 1 : 0);
