#!/usr/bin/env node
// checkpoint-eval-predicate.mjs
// Evaluate a checkpoint on a held-out eval set; exit 0 if score ≥ threshold,
// 1 if below. Designed to be the predicate for a bisection driver.
//
// USAGE:
//   CHECKPOINT=ckpts/step-12000 THRESHOLD=0.72 node checkpoint-eval-predicate.mjs
//
import { spawnSync } from 'child_process';

const ckpt = process.env.CHECKPOINT;
const threshold = Number(process.env.THRESHOLD || 0.7);
const eval_suite = process.env.EVAL || 'my_regression_suite';
const max_samples = Number(process.env.MAX_SAMPLES || 500);

if (!ckpt) { console.error('Set CHECKPOINT'); process.exit(125); }

// Use a deterministic eval — fixed seed (the --seed flag below), pinned
// network state. Note: --tasks takes a registered TASK NAME; to eval a
// custom .jsonl, register it first with a small task YAML
// (lm-eval docs: "new task guide") and pass that task's name here.
const env = { ...process.env, TRANSFORMERS_OFFLINE: '1', HF_HUB_OFFLINE: '1' };

const r = spawnSync('python', [
  '-m', 'lm_eval',
  '--model', 'hf',
  '--model_args', `pretrained=${ckpt},dtype=bfloat16,device_map=auto`,
  '--tasks', eval_suite,
  '--num_fewshot', '0',
  '--limit', String(max_samples),
  '--seed', '42',
  '--output_path', '/tmp/eval.json',
], { stdio: 'inherit', env });

if (r.status !== 0) { console.error('Eval crashed'); process.exit(125); }

const data = JSON.parse(fs.readFileSync('/tmp/eval.json', 'utf8'));
const score = data.results[Object.keys(data.results)[0]].acc;
console.log(`checkpoint=${ckpt}  score=${score.toFixed(4)}  threshold=${threshold}`);

process.exit(score >= threshold ? 0 : 1);
