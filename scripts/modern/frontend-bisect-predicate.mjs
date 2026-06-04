#!/usr/bin/env node
// Boots the frontend (current commit), points it at the production API, runs
// Playwright through the broken user flow. If the flow fails, this commit
// is incompatible with the current API.
import { spawnSync } from 'child_process';
const r = spawnSync('pnpm', ['dlx', 'playwright', 'test', 'e2e/checkout.spec.ts',
  '--', '--config=playwright.production-api.config.ts'], { stdio: 'inherit' });
process.exit(r.status);
