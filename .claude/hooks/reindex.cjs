#!/usr/bin/env node
/* PostToolUse hook — after git commit/merge, refresh GitNexus index so the
 * next impact check sees current code structure. Non-blocking.
 *
 * Only fires when a Bash tool call contains `git commit` or `git merge`.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

let input = '';
try { input = fs.readFileSync(0, 'utf8'); } catch (e) { /* no stdin */ }

let payload = {};
try { payload = input ? JSON.parse(input) : {}; } catch (e) { /* malformed */ }

const toolName = payload.tool_name || '';
if (toolName !== 'Bash') {
  process.exit(0);
}

const cmd = (payload.tool_input && payload.tool_input.command) || '';
if (!/git\s+(commit|merge|pull|rebase)/.test(cmd)) {
  process.exit(0);
}

const gitnexusDir = path.join(process.cwd(), '.gitnexus');
if (!fs.existsSync(gitnexusDir)) {
  process.exit(0);
}

// Fire-and-forget reindex. Do NOT block CC.
try {
  const child = cp.spawn(
    process.platform === 'win32' ? 'powershell.exe' : 'sh',
    process.platform === 'win32'
      ? ['-Command', 'npx --yes gitnexus analyze --incremental']
      : ['-c', 'npx --yes gitnexus analyze --incremental'],
    { detached: true, stdio: 'ignore', cwd: process.cwd() }
  );
  child.unref();
  process.stderr.write('[reindex] spawned GitNexus incremental analyze\n');
} catch (e) {
  process.stderr.write('[reindex] skipped: ' + e.message + '\n');
}
process.exit(0);
