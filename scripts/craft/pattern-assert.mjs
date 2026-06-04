#!/usr/bin/env node
// pattern-assert.mjs
// Behavioral predicate — asserts function X returns expected value for input Y.
import { spawnSync } from 'child_process';

// Setup
if (spawnSync('pnpm', ['install', '--frozen-lockfile', '--prefer-offline'], { stdio: 'ignore' }).status !== 0) process.exit(125);
if (spawnSync('pnpm', ['build'], { stdio: 'ignore' }).status !== 0) process.exit(125);

// Exercise + Observe
const { calculateTax } = await import('./dist/tax.mjs');
const result = calculateTax({ items: [{ price: 100 }], region: 'US-CA' });

// Exit
const ok = result.total === 108.5 && result.tax === 8.5;
process.exit(ok ? 0 : 1);
