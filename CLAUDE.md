# Claude Code Guide

Read [`AGENTS.md`](./AGENTS.md) first.

For Client Portal work in this repo:

1. Treat `.codex/skills/` as the shared domain playbook.
2. Start with `.codex/skills/client-portal-core/SKILL.md`.
3. Use `.codex/skills/client-portal-core/references/domain-map.md` to route the task to the correct domain skill.
4. Use `.codex/skills/client-portal-core/scripts/client_portal_api.py` for live API auth, discovery, and execution.

If a prompt mentions clients, contracts, proposals, tickets, time entries, invoices, users, communications, reporting, admin, or payroll in the Client Portal, check the matching `client-portal-*` folder under `.codex/skills/` before improvising.
