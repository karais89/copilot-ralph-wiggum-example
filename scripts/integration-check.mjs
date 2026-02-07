#!/usr/bin/env node
import { exec } from 'child_process';
import { promisify } from 'util';

const execP = promisify(exec);

async function run(cmd) {
  const { stdout, stderr } = await execP(cmd, { maxBuffer: 10 * 1024 * 1024 });
  if (stderr && stderr.trim()) {
    // some tools write to stderr even on success — keep but show
    console.error(stderr);
  }
  return stdout;
}

function validateStats(obj) {
  const required = ['total', 'completed', 'pending', 'overdue', 'completionRate', 'generated_at'];
  for (const k of required) {
    if (!(k in obj)) {
      throw new Error(`Missing required key: ${k}`);
    }
  }
  if (typeof obj.total !== 'number' || obj.total < 0) throw new Error('Invalid total');
  if (typeof obj.completed !== 'number' || obj.completed < 0) throw new Error('Invalid completed');
  if (typeof obj.pending !== 'number' || obj.pending < 0) throw new Error('Invalid pending');
  if (typeof obj.overdue !== 'number' || obj.overdue < 0) throw new Error('Invalid overdue');
  if (typeof obj.completionRate !== 'number' || obj.completionRate < 0 || obj.completionRate > 100) throw new Error('Invalid completionRate');
  if (typeof obj.generated_at !== 'string' || Number.isNaN(Date.parse(obj.generated_at))) throw new Error('Invalid generated_at');
}

async function main() {
  try {
    console.log('Building project...');
    await run('npm run build');

    console.log('Running stats (JSON) output...');
    const out = await run('node dist/index.js stats -j');
    let parsed;
    try {
      parsed = JSON.parse(out);
    } catch (err) {
      console.error('Output was not valid JSON:');
      console.error(out);
      throw err;
    }

    validateStats(parsed);
    console.log('Integration check passed: stats JSON is valid.');
    process.exit(0);
  } catch (err) {
    console.error('Integration check failed:', err instanceof Error ? err.message : String(err));
    process.exit(2);
  }
}

if (process.argv[1].endsWith('integration-check.mjs')) {
  main();
}
