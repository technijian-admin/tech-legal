---
name: client-portal-clients-contracts
description: Use when working with Client Portal clients and contracts: client codes, active or inactive clients, contract lists, contract reports, contract-directory lookups, client billable status, or prompts that join clients to contracts. Good for requests like list clients, show active contracts, get a contract report, or generate an active client list with client name and client code.
---

# Client Portal Clients & Contracts

Use this skill for client master data and contract-state questions.

## Workflow

1. Use `../client-portal-core/scripts/client_portal_api.py search "..."` if the exact procedure is unclear.
2. Read [references/coverage.md](references/coverage.md).
3. Prefer read-only list/report procedures before any save/update contract paths.
4. If completeness matters, call out whether the result is truly client-linked or only location-linked.

## First Search Phrases

- `list clients`
- `list contracts`
- `active contract client`
- `contract report`
- `contract for directory`
