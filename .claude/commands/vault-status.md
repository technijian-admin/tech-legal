---
name: vault-status
description: Show a dashboard of the Obsidian memory vault — topic count, volatility distribution, staleness, retrieval hit rate, recent mutations, next review due date.
---

Read the vault `HEALTH.md` at `C:/Users/rjain/OneDrive - Technijian, Inc/Documents/obsidian/tech-legal/claude-memory/HEALTH.md` and present a concise dashboard with:

1. Status line: GREEN / YELLOW / RED
2. Size table (topics, words, avg, max)
3. Retrieval (attempts, hit rate, miss rate — note if reconstructed/seed)
4. Freshness (stale >60d, stale >180d, orphans, broken links)
5. Volatility distribution (stable/evolving/ephemeral %)
6. Weekly review status (days since last `/review`, next due)
7. Upgrade recommendation from `/graduate`

Also:
- Count actual files in `claude-memory/topics/` to verify HEALTH.md is current
- Count recent CHANGELOG entries (last 7 days) as a sanity check on whether the health hook is running
- If `days_since_review > 7`, print a reminder banner: "Run `/review` to refresh weekly metrics."

Output format: readable markdown table + 2-line summary at top. Target ~40 lines total.
