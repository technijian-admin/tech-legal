#!/usr/bin/env node
/* Stop hook — detect preference-shaped statements in the final user turn and
 * APPEND them to preferences.md. Separate from topic consolidation.
 *
 * Preferences are universal rules ("always X", "don't Y", "prefer Z") rather
 * than domain knowledge. They get loaded on every retrieval regardless of topic.
 *
 * Non-destructive: only APPENDS to preferences.md; never overwrites existing
 * entries. Creates the file if missing. Writes a CHANGELOG entry with the
 * [manual] prefix since the extraction is heuristic.
 */
'use strict';
const fs = require('fs');
const path = require('path');

const VAULT = 'C:\\Users\\rjain\\OneDrive - Technijian, Inc\\Documents\\obsidian\\tech-legal';
const MEM = path.join(VAULT, 'claude-memory');
const PREF = path.join(MEM, 'preferences.md');
const CHANGELOG = path.join(MEM, 'CHANGELOG.md');

let input = '';
try { input = fs.readFileSync(0, 'utf8'); } catch (e) { /* no stdin */ }

let payload = {};
try { payload = input ? JSON.parse(input) : {}; } catch (e) { /* malformed */ }

// We expect the transcript or recent user turns to be passed in; CC's exact
// payload shape for Stop hooks varies by version. For now, accept a `messages`
// array or `transcript` field and scan for preference patterns.
const messages = payload.messages || [];
const transcript = (payload.transcript || '') + '\n' + messages
  .filter(m => m && m.role === 'user')
  .map(m => typeof m.content === 'string' ? m.content : JSON.stringify(m.content))
  .join('\n');

if (!transcript.trim()) {
  process.exit(0);
}

const patterns = [
  /\b(?:i\s+(?:prefer|want|would\s+like)|always)\s+([^.?!\n]{6,120})[.?!\n]/gi,
  /\b(?:don't|do\s+not|never)\s+([^.?!\n]{6,120})[.?!\n]/gi,
  /\b(?:from\s+now\s+on|going\s+forward|in\s+future),?\s+([^.?!\n]{6,120})[.?!\n]/gi,
];

const hits = new Set();
for (const re of patterns) {
  let m;
  while ((m = re.exec(transcript)) !== null) {
    const raw = m[0].trim();
    if (raw.length > 20 && raw.length < 200) hits.add(raw.replace(/\s+/g, ' '));
  }
}

if (hits.size === 0) {
  process.exit(0);
}

// Heuristic: many small matches from one conversation is noisy. Limit to 3.
const sorted = Array.from(hits).slice(0, 3);

const today = new Date().toISOString().slice(0, 10);

// Ensure preferences.md exists with header
if (!fs.existsSync(PREF)) {
  fs.writeFileSync(PREF,
    `---
kind: preferences
last_updated: ${today}
---

# Preferences

Universal rules always loaded on retrieval. One-liner per preference. Append-only — if a preference becomes wrong, mark it superseded rather than deleting.

`, 'utf8');
}

let pref = fs.readFileSync(PREF, 'utf8');
const appended = [];

for (const line of sorted) {
  const normalized = line.toLowerCase();
  if (pref.toLowerCase().includes(normalized)) continue; // already present
  const entry = `- [${today}] ${line}\n`;
  pref += entry;
  appended.push(line);
}

if (appended.length) {
  // Update last_updated header
  pref = pref.replace(/(last_updated:\s*)\S+/, `$1${today}`);
  fs.writeFileSync(PREF, pref, 'utf8');

  // CHANGELOG entry
  let changelog = '';
  try { changelog = fs.readFileSync(CHANGELOG, 'utf8'); } catch (e) { /* fresh */ }
  const clEntry = `\n- \`[manual]\` preferences.md: auto-extracted ${appended.length} candidate(s) on ${today} — review on next /review.`;
  fs.writeFileSync(CHANGELOG, changelog + clEntry, 'utf8');

  process.stderr.write(`[preference-extract] appended ${appended.length} candidate(s) — review on next /review\n`);
}
process.exit(0);
