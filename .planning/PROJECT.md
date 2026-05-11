# QuickBooks Enterprise Direct-SDK Accounting Integration

## What This Is

A self-hosted service plus a Claude skill that give Claude real-time, programmatic access to QuickBooks Enterprise — reading reports/lists and creating/updating transactions — by talking to QuickBooks Desktop directly through the QuickBooks SDK COM interface (`QBXMLRP2.RequestProcessor`). The service runs on the QuickBooks host (`10.120.254.13`), unattended, and exposes a bearer-auth HTTPS REST API; a Python client and a `quickbooks-accounting` skill drive it from wherever Claude runs. It lives inside the `tech-legal` repo (`tech-legal/quickbooks/` for the service + client, `tech-legal/.claude/skills/quickbooks-accounting/` for the skill).

## Core Value

Claude can run a QuickBooks read (a report, a list, a transaction lookup) and get an answer in seconds — and can create/update a transaction only after an explicit dry-run-and-confirm step, with every write recorded in an immutable audit log.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Service on the QuickBooks host wraps `QBXMLRP2.RequestProcessor` (COM behind an `IRequestProcessor` interface so the .NET solution builds/tests without the QuickBooks SDK installed)
- [ ] Runs unattended (no interactive logon) — integrated-app auto-login, multi-user company file
- [ ] Bearer-auth HTTPS REST API: `GET /api/health`, `POST /api/qbxml` (raw passthrough), `POST /api/ops/{op}`, `POST /api/ops/{op}/dryrun`
- [ ] Request execution serialized (single-threaded QB session) with a configurable timeout; auto-reconnect if QB restarts
- [ ] Read ops: `company_info`, `report` (P&L / BalanceSheet / AgingAR / AgingAP by date range), `list_customers` / `list_vendors` / `list_items` / `list_accounts`, `list_invoices` / `list_bills` / `list_payments` (filter by date/entity), `get_transaction`
- [ ] Write ops (dry-run-gated): `create_customer` / `create_vendor` / `create_invoice` / `create_bill` / `create_check`, `receive_payment`, `create_journal_entry`, `mod_*` (via TxnID/ListID + EditSequence)
- [ ] Write-safety: `Safety:AllowWrites` defaults false (writes → 403); skill always dry-runs and requires explicit user confirmation; immutable audit log of every executed write
- [ ] Python `qb_client.py` on the workstation side (HTTPS, bearer token, retries, dry-run helpers) + runnable examples
- [ ] `quickbooks-accounting` Claude skill (SKILL.md + references) that drives the API: health check, op catalog, safe-write workflow, raw-qbXML fallback
- [ ] Config-driven portability: all machine-specifics in gitignored `appsettings.json` (service) and `.env` (client) with committed `.sample` versions; deploy scripts (`make-cert.ps1`, `install-service.ps1`/`uninstall-service.ps1`, `run-as-task.ps1` fallback) and a setup runbook (`README.md`, `register-integrated-app.md`)
- [ ] Tests: xUnit unit tests (QbXmlBuilder golden files, QbXmlParser samples incl. errors, QbSession state machine with mocked COM, QbErrors), HTTP integration tests against the mocked processor (incl. 403-when-AllowWrites-false and audit rows), Python client tests vs a stub server

### Out of Scope

- QBWC-polled SOAP design — superseded by direct COM; kept only as a fallback note in the service README
- Payroll, inventory assemblies, sales-tax filing, multi-currency specifics — addable later as new ops
- Any UI / web front-end — the interfaces are the REST API and the Claude skill
- Scheduled jobs / bidirectional sync — every call is operator/skill-initiated on demand
- Mapping the rest of the `tech-legal` repo — this is a new isolated subsystem

## Context

- **QuickBooks host:** `10.120.254.13` runs QuickBooks Enterprise; company file to be hosted multi-user. Exact Enterprise year/version still to be confirmed (pins the qbXML spec version, e.g. `16.0`).
- **Integration mechanism:** QuickBooks Desktop SDK (`QBXMLRP2.RequestProcessor` COM), qbXML request/response. No Web Connector.
- **Repo:** `tech-legal` (git, GitHub `technijian-admin/tech-legal`). Currently on feature branch `quickbooks/direct-sdk-integration-2026-05-11`.
- **Design spec:** `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` — the source of truth; brainstormed and approved 2026-05-11. Not to be re-litigated.
- **Build-vs-deploy split:** the codebase (service + mocked-COM tests, Python client + tests, skill) can be built/tested on any machine. Deployment to `10.120.254.13` additionally needs: the QuickBooks SDK installed there, a dedicated Windows service account QB is licensed under, the one-time integrated-app authorization done in QB by an Admin, the company file hosted multi-user, and a firewall path from the client machine to the chosen HTTPS port.
- **Known risk:** Windows services run in session 0 with no interactive desktop and QuickBooks Desktop COM is historically fragile there; mitigations (correct auto-login config; fallback to a startup scheduled task via `run-as-task.ps1`) documented in the service README.

## Constraints

- **Tech stack**: ASP.NET Core (.NET 8) service in C#; Python 3 client (`requests`); Claude skill is Markdown + the Python client. — matches the approved spec and the repo's existing tooling.
- **Git workflow**: never commit/push/merge directly to `main` (tech-legal requires PR review for `main`); all work on `quickbooks/direct-sdk-integration-2026-05-11` (or further feature branches). — repo policy.
- **Security**: writes off by default; dry-run + explicit confirmation before any write; immutable write audit log; bearer-token auth on every API call; HTTPS bind. — write-safety model from the spec.
- **Portability**: no hardcoded IPs/paths/tokens in code — all in gitignored config with committed samples; the `quickbooks/` folder must be relocatable. — user requirement (repo will move workstations).
- **COM isolation**: the real `QBXMLRP2` interop sits behind `IRequestProcessor` so the solution compiles and the full test suite runs without the QuickBooks SDK present. — spec design decision.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Direct QB SDK COM, drop the Web Connector | Real-time synchronous round-trips; no polling/SOAP/queue | — Pending |
| Service runs unattended on the QB host | No one logged into the QB server; auto-login integrated app | — Pending |
| Writes default-disabled + dry-run + audit log | Touching real books safely | — Pending |
| Live in `tech-legal/quickbooks/` (existing repo) | User's choice; keep the subsystem self-contained/portable | — Pending |
| COM behind `IRequestProcessor` | Build & test anywhere without the QB SDK | — Pending |
| Build through GSD (this workflow) | User chose the GSD full-project path | — Pending |

---
*Last updated: 2026-05-11 after initialization*
