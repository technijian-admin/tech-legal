# QuickBooks Direct-SDK Accounting Integration — Roadmap

## Phases

- [x] **Phase 1: Foundation & Mockable COM Seam** - .NET 8 solution, IRequestProcessor seam, FakeRequestProcessor, tri-mode host, CI
- [x] **Phase 2: COM Session Lifecycle** - QbConnectionManager (STA thread, gate, watchdog, dead-ticket rebuild), QbErrors map
- [x] **Phase 3: qbXML Engine** - QbXmlBuilder/Parser, report parser, iterators, size-guard spill
- [x] **Phase 4: Read Ops** - 12 read ops (company_info, reports, list_*, get_transaction, run_query)
- [x] **Phase 5: REST API, Auth & Health** - minimal API (/api/health, /api/qbxml, /api/ops, /api/ops/{op}, /api/ops/{op}/dryrun), bearer auth, ProblemDetails
- [x] **Phase 6: Write Safety, Dry-Run & Audit** - AllowWrites gate, dry-run (byte-exact qbXML + preFlight), audit log, currencyRef/exchangeRate refusal
- [x] **Phase 7: Write Ops** - 8 write ops (create_customer/vendor/invoice/bill/check, receive_payment, create_journal_entry, mod)
- [x] **Phase 8: Python Client, Claude Skill & Dev Tooling** - `qb_client.py` + examples + tests, `quickbooks-accounting` skill, `MULTI-LLM.md` + `run-codex-phase.ps1`
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
**Plans**: 1 plan

Plans:
- [ ] 01-01-PLAN.md — Scaffold solution + 3 projects, IRequestProcessor seam, FakeRequestProcessor + RealRequestProcessor stub, tri-mode host, tests, CI

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
**Plans**: 1 plan

Plans:
- [ ] 02-01-PLAN.md — COM session lifecycle: QbConnectionManager (STA thread, SemaphoreSlim gate, watchdog, dead-ticket rebuild+retry-once), QbErrors map, RealRequestProcessor adapter, DI wiring

### Phase 3: qbXML Engine
**Goal**: Pure, I/O-free qbXML request building and response parsing — including a dedicated header-aware report parser, iterator handling, and a size-guard that spills oversized raw qbXML to disk — all unit-testable on a dev box against the fake.
**Depends on**: Phase 2
**Requirements**: READ-01, READ-02, READ-03, READ-11
**Success Criteria** (what must be TRUE):
  1. `QbXmlBuilder` always emits the `<?qbxml version="N.N"?>` PI from config; `QbXmlParser` returns clean JSON and surfaces per-element and per-message `statusCode`/`statusSeverity`/`statusMessage`, and a zero-row result parses as success, not an error.
  2. A separate report parser reads `ColDesc` headers and positional `ColData`/`RowData` (DataRow/SubtotalRow/TotalRow/TextRow) with no ordinal guessing — covered by sample-response golden tests.
  3. Iterators are driven correctly (`iterator="Start"`/`"Continue"`, `iteratorID`, `iteratorRemainingCount`) and a multi-page list is reassembled.
  4. An oversized raw qbXML response spills to a configured disk path and the JSON result carries a `rawSpilledTo` pointer instead of the whole blob.
**Plans**: 1 plan

Plans:
- [ ] 03-01-PLAN.md — qbXML engine: QbXmlBuilder (PI from config), QbXmlParser (status surfacing), report parser (ColDesc-driven), iterator handling, size-guard spill

