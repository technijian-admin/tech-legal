#!/usr/bin/env node
/* UserPromptSubmit hook for tech-legal.
 * Reads Obsidian vault conversation-log + claude-memory, scores entries
 * against the incoming prompt, and injects the top matches as additional
 * context so the model always has prior-session memory available.
 *
 * Vault path is fixed per user instruction:
 *   C:\Users\rjain\OneDrive - Technijian, Inc\Documents\obsidian\tech-legal
 */

const fs = require('fs');
const path = require('path');

const VAULT_ROOT = 'C:\\Users\\rjain\\OneDrive - Technijian, Inc\\Documents\\obsidian\\tech-legal';
const LOG_DIR = path.join(VAULT_ROOT, 'conversation-log');
const MEM_DIR = path.join(VAULT_ROOT, 'claude-memory');
const TOPICS_DIR = path.join(MEM_DIR, 'topics');
const PREFERENCES = path.join(MEM_DIR, 'preferences.md');

const MAX_INJECT_CHARS = 9000;  // bumped from 4000 to fit topic catalog + high-stakes banner
const TOP_N_TURNS = 4;
const MAX_LOG_FILES = 14;

// Keywords that mean "before acting, you MUST grep vault memory" — surfaces
// non-content-matched topics that share a keyword in title/description/filename.
// Triggered the Rev3 DocuSign 5-min-URL miss on 2026-04-24; expand cautiously.
const HIGH_STAKES_KEYWORDS = [
  'docusign','foxit','envelope','void','sign','signed','signing',
  'send','sent','email','mail','draft','reply','respond','broadcast',
  'contract','msa','sow','redline','agreement','amendment','exhibit','schedule a','schedule b','schedule c','schedule d',
  'bwh','affg','aafg','bst','sunrun','vtd','aava','ampac','okl','chl','taly','brandywine','technijian',
  'iris','dave','jeff','frank','susolik','klein','dunn','cron','barisic',
  'invoice','payment','wire','demand','arbitration','litigation','ndr','bounce'
];
function detectHighStakes(prompt) {
  const lower = (prompt || '').toLowerCase();
  return HIGH_STAKES_KEYWORDS.filter(k => new RegExp(`\\b${k.replace(/\s+/g, '\\s+')}\\b`).test(lower));
}
const STOP_WORDS = new Set([
  'the','a','an','and','or','but','if','then','else','of','to','in','on','at','for','with','by','from','as','is','are','was','were','be','been','being','have','has','had','do','does','did','this','that','these','those','it','its','i','you','he','she','we','they','me','my','your','our','their','what','how','why','when','where','which','who','can','could','would','should','will','shall','may','might','must','not','no','so','too','very','just','also','about','please','make','sure','see','review'
]);

function tokenize(s) {
  return (s || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s\-_./]/g, ' ')
    .split(/\s+/)
    .filter(t => t.length > 2 && !STOP_WORDS.has(t));
}

function listRecentLogFiles() {
  if (!fs.existsSync(LOG_DIR)) return [];
  return fs.readdirSync(LOG_DIR)
    .filter(f => /^\d{4}-\d{2}-\d{2}\.md$/.test(f))
    .sort()
    .slice(-MAX_LOG_FILES)
    .map(f => path.join(LOG_DIR, f));
}

function parseConversationLog(text, filename) {
  const re = /^### (USER|ASSISTANT) — ([^\s\[]+)\s*\[([^\]]+)\]\s*$/gm;
  const markers = [];
  for (const m of text.matchAll(re)) {
    markers.push({
      role: m[1], ts: m[2], sid: m[3],
      start: m.index, headerEnd: m.index + m[0].length
    });
  }
  const turns = [];
  for (let i = 0; i < markers.length; i++) {
    const cur = markers[i];
    const end = i + 1 < markers.length ? markers[i + 1].start : text.length;
    const body = text.slice(cur.headerEnd, end).replace(/^\s*\n/, '').replace(/\n---\s*\n?$/, '').trim();
    turns.push({ file: filename, role: cur.role, ts: cur.ts, sid: cur.sid, body });
  }
  const pairs = [];
  for (let i = 0; i < turns.length - 1; i++) {
    if (turns[i].role === 'USER' && turns[i + 1].role === 'ASSISTANT' && turns[i].sid === turns[i + 1].sid) {
      pairs.push({
        file: turns[i].file, ts: turns[i].ts, sid: turns[i].sid,
        user: turns[i].body, assistant: turns[i + 1].body
      });
      i++;
    }
  }
  return pairs;
}

