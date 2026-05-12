# Requirements: QuickBooks Enterprise Direct-SDK Accounting Integration

**Defined:** 2026-05-11
**Core Value:** Claude can run a QuickBooks read and get an answer in seconds — and can create/update a transaction only after an explicit dry-run-and-confirm step, with every write in an immutable audit log.
**Authoritative design:** `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` + `.planning/research/SUMMARY.md`.

## v1 Requirements

### Service skeleton & build (SVC)

- [ ] **SVC-01**: The .NET solution builds and its full test suite passes on a Windows machine with **no QuickBooks SDK installed** (COM kept behind an `IRequestProcessor` interface; the `tlbimp`-generated `Interop.QBXMLRP2Lib.dll` is pure metadata, referenced only by a separate `Qb.Com` adapter project).
- [ ] **SVC-02**: A `FakeRequestProcessor` (canned qbXML responses, scriptable errors) implements `IRequestProcessor` so every layer above the COM seam is testable without QuickBooks.
- [ ] **SVC-03**: The project targets `net8.0-windows` and publishes as an **x86** single executable (matches the 32-bit QB SDK COM).
- [ ] **SVC-04**: The same published executable runs as (a) a console app for dev, (b) a Windows service (`AddWindowsService()`), and (c) a Task-Scheduler-launched process — no code change between them.
- [ ] **SVC-05**: A CI workflow builds the solution and runs all tests on push (green with no QuickBooks present).

### COM session lifecycle (SESS)

- [ ] **SESS-01**: A long-lived `QbConnectionManager` owns the COM connection+session lifecycle (`OpenConnection2` → `BeginSession` → `ProcessRequest` → `EndSession` → `CloseConnection`), opened lazily on first use, `OpenMode = DoNotCare`, `connectionType = localQBD`, never `SingleUser`.
- [ ] **SESS-02**: All COM calls run on a single dedicated STA worker thread, serialized through a `SemaphoreSlim(1,1)` gate; concurrent API requests queue (bounded wait, then `409 Busy`).
- [ ] **SESS-03**: On a dead ticket / dropped session the manager **rebuilds** the COM object and retries **exactly once**, then fails loudly with the QuickBooks error.
- [ ] **SESS-04**: A `QbErrors` map translates the `0x8004xxxx` HRESULT family (and the "Class not registered" / `RequestProcessor2`-cast cases) into a human message + remediation hint, surfaced in API responses and `/api/health`.
- [ ] **SESS-05**: A watchdog timeout aborts a `ProcessRequest` that exceeds the configured limit and returns a clear timeout error without wedging the session.

### qbXML read pipeline & read ops (READ)

- [ ] **READ-01**: `QbXmlBuilder` produces qbXML request strings (always emitting the `<?qbxml version="N.N"?>` PI from config) for every read op; `QbXmlParser` turns entity responses into clean JSON and surfaces per-element and per-message `statusCode`/`statusSeverity`/`statusMessage` (a zero-row result is **not** an error).
- [ ] **READ-02**: A separate report parser reads `ColDesc` headers and positional `ColData`/`RowData` (DataRow/SubtotalRow/TotalRow/TextRow) — never by ordinal guess.
- [ ] **READ-03**: List ops handle qbXML iterators (`Start`/`Continue`, `iteratorID`, `iteratorRemainingCount`) so large result sets come back complete; responses over a configured size threshold spill the raw qbXML to a file beside the audit log and return a reference + the parsed summary.
- [ ] **READ-04**: `op: company_info` returns company name, address, fiscal-year start, QuickBooks edition.
- [ ] **READ-05**: `op: get_company_preferences` returns sales-tax-enabled, decimal places, multi-currency-enabled, and the default A/R and A/P accounts.
- [ ] **READ-06**: `op: report` runs `ProfitAndLoss`, `BalanceSheet`, `AgingAR`, `AgingAP` over a date range (explicit dates or a date macro) and returns the parsed report.
- [ ] **READ-07**: `op: list_customers` / `list_vendors` / `list_items` / `list_accounts` return the lists (optional active-only / name filter); the item parser normalizes the polymorphic `ItemServiceRet`/`ItemInventoryRet`/… shapes.
- [ ] **READ-08**: `op: list_invoices` / `list_bills` / `list_payments` return the transactions filtered by date range and/or entity (customer/vendor).
- [ ] **READ-09**: `op: get_transaction` returns a transaction looked up by `TxnID` or `RefNumber` (handling that `RefNumber` is non-unique).
- [ ] **READ-10**: `op: run_query` runs a generic entity query (Employee, OtherName, SalesReceipt, Estimate, PurchaseOrder, CreditMemo, Deposit, Class, …) with filters and returns parsed rows.
- [ ] **READ-11**: Whether read ops pass `OwnerID="0"` (to include `DataExtRet` custom fields) is an explicit, documented config choice — not an accident.

