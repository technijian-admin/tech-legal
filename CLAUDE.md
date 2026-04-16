# Claude Code Guide

Read [`AGENTS.md`](./AGENTS.md) first.

## Reasoning & Safety Settings

- **Effort:** max (set globally). Never reduce.
- **Destructive operations on Client Portal:** NEVER use delete endpoints (`stp_Con_Delete`, etc.). Only use status updates (Close/Inactive). If a status update doesn't appear to work, STOP and ask the user — do not escalate to more destructive operations.
- **Bulk operations:** Before executing any bulk write (email sends, contract changes, API updates), present the exact target list to the user and wait for confirmation.
- **Bounced email ≠ inactive client:** A bounced contact means update the contact info, not close the client. Only close a client when the user explicitly says so after reviewing.

## Client Portal API Safety Rules

1. READ operations are safe to run freely.
2. WRITE operations (any SP with Save, Update, Create, Delete in the name) require user confirmation before execution.
3. Never call `stp_Con_Delete` or any delete SP. Period.
4. If `stp_Update_Contract` returns 200 but data appears unchanged, tell the user — do not try alternative approaches autonomously.

For Client Portal work in this repo:

1. Treat `.codex/skills/` as the shared domain playbook.
2. Start with `.codex/skills/client-portal-core/SKILL.md`.
3. Use `.codex/skills/client-portal-core/references/domain-map.md` to route the task to the correct domain skill.
4. Use `.codex/skills/client-portal-core/scripts/client_portal_api.py` for live API auth, discovery, and execution.

If a prompt mentions clients, contracts, proposals, tickets, time entries, invoices, users, communications, reporting, admin, or payroll in the Client Portal, check the matching `client-portal-*` folder under `.codex/skills/` before improvising.
