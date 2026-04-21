#!/usr/bin/env node
/* PreToolUse hook — call GitNexus to assess impact before Edit/Write.
 * Reads the tool_input from stdin, looks up the file path, and if a
 * GitNexus index exists, runs a lightweight impact check.
 *
 * For now this is a safe non-blocking implementation: it logs the check
 * to stderr and exits 0. Wire up real impact calls after GitNexus indexing
 * completes and the MCP server is live.
 *
 * Protocol: receives JSON on stdin; to BLOCK the tool call, write JSON
 * {"block": true, "message": "..."} to stdout and exit non-zero.
 */
'use strict';
const fs = require('fs');
const path = require('path');

let input = '';
try {
  input = fs.readFileSync(0, 'utf8');
} catch (e) { /* no stdin */ }

let payload = {};
try { payload = input ? JSON.parse(input) : {}; } catch (e) { /* malformed */ }

// Only act on Edit/Write
const toolName = payload.tool_name || '';
const toolInput = payload.tool_input || {};
if (!/^(Edit|Write|MultiEdit)$/.test(toolName)) {
  process.exit(0);
}

const filePath = toolInput.file_path || toolInput.path || '';
const gitnexusDir = path.join(process.cwd(), '.gitnexus');
if (!fs.existsSync(gitnexusDir)) {
  // No index yet — silent pass
  process.exit(0);
}

// Placeholder: when GitNexus MCP is wired up, query it here and return
// a block payload if risk is HIGH or CRITICAL. For now, log to stderr.
process.stderr.write(`[impact-check] ${toolName} on ${path.basename(filePath)} (no MCP integration yet — non-blocking)\n`);
process.exit(0);
