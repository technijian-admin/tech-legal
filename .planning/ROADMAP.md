# Roadmap: QuickBooks Enterprise Direct-SDK Accounting Integration

## Overview

This build walks the "seam → lifecycle → reads → API → writes → client → deploy" spine. It starts by establishing the mockable COM seam (`IRequestProcessor` + `FakeRequestProcessor`) and a CI-green skeleton, then brings up the real COM session lifecycle, then the qbXML read engine and all read ops, then the HTTPS/bearer REST API and health surface, then the write-safety machinery (AllowWrites gate, dry-run, hash-chained audit log) before any actual write ops, then the write ops themselves, then the Python client + `quickbooks-accounting` Claude skill + multi-LLM dev tooling, and finally packaging, deploy scripts, and the on-box smoke checklist against the live QuickBooks host (`10.120.254.13`). Phases 1–8 are fully buildable and testable against fakes with no QuickBooks installed; phase 9 is the only one that needs the actual host. Phases are executed by Codex CLI from each phase's `PLAN.md` and reviewed by Claude.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation & Mockable COM Seam** - Solution skeleton, `IRequestProcessor` + fake, x86 config, CI green with no QuickBooks
- [ ] **Phase 2: COM Session Lifecycle** - `QbConnectionManager` state machine on an STA worker thread, dead-ticket retry, `QbErrors`, real adapter
- [ ] **Phase 3: qbXML Engine** - `QbXmlBuilder` / `QbXmlParser`, separate report parser, iterators, size-guard spill, `OwnerID` config
- [ ] **Phase 4: Read Ops** - `company_info`, `get_company_preferences`, `report`, `list_*`, `get_transaction`, `run_query`
- [ ] **Phase 5: REST API, Auth & Health** - Kestrel HTTPS-only, bearer middleware, `/api/health`, raw `/api/qbxml` passthrough, `OpRegistry`
- [ ] **Phase 6: Write Safety, Dry-Run & Audit** - `AllowWrites` default-false 403 gate, `/api/ops/{op}/dryrun`, immutable hash-chained audit log
- [ ] **Phase 7: Write Ops** - `create_customer`/`vendor`/`invoice`/`bill`/`check`, `receive_payment`, `create_journal_entry`, `mod_*`
- [ ] **Phase 8: Python Client, Claude Skill & Dev Tooling** - `qb_client.py` + examples + tests, `quickbooks-accounting` skill, `MULTI-LLM.md` + `run-codex-phase.ps1`
- [ ] **Phase 9: Packaging, Deploy & On-Box Smoke** - cert/install/uninstall/task scripts, gitignored config + `.sample`s, integrated-app + deploy runbooks, live smoke checklist

## Phase Details

### Phase 1: Foundation & Mockable COM Seam
**Goal**: A .NET 8 solution that builds and runs its full test suite on a Windows box with no QuickBooks SDK installed, with the COM dependency isolated behind a swappable interface.
**Depends on**: Nothing (first phase)
**Requirements**: SVC-01, SVC-02, SVC-03, SVC-04, SVC-05
**Success Criteria** (what must be TRUE):
  1. `dotnet build` and `dotnet test` both succeed on a clean Windows machine with no QuickBooks SDK present, and the only project referencing `Interop.QBXMLRP2Lib.dll` is an isolated `Qb.Com` adapter project.
  2. A `FakeRequestProcessor` implements `IRequestProcessor`, returns canned qbXML responses, and can be scripted to raise specific COM-style errors — and a test exercises it.
  3. The service project targets `net8.0-windows`, publishes as a single x86 executable, and that one executable starts as a console app, can be registered as a Windows service, and can be launched by Task Scheduler with no code change.
  4. A CI workflow runs on push, builds the solution, runs all tests, and is green without QuickBooks installed on the runner.
**Plans**: TBD

Plans:
- [ ] 01-01: TBD

