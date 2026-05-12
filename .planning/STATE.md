# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-11)

**Core value:** Claude can run a QuickBooks read and get an answer in seconds — and can create/update a transaction only after an explicit dry-run-and-confirm step, with every write in an immutable audit log.
**Current focus:** Phase 8 — Python Client, Claude Skill & Dev Tooling

## Current Position

Phase: 8 of 9 (Python Client, Claude Skill & Dev Tooling)
Plan: 0 of TBD in current phase
Status: Phase 7 complete; ready to plan Phase 8
Last activity: 2026-05-12 — Phase 7 complete (all eight v1 write ops landed; Debug+Release build green, 255/255 tests green)

Progress: [████████░░] 78%

## Performance Metrics

**Velocity:**
- Total plans completed: 7
- Average duration: 1 plan per completed phase
- Total execution time: 7 sessions

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 1 | 1 | 1 |
| 2 | 1 | 1 | 1 |
| 3 | 1 | 1 | 1 |
| 4 | 1 | 1 | 1 |
| 5 | 1 | 1 | 1 |
| 6 | 1 | 1 | 1 |
| 7 | 1 | 1 | 1 |

**Recent Trend:**
- Last 5 plans: 03-01, 04-01, 05-01, 06-01, 07-01
- Trend: steady - each phase landed green and reviewed complete

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: 9-phase "seam → lifecycle → reads → API → writes → client → deploy" spine; reads split into qbXML engine (P3) + read ops (P4); writes split into safety/dry-run/audit (P6) + write ops (P7), per comprehensive depth.
- [Project]: Phases executed by Codex CLI from each PLAN.md, reviewed by Claude (multi-LLM pipeline) — keep success criteria concrete/verifiable.
- [Project]: COM behind `IRequestProcessor` so the .NET solution builds + full test suite runs with no QuickBooks SDK installed (phases 1–8 CI-able; only phase 9 needs host `10.120.254.13`).
- [Phase 5]: Minimal API route groups, not MVC controllers, define the `/api` surface.
- [Phase 5]: `/api/health` is bearer-gated because it exposes company-file and QuickBooks version facts.
- [Phase 5]: `SafetyOptions` and `QbWriteDetector` live in `QbConnectService.Qb.Com` so Phase 6 can reuse them.
- [Phase 5]: `/api/ops/{op}` returns `{ op, result }`; non-zero QuickBooks `statusCode` values stay in normal 200 bodies.
- [Phase 6]: `IWriteOp : IReadOp` and `WriteOpBase` landed before any production write op; the only Phase-6 write implementation is the test-only `FakeWriteOp`.
- [Phase 6]: `AllowWrites` is enforced in depth at the ops endpoint, the raw qbXML passthrough, and the connection manager, with `WriteOpBase` adding a fourth defensive belt.
- [Phase 6]: `AuditLog` writes executed-writes-only JSONL rows using canonical `Utf8JsonWriter` bytes, a 64-zero genesis `prevHash`, and `requesterId = tok-<8hex>`.
- [Phase 7]: The v1 write surface is seven thin `create_*` `WriteOpBase` subclasses plus one generic `mod` op; no new endpoints were added because `IWriteOp : IReadOp` plugs into the existing `OpRegistry` / `/api/ops/{op}` / `/dryrun` path.
- [Phase 7]: `mod` is intentionally one generic header-level-only op with fresh-read `EditSequence` semantics; stale `3200` responses are returned verbatim, audited once, and never retried.
- [Phase 7]: v1 write ops refuse `currencyRef` / `exchangeRate` up front and use constructed qbXML fixtures plus medium-confidence query/filter wrappers that Phase 9 re-pins against `10.120.254.13`.

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 2 & 9]: Environment facts unconfirmed — exact QuickBooks Enterprise build on `10.120.254.13` (pins qbXML spec ceiling + bitness), whether the `.QBW` is hosted multi-user, whether PII is enabled (could block unattended mode), `RequestProcessor` vs `RequestProcessor2` ProgID, `svc_qbsdk` creatability + "log on as a service" rights, firewall path for the HTTPS port.
- [Phase 9]: The qbXML write-verb enumeration and production `.pfx` flow still need live-host re-pin work.

## Session Continuity