function loadAllPairs() {
  const pairs = [];
  for (const f of listRecentLogFiles()) {
    try {
      const text = fs.readFileSync(f, 'utf8');
      pairs.push(...parseConversationLog(text, path.basename(f)));
    } catch (_) {}
  }
  return pairs;
}

function loadMemoryEntries() {
  // Prefer post-migration topics/ subfolder; fall back to MEM_DIR root for legacy.
  const dir = fs.existsSync(TOPICS_DIR) ? TOPICS_DIR : MEM_DIR;
  if (!fs.existsSync(dir)) return { pinned: [], regular: [] };
  const exclude = new Set(['MEMORY.md', 'index.md', 'CHANGELOG.md', 'HEALTH.md', 'preferences.md']);
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.md') && !exclude.has(f));
  const pinned = [], regular = [];
  for (const f of files) {
    try {
      const text = fs.readFileSync(path.join(dir, f), 'utf8');
      const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
      const meta = {};
      let body = text;
      if (fm) {
        for (const line of fm[1].split(/\r?\n/)) {
          const kv = line.match(/^([^:]+):\s*(.*)$/);
          if (kv) meta[kv[1].trim()] = kv[2].trim();
        }
        body = fm[2];
      }
      const entry = {
        file: f,
        title: meta.topic || meta.name || f.replace(/\.md$/, ''),
        type: (meta.type || 'memory').toLowerCase(),
        body: body.trim()
      };
      if (entry.type === 'user' || entry.type === 'reference') pinned.push(entry);
      else regular.push(entry);
    } catch (_) {}
  }
  return { pinned, regular };
}