### Phase 2: COM Session Lifecycle
**Goal**: A long-lived connection manager that owns the real QuickBooks COM connection+session lifecycle correctly, serializes all COM calls, recovers from a dropped session exactly once, and translates QuickBooks HRESULTs into actionable messages.
**Depends on**: Phase 1
**Requirements**: SESS-01, SESS-02, SESS-03, SESS-04, SESS-05
**Success Criteria** (what must be TRUE):
  1. A `QbConnectionManager` singleton drives `OpenConnection2 → BeginSession → ProcessRequest → EndSession → CloseConnection`, opens lazily on first use, and uses `OpenMode = DoNotCare`, `connectionType = localQBD`, never `SingleUser` — verified via the fake processor.
  2. All COM calls run on one dedicated STA worker thread serialized through a `SemaphoreSlim(1,1)`; a concurrent request waits a bounded time then gets `409 Busy`.
  3. On a simulated dead ticket / dropped session the manager rebuilds the COM object and retries exactly once, then surfaces the QuickBooks error verbatim (no second retry).
  4. A `QbErrors` map turns the `0x8004xxxx` family plus "Class not registered" / `RequestProcessor2`-cast cases into a human message + remediation hint, and that mapping shows up in API/health responses.
  5. A watchdog aborts a `ProcessRequest` that exceeds the configured timeout and returns a clear timeout error without leaving the session wedged.
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: qbXML Engine
**Goal**: Pure, I/O-free qbXML request building and response parsing — including a dedicated header-aware report parser, iterator handling, and a size-guard that spills oversized raw qbXML to disk — all unit-testable on a dev box against the fake.
**Depends on**: Phase 2
**Requirements**: READ-01, READ-02, READ-03, READ-11
**Success Criteria** (what must be TRUE):
  1. `QbXmlBuilder` always emits the `<?qbxml version="N.N"?>` PI from config; `QbXmlParser` returns clean JSON and surfaces per-element and per-message `statusCode`/`statusSeverity`/`statusMessage`, and a zero-row result parses as success, not an error.
  2. A separate report parser reads `ColDesc` headers and positional `ColData`/`RowData` (DataRow/SubtotalRow/TotalRow/TextRow) with no ordinal guessing — covered by sample-response golden tests.
  3. List parsing follows qbXML iterators (`Start`/`Continue`, `iteratorID`, `iteratorRemainingCount`) so a multi-page result comes back complete; a response over the configured size threshold spills the raw qbXML to a file beside the audit log and returns a reference plus the parsed summary.
  4. Whether read requests pass `OwnerID="0"` (to include `DataExtRet` custom fields) is a documented config setting with a sensible default — not implicit.
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

### Phase 4: Read Ops
**Goal**: Every v1 read operation implemented on top of the qbXML engine and exercised end-to-end against the fake processor.
**Depends on**: Phase 3
**Requirements**: READ-04, READ-05, READ-06, READ-07, READ-08, READ-09, READ-10
**Success Criteria** (what must be TRUE):
  1. `op: company_info` returns company name, address, fiscal-year start, and QuickBooks edition; `op: get_company_preferences` returns sales-tax-enabled, decimal places, multi-currency-enabled, and the default A/R and A/P accounts.
  2. `op: report` runs `ProfitAndLoss`, `BalanceSheet`, `AgingAR`, and `AgingAP` over an explicit date range or a date macro and returns the parsed report.
  3. `op: list_customers` / `list_vendors` / `list_items` / `list_accounts` return the lists with optional active-only / name filtering, and the item parser normalizes the polymorphic `ItemServiceRet`/`ItemInventoryRet`/… shapes.
  4. `op: list_invoices` / `list_bills` / `list_payments` return transactions filtered by date range and/or entity, and `op: get_transaction` looks up a transaction by `TxnID` or `RefNumber` (handling that `RefNumber` is non-unique).
  5. `op: run_query` runs a generic entity query (Employee, OtherName, SalesReceipt, Estimate, PurchaseOrder, CreditMemo, Deposit, Class, …) with filters and returns parsed rows.
**Plans**: TBD

Plans:
- [ ] 04-01: TBD

