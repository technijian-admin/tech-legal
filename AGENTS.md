# Agent Guide

This repo contains a shared Client Portal agent playbook under `.codex/skills/`.

If you are an AI coding or CLI agent working in this repository:

1. Start with `.codex/skills/client-portal-core/SKILL.md`.
2. Use `.codex/skills/client-portal-core/references/domain-map.md` to pick the correct business-domain skill.
3. Use `.codex/skills/client-portal-core/scripts/client_portal_api.py` for live Client Portal discovery and execution.
4. Treat the repo copy of `.codex/skills/` as the source of truth.

## Shared Skill Layout

- `.codex/skills/client-portal-core/`
- `.codex/skills/client-portal-clients-contracts/`
- `.codex/skills/client-portal-proposals-estimates-sales/`
- `.codex/skills/client-portal-tickets-service-delivery/`
- `.codex/skills/client-portal-time-entries-approvals/`
- `.codex/skills/client-portal-users-directory-assets/`
- `.codex/skills/client-portal-invoices-billing-payments/`
- `.codex/skills/client-portal-communications-signatures/`
- `.codex/skills/client-portal-admin-automation-security/`
- `.codex/skills/client-portal-reporting-analytics/`
- `.codex/skills/client-portal-payroll-hr-ops/`

## Client Portal Conventions

- Base URL: `https://api-clientportal.technijian.com`
- Token endpoint: `POST /api/auth/token`
- Shared helper script:
  `.codex/skills/client-portal-core/scripts/client_portal_api.py`
- Repo-to-Codex sync script:
  `scripts/sync-codex-skills.sh`

## Important Notes

- The `.codex/skills/` folders are written in Codex skill format, but the contents are plain Markdown and Python, so other agents should read them as reusable operating instructions.
- Many Client Portal procedures are write-sensitive. Prefer read-only discovery and report/list procedures first unless the user clearly asks to create, update, save, delete, sync, or send.
- Some joined reports are only best-effort because parts of the API are location-linked rather than client-linked. Read the domain coverage notes before claiming full completeness.
