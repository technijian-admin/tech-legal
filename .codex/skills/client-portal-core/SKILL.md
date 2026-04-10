---
name: client-portal-core
description: Use when working with the Client Portal API itself: token generation, bearer auth, Swagger or catalog discovery, stored-procedure search, request-template lookup, generic execute calls, or when the right business-domain skill is unclear. Good for auth errors, route discovery, parameter shapes, and mapping plain-English prompts to Client Portal procedures.
---

# Client Portal Core

Use this skill for any Client Portal API task that starts with discovery, auth, or ambiguity.

## Start Here

1. Use the helper script at `scripts/client_portal_api.py`.
2. Read [references/auth.md](references/auth.md) for credential storage and live auth behavior.
3. Read [references/domain-map.md](references/domain-map.md) when the prompt could fit multiple domain skills.
4. Read [references/api-surface.md](references/api-surface.md) if you need the broader module landscape.
5. Prefer read-only procedures unless the user explicitly asks to create, save, update, delete, sync, or send.

## Fast Workflow

- Search likely procedures:

```bash
python3 scripts/client_portal_api.py search "active contract client"
```

- Inspect a specific guide entry:

```bash
python3 scripts/client_portal_api.py guide client-portal dbo stp_Get_Client_List
```

- Execute a read-only procedure with its default request template:

```bash
python3 scripts/client_portal_api.py execute client-portal dbo stp_Get_Client_List
```

- Execute with parameter overrides:

```bash
python3 scripts/client_portal_api.py execute client-portal dbo stp_Get_Contract_Report_NEW --params '{"Contract_ID": 4389}'
```

- Run the seeded example recipe:

```bash
python3 scripts/client_portal_api.py recipe active-client-contracts --limit 25
```

## Discovery Strategy

- `catalog/guide` is curated and route-ready. Use it first for common tasks.
- `catalog/objects` is much closer to full procedure coverage. Use `search` when curated guide coverage is too narrow.
- After `guide`, use the returned `requestTemplate` unless you have a reason to override specific parameters.
- If a procedure is not obvious, use `search`, then `guide`, then `execute`.

## Live Facts

- Token endpoint: `POST /api/auth/token`
- Request keys verified live: `userName`, `password`
- Runtime endpoints return `401` without bearer auth even though Swagger is public.
- Most routes follow:
  `POST /api/modules/{module}/stored-procedures/{databaseAlias}/{schema}/{procedure}/execute`

## Escalate To Domain Skills

- Clients/contracts: `../client-portal-clients-contracts`
- Proposals/estimates/sales: `../client-portal-proposals-estimates-sales`
- Tickets/service delivery: `../client-portal-tickets-service-delivery`
- Time entry/approvals/workshift: `../client-portal-time-entries-approvals`
- Users/directory/assets: `../client-portal-users-directory-assets`
- Invoices/billing/payments: `../client-portal-invoices-billing-payments`
- Communications/signatures/collaboration: `../client-portal-communications-signatures`
- Admin/automation/security: `../client-portal-admin-automation-security`
- Reporting/analytics/tree data: `../client-portal-reporting-analytics`
- Payroll/HR operations: `../client-portal-payroll-hr-ops`
