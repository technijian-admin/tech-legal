---
name: contradictions
description: List all unresolved contradictions in vault topic pages. Shorter focused version of /review.
---

Grep every file under `C:/Users/rjain/OneDrive - Technijian, Inc/Documents/obsidian/tech-legal/claude-memory/topics/` for `## Open questions` sections. For each non-empty section, present:

- Topic name + file path
- The contradicting statements (both sides, with sources if available)
- Current `confidence` level
- Date the contradiction was logged

For each one, ask: which statement is correct? Or should both be preserved because context matters?

Apply user decisions:
- **Resolve with one side:** update `## Key facts` with the chosen version, remove the Open Questions entry, log `[replaced]` in CHANGELOG with reasoning, restore `confidence` by one step.
- **Keep both:** move the contents into `## Decisions & rationale` with a clarifying note about when each applies, remove the Open Questions entry, log `[manual]` in CHANGELOG.
- **Skip:** leave for next review.

Commit each decision as its own `[replaced]` or `[manual]` entry in git + CHANGELOG so history is traceable.
