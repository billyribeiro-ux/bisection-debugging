#!/usr/bin/env node
// ex-3-solution.mjs — Exercise 3 model.
import { spawnSync } from 'child_process';

if (spawnSync('pnpm', ['install', '--frozen-lockfile', '--prefer-offline'], { stdio: 'ignore' }).status !== 0) process.exit(125);

let getUserById;
try { ({ getUserById } = await import('./src/users.mjs')); } catch { process.exit(125); }

// The bug only appears in a specific call sequence — encode it.
const u2 = await getUserById(2);
const u1 = await getUserById(1);    // should return user 1, not user 2

if (!u1 || !u2)                          process.exit(125);  // missing fixture data
if (u1.id !== 1 || u2.id !== 2)          process.exit(1);    // BUG present
process.exit(0);
