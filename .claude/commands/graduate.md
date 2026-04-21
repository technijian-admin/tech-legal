---
name: graduate
description: Check vault health and recommend stay-put / cleanup / upgrade (e.g., migrate to LightRAG).
---

Preconditions:
1. Read `claude-memory/HEALTH.md`. If `days_since_review > 30`, refuse: "Run `/review` first — vault health cannot be trusted after 30 days without review."
2. Check `.retrieval-log.jsonl` age. If less than 30 days of log data exists, print "insufficient data" with the actual count.

Decision logic:

**GREEN** → "Stay put. Next check: today + 7 days."

**YELLOW** → "Cleanup before upgrade. Recommended actions:
- `/consolidate` to collapse related updates
- Review never-accessed topics, mark for prune or archive
- Update hot-but-stale topics
Recheck in a week."

**RED** → tailored recommendation based on primary cause:

| Cause | Recommendation |
|---|---|
| Topic count > 400 and hit rate < 50% | Migrate to LightRAG. Command: `npx lightrag-init`. |
| Miss rate > 30%, topic count moderate | Try aliases first — 2-week trial. If still RED, migrate. |
| Stale > 25% | Not a tooling problem. Run `/consolidate` aggressively; archive ephemeral topics past their window. |
| Heavy PDF/document corpus | LightRAG for this repo specifically. |

Always include:
- The migration command (or cleanup command)
- What you'd lose if you migrate (e.g., "git history of vault stays; topic page schema changes")
- Estimated migration time

If no clear trigger, output "No upgrade needed — current stack handles this workload."