Last session: 2026-05-12
Stopped at: Phases 1, 2, 3, 4, 5, 6 & 7 COMPLETE (Codex-executed, Debug+Release build green; tests 255/255 green after Phase 7). Next: Phase 8 (Python client, `quickbooks-accounting` skill, and dev tooling) against the now-stable eight-op write surface. Phase 9's on-box smoke run still requires the live QuickBooks host (`10.120.254.13` + SDK + integrated-app auth) so its checklist is built/reviewed but the live run is left for the user.
Resume file: None

**Quality bar (user expectation):** every phase review must land at 100/100. The reviewer scores the *code/functionality/quality*; a process nit (e.g. Codex using a duplicate commit message) is recorded as INFO — not a deduction — only when (a) the code is genuinely defect-free, (b) the proper fix isn't safely doable here (e.g. history rewrite on a pushed branch with concurrent unrelated automated git activity and no interactive rebase), AND (c) a durable forward-fix is in place (e.g. the `run-codex-phase.ps1` prompt now tells Codex to amend / use `fix(...)` when revising an already-committed task). Otherwise: fix it before declaring the phase done.

### Completed phases

- **Phase 1 — Foundation & Mockable COM Seam** (SVC-01..05): 3-project .NET 8 solution, `IRequestProcessor` seam, `[ComImport]` placeholder interop stub + throwing `RealRequestProcessor` stub, tri-mode host, `FakeRequestProcessor`, CI. Commits `6477ead`..`3d6426c`. Reviewed 100/100.
- **Phase 2 — COM Session Lifecycle** (SESS-01..05): `QbConnectionManager` (STA worker thread + `SemaphoreSlim(1,1)` gate + bounded busy-wait → `QbBusyException` + watchdog → `QbTimeoutException`+poison + dead-ticket → rebuild-COM-object + retry-once), `QbErrors` HRESULT map, `QbException`/`QbBusyException`/`QbTimeoutException`, `StaThread`, real `RealRequestProcessor` COM forwarder + activation-failure smoke test, DI wiring (`Func<IRequestProcessor>` → `RealRequestProcessor` on Windows-non-test; `QbConnectionManager` singleton `IAsyncDisposable`). Commits `00ce1a8`..`aca78bb` (incl. 2 same-message revision commits — INFO only, durable fix in the Codex prompt). Reviewed 100/100. Zero new NuGet packages.
- **Phase 3 — qbXML Engine** (READ-01,02,03,11): `QbXmlOptions` (relocated `OwnerIdZero` here from `QbOptions`; `Version`/`MaxReturned`/`MaxResponseBytes`/`SpillPath`), `QbXmlModels` (`QbStatus`/`ParsedElement`/`ParsedQbXmlResponse`/`ParsedReport`/...), `QbXmlBuilder` (pure — `<?xml?>` decl + `<?qbxml version?>` PI + `QBXMLMsgsRq onError` envelope via `XDocument.Save`; `WithIterator`/`WithOwnerIdZero`), `QbXmlParser` (pure — per-message+per-element status, zero-row=success, `DataExtRet`→`customFields`, polymorphic Item→`type`), `QbReportParser` (pure, separate — `ColDesc`-driven, `ColData` by `colID`), `QbResponseSpiller` (size-guard → spill to `SpillPath`??`Audit:Path`??`%TEMP%`), `QbListExecutor` (iterator Start→Continue loop over `QbConnectionManager`, accumulate, mid-iteration-error abort, spill-after-parse), 8 qbXML golden fixtures, `FakeRequestProcessor.AddResponses` multi-response queue + `ProcessRequests` capture, DI wiring. Commits `d2f130d`..`712818a` (8 distinct-titled `feat(03-01)` + `54b155c` `docs(03-01)` — no duplicate titles). Reviewed 100/100. Zero new NuGet packages. Test count 44→76. NOTE: the P&L report fixture is constructed (not live-captured) — Phase 9 should re-pin its `ColDesc`/`ColTitle`/`ColType` casing on the real host.
- **Phase 4 — Read Ops** (READ-04..10): `IReadOp` + `ReadOpBase` (`QuerySingleAsync`/`QueryListAsync`/`QueryReportAsync`/`ListResult`) + `ArgReader` + 12 ops in `Qb/Ops/` (`namespace QbConnectService.Qb.Ops`): `company_info` (Host+Company in one message, navigates by element name; edition from `HostRet.ProductName`), `get_company_preferences` (`PreferencesQueryRq` + AR/AP `AccountQueryRq` follow-up), `report` (one op, ProfitAndLoss/BalanceSheet → `GeneralSummaryReportQueryRq`, AgingAR/AgingAP → `AgingReportQueryRq`; exactly-one-of range|macro), `list_customers`/`list_vendors`/`list_accounts`/`list_items` (ActiveStatus+name filter via `QbListExecutor`; Item polymorphism free via parser `type`), `list_invoices`/`list_bills`/`list_payments` (`TxnDateRangeFilter`+entity filter via `QbListExecutor`), `get_transaction` (TxnID|RefNumber → `{matches,count,ambiguous}`, never collapses), `run_query` (hard-coded read-only-entity whitelist + key-validated simple-child filters; Company/Host/Preferences single-shot else `QbListExecutor`). All 12 registered as `IReadOp` singletons in `Program.cs` (so Phase 5's `OpRegistry` is `IEnumerable<IReadOp>`→dict). Plan revised once per plan-checker (3 real blockers caught & fixed pre-execution). Commits `26a522f`..`8e509ca` (8 distinct-titled `feat(04-01)` + `6b2cfc6` `docs(04-01)` — no dup titles; Codex committed its own SUMMARY+checkbox+ROADMAP). Reviewed 100/100. Zero new NuGet packages. Test count 76→106. NOTE: the new `*Rs` fixtures are constructed — Phase 9 re-pins qbXML element/enum names.
- **Phase 5 — REST API, Auth & Health** (API-01..06): `ServerOptions`/`AuthOptions`/`SafetyOptions`, HTTPS-only Kestrel bind with file-cert or dev-cert fallback, static bearer middleware over `/api` with `FixedTimeEquals`, global `IExceptionHandler` → `ProblemDetails`, `OpRegistry`, `GET /api/health`, `POST /api/qbxml`, `GET /api/ops`, `POST /api/ops/{op}`, reusable `QbWriteDetector`, and `WebApplicationFactory<Program>` integration coverage against the fake processor. Commits `d2234b3`..`54daaa6` (7 distinct-titled `feat(05-01)` task commits). Reviewed 100/100. One new test-only NuGet package: `Microsoft.AspNetCore.Mvc.Testing 8.0.*`. Test count 106→152. NOTE: the write-verb enumeration is MEDIUM-confidence and should be re-pinned on the live host in Phase 9; write-op widening is deferred to Phase 7.
- **Phase 6 — Write Safety, Dry-Run & Audit** (WRITE-01,02,08): hash-chained `AuditLog` + `AuditOptions`/`AuditAuthOptions`/`AuditRecord`, `IWriteOp`/`WriteOpBase`/`DryRunResult`, `QbWriteForbiddenException`, `POST /api/ops/{op}/dryrun`, and three-layer `AllowWrites` enforcement (ops endpoint, raw qbXML passthrough, defensive `QbConnectionManager`) landed before any real write op exists. **Phase 6 ships ZERO real write ops BY DESIGN**; the test-only `FakeWriteOp` exercises the machinery and Phase 7 adds the real `create_*` / `mod_*` ops. Commits `1d67f7f`..this docs commit. Zero new NuGet packages. Test count 152→181. NOTE: dry-run, refused 403 writes, and COM/parse failures append no audit rows; `VerifyChainAsync` reports a torn or malformed last line as a break in v1.
- **Phase 7 — Write Ops** (WRITE-03..07): `WriteOpBase` gained `FetchByNameAsync` / `FetchCurrentAsync`, `WriteOpHelpers.cs` added shared multi-currency rejection + ref/address/line builders, `ArgReader` gained `List` / `Decimal` / `RequiredString`, and eight production write ops landed: `create_customer`, `create_vendor`, `create_invoice`, `create_bill`, `create_check`, `receive_payment`, `create_journal_entry`, and generic `mod`. `Program.cs` now registers 20 `IReadOp` implementations total, and `OpRegistrationTests` asserts all eight write ops resolve and implement `IWriteOp`. Commits `4334825`..this docs commit. Zero new NuGet packages. Test count 181→255. NOTE: all new qbXML fixtures are constructed and carry the Phase-9 re-pin comment; `mod` is header-level-only in v1, refuses multi-currency, and never retries stale `3200` `EditSequence` responses.
