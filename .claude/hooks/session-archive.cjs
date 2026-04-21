#!/usr/bin/env node
/* SessionEnd hook — archive the full session transcript into the vault.
 *
 * Writes two artifacts:
 *   1. <vault>/session-archive/<YYYY-MM-DD>_<session-short>.jsonl
 *      — verbatim copy of the raw transcript for forensic/replay.
 *   2. <vault>/session-archive/<YYYY-MM-DD>_<session-short>.md
 *      — human-readable markdown rendering with user prompts, assistant
 *        replies, tool calls summarized. Readable in Obsidian.
 *
 * Idempotent: skips if destination exists and is non-empty (so multi-end
 * triggers don't corrupt existing archives).
 *
 * Non-destructive: never deletes or modifies the source transcript.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const VAULT = 'C:\\Users\\rjain\\OneDrive - Technijian, Inc\\Documents\\obsidian\\tech-legal';
const ARCHIVE_DIR = path.join(VAULT, 'session-archive');

function ensureDir(p) { try { fs.mkdirSync(p, { recursive: true }); } catch (_) {} }

let input = '';
try { input = fs.readFileSync(0, 'utf8'); } catch (_) {}

let payload = {};
try { payload = input ? JSON.parse(input) : {}; } catch (_) {}

const transcriptPath = payload.transcript_path || payload.transcriptPath;
const sessionId = payload.session_id || payload.sessionId || '';
if (!transcriptPath || !fs.existsSync(transcriptPath)) {
  process.exit(0);
}

ensureDir(ARCHIVE_DIR);

const today = new Date().toISOString().slice(0, 10);
const shortSid = (sessionId || path.basename(transcriptPath, '.jsonl')).slice(0, 8) || 'unknown';
const stamp = `${today}_${shortSid}`;
const jsonlOut = path.join(ARCHIVE_DIR, `${stamp}.jsonl`);
const mdOut = path.join(ARCHIVE_DIR, `${stamp}.md`);

// Skip if already archived (idempotent).
try {
  if (fs.existsSync(jsonlOut) && fs.statSync(jsonlOut).size > 0) {
    process.exit(0);
  }
} catch (_) {}

// 1. Copy JSONL verbatim
try {
  fs.copyFileSync(transcriptPath, jsonlOut);
} catch (e) {
  process.stderr.write(`[session-archive] copy failed: ${e.message}\n`);
  process.exit(0);
}

// 2. Render readable markdown
const lines = fs.readFileSync(transcriptPath, 'utf8').split(/\r?\n/).filter(Boolean);
const rows = [];
for (const ln of lines) {
  try { rows.push(JSON.parse(ln)); } catch (_) {}
}

function flatten(content) {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  const parts = [];
  for (const c of content) {
    if (!c) continue;
    if (typeof c === 'string') { parts.push(c); continue; }
    if (c.type === 'text' && typeof c.text === 'string') { parts.push(c.text); continue; }
    if (c.type === 'tool_use') {
      const n = c.name || 'tool';
      const inp = c.input ? JSON.stringify(c.input).slice(0, 400) : '';
      parts.push(`\n> **[tool: ${n}]** ${inp}${inp.length >= 400 ? '…' : ''}\n`);
      continue;
    }
    if (c.type === 'tool_result') {
      const s = typeof c.content === 'string' ? c.content : JSON.stringify(c.content || '');
      const trimmed = s.length > 600 ? s.slice(0, 600) + '…' : s;
      parts.push(`\n> **[tool result]** ${trimmed}\n`);
      continue;
    }
    if (c.type === 'thinking') continue;
  }
  return parts.join('\n').trim();
}

function stripReminders(s) {
  if (!s) return '';
  return s
    .replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, '')
    .replace(/<command-name>[\s\S]*?<\/command-stderr>/g, '')
    .replace(/<local-command-[\s\S]*?\/local-command-[^>]+>/g, '')
    .trim();
}

const md = [];
md.push(`---`);
md.push(`kind: session-archive`);
md.push(`session_id: ${sessionId || 'unknown'}`);
md.push(`date: ${today}`);
md.push(`turn_count: ${rows.length}`);
md.push(`source_transcript: ${transcriptPath.replace(/\\/g, '/')}`);
md.push(`---`);
md.push('');
md.push(`# Session ${shortSid} — ${today}`);
md.push('');
md.push(`Full transcript (JSONL): [${stamp}.jsonl](${stamp}.jsonl)`);
md.push('');

for (const r of rows) {
  const msg = r.message || r;
  const role = msg.role || r.type;
  const ts = (r.timestamp || msg.timestamp || '').toString().slice(0, 19);
  if (role === 'user') {
    const raw = stripReminders(flatten(msg.content));
    if (!raw) continue;
    md.push(`## USER — ${ts}`);
    md.push('');
    md.push(raw);
    md.push('');
  } else if (role === 'assistant') {
    const raw = flatten(msg.content);
    if (!raw) continue;
    md.push(`## ASSISTANT — ${ts}`);
    md.push('');
    md.push(raw);
    md.push('');
  }
}

try {
  fs.writeFileSync(mdOut, md.join('\n'), 'utf8');
} catch (e) {
  process.stderr.write(`[session-archive] md render failed: ${e.message}\n`);
}

process.stderr.write(`[session-archive] wrote ${path.basename(jsonlOut)} + ${path.basename(mdOut)}\n`);
process.exit(0);
