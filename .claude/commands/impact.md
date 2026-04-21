---
name: impact
description: Run GitNexus impact analysis on specified symbol or file path. Shows dependents and blast radius.
---

Arguments: `$ARGUMENTS` — symbol name, file path, or function/class identifier.

Use the GitNexus MCP tool `gitnexus_impact` with the argument. Output:

- What the symbol is (type, file, line)
- Direct callers / importers (top 20)
- Transitive impact count
- Risk classification: LOW / MEDIUM / HIGH / CRITICAL
- Test coverage for affected files if available

If `.gitnexus/` is missing or stale (>7 days old vs latest git commit), suggest running `npx gitnexus analyze` first.

For CRITICAL risk edits, require explicit user confirmation before proceeding.