### Phase 4: Read Ops
**Goal**: The twelve read operations, each a thin builder+parser composition over the qbXML engine, registered in an op registry and unit-tested against canned responses.
**Depends on**: Phase 3
**Requirements**: READ-04, READ-05, READ-06, READ-07, READ-08, READ-09, READ-10
**Success Criteria** (what must be TRUE):
  1. `company_info`, `get_company_preferences`, `report` (P&L/BalanceSheet/AgingAR/AgingAP), `list_customers`/`list_vendors`/`list_accounts`/`list_items`, `list_invoices`/`list_bills`/`list_payments`, `get_transaction`, `run_query` all exist as ops in an `OpRegistry`, each callable by name with a JSON args dict.
  2. Each op composes a `QbXmlBuilder` request and a `QbXmlParser`/report-parser response with no direct COM access; all are unit-tested against canned qbXML.
  3. `report` accepts exactly one of (`fromDate`+`toDate`) or `dateMacro`; `get_transaction` accepts exactly one of `txnId`/`refNumber` and always returns a list (never collapses); `run_query` enforces the read-only entity whitelist and validates filter keys.
  4. List ops are iterator-driven and normalize polymorphic rows (e.g. item subtypes).
**Plans**: 1 plan

Plans:
- [ ] 04-01-PLAN.md — 12 read ops + OpRegistry: company_info, get_company_preferences, report, list_*, get_transaction, run_query — builders + parsers + canned-response tests

### Phase 5: REST API, Auth & Health
**Goal**: A minimal HTTPS REST API over the op layer — health, raw-qbXML passthrough, op listing, op invocation, dry-run — with bearer-token auth and RFC-7807 error bodies.
**Depends on**: Phase 4
**Requirements**: API-01, API-02, API-03, API-04, API-05, API-06
**Success Criteria** (what must be TRUE):
  1. `GET /api/health` returns the live COM session state (never lies — it probes), `GET /api/ops` lists the registered ops, `POST /api/qbxml` passes raw qbXML through, `POST /api/ops/{op}` invokes an op with a JSON args body, `POST /api/ops/{op}/dryrun` returns the would-be qbXML + preFlight without side effects.
  2. Every `/api/*` call requires `Authorization: Bearer <token>`; missing/wrong → `401` with a `ProblemDetails` body and `WWW-Authenticate: Bearer`.
  3. All errors are RFC-7807 `ProblemDetails` (`status`/`title`/`detail`, plus `qbErrorCode` on QuickBooks COM errors); a non-zero qbXML `statusCode` is NOT an HTTP error (it rides inside `result.status` on a `200`).
  4. The API-06 invariant holds: the only way to reach QuickBooks is through the op layer or the explicit raw-qbXML endpoint — nothing bypasses the connection manager.
**Plans**: 1 plan

Plans:
- [ ] 05-01-PLAN.md — Minimal API (health/qbxml/ops/ops-{op}/ops-{op}-dryrun), BearerAuthMiddleware, ApiExceptionHandler (ProblemDetails), DI wiring, integration tests

### Phase 6: Write Safety, Dry-Run & Audit
**Goal**: The write-safety substrate — a global `AllowWrites` gate, a dry-run that returns byte-exact qbXML plus pre-flight checks with zero side effects, an append-only audit log of every write, and an up-front refusal of multi-currency args.
**Depends on**: Phase 5
**Requirements**: WRITE-01, WRITE-02, WRITE-03, WRITE-04
**Success Criteria** (what must be TRUE):
  1. With `Safety:AllowWrites=false`, any write op (or a raw qbXML body containing `Add`/`Mod`/`Del`/`Void`) returns `403` with a `ProblemDetails` "Writes disabled"; with `true`, writes proceed.
  2. `POST /api/ops/{op}/dryrun` returns `{ qbXml, summary, preFlight: [{name, ok, detail}], resolvedReferences, allowWrites }` for write ops — byte-exact qbXML, zero side effects, works even when `AllowWrites=false`; for read ops it returns a preview with `summary: null`.
  3. Every executed write is appended to an audit log (timestamp, op, args, resulting qbXML, status, an `auditSeq`).
  4. A write op with `currencyRef` or `exchangeRate` in its args (or `fields`) is refused up front with a clear message — multi-currency is out of scope for v1.
**Plans**: 1 plan

Plans:
- [ ] 06-01-PLAN.md — Write safety: AllowWrites gate, dry-run (byte-exact qbXML + preFlight + resolvedReferences), append-only audit log, currencyRef/exchangeRate refusal, tests

