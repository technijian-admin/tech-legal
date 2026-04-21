# Claude Code Hooks — tech-legal

Two project-scoped hooks wire Claude Code to the Obsidian vault at
`C:\Users\rjain\OneDrive - Technijian, Inc\Documents\obsidian\tech-legal`.

## Hooks

### `vault-inject.cjs` — `UserPromptSubmit`

Runs before every user prompt reaches the model. Reads:

- `vault/claude-memory/*.md` — structured memory (pinned = `type: user` or `type: reference`)
- `vault/conversation-log/YYYY-MM-DD.md` — last 14 days of captured turns

Scores each entry by keyword overlap with the prompt, ranks by score + recency,
emits a JSON `hookSpecificOutput.additionalContext` block (capped at 4000 chars)
containing pinned memory + topic memory + top 4 prior relevant turns.

### `vault-capture.cjs` — `Stop`

Runs when the agent finishes responding. Reads the Claude Code transcript JSONL,
extracts the most recent `user` + `assistant` message pair (skipping tool_use /
tool_result / thinking blocks), appends them to today's conversation-log file
using the canonical format:

```
### USER — <ISO timestamp> [<session-id prefix 8 chars>]
<prompt text>

### ASSISTANT — <ISO timestamp> [<session-id prefix 8 chars>]
<response text>

---
```

Dedupes by `(session-prefix, timestamp)` so cross-device OneDrive sync doesn't
produce double entries.

## Registration

Both hooks are registered in `.claude/settings.json` at project root. Because
they live inside the repo, they sync to other machines via git automatically —
unlike global `~/.claude/settings.json` which does not sync.

## Activation

**Hooks load at session start.** After any change to these files or to
`settings.json`, close and reopen Claude Code for the new configuration to take
effect. Running `/hooks` inside Claude Code shows the active hook list.

## Storage format

The vault layout this system expects / maintains:

```
C:\Users\rjain\OneDrive - Technijian, Inc\Documents\obsidian\tech-legal\
├── claude-memory\
│   ├── MEMORY.md                          # index (human-readable)
│   ├── <topic>.md                         # one file per memory (frontmatter: name, description, type)
│   └── ...
└── conversation-log\
    ├── YYYY-MM-DD.md                      # one file per day
    └── ...
```

Memory files use simple frontmatter:

```markdown
---
name: <title>
description: <one-line hook for relevance>
type: user | feedback | project | reference
---

<body>
```

`type: user` and `type: reference` are always injected (pinned). Other types
only inject when the prompt's tokens overlap the body.

## Troubleshooting

- **Nothing is injected**: confirm `conversation-log/` exists and has
  `YYYY-MM-DD.md` files in the documented format. Run the hook manually:
  `echo '{"prompt":"OKL Dell server"}' | node .claude/hooks/vault-inject.cjs`
  should print a JSON block.
- **Capture didn't fire**: Stop hook needs `transcript_path` and `session_id`
  in the hook payload. These are provided by Claude Code — if missing, the
  hook silently exits.
- **Duplicate entries appear**: harmless, caused by multiple machines writing
  after OneDrive sync. Dedup triggers on exact (session-prefix, timestamp) so
  clock drift between machines can let duplicates slip through. Reconcile by
  hand if needed.
