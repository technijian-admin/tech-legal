---
name: review
description: Weekly vault review — surface new topics, updated topics, unresolved contradictions, volatility candidates, ephemeral-archive candidates, and prune candidates. Target 5-10 min.
---

Read the vault at `C:/Users/rjain/OneDrive - Technijian, Inc/Documents/obsidian/tech-legal/claude-memory/`. Produce a checklist-style weekly review covering:

1. **New topics this week** — scan `CHANGELOG.md` for `[consolidate]` entries in the last 7 days. For each new topic, show filename + 1-line summary. Ask: keep as-is / edit / archive?

2. **Topics updated this week** — `CHANGELOG.md` entries for existing topics. Spot-check the change — is the summary still accurate?

3. **Unresolved contradictions** — grep all `topics/*.md` for `## Open questions` sections and list any non-empty entries. For each: present both sides, ask user to resolve (which one is correct? or keep both as "context matters").

4. **Volatility candidates** — topics whose content history suggests volatility should change:
   - `stable` topics modified multiple times in the last 30 days → flag as "might actually be evolving"
   - `ephemeral` topics not modified in 60 days → flag for possible archive
   - `evolving` topics stable for 6+ months → flag as "might actually be stable"

5. **Ephemeral topics approaching 60-day auto-archive** — list topics with `volatility: ephemeral` and `last_accessed` > 45 days ago. User can archive early, keep, or promote to evolving.

6. **Prune candidates** — topics with `access_count: 0` for >30 days AND not in any `[consolidate]` CHANGELOG entries recently. Candidates for archive (not deletion).

Output as a numbered checklist. For each item the user can say: keep / edit / archive / change-volatility. Apply approved decisions to topic frontmatter + CHANGELOG + git commit with `[manual]` prefix.

After applying decisions, update HEALTH.md "Last `/review` run" to today.
