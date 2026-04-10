---
name: client-portal-reporting-analytics
description: Use when working with Client Portal reports, dashboards, tree views, analytics queries, Excel-export procedures, PRTG reads, or cross-domain read-only summaries. Good for prompts that ask for counts, rollups, reports, KPI lists, contract reports, invoice reports, asset reports, or tree-based drilldowns.
---

# Client Portal Reporting & Analytics

Use this skill for read-mostly analytical work that spans operational domains.

## Workflow

1. Start with `../client-portal-core/scripts/client_portal_api.py search "... report"` or `search "... tree"`.
2. Read [references/coverage.md](references/coverage.md).
3. Prefer report and tree procedures before lower-level write-oriented modules.
4. If the prompt spans multiple domains, join read-only outputs rather than guessing from one module.

## First Search Phrases

- `contract report`
- `invoice report`
- `asset report`
- `tree data`
- `prtg`
- `excel`
