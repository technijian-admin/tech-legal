# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-11)

**Core value:** Claude can run a QuickBooks read and get an answer in seconds — and can create/update a transaction only after an explicit dry-run-and-confirm step, with every write in an immutable audit log.
**Current focus:** Phase 1 — Foundation & Mockable COM Seam

## Current Position

Phase: 1 of 9 (Foundation & Mockable COM Seam)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-05-11 — Roadmap created (9 phases, 44/44 v1 requirements mapped)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: —
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: 9-phase "seam → lifecycle → reads → API → writes → client → deploy" spine; reads split into qbXML engine (P3) + read ops (P4); writes split into safety/dry-run/audit (P6) + write ops (P7), per comprehensive depth.
- [Project]: Phases executed by Codex CLI from each PLAN.md, reviewed by Claude (multi-LLM pipeline) — keep success criteria concrete/verifiable.
- [Project]: COM behind `IRequestProcessor` so the .NET solution builds + full test suite runs with no QuickBooks SDK installed (phases 1–8 CI-able; only phase 9 needs host `10.120.254.13`).

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 2 & 9]: Environment facts unconfirmed — exact QuickBooks Enterprise build on `10.120.254.13` (pins qbXML spec ceiling + bitness), whether the `.QBW` is hosted multi-user, whether PII is enabled (could block unattended mode), `RequestProcessor` vs `RequestProcessor2` ProgID, `svc_qbsdk` creatability + "log on as a service" rights, firewall path for the HTTPS port.

## Session Continuity

Last session: 2026-05-12
Stopped at: Phases 1, 2, 3 & 4 COMPLETE (Codex-executed, Claude-reviewed, all 100/100; build + 106/106 tests green; reviews in docs/review/EXECUTIVE-SUMMARY.md). **Autonomous mode** — user asked to run the full loop to completion: for each remaining phase (5→9) run `/gsd:plan-phase N` (research→plan→checker) → `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase N` → review & fix to 100/100 → next. Next: Phase 5 (REST API, Auth & Health — API-01..06). Phase 9's on-box smoke run requires the live QuickBooks host (10.120.254.13 + SDK + integrated-app auth) so its checklist is built/reviewed but the live run is left for the user.
Resume file: None

**Quality bar (user expectation):** every phase review must land at 100/100. The reviewer scores the *code/functionality/quality*; a process nit (e.g. Codex using a duplicate commit message) is recorded as INFO — not a deduction — only when (a) the code is genuinely defect-free, (b) the proper fix isn't safely doable here (e.g. history rewrite on a pushed branch with concurrent unrelated automated git activity and no interactive rebase), AND (c) a durable forward-fix is in place (e.g. the `run-codex-phase.ps1` prompt now tells Codex to amend / use `fix(...)` when revising an already-committed task). Otherwise: fix it before declaring the phase done.

### Completed phases

- **Phase 1 — Foundation & Mockable COM Seam** (SVC-01..05): 3-project .NET 8 solution, `IRequestProcessor` seam, `[ComImport]` placeholder interop stub + throwing `RealRequestProcessor` stub, tri-mode host, `FakeRequestProcessor`, CI. Commits `6477ead`..`3d6426c`. Reviewed 100/100.
- **Phase 2 — COM Session Lifecycle** (SESS-01..05): `QbConnectionManager` (STA worker thread + `SemaphoreSlim(1,1)` gate + bounded busy-wait → `QbBusyException` + watchdog → `QbTimeoutException`+poison + dead-ticket → rebuild-COM-object + retry-once), `QbErrors` HRESULT map, `QbException`/`QbBusyException`/`QbTimeoutException`, `StaThread`, real `RealRequestProcessor` COM forwarder + activation-failure smoke test, DI wiring (`Func<IRequestProcessor>` → `RealRequestProcessor` on Windows-non-test; `QbConnectionManager` singleton `IAsyncDisposable`). Commits `00ce1a8`..`aca78bb` (incl. 2 same-message revision commits — INFO only, durable fix in the Codex prompt). Reviewed 100/100. Zero new NuGet packages.
- **Phase 3 — qbXML Engine** (READ-01,02,03,11): `QbXmlOptions` (relocated `OwnerIdZero` here from `QbOptions`; `Version`/`MaxReturned`/`MaxResponseBytes`/`SpillPath`), `QbXmlModels` (`QbStatus`/`ParsedElement`/`ParsedQbXmlResponse`/`ParsedReport`/...), `QbXmlBuilder` (pure — `<?xml?>` decl + `<?qbxml version?>` PI + `QBXMLMsgsRq onError` envelope via `XDocument.Save`; `WithIterator`/`WithOwnerIdZero`), `QbXmlParser` (pure — per-message+per-element status, zero-row=success, `DataExtRet`→`customFields`, polymorphic Item→`type`), `QbReportParser` (pure, separate — `ColDesc`-driven, `ColData` by `colID`), `QbResponseSpiller` (size-guard → spill to `SpillPath`??`Audit:Path`??`%TEMP%`), `QbListExecutor` (iterator Start→Continue loop over `QbConnectionManager`, accumulate, mid-iteration-error abort, spill-after-parse), 8 qbXML golden fixtures, `FakeRequestProcessor.AddResponses` multi-response queue + `ProcessRequests` capture, DI wiring. Commits `d2f130d`..`712818a` (8 distinct-titled `feat(03-01)` + `54b155c` `docs(03-01)` — no duplicate titles). Reviewed 100/100. Zero new NuGet packages. Test count 44→76. NOTE: the P&L report fixture is constructed (not live-captured) — Phase 9 should re-pin its `ColDesc`/`ColTitle`/`ColType` casing on the real host.
- **Phase 4 — Read Ops** (READ-04..10): `IReadOp` + `ReadOpBase` (`QuerySingleAsync`/`QueryListAsync`/`QueryReportAsync`/`ListResult`) + `ArgReader` + 12 ops in `Qb/Ops/` (`namespace QbConnectService.Qb.Ops`): `company_info` (Host+Company in one message, navigates by element name; edition from `HostRet.ProductName`), `get_company_preferences` (`PreferencesQueryRq` + AR/AP `AccountQueryRq` follow-up), `report` (one op, ProfitAndLoss/BalanceSheet → `GeneralSummaryReportQueryRq`, AgingAR/AgingAP → `AgingReportQueryRq`; exactly-one-of range|macro), `list_customers`/`list_vendors`/`list_accounts`/`list_items` (ActiveStatus+name filter via `QbListExecutor`; Item polymorphism free via parser `type`), `list_invoices`/`list_bills`/`list_payments` (`TxnDateRangeFilter`+entity filter via `QbListExecutor`), `get_transaction` (TxnID|RefNumber → `{matches,count,ambiguous}`, never collapses), `run_query` (hard-coded read-only-entity whitelist + key-validated simple-child filters; Company/Host/Preferences single-shot else `QbListExecutor`). All 12 registered as `IReadOp` singletons in `Program.cs` (so Phase 5's `OpRegistry` is `IEnumerable<IReadOp>`→dict). Plan revised once per plan-checker (3 real blockers caught & fixed pre-execution). Commits `26a522f`..`8e509ca` (8 distinct-titled `feat(04-01)` + `6b2cfc6` `docs(04-01)` — no dup titles; Codex committed its own SUMMARY+checkbox+ROADMAP). Reviewed 100/100. Zero new NuGet packages. Test count 76→106. NOTE: the new `*Rs` fixtures are constructed — Phase 9 re-pins qbXML element/enum names.