// Lightweight catalog: list ALL topic files with title + description only
// (no body). Always injected so the model knows what memory exists and can
// grep it on demand even when keyword scoring misses. Designed to be cheap
// (~50 files, frontmatter only) so it stays well under the 8s hook timeout.
function loadTopicCatalog() {
  const dir = fs.existsSync(TOPICS_DIR) ? TOPICS_DIR : MEM_DIR;
  if (!fs.existsSync(dir)) return [];
  const exclude = new Set(['MEMORY.md', 'index.md', 'CHANGELOG.md', 'HEALTH.md', 'preferences.md']);
  const out = [];
  for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.md') && !exclude.has(f))) {
    try {
      const text = fs.readFileSync(path.join(dir, f), 'utf8');
      const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
      const meta = {};
      if (fm) {
        for (const line of fm[1].split(/\r?\n/)) {
          const kv = line.match(/^([^:]+):\s*(.*)$/);
          if (kv) meta[kv[1].trim()] = kv[2].trim().replace(/^["']|["']$/g, '');
        }
      }
      out.push({
        file: f,
        title: meta.topic || meta.name || f.replace(/\.md$/, ''),
        desc: (meta.description || meta.aliases || '').slice(0, 140)
      });
    } catch (_) {}
  }
  return out;
}

// Load preferences.md unconditionally — per memory-stack spec, preferences
// are universal rules that apply to every interaction regardless of topic
// match. This is loaded as an extra pinned entry on every prompt.
function loadPreferences() {
  if (!fs.existsSync(PREFERENCES)) return null;
  try {
    const text = fs.readFileSync(PREFERENCES, 'utf8');
    // Strip frontmatter
    const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
    const body = (fm ? fm[2] : text).trim();
    if (!body) return null;
    return {
      file: 'preferences.md',
      title: 'User Preferences (universal)',
      type: 'user',
      body
    };
  } catch (_) { return null; }
}

function scorePair(promptTokens, pair) {
  const text = (pair.user + ' ' + pair.assistant).toLowerCase();
  let score = 0;
  for (const t of promptTokens) if (text.includes(t)) score += 1;
  if (pair.file) {
    const m = pair.file.match(/^(\d{4}-\d{2}-\d{2})\.md$/);
    if (m) {
      const d = new Date(m[1]);
      const ageDays = (Date.now() - d.getTime()) / (1000 * 60 * 60 * 24);
      score += Math.max(0, 2 - ageDays * 0.1);
    }
  }
  return score;
}

function truncate(s, n) {
  if (s.length <= n) return s;
  return s.slice(0, n - 3) + '...';
}

(function main() {
  let payload = '';
  try { payload = fs.readFileSync(0, 'utf8'); } catch (_) {}
  let input = {};
  try { input = JSON.parse(payload); } catch (_) {}
  const prompt = input.prompt || '';

  const ptoks = tokenize(prompt);
  if (!ptoks.length) { process.exit(0); }

  const { pinned, regular } = loadMemoryEntries();
  // Always include preferences.md if present — universal rules, not topic-matched.
  const prefs = loadPreferences();
  if (prefs) pinned.unshift(prefs);
  const pairs = loadAllPairs();
  const catalog = loadTopicCatalog();
  const highStakes = detectHighStakes(prompt);

  const ranked = pairs
    .map(p => ({ ...p, _score: scorePair(ptoks, p) }))
    .filter(p => p._score > 0)
    .sort((a, b) => b._score - a._score)
    .slice(0, TOP_N_TURNS);

  const memScored = regular
    .map(e => {
      const body = e.body.toLowerCase();
      let s = 0;
      for (const t of ptoks) if (body.includes(t)) s += 1;
      return { ...e, _score: s };
    })
    .filter(e => e._score > 0)
    .sort((a, b) => b._score - a._score)
    .slice(0, 3);

  if (!pinned.length && !ranked.length && !memScored.length && !catalog.length && !highStakes.length) { process.exit(0); }

  const sections = [];
  let used = 0;

  // HIGH-STAKES BANNER — first so it's most visible. Surfaces topics whose
  // title/description/filename mentions any of the high-stakes keywords from
  // the prompt, even if their body didn't match the keyword scoring above.
  if (highStakes.length && catalog.length) {
    const matched = catalog.filter(t => {
      const hay = (t.title + ' ' + t.desc + ' ' + t.file).toLowerCase();
      return highStakes.some(k => hay.includes(k.toLowerCase()));
    }).slice(0, 12);
    if (matched.length) {
      const lines = matched.map(t => `- **${t.title}** \`(${t.file})\`${t.desc ? ' — ' + t.desc : ''}`);
      const banner = [
        `## HIGH-STAKES WRITE DETECTED — keywords: ${highStakes.join(', ')}`,
        ``,
        `**You MUST grep these vault topics before any send/sign/commit action.** Vault topics path:`,
        `\`C:/Users/rjain/OneDrive - Technijian, Inc/Documents/obsidian/tech-legal/claude-memory/topics/\``,
        ``,
        `Topics whose name/description matches your keywords:`,
        ...lines,
        ``
      ].join('\n');
      if (used + banner.length <= MAX_INJECT_CHARS) { sections.push(banner); used += banner.length; }
    }
  }

  if (pinned.length) {
    const blocks = pinned.map(e => `- **${e.title}**: ${truncate(e.body.replace(/\n+/g, ' '), 400)}`);
    const block = `## Pinned memory\n${blocks.join('\n')}\n`;
    if (used + block.length <= MAX_INJECT_CHARS) { sections.push(block); used += block.length; }
  }

  if (memScored.length) {
    const blocks = memScored.map(e => `### ${e.title}\n${truncate(e.body, 600)}`);
    const block = `## Topic memory\n${blocks.join('\n\n')}\n`;
    if (used + block.length <= MAX_INJECT_CHARS) { sections.push(block); used += block.length; }
  }

  if (ranked.length) {
    const blocks = [];
    for (const p of ranked) {
      const u = truncate(p.user.replace(/\n+/g, ' '), 200);
      const a = truncate(p.assistant, 800);
      const block = `### ${p.file} @ ${p.ts} [${p.sid}]\n**You:** ${u}\n**Assistant:** ${a}`;
      if (used + block.length > MAX_INJECT_CHARS) break;
      blocks.push(block);
      used += block.length;
    }
    if (blocks.length) sections.push(`## Prior relevant turns from vault\n${blocks.join('\n\n')}\n`);
  }

  // FULL TOPIC CATALOG — last (lowest priority but always included if it fits).
  // Gives the model a complete inventory of memory it can grep on demand,
  // even for topics that didn't match keyword scoring.
  if (catalog.length) {
    const lines = catalog.map(t => `- ${t.title} \`(${t.file})\``);
    const block = `## All vault topics available (grep before acting on the relevant one)\n${lines.join('\n')}\n`;
    if (used + block.length <= MAX_INJECT_CHARS) { sections.push(block); used += block.length; }
  }

  if (!sections.length) { process.exit(0); }

  const context = `# Vault context (auto-injected from Obsidian vault)\n\n${sections.join('\n')}`;
  const output = {
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: context
    }
  };
  process.stdout.write(JSON.stringify(output));
  process.exit(0);
})();