### REST API, auth & health (API)

- [ ] **API-01**: The service binds HTTPS-only (Kestrel + a file `.pfx` cert) on a configurable URL/port; plain HTTP is refused.
- [ ] **API-02**: Every API call requires `Authorization: Bearer <token>` (token from config, compared with `CryptographicOperations.FixedTimeEquals`); missing/wrong → 401.
- [ ] **API-03**: `GET /api/health` reports liveness plus: company-file name, QuickBooks version, SDK version, supported qbXML versions (from `HostQueryRq`), last error, current mode, and the `AllowWrites` flag — and never reports "healthy" when the COM session is actually down.
- [ ] **API-04**: `POST /api/qbxml` accepts a raw qbXML request and returns the raw qbXML response (size-guarded); if `AllowWrites` is false the request is rejected with 403 when its qbXML contains an `Add`/`Mod`/`Del`/`Void` request — detected by parsing **element names**, not substring matching.
- [ ] **API-05**: `POST /api/ops/{op}` dispatches a high-level op through an `OpRegistry` (validates args, builds qbXML, executes, returns `200 { op, result }` where `result` carries the status fields); unknown op → 404.
- [ ] **API-06**: A `statusCode != 0` from QuickBooks is returned as a normal `200` body (it's a business outcome); HTTP 4xx/5xx are reserved for transport/auth/safety-gate/COM-unavailable.

### Write ops, dry-run & safety (WRITE)

- [ ] **WRITE-01**: `Safety:AllowWrites` defaults to **false**; while false every write op (`create_*`, `mod_*`, and raw qbXML containing `Add`/`Mod`/`Del`/`Void`) is rejected with 403 — enforced in the ops controller, the raw passthrough, and defensively in the connection manager.
- [ ] **WRITE-02**: `POST /api/ops/{op}/dryrun` returns the byte-exact qbXML that would be sent, a resolved-reference echo (names → ListID/TxnID/EditSequence), a plain-English summary (field-level before/after diff for `mod_*`), and pre-flight validation results (referenced entities exist? journal entry balanced? `AllowWrites` state? multi-currency refused?) — with **zero side effects**, and the `/dryrun` endpoint itself is **not** write-gated.
- [x] **WRITE-03**: `op: create_customer` / `create_vendor` add a customer/vendor.
- [x] **WRITE-04**: `op: create_invoice` / `create_bill` / `create_check` add the respective transaction.
- [x] **WRITE-05**: `op: receive_payment` records a customer payment against invoices.
- [x] **WRITE-06**: `op: create_journal_entry` adds a balanced journal entry (rejected pre-flight if it doesn't balance).
- [x] **WRITE-07**: `op: mod` updates an existing object by `ListID`/`TxnID` + `EditSequence` (full-replace semantics), using the `EditSequence` from a fresh read; a stale `EditSequence` (`3200`) is returned verbatim, never retried/auto-fixed.
- [ ] **WRITE-08**: Every **executed** write appends a record to an append-only, hash-chained audit log on the QuickBooks host (UTC timestamp, op, args, qbXML sent, response statusCode/severity/message, calling token id); the dry-run path writes nothing.

### Python client & Claude skill (CLIENT)

- [x] **CLIENT-01**: `quickbooks/clients/qb_client.py` is an HTTPS client (bearer token, `urllib3.Retry`, config from a gitignored `.env` with a committed `.env.sample`) exposing health, raw-qbXML, op, and dry-run helpers.
- [x] **CLIENT-02**: Runnable examples (`pull P&L`, `list invoices`, `create_customer` dry-run) and a pinned `requirements.txt` are included; `qb_client.py` has `pytest` tests against a stub HTTP server (`responses`).
- [x] **CLIENT-03**: A `quickbooks-accounting` Claude skill (`SKILL.md` + `references/qbxml-cheatsheet.md` + `references/setup-and-troubleshooting.md`) teaches: health check, the op catalog, how to run a read, the **safe write workflow** (dry-run → show qbXML + summary → explicit user confirm → execute → confirm result → note the audit row), and the raw-qbXML fallback.

### Multi-LLM dev tooling (DEV)

- [x] **DEV-01**: `quickbooks/dev/MULTI-LLM.md` documents the build pipeline (Claude researches + GSD-plans + reviews; Codex CLI executes code-gen from each phase's `PLAN.md`; DeepSeek-CC review recipe as an option) including the exact env vars and commands.
- [x] **DEV-02**: `quickbooks/dev/run-codex-phase.ps1` takes a phase's `PLAN.md` and invokes `codex` to implement it on the current branch (commit-per-task), so the plan→execute handoff is one command.

### Packaging, deploy & on-box verification (DEPLOY)

- [x] **DEPLOY-01**: `make-cert.ps1` generates the self-signed HTTPS cert; `install-service.ps1` / `uninstall-service.ps1` register/remove the Windows service running as `svc_qbsdk` with restart-on-crash; `run-as-task.ps1` is the documented session-0 fallback (startup scheduled task as `svc_qbsdk`). The scripts are authored and statically verified in dev/CI; execution remains a host operator step.
- [x] **DEPLOY-02**: All machine-specifics live only in gitignored `QbConnectService/appsettings.json` and `clients/.env`, each with a committed `.sample` version; nothing machine-specific is hardcoded in source.
- [x] **DEPLOY-03**: `register-integrated-app.md` documents the one-time QuickBooks-side authorization (Admin, single-user mode, "allow to login automatically", bound to `svc_qbsdk`, with the "Reauthorize" recovery path and the PII gotcha), and `README.md` is the full deploy runbook for `10.120.254.13` including the QBWC-fallback note and the HRESULT troubleshooting table.
- [x] **DEPLOY-04**: An on-box smoke checklist verifies, in order: `GET /api/health` → `company_info` → a `report` → `create_customer` **dry-run** (inspect the qbXML) → with `AllowWrites=true`, one real low-stakes write → confirm it in QuickBooks → confirm the audit-log row. The checklist records the environment facts to verify (QuickBooks Enterprise year/version, multi-user hosting status, `svc_qbsdk` account + "log on as a service" rights, firewall path for the HTTPS port). The checklist is authored here; the live run and any re-pin edits remain documented host operator follow-ups.

## v2 Requirements

- **V2-01**: Additional wrapped ops (employees, sales receipts, estimates, POs, credit memos, deposits) promoted from `run_query` to first-class ops as needed.
- **V2-02**: A session-keeper / always-up wrapper if the Task-Scheduler fallback proves insufficient for unattended operation.
- **V2-03**: Optional DeepSeek-backed research integrated into `/gsd:research-phase` rather than run as a separate session.

## Out of Scope

| Feature | Reason |
|---------|--------|
| QBWC-polled SOAP design | Superseded by direct COM; kept only as a fallback note in the service README |
| Payroll, inventory assemblies | Sensitive/complex; not core to v1 read+write value |
| Sales-tax filing | Regulatory surface; out of scope |
| Multi-currency specifics | Explicitly refused in pre-flight for v1 writes |
| Bidirectional / scheduled sync | Every call is operator/skill-initiated on demand |
| Batch / mega-request writes | Partial-failure semantics unsafe for an autonomous agent |
| First-class Delete/Void ops | Destructive — raw-qbXML only, never a wrapped op |
| Any UI / web front-end | Interfaces are the REST API and the Claude skill |
| Mapping the rest of the `tech-legal` repo | This is a new isolated subsystem |

## Traceability

Coverage: 44 / 44 v1 requirements mapped, each to exactly one phase. See `.planning/ROADMAP.md` for phase details.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SVC-01 | Phase 1 — Foundation & Mockable COM Seam | Pending |
| SVC-02 | Phase 1 — Foundation & Mockable COM Seam | Pending |
| SVC-03 | Phase 1 — Foundation & Mockable COM Seam | Pending |
| SVC-04 | Phase 1 — Foundation & Mockable COM Seam | Pending |
| SVC-05 | Phase 1 — Foundation & Mockable COM Seam | Pending |
| SESS-01 | Phase 2 — COM Session Lifecycle | Pending |
| SESS-02 | Phase 2 — COM Session Lifecycle | Pending |
| SESS-03 | Phase 2 — COM Session Lifecycle | Pending |
| SESS-04 | Phase 2 — COM Session Lifecycle | Pending |
| SESS-05 | Phase 2 — COM Session Lifecycle | Pending |
| READ-01 | Phase 3 — qbXML Engine | Pending |
| READ-02 | Phase 3 — qbXML Engine | Pending |
| READ-03 | Phase 3 — qbXML Engine | Pending |
| READ-11 | Phase 3 — qbXML Engine | Pending |
| READ-04 | Phase 4 — Read Ops | Pending |
| READ-05 | Phase 4 — Read Ops | Pending |
| READ-06 | Phase 4 — Read Ops | Pending |
| READ-07 | Phase 4 — Read Ops | Pending |
| READ-08 | Phase 4 — Read Ops | Pending |
| READ-09 | Phase 4 — Read Ops | Pending |
| READ-10 | Phase 4 — Read Ops | Pending |
| API-01 | Phase 5 — REST API, Auth & Health | Done |
| API-02 | Phase 5 — REST API, Auth & Health | Done |
| API-03 | Phase 5 — REST API, Auth & Health | Done |
| API-04 | Phase 5 — REST API, Auth & Health | Done |
| API-05 | Phase 5 — REST API, Auth & Health | Done |
| API-06 | Phase 5 — REST API, Auth & Health | Done |
| WRITE-01 | Phase 6 — Write Safety, Dry-Run & Audit | Done |
| WRITE-02 | Phase 6 — Write Safety, Dry-Run & Audit | Done |
| WRITE-08 | Phase 6 — Write Safety, Dry-Run & Audit | Done |
| WRITE-03 | Phase 7 — Write Ops | Done |
| WRITE-04 | Phase 7 — Write Ops | Done |
| WRITE-05 | Phase 7 — Write Ops | Done |
| WRITE-06 | Phase 7 — Write Ops | Done |
| WRITE-07 | Phase 7 — Write Ops | Done |
| CLIENT-01 | Phase 8 — Python Client, Claude Skill & Dev Tooling | Done |
| CLIENT-02 | Phase 8 — Python Client, Claude Skill & Dev Tooling | Done |
| CLIENT-03 | Phase 8 — Python Client, Claude Skill & Dev Tooling | Done |
| DEV-01 | Phase 8 — Python Client, Claude Skill & Dev Tooling | Done |
| DEV-02 | Phase 8 — Python Client, Claude Skill & Dev Tooling | Done |
| DEPLOY-01 | Phase 9 — Packaging, Deploy & On-Box Smoke | Done |
| DEPLOY-02 | Phase 9 — Packaging, Deploy & On-Box Smoke | Done |
| DEPLOY-03 | Phase 9 — Packaging, Deploy & On-Box Smoke | Done |
| DEPLOY-04 | Phase 9 — Packaging, Deploy & On-Box Smoke | Done |

---
*Requirements defined: 2026-05-11*
*Last updated: 2026-05-12 — Phase 9 deploy packaging complete (DEPLOY-01..04 done)*