### Phase 5: REST API, Auth & Health
**Goal**: An HTTPS-only, bearer-authenticated REST surface that exposes health, a raw qbXML passthrough, and high-level op dispatch — with HTTP status codes used only for transport/auth/safety/COM-availability and QuickBooks business outcomes returned as 200s.
**Depends on**: Phase 4
**Requirements**: API-01, API-02, API-03, API-04, API-05, API-06
**Success Criteria** (what must be TRUE):
  1. The service binds HTTPS-only via Kestrel with a file `.pfx` cert on a configurable URL/port and refuses plain HTTP; every API call requires `Authorization: Bearer <token>` compared with `CryptographicOperations.FixedTimeEquals`, and a missing/wrong token gets 401.
  2. `GET /api/health` reports liveness plus company-file name, QuickBooks version, SDK version, supported qbXML versions (from `HostQueryRq`), last error, current mode, and the `AllowWrites` flag — and never reports "healthy" when the COM session is actually down.
  3. `POST /api/qbxml` accepts a raw qbXML request and returns the raw qbXML response (size-guarded); when `AllowWrites` is false a request whose qbXML contains an `Add`/`Mod`/`Del`/`Void` request — detected by parsing element names, not substrings — is rejected with 403.
  4. `POST /api/ops/{op}` dispatches through an `OpRegistry` (validates args, builds qbXML, executes, returns parsed JSON plus the raw qbXML plus the status fields); an unknown op returns 404; a `statusCode != 0` from QuickBooks comes back as a normal 200 body.
  5. `WebApplicationFactory` integration tests against the fake processor cover health, auth (401), the raw passthrough (including the 403 verb-scan), and op dispatch (including 404 and the 200-with-nonzero-statusCode case).
**Plans**: TBD

Plans:
- [ ] 05-01: TBD

### Phase 6: Write Safety, Dry-Run & Audit
**Goal**: The full write-safety machinery — a default-off AllowWrites gate enforced in depth, a zero-side-effect dry-run endpoint, and an immutable hash-chained audit log — landed before any write op exists.
**Depends on**: Phase 5
**Requirements**: WRITE-01, WRITE-02, WRITE-08
**Success Criteria** (what must be TRUE):
  1. `Safety:AllowWrites` defaults to false; while false, every write op (`create_*`, `mod_*`, and raw qbXML containing `Add`/`Mod`/`Del`/`Void`) is rejected with 403 — enforced in the ops controller, in the raw passthrough, and defensively in the connection manager — and a test proves all three layers.
  2. `POST /api/ops/{op}/dryrun` returns the byte-exact qbXML that would be sent, a resolved-reference echo (names → ListID/TxnID/EditSequence), a plain-English summary (field-level before/after diff for `mod_*`), and pre-flight validation results (referenced entities exist? journal entry balanced? `AllowWrites` state? multi-currency refused?) — with zero side effects.
  3. The `/dryrun` endpoint is itself not write-gated: it works and writes nothing even when `AllowWrites` is false.
  4. Every executed write appends a record to an append-only, hash-chained audit log on the QuickBooks host (UTC timestamp, op, args, qbXML sent, response statusCode/severity/message, calling token id); the dry-run path appends nothing; a test verifies a tampered row breaks the hash chain.
**Plans**: TBD

Plans:
- [ ] 06-01: TBD

### Phase 7: Write Ops
**Goal**: Every v1 write operation implemented behind the safety gate, dry-run, and audit log, with stale-`EditSequence` and full-replace `mod_*` semantics handled correctly.
**Depends on**: Phase 6
**Requirements**: WRITE-03, WRITE-04, WRITE-05, WRITE-06, WRITE-07
**Success Criteria** (what must be TRUE):
  1. `op: create_customer` / `create_vendor` add a customer/vendor; `op: create_invoice` / `create_bill` / `create_check` add the respective transaction (all exercised via dry-run + a gated execute against the fake).
  2. `op: receive_payment` records a customer payment against invoices.
  3. `op: create_journal_entry` adds a balanced journal entry and is rejected at pre-flight when it doesn't balance.
  4. `op: mod_*` updates an existing object by `ListID`/`TxnID` + `EditSequence` with full-replace semantics, using an `EditSequence` from a fresh read; a stale `EditSequence` (`0x800404C5`) is returned verbatim, never retried or auto-fixed.
  5. Each executed write in these ops produces exactly one audit-log row; each dry-run produces none — verified by tests.
**Plans**: TBD

