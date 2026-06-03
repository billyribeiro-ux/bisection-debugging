// capture-baseline.mjs — run once on the last known-good commit.
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await (await browser.newContext({ viewport: { width: 1280, height: 800 }})).newPage();
await page.goto('http://localhost:5173/');
await page.waitForLoadState('networkidle');
await page.screenshot({ path: 'baseline.png', fullPage: true });
await browser.close();