### Phase 7: Write Ops
**Goal**: The eight write operations — seven `*Add` ops plus one generic header-level `mod` — each with pre-flight validation, dry-run support, audit logging, and full unit-test coverage against the fake.
**Depends on**: Phase 6
**Requirements**: WRITE-05, WRITE-06, WRITE-07, WRITE-08, WRITE-09
**Success Criteria** (what must be TRUE):
  1. `create_customer`, `create_vendor`, `create_invoice`, `create_bill`, `create_check`, `receive_payment`, `create_journal_entry` build the right `*Add` requests (with reference resolution, line items where applicable), and `mod` does a header-level full-replace using an `EditSequence` fetched from a fresh server-side read.
  2. Each write op has pre-flight checks (e.g. journal entry debits == credits, receive_payment applied amounts vs total) surfaced in the dry-run; a failed pre-flight blocks execution.
  3. A stale `EditSequence` on `mod` comes back as qbXML `statusCode=3200` (severity Error) verbatim in `result.status`, audited once, never auto-retried.
  4. All eight ops are unit-tested against the fake (dry-run qbXML golden tests + execute-path tests + pre-flight-failure tests).
**Plans**: 1 plan

Plans:
- [ ] 07-01-PLAN.md — 8 write ops: create_customer/vendor/invoice/bill/check, receive_payment, create_journal_entry, generic mod — builders + pre-flight + dry-run + audit + fake tests

### Phase 8: Python Client, Claude Skill & Dev Tooling
**Goal**: A workstation-side Python client, the `quickbooks-accounting` Claude skill that drives the API safely, and the documented multi-LLM build pipeline tooling.
**Depends on**: Phase 7
**Requirements**: CLIENT-01, CLIENT-02, CLIENT-03, DEV-01, DEV-02
**Success Criteria** (what must be TRUE):
  1. `quickbooks/clients/qb_client.py` is an HTTPS client (bearer token, `urllib3.Retry`, config from a gitignored `.env` with a committed `.env.sample`) exposing health, raw-qbXML, op, and dry-run helpers; runnable examples (`pull P&L`, `list invoices`, `create_customer` dry-run) and a pinned `requirements.txt` are included.
  2. `qb_client.py` has `pytest` tests against a stub HTTP server (`responses`) that pass.
  3. A `quickbooks-accounting` Claude skill exists (`SKILL.md` + `references/qbxml-cheatsheet.md` + `references/setup-and-troubleshooting.md`) teaching the health check, the op catalog, how to run a read, the safe write workflow (dry-run → show qbXML + summary → explicit user confirm → execute → confirm result → note the audit row), and the raw-qbXML fallback.
  4. `quickbooks/dev/MULTI-LLM.md` documents the build pipeline (Claude researches + GSD-plans + reviews; Codex CLI executes from each phase's `PLAN.md`; the DeepSeek-CC review recipe as an option) with the exact env vars and commands, and `quickbooks/dev/run-codex-phase.ps1` takes a phase's `PLAN.md` and invokes `codex` to implement it on the current branch (commit-per-task).
**Plans**: 1 plan

Plans:
- [x] 08-01-PLAN.md — Python qb_client + examples + tests, quickbooks-accounting skill, hardened MULTI-LLM.md + run-codex-phase.ps1, python-client CI job

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
| 1. Foundation & Mockable COM Seam | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-12 |
| 2. COM Session Lifecycle | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-12 |
| 3. qbXML Engine | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-12 |
| 4. Read Ops | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-11 |
| 5. REST API, Auth & Health | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-11 |
| 6. Write Safety, Dry-Run & Audit | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-12 |
| 7. Write Ops | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-12 |
| 8. Python Client, Claude Skill & Dev Tooling | 1/1 | ✓ Complete (reviewed 100/100) | 2026-05-12 |
| 9. Packaging, Deploy & On-Box Smoke | 0/TBD | Not started | - |