Plans:
- [ ] 07-01: TBD

### Phase 8: Python Client, Claude Skill & Dev Tooling
**Goal**: A workstation-side Python client, the `quickbooks-accounting` Claude skill that drives the API safely, and the documented multi-LLM build pipeline tooling.
**Depends on**: Phase 7
**Requirements**: CLIENT-01, CLIENT-02, CLIENT-03, DEV-01, DEV-02
**Success Criteria** (what must be TRUE):
  1. `quickbooks/clients/qb_client.py` is an HTTPS client (bearer token, `urllib3.Retry`, config from a gitignored `.env` with a committed `.env.sample`) exposing health, raw-qbXML, op, and dry-run helpers; runnable examples (`pull P&L`, `list invoices`, `create_customer` dry-run) and a pinned `requirements.txt` are included.
  2. `qb_client.py` has `pytest` tests against a stub HTTP server (`responses`) that pass.
  3. A `quickbooks-accounting` Claude skill exists (`SKILL.md` + `references/qbxml-cheatsheet.md` + `references/setup-and-troubleshooting.md`) teaching the health check, the op catalog, how to run a read, the safe write workflow (dry-run → show qbXML + summary → explicit user confirm → execute → confirm result → note the audit row), and the raw-qbXML fallback.
  4. `quickbooks/dev/MULTI-LLM.md` documents the build pipeline (Claude researches + GSD-plans + reviews; Codex CLI executes from each phase's `PLAN.md`; the DeepSeek-CC review recipe as an option) with the exact env vars and commands, and `quickbooks/dev/run-codex-phase.ps1` takes a phase's `PLAN.md` and invokes `codex` to implement it on the current branch (commit-per-task).
**Plans**: TBD

Plans:
- [ ] 08-01: TBD

### Phase 9: Packaging, Deploy & On-Box Smoke
**Goal**: Everything needed to install, configure, and verify the service on the live QuickBooks host — deploy scripts, portable config, runbooks, and an ordered on-box smoke checklist culminating in one real low-stakes write confirmed in QuickBooks and in the audit log.
**Depends on**: Phase 8
**Requirements**: DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04
**Success Criteria** (what must be TRUE):
  1. `make-cert.ps1` generates the self-signed HTTPS cert; `install-service.ps1` / `uninstall-service.ps1` register/remove the Windows service running as `svc_qbsdk` with restart-on-crash; `run-as-task.ps1` provides the documented session-0 startup-task fallback.
  2. All machine-specifics live only in gitignored `QbConnectService/appsettings.json` and `clients/.env`, each with a committed `.sample` version; nothing machine-specific is hardcoded in source.
  3. `register-integrated-app.md` documents the one-time QuickBooks-side authorization (Admin, single-user mode, "allow to login automatically", bound to `svc_qbsdk`, with the "Reauthorize" recovery path and the PII gotcha), and `README.md` is the full `10.120.254.13` deploy runbook including the QBWC-fallback note and the HRESULT troubleshooting table.
  4. An on-box smoke checklist verifies, in order, `GET /api/health` → `company_info` → a `report` → `create_customer` dry-run (inspect the qbXML) → with `AllowWrites=true`, one real low-stakes write → confirm it in QuickBooks → confirm the audit-log row — and records the environment facts to verify (QuickBooks Enterprise year/version, multi-user hosting status, `svc_qbsdk` account + "log on as a service" rights, firewall path for the HTTPS port).
**Plans**: TBD

Plans:
- [ ] 09-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Mockable COM Seam | 0/TBD | Not started | - |
| 2. COM Session Lifecycle | 0/TBD | Not started | - |
| 3. qbXML Engine | 0/TBD | Not started | - |
| 4. Read Ops | 0/TBD | Not started | - |
| 5. REST API, Auth & Health | 0/TBD | Not started | - |
| 6. Write Safety, Dry-Run & Audit | 0/TBD | Not started | - |
| 7. Write Ops | 0/TBD | Not started | - |
| 8. Python Client, Claude Skill & Dev Tooling | 0/TBD | Not started | - |
| 9. Packaging, Deploy & On-Box Smoke | 0/TBD | Not started | - |
