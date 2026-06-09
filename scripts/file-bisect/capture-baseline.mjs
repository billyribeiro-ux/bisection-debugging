// capture-baseline.mjs — run once on the last known-good commit.
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await (await browser.newContext({ viewport: { width: 1280, height: 800 }})).newPage();
await page.goto('http://localhost:5173/');
await page.waitForLoadState('networkidle');
// Fixed-viewport screenshot, NOT fullPage: page height changes between
// commits (that's often the regression itself), and pixelmatch throws on
// images whose dimensions differ.
await page.screenshot({ path: 'baseline.png' });
await browser.close();
