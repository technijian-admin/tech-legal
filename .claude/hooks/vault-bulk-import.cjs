#!/usr/bin/env node
/* One-shot bulk transcript dump for tech-legal vault.
 * Reads a Claude Code session JSONL and appends EVERY USER/ASSISTANT turn
 * to the Obsidian conversation-log in the same canonical format as
 * vault-capture.cjs. Uses the same dedupe so re-running is idempotent.
 *
 * Usage:
 *   node vault-bulk-import.cjs <transcript-jsonl-path>
 */

const fs = require('fs');
const path = require('path');

const VAULT_ROOT = 'C:\\Users\\rjain\\OneDrive - Technijian, Inc\\Documents\\obsidian\\tech-legal';
const LOG_DIR = path.join(VAULT_ROOT, 'conversation-log');

const MAX_ASSISTANT_CHARS = 12000;
const MAX_USER_CHARS = 4000;

function ensureDir(p) { try { fs.mkdirSync(p, { recursive: true }); } catch (_) {} }

function readTranscript(transcriptPath) {
  const text = fs.readFileSync(transcriptPath, 'utf8');
  const lines = text.split(/\r?\n/).filter(Boolean);
  const rows = [];
  for (const line of lines) {
    try { rows.push(JSON.parse(line)); } catch (_) {}
  }
  return rows;
}

function flattenContent(content) {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  const parts = [];
  for (const c of content) {
    if (!c) continue;
    if (typeof c === 'string') { parts.push(c); continue; }
    if (c.type === 'text' && typeof c.text === 'string') { parts.push(c.text); continue; }
    if (c.type === 'tool_use') {
      const name = c.name || 'tool';
      parts.push(`_[tool use: ${name}]_`);
      continue;
    }
    if (c.type === 'tool_result') {
      const s = typeof c.content === 'string' ? c.content : JSON.stringify(c.content || '');
      const snippet = s.length > 200 ? s.slice(0, 200) + '...' : s;
      parts.push(`_[tool result: ${snippet}]_`);
      continue;
    }
    if (c.type === 'thinking') continue;
  }
  return parts.join('\n\n').trim();
}

function stripSystemWrappers(s) {
  if (!s) return '';
  return s
    .replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, '')
    .replace(/<command-name>[\s\S]*?<\/command-name>/g, '')
    .replace(/<command-message>[\s\S]*?<\/command-message>/g, '')
    .replace(/<command-args>[\s\S]*?<\/command-args>/g, '')
    .replace(/<local-command-stdout>[\s\S]*?<\/local-command-stdout>/g, '')
    .trim();
}

function truncate(s, n) {
  if (!s) return '';
  if (s.length <= n) return s;
  return s.slice(0, n - 3) + '...';
}

function dayFileFor(iso) {
  const d = new Date(iso);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return path.join(LOG_DIR, `${y}-${m}-${day}.md`);
}

function alreadyLogged(file, sidPrefix, userTs, assistantTs) {
  if (!fs.existsSync(file)) return false;
  const text = fs.readFileSync(file, 'utf8');
  const u = `### USER — ${userTs} [${sidPrefix}]`;
  const a = `### ASSISTANT — ${assistantTs} [${sidPrefix}]`;
  return text.includes(u) && text.includes(a);
}

function appendPair(file, sidPrefix, userBlock, assistantBlock) {
  ensureDir(path.dirname(file));
  const existing = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  const needsLeadingNewline = existing && !existing.endsWith('\n');
  const block = `${needsLeadingNewline ? '\n' : ''}\n---\n\n### USER — ${userBlock.ts} [${sidPrefix}]\n\n${userBlock.text}\n\n### ASSISTANT — ${assistantBlock.ts} [${sidPrefix}]\n\n${assistantBlock.text}\n`;
  fs.appendFileSync(file, block, 'utf8');
}

function extractAllPairs(rows) {
  // Walk forward, build (USER, ASSISTANT) pairs in chronological order.
  // A pair is: a non-tool USER message followed by the next non-tool ASSISTANT
  // text response (skipping tool_use / tool_result / system-only entries).
  const pairs = [];
  let pendingUser = null;
  for (const r of rows) {
    const msg = r.message || r;
    const role = msg.role || r.type;
    const ts = r.timestamp || msg.timestamp;
    if (role === 'user') {
      const raw = flattenContent(msg.content);
      const text = stripSystemWrappers(raw);
      // Skip user entries that are purely tool_result / system-only / empty
      if (!text || text.length === 0) continue;
      pendingUser = { ts: ts || new Date().toISOString(), text };
    } else if (role === 'assistant' && pendingUser) {
      const text = flattenContent(msg.content);
      if (!text || text.length === 0) continue;
      pairs.push({
        user: pendingUser,
        assistant: { ts: ts || pendingUser.ts, text }
      });
      pendingUser = null;
    }
  }
  return pairs;
}

(function main() {
  const transcriptPath = process.argv[2];
  if (!transcriptPath) {
    console.error('Usage: vault-bulk-import.cjs <transcript-jsonl-path>');
    process.exit(2);
  }
  if (!fs.existsSync(transcriptPath)) {
    console.error(`Transcript not found: ${transcriptPath}`);
    process.exit(2);
  }

  const sessionId = path.basename(transcriptPath, '.jsonl');
  const sidPrefix = sessionId.slice(0, 8);

  const rows = readTranscript(transcriptPath);
  console.log(`Read ${rows.length} JSONL rows from ${path.basename(transcriptPath)}`);

  const pairs = extractAllPairs(rows);
  console.log(`Extracted ${pairs.length} USER/ASSISTANT pairs.`);

  let written = 0;
  let skipped = 0;
  for (const pair of pairs) {
    const file = dayFileFor(pair.user.ts);
    if (alreadyLogged(file, sidPrefix, pair.user.ts, pair.assistant.ts)) {
      skipped++;
      continue;
    }
    appendPair(
      file,
      sidPrefix,
      { ts: pair.user.ts, text: truncate(pair.user.text, MAX_USER_CHARS) },
      { ts: pair.assistant.ts, text: truncate(pair.assistant.text, MAX_ASSISTANT_CHARS) }
    );
    written++;
  }
  console.log(`Wrote ${written} new pairs. Skipped ${skipped} (already logged).`);
})();
