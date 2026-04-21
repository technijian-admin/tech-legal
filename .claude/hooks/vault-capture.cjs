#!/usr/bin/env node
/* Stop hook for tech-legal.
 * Reads the Claude Code transcript JSONL, extracts the most recent
 * USER prompt + ASSISTANT response, and appends them to the Obsidian
 * vault conversation-log in the canonical format:
 *
 *   ### USER — <ISO timestamp> [<session-id prefix>]
 *   <text>
 *
 *   ### ASSISTANT — <ISO timestamp> [<session-id prefix>]
 *   <text>
 *
 *   ---
 *
 * Dedupes by (session-id prefix, rounded timestamp) so that if another
 * machine's hook also writes via OneDrive sync we don't duplicate turns.
 */

const fs = require('fs');
const path = require('path');

const VAULT_ROOT = 'C:\\Users\\rjain\\OneDrive - Technijian, Inc\\Documents\\obsidian\\tech-legal';
const LOG_DIR = path.join(VAULT_ROOT, 'conversation-log');

const MAX_ASSISTANT_CHARS = 12000;
const MAX_USER_CHARS = 4000;

function ensureDir(p) { try { fs.mkdirSync(p, { recursive: true }); } catch (_) {} }

function readTranscript(transcriptPath) {
  if (!transcriptPath || !fs.existsSync(transcriptPath)) return [];
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

function extractLastPair(rows) {
  let lastUser = null;
  let lastAssistant = null;
  for (let i = rows.length - 1; i >= 0; i--) {
    const r = rows[i];
    const msg = r.message || r;
    const role = msg.role || r.type;
    const ts = r.timestamp || msg.timestamp;
    if (!lastAssistant && role === 'assistant') {
      const text = flattenContent(msg.content);
      if (text && text.trim().length > 0) {
        lastAssistant = { text: text.trim(), ts: ts || new Date().toISOString() };
      }
    } else if (lastAssistant && !lastUser && role === 'user') {
      const raw = flattenContent(msg.content);
      const text = stripSystemWrappers(raw);
      if (text && text.trim().length > 0) {
        lastUser = { text: text.trim(), ts: ts || lastAssistant.ts };
        break;
      }
    }
  }
  return { user: lastUser, assistant: lastAssistant };
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

(function main() {
  let payload = '';
  try { payload = fs.readFileSync(0, 'utf8'); } catch (_) {}
  let input = {};
  try { input = JSON.parse(payload); } catch (_) {}

  const sessionId = input.session_id || input.sessionId || '';
  const transcriptPath = input.transcript_path || input.transcriptPath || '';
  if (!sessionId || !transcriptPath) { process.exit(0); }

  const rows = readTranscript(transcriptPath);
  if (!rows.length) { process.exit(0); }

  const { user, assistant } = extractLastPair(rows);
  if (!user || !assistant) { process.exit(0); }

  const sidPrefix = sessionId.slice(0, 8);
  const userText = truncate(user.text, MAX_USER_CHARS);
  const assistantText = truncate(assistant.text, MAX_ASSISTANT_CHARS);

  const file = dayFileFor(user.ts);

  if (alreadyLogged(file, sidPrefix, user.ts, assistant.ts)) { process.exit(0); }

  appendPair(
    file,
    sidPrefix,
    { ts: user.ts, text: userText },
    { ts: assistant.ts, text: assistantText }
  );

  process.exit(0);
})();
