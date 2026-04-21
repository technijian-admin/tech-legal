---
name: consolidate
description: Manually trigger the consolidation hook logic on the current conversation. Extract durable knowledge and write to the matching topic page (or create one).
---

Normally consolidation runs automatically on Stop. Use this command to force it on demand (e.g., at the end of a long exploratory conversation you want captured without ending the session).

Process:

1. **Decide worthiness** — scan the recent conversation for durable knowledge: decisions, rationale, new facts about the system, corrections to prior understanding, preferences. Skip if trivial, code-structural only, or procedural only.

2. **Check for preferences** — any "I prefer X", "don't do Y", "always Z" statements? These go to `claude-memory/preferences.md` (create if missing), not a topic page. Ask user for confirmation before writing preferences.

3. **Match or create topic page** — search `topics/` for a page matching the subject. If a close match exists, update it. If not and the material is substantial, create a new topic page with full frontmatter (`volatility: evolving` default).

4. **Contradiction detection** — before updating, compare new info against existing `## Key facts` and `## Decisions & rationale`:
   - Compatible → append.
   - Clarifying → refine in place, note in CHANGELOG.
   - Contradicting → append to `## Open questions`, preserve both, lower `confidence` one step, log `[contradiction]`.
   - Replacing (only with explicit "that was wrong" signal) → overwrite, log `[replaced]`.

5. **Respect volatility** — stable topics need strong signal for contradictions; ephemeral topics can be overwritten freely.

6. **Update frontmatter** — `last_updated` to today, increment `access_count`, refresh `last_accessed`.

7. **Commit** — git commit in vault with `[consolidate] <topic>: <one-line summary>`.

Print summary: topics updated / created / skipped, with rationale.
