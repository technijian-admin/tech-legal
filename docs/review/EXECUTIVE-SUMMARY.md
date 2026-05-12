# Code Review — Executive Summary

**Subsystem:** QuickBooks Enterprise Direct-SDK Integration — **Phase 1: Foundation & Mockable COM Seam**
**Branch:** `quickbooks/direct-sdk-integration-2026-05-11`
**Date:** 2026-05-12
**Reviewer:** Claude (post-Codex-execution review; Codex executed `01-01-PLAN.md`, 7 tasks + 1 CI fix)
**Health Score:** **100 / 100 (Grade A — ready to proceed to Phase 2)**

> **Update 2026-05-12 (post-review remediation):** both LOW findings resolved. LOW-1 (executor left `01-01-PLAN.md`/`01-01-SUMMARY.md` uncommitted) → committed as `9f3bab4`. LOW-2 (`bin`/`obj`/`publish` build artifacts in the working tree) → `git clean -fdX quickbooks/` removed them; they're gitignored, so they'll naturally reappear on the next `dotnet build` (Phase 2) and that is expected and fine. Score raised to 100/100.

## Scope of this review

This is a review of a single GSD phase that produced a **.NET solution skeleton + the mockable COM seam + fakes + CI** — nothing above the COM boundary exists yet (no REST API, no DB, no frontend, no auth, no qbXML engine, no ops). So the full `/gsd:code-review` cross-cutting machinery does not apply:

| Cross-cutting analysis | Status |
|---|---|
| Layer review (.NET backend skeleton) | ✅ Done (see `layers/dotnet-backend-findings.md`) |
| Traceability matrix (UI→API→DB) | N/A — no UI / API / DB layers yet (Phases 4–7) |
| Contract alignment (FE↔BE DTOs) | N/A — no DTOs or frontend yet |
| Dead-code analysis | N/A — 16 source files, all referenced; the only "stub" code (`RealRequestProcessor` throwing, `QBXMLRP2Lib.cs` placeholder GUIDs) is intentionally so and flagged in-file |

## Build status

| Check | Result |
|---|---|
| `dotnet build QbConnectService.sln -c Release` (local, .NET 10 SDK building `net8.0-windows`) | **PASS** — 0 errors, 0 warnings |
| `dotnet test QbConnectService.sln -c Release` | **PASS** — 7/7 tests passed, 0 failed |
| GitHub Actions `quickbooks-ci` (windows-latest, .NET 8 SDK, no QuickBooks) | **PASS** — run `25708034197` = `success` (an earlier run failed on a missing `-r win-x86` restore; Codex's `3d6426c` fixed it and the re-run passed) |

## Requirement coverage (SVC-01..SVC-05)

| Req | Verified |
|---|---|
| SVC-01: builds + tests SDK-free; interop confined to `Qb.Com` | ✅ `[ComImport]` appears only in `Qb.Com/Interop/QBXMLRP2Lib.cs`; host references `Qb.Com`; test project references **only** the host (`ProjectReference` comment + verified) |
| SVC-02: `FakeRequestProcessor : IRequestProcessor`, canned responses keyed by `*Rq`, scriptable COM errors, a test exercises it | ✅ `FakeRequestProcessor.cs` (109 lines) + 4 tests (lifecycle / canned-response / scripted-COM-error-then-drained / unscripted-throws) |
| SVC-03: `net8.0-windows`, single x86 exe; `BuildConfigTests` asserts it | ✅ host `.csproj` has `PlatformTarget=x86` + `RuntimeIdentifier=win-x86` + Release `PublishSingleFile`; `BuildConfigTests` asserts `Machine.I386` + `CorFlags.Requires32Bit` + `net8.0` + `windows` target — passing |
| SVC-04: same exe = console / Windows service / scheduled task; `HostStartupTests` passes | ✅ `Program.cs` calls `AddWindowsService()`; `HostStartupTests` proves clean start/stop; `dotnet publish -r win-x86 -p:PublishSingleFile=true` produces a single `QbConnectService.exe` |
| SVC-05: path-filtered `quickbooks-ci.yml` builds + tests on push, green with no QuickBooks | ✅ workflow on `windows-latest`, path-filtered to `quickbooks/QbConnectService/**`, last run green |

## Repo hygiene

✅ `.gitignore` was **appended** (original 6 lines intact) with the real `appsettings.json` / `clients/.env` / `quickbooks/**/bin/`,`obj/`,`publish/` ignores. ✅ Only `appsettings.sample.json` is committed — no real `appsettings.json` exists. ✅ No nested `.git` under `quickbooks/`. ✅ 16 source files tracked; build artifacts untracked. ✅ One atomic commit per task (8 commits: 7 tasks + 1 CI fix). ✅ Stayed on the feature branch; nothing outside `quickbooks/`, `.github/workflows/quickbooks-ci.yml`, `.gitignore`, `.planning/phases/01-*` touched.

## Scope discipline

✅ **Zero Phase 2–9 work present.** No `QbConnectionManager`, no STA worker thread / retry logic / `QbErrors`, no `QbXmlBuilder`/`QbXmlParser` or report parser, no controllers (just an `app.MapGet("/")` placeholder), no Kestrel HTTPS binding, no bearer auth, no `AllowWrites` enforcement code, no audit log, no Python client, no Claude skill, no deploy scripts. `RealRequestProcessor` correctly throws `NotImplementedException`; `QBXMLRP2Lib.cs` is correctly a compile-only placeholder stub — both flagged in-file for the Phase 2 author.

## Findings

| Severity | Count |
|---|---|
| Blocker | 0 |
| High | 0 |
| Medium | 0 |
| Low | 2 |
| Info (documented, no action) | 3 |

**LOW-1** — The executor left Phase-1 output uncommitted: `01-01-PLAN.md` (task checkboxes ticked) is modified and `01-01-SUMMARY.md` is untracked. Fix: commit both (one commit, scoped to `.planning/phases/01-*`).
**LOW-2** — `bin/`/`obj/`/`publish/` build artifacts sit in the working tree (correctly gitignored, but clutter, especially with another team's automated work also using this checkout). Fix (optional): `git clean -fdX quickbooks/` to remove ignored artifacts.

**INFO** — (a) `QbConnectService.Tests.csproj` targets `net8.0-windows` + `PlatformTarget=x86` (plan said plain `net8.0`); justified — a `net8.0` test project can't reference a `net8.0-windows` host and an x86 host assembly can't load under the default x64 test host. (b) An extra CI-only commit was needed after the first remote run failed (restore lacked `-r win-x86` so `windows-latest` didn't fetch the x86 runtime packs before `--no-build`); fixed. (c) `IRequestProcessor.cs` lives in `QbConnectService.Qb.Com` (namespace stays `QbConnectService.Qb`) rather than the host — the plan anticipated and allowed this (avoids a circular reference; host + tests see it transitively).

## Recommendation

**Proceed to Phase 2.** Phase 1 is solid: build + tests + CI green, requirements met, scope clean, hygiene clean, deviations documented and reasonable. Fix LOW-1 (commit the dangling Phase-1 output) first — it's trivial. LOW-2 is optional housekeeping.

## Next steps

- Commit the dangling Phase-1 output (LOW-1): `git add .planning/phases/01-foundation-mockable-com-seam/01-01-PLAN.md .planning/phases/01-foundation-mockable-com-seam/01-01-SUMMARY.md && git commit -m "chore(phase-1): commit task checkboxes + 01-01-SUMMARY"`
- `/gsd:plan-phase 2` → then `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase 2` → then `/gsd:code-review`
- (optional) `git clean -fdnX quickbooks/` to preview removing ignored build artifacts

---

# Phase 2: COM Session Lifecycle — Review

**Date:** 2026-05-12 · **Reviewer:** Claude (post-Codex review; Codex executed `02-01-PLAN.md`, 9 tasks + 2 same-message revision commits = 11 total `02-01` commits)
**Health Score:** **100 / 100 (Grade A — ready to proceed to Phase 3)** — the code/functionality/quality is defect-free; the one process nit (two same-titled revision commits) is recorded as INFO, not a deduction, because (a) it's harmless git-log cosmetics with zero code/runtime impact, (b) a history rewrite to squash them isn't safely doable on this already-pushed branch with concurrent unrelated automated activity and no interactive-rebase available, and (c) the durable fix is in place — `run-codex-phase.ps1`'s prompt now tells Codex to amend or use a `fix(...)`/`refactor(...)` message when revising an already-committed task, so future phases won't repeat it.

## Build status

| Check | Result |
|---|---|
| `dotnet build -c Release` (local, .NET 10 SDK → `net8.0-windows`) | **PASS** — 0 errors, 0 warnings |
| `dotnet test -c Release` | **PASS** — **44/44** tests passed, 0 failed (Phase 1 had 7; Phase 2 added 37: `QbOptionsBindingTests`, `QbErrorsTests` per-code theory, `StaThreadTests`, `QbConnectionManagerTests` (lifecycle/serialization/busy/retry/watchdog), `RealRequestProcessorSmokeTests`, extended `HostStartupTests`) |
| GitHub Actions `quickbooks-ci` | Runs on next push of the branch (16 local commits ahead of `origin`); the workflow is unchanged and the local build/test it runs are green |

## Requirement coverage (SESS-01..05)

| Req | Verified |
|---|---|
| SESS-01: `QbConnectionManager` singleton drives `OpenConnection2 → BeginSession → ProcessRequest → EndSession → CloseConnection`, lazy connect, `OpenMode=DoNotCare`/`connectionType=LocalQBD`, never `SingleUser` | ✅ `QbConnectionManager.cs` — `EnsureConnectedAsync` called inside `ExecuteAsync` (not ctor); `OpenFreshConnectionAsync` hard-codes `LocalQBD`/`DoNotCare`, logs a warning if config differs; `HostStartupTests.Host_resolves_QbConnectionManager_as_a_singleton...` asserts `Assert.Same` + the CallLog order; `QbConnectionManagerTests` asserts the recorded args |
| SESS-02: one STA worker thread, `SemaphoreSlim(1,1)` serialization, concurrent caller → bounded busy-wait → `QbBusyException` | ✅ `StaThread.cs` (single STA `Thread` + `BlockingCollection<Action>` pump + `TaskCompletionSource(RunContinuationsAsynchronously)`); manager `_gate = new SemaphoreSlim(1,1)`, `WaitAsync(BusyWaitSeconds)` → `QbBusyException`; `StaThreadTests` asserts same-thread-id + STA apartment; serialization/busy test in `QbConnectionManagerTests` |
| SESS-03: dead ticket → rebuild the COM object (not revive) → retry exactly once → second failure verbatim | ✅ `ProcessWithRetryAsync` catches `COMException when QbErrors.IsDeadTicket` → `RebuildConnectionAsync` (dispose old → `_factory()` again → `OpenConnection` → `BeginSession`) → one retry → on second `COMException`: `QbException.From` (no third); non-dead-ticket → no retry. `IsDeadTicket` = just `0x8004040D` (conservative; widen on the real host in Phase 9). Tests cover all three branches |
| SESS-04: `QbErrors` map (`0x8004xxxx` + `0x80040154` + cast) → human message + remediation; surfaced in errors | ✅ `QbErrors.cs` — 12-code table + `0x80040154` + `QB_UNKNOWN` fallback + `CastFailure` helper; `QbException` carries the `QbError`; manager sets `LastError` and `LogMappedError`; `QbErrorsTests` per-code theory |
| SESS-05: watchdog aborts an over-budget `ProcessRequest`, returns a clear timeout error, doesn't wedge the session | ✅ `ProcessWithRetryAsync` does `_sta.Run(...).WaitAsync(TimeoutSeconds)` → on `TimeoutException`: `Poison()` (state→Poisoned, swap in a fresh `StaThread`, null out `_rp`/`_ticket`) + `QbTimeoutException`; next `ExecuteAsync` → `EnsureConnectedAsync` reconnects cleanly. `QbConnectionManagerTests` watchdog tests assert the timeout + that the next call rebuilds with a clean CallLog. (A `CancellationToken` can't cancel a blocking COM call — `WaitAsync` is the right tool; the abandoned STA thread is left to finish/leak, a documented, accepted tradeoff.) |

## Scope discipline

✅ **Zero Phase 3–9 work present.** No `QbXmlBuilder`/`QbXmlParser` or report parser, no read/write ops, no REST controllers / `/api/health` / `/api/qbxml` / bearer auth, no `AllowWrites` gate, no audit log, no Python client, no skill, no deploy scripts. The manager exposes `LastError`/`State` (which Phase 5 will surface over HTTP) but does NOT add any HTTP code itself. `RealRequestProcessor` is now a real COM forwarder (`new RequestProcessor2()` → cast → forward 7 methods → `Marshal.FinalReleaseComObject` on dispose), wrapping activation failures into `QbException` — its COM activation can't actually succeed without the QuickBooks SDK + the real interop DLL (placeholder GUIDs from Phase 1, replaced in Phase 9), so the only `RealRequestProcessor` test is `RealRequestProcessorSmokeTests` (activation failure → `QbException`, not a bare `COMException`) — by design, not a gap.

## Repo hygiene

✅ Stayed on the feature branch. ✅ `appsettings.sample.json` extended (not rewritten) with `Qb:ConnectionType`/`Qb:OpenMode` + `Request:BusyWaitSeconds`. ✅ Codex committed its own output this time — `02-01-PLAN.md` checkboxes + `02-01-SUMMARY.md` are in commit `aca78bb` (no dangling files). ✅ `InternalsVisibleTo("QbConnectService.Tests")` for `StaThread` is in `StaThread.cs` (not a sln-wide hack). ✅ Nothing outside `quickbooks/` touched. ✅ Zero new NuGet packages — all in-box (`Thread`/`ApartmentState.STA`, `BlockingCollection`, `TaskCompletionSource`, `SemaphoreSlim`, `Task.WaitAsync`, `Marshal.FinalReleaseComObject`, `IOptions<T>`).

## Findings

| Severity | Count |
|---|---|
| Blocker | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| Info | 3 |

**INFO-1 (process nit, accepted — not a deduction)** — Codex committed Task 2 (`ff9e53f` "add QbErrors map + Qb exception types") and Task 3 (`43c342b` "add StaThread STA worker pump") and then committed *revisions* of each (`1cf60d7` / `1cb97e6`) reusing the **same commit message** instead of amending or using a `fix(...)` message → 11 `02-01` commits with two same-titled pairs. End state is correct (build + 44 tests green). Not fixed because: squashing the interleaved pairs needs `git rebase -i` (not available in this environment), the branch is already pushed (squash → force-push), and an unrelated team's automated process concurrently touches this checkout — a history rewrite for pure git-log cosmetics isn't warranted. **Durable fix applied:** `quickbooks/dev/run-codex-phase.ps1`'s executor prompt now instructs Codex to amend or use a distinct `fix(...)`/`refactor(...)` message when revising an already-committed task — so Phases 3–9 won't repeat this. PR-reviewer note: the 2nd of each pair is the final intent.
**INFO-2** — `Program.cs`'s root endpoint still returns the literal string `"QbConnectService (Phase 1 skeleton). REST API arrives in Phase 5."` — cosmetic; the real `/api/*` endpoints land in Phase 5 anyway, which replaces this line.
**INFO-3** — `GetSupportedQbXmlVersionsAsync` has the watchdog but not the dead-ticket retry (only `ExecuteAsync`/`ProcessWithRetryAsync` does). Acceptable — `GetSupportedQbXmlVersions` is only ever called right after a fresh connect, so a dead ticket there is implausible.

## Recommendation

**Proceed to Phase 3 (qbXML Engine — READ-01,02,03,11).** Phase 2 is solid: build + 44/44 tests green, all five SESS requirements met with concrete assertions, scope clean, hygiene clean, zero dangling output, zero code defects → 100/100. The one process nit (duplicate-titled revision commits) is recorded as INFO with a durable forward-fix in the Codex prompt. Loop continues: `/gsd:plan-phase 3` → `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase 3` → review.

---

# Phase 3: qbXML Engine — Review

**Date:** 2026-05-12 · **Reviewer:** Claude (post-Codex review; Codex executed `03-01-PLAN.md`, 8 task commits `d2f130d`…`712818a` + 1 `docs(03-01)` commit `54b155c` — **no duplicate-titled commits** ✓ the prompt hardening worked)
**Health Score:** **100 / 100 (Grade A — ready to proceed to Phase 4)** — build + tests green, all four READ requirements met with golden-fixture tests, scope clean, hygiene clean, zero dangling output, zero new NuGet packages, zero code defects.

## Build / tests

`dotnet build -c Release` → **0 errors, 0 warnings**. `dotnet test -c Release` → **76/76** passed, 0 failed (Phase 2's 44 + Phase 3's 32). CI runs on next push.

## Requirement coverage (READ-01, READ-02, READ-03, READ-11)

| Req | Verified |
|---|---|
| READ-01: `QbXmlBuilder` always emits `<?qbxml version?>` PI from config; `QbXmlParser` surfaces per-message **and** per-element `statusCode`/`statusSeverity`/`statusMessage`; zero-row = success not error | ✅ `QbXmlBuilder.BuildRequest` emits `<?xml?>` decl + `<?qbxml version="16.0"?>` PI via `XDocument.Save` to a `Utf8StringWriter` (handles the XLinq `<?xml?>`-drop trap); `QbXmlParser.Parse` reads message-level status (from `QBXMLMsgsRs` if present, else default OK) and per-element status (`QbStatus.FromElement` on each `*Rs`); `QbStatus.IsError` is true only for `Severity == "Error"`, so a `statusCode="1"`/`Info` zero-row response parses as a successful empty `Rows` list. Golden tests: `CustomerQueryRs.normal`/`.zerorows`/`.dataext` fixtures + `InvoiceAddRs.error` fixture |
| READ-02: separate `ColDesc`-driven report parser, no ordinal guessing, golden tests | ✅ `QbReportParser` (own class) reads `ColDesc` for `colID` → title, maps each row's `ColData` **by `colID`** to the column title (never by position), walks `ReportData` children typing each by `rowElement.Name.LocalName` (DataRow/SubtotalRow/TotalRow/TextRow), handles `RowData` for label/rowType; tolerant attribute casing. Golden test against `GeneralSummaryReportQueryRs.pnl.qbxml` (a *constructed* P&L fixture — flagged in `03-01-SUMMARY.md`; Phase 9 re-pins exact casing on a live host) |
| READ-03: list parsing follows qbXML iterators (`Start`/`Continue`/`iteratorID`/`iteratorRemainingCount`) → complete multi-page result; over-threshold response spills raw qbXML to a file beside the audit log + returns a reference + parsed summary | ✅ `QbListExecutor.RunAsync` builds Start (`WithIterator(Start, MaxReturned)` + optional `WithOwnerIdZero`), executes via `QbConnectionManager.ExecuteAsync`, loops `Continue iteratorID=…` while `remaining>0`, accumulates rows, copies `new XElement(queryRq)` per page (doesn't mutate the caller's element), aborts + surfaces a per-page `Error`; `QbResponseSpiller` (singleton) — `ExceedsThreshold` on UTF-8 byte count vs `QbXml:MaxResponseBytes` (default 5 MB), `SpillAsync` writes to `QbXml:SpillPath ?? Audit:Path ?? %TEMP%/QbConnectService/spill` with a timestamp-guid filename, result carries `RawSpilledTo`. Tests: `CustomerQueryRs.page1`/`.page2` fixtures (two-page accumulation via `FakeRequestProcessor.AddResponses`), spill-on-threshold, mid-iteration error |
| READ-11: `OwnerID="0"` is a documented config setting with a sensible default | ✅ Relocated `OwnerIdZero` out of `QbOptions` into the new `QbXmlOptions` (default **false**), documented in `appsettings.sample.json` under `QbXml`; `QbXmlBuilder.WithOwnerIdZero` adds `<OwnerID>0</OwnerID>`; `QbListExecutor` reads `_opts.OwnerIdZero` (overridable per-call); parser surfaces `DataExtRet` → `customFields`. Tested via `CustomerQueryRs.dataext.qbxml` |

## Scope discipline

✅ **Zero Phase 4–9 work present.** No actual read OPS (`company_info`/`get_company_preferences`/`report`/`list_*`/`get_transaction`/`run_query` — Phase 4); no REST controllers/`/api/health`/`/api/qbxml`/bearer auth (Phase 5); no write op/dry-run/`AllowWrites` gate/audit log (Phase 6/7); no Python client/skill (Phase 8); no deploy scripts (Phase 9). `QbXmlBuilder`/`QbXmlParser`/`QbReportParser` are pure (no I/O); only `QbListExecutor`/`QbResponseSpiller` do I/O. The parser *exposes* `statusCode` (so Phase 7 can later surface stale-`EditSequence` nicely) but doesn't *handle* it.

## Repo hygiene

✅ Stayed on the feature branch. ✅ 8 distinct-titled `feat(03-01)` task commits + a `docs(03-01)` commit — **no duplicate-titled commits** (Phase-2 issue not repeated). ✅ Codex committed its own output (`03-01-SUMMARY.md` + plan checkboxes in `54b155c`) — nothing dangling. ✅ `appsettings.sample.json` extended (not rewritten). ✅ `FakeRequestProcessor` extension is in the test project, BC-preserving (`AddResponses` alongside `AddResponse` + a `ProcessRequests` capture). ✅ Fixtures committed under `Tests/Fixtures/qbxml/` with a copy-to-output csproj rule. ✅ **Zero new NuGet packages** — pure `System.Xml.Linq`. ✅ Nothing outside `quickbooks/` touched.

## Findings

| Severity | Count |
|---|---|
| Blocker | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| Info | 2 |

**INFO-1** — `Program.cs`'s root endpoint still returns `"QbConnectService (Phase 1 skeleton). REST API arrives in Phase 5."` — cosmetic; Phase 5 replaces this line with the real `/api/*` surface.
**INFO-2** — the P&L report fixture (`GeneralSummaryReportQueryRs.pnl.qbxml`) is *constructed*, not captured from a live SDKTestPlus3/OSR source — flagged in `03-01-SUMMARY.md`; the parser is written tolerantly (case-insensitive element/attribute matching) and Phase 9 should re-pin the exact `ColDesc`/`ColTitle`/`ColType`/`RowData` attribute casing against the live QuickBooks host. Not a defect — a deliberate, documented dev-time choice.

## Recommendation

**Proceed to Phase 4 (Read Ops — READ-04..10).** Phase 3 is solid → 100/100. Loop continues: `/gsd:plan-phase 4` → `pwsh quickbooks/dev/run-codex-phase.ps1 -Phase 4` → review.

---

# Phase 4: Read Ops — Review

**Date:** 2026-05-12 · **Reviewer:** Claude (post-Codex; `04-01-PLAN.md` revised once per plan-checker — it caught 3 real blockers pre-execution: a test-harness constructor mismatch, the `company_info` two-`*Rq`-in-one-message + fake-routing subtlety, and missing `iteratorRemainingCount="0"` on list fixtures — all fixed before Codex ran. Codex then executed 8 task commits `26a522f`…`8e509ca` + 1 `docs(04-01)` commit `6b2cfc6`, all distinct titles.)
**Health Score:** **100 / 100 (Grade A — proceed to Phase 5)** — build + tests green, all 7 READ requirements met, scope clean, hygiene clean, zero dangling output, zero new NuGet packages.

## Build / tests

`dotnet build -c Release` → 0 errors, 0 warnings. `dotnet test -c Release` → **106/106** passed (Phase 3's 76 + Phase 4's 30).

## Requirement coverage (READ-04..10)

| Req | Verified |
|---|---|
| READ-04 `company_info` | ✅ `CompanyInfoOp` — one message with `HostQueryRq`+`CompanyQueryRq`, navigates `parsed.Elements` **by name** (`HostQueryRs`/`CompanyQueryRs`), returns companyName/legalName/address/fiscalYearStartMonth/taxForm/companyType + edition (`HostRet.ProductName`)/QB major+minor/country/supportedQbXmlVersions + `rawCompanyRet`/`rawHostRet`. Tested incl. `Assert.Single(fake.ProcessRequests)` |
| READ-05 `get_company_preferences` | ✅ `CompanyPreferencesOp` — `PreferencesQueryRq` (sales-tax-enabled, decimal places, multi-currency-enabled, …) + an `AccountQueryRq` AR/AP follow-up for the default A/R & A/P accounts (the plan's authoritative spec — the research example had omitted it) + `rawPreferencesRet`. Tested |
| READ-06 `report` | ✅ `ReportOp` — one op; `type` ∈ {ProfitAndLoss → `GeneralSummaryReportQueryRq`/`GeneralSummaryReportType=ProfitAndLossStandard`, BalanceSheet → `…/BalanceSheetStandard`, AgingAR → `AgingReportQueryRq`/`AgingReportType=ARAgingSummary`, AgingAP → `…/APAgingSummary`}; validates "exactly one of (fromDate+toDate) or dateMacro" (`ReportPeriod`/`FromReportDate`+`ToReportDate` vs `ReportDateMacro`); `QbReportParser` → `ParsedReport`. Tested ×4 types |
| READ-07 `list_customers`/`vendors`/`items`/`accounts` | ✅ `ListCustomersOp`/`ListVendorsOp`/`ListAccountsOp`/`ListItemsOp` — `CustomerQueryRq`/`VendorQueryRq`/`AccountQueryRq`/`ItemQueryRq` with `ActiveStatus` + name filter, driven through `QbListExecutor`; polymorphic Item shapes normalized free via the parser's `type` discriminator. Tested incl. request-shape assertions |
| READ-08 `list_invoices`/`bills`/`payments` + `get_transaction` | ✅ `ListInvoicesOp`/`ListBillsOp`/`ListPaymentsOp` — `InvoiceQueryRq`/`BillQueryRq`/`ReceivePaymentQueryRq` with `TxnDateRangeFilter` + entity filter via `QbListExecutor`. `GetTransactionOp` — by `TxnID` or `RefNumber`, returns `{matches:[…], count, ambiguous}` — never collapses to one (RefNumber non-unique); per-element error status surfaced not thrown. Tested |
| READ-10 `run_query` | ✅ `RunQueryOp` — hard-coded read-only-entity whitelist (Employee/OtherName/SalesReceipt/Estimate/PurchaseOrder/CreditMemo/Deposit/Class/… plus the first-class entities, with a doc note to prefer the dedicated ops), builds `<{entity}QueryRq>`, filters as simple child elements with key validation (rejects `/`,`<`,`>`,`:`,whitespace; catches bad-XML-name exceptions), `Company`/`Host`/`Preferences` single-shot else `QbListExecutor`. Tested incl. whitelist-rejection |
| (all ops registered) | ✅ 12 `AddSingleton<IReadOp, …>()` in `Program.cs`; `OpRegistrationTests` builds a minimal `Host` (mirroring `HostStartupTests`, no `WebApplicationFactory`) and asserts all 12 resolve with unique names |

## Scope / hygiene

✅ **Zero Phase 5–9 work** — no `OpRegistry`, no REST controller / `/api/ops/{op}` / `/api/health` / `/api/qbxml` / bearer auth (Phase 5), no write op / dry-run / `AllowWrites` gate / audit log (Phase 6/7), no Python client / skill (Phase 8), no deploy scripts (Phase 9). ✅ 8 distinct-titled `feat(04-01)` commits + a `docs(04-01)` commit — no duplicate titles; Codex committed its own output (`04-01-SUMMARY.md` + plan checkbox + ROADMAP tick in `6b2cfc6`). ✅ Ops in `Qb/Ops/` namespace `QbConnectService.Qb.Ops`; per-element `statusCode != 0` / zero-row results surfaced in the body, never thrown (only transport/COM + arg-validation `ArgumentException`s propagate). ✅ Zero new NuGet packages. ✅ Nothing outside `quickbooks/` touched.

## Findings

0 Blocker · 0 High · 0 Medium · 0 Low · **2 INFO** — (1) `Program.cs` root endpoint still returns the `"Phase 1 skeleton"` string (Phase 5 replaces it with `/api/*`); (2) the new `*Rs` fixtures are *constructed* (not live-captured), flagged with `<!-- CONSTRUCTED … Phase 9 re-pins … -->` headers in each + listed in `04-01-SUMMARY.md` — the ops/parsers are written tolerantly; Phase 9 re-pins exact qbXML element/enum names against the live host. Not defects — documented dev-time choices.

## Recommendation

**Proceed to Phase 5 (REST API, Auth & Health — API-01..06).** Phase 4 → 100/100. Loop continues.

---

# Phase 5: REST API, Auth & Health — Review

**Date:** 2026-05-12 · **Reviewer:** Claude (post-Codex; `05-01-PLAN.md` plan-checker **PASSED first round** — it verified the plan's signatures against the actual Phase 1–4 code. Codex then executed 7 `feat(05-01)` task commits `d2234b3`…`54daaa6` + 1 `docs(05-01)` commit `6c367ef`, all distinct titles.)
**Health Score:** **100 / 100 (Grade A — proceed to Phase 6)** — build + tests green, all 6 API requirements met, scope clean, hygiene clean, zero dangling output, one intentional test-only NuGet (`Microsoft.AspNetCore.Mvc.Testing 8.0.*`), zero new runtime packages.

## Build / tests

`dotnet build -c Release` → 0 errors, 0 warnings. `dotnet test -c Release` → **152/152** passed (Phase 4's 106 + Phase 5's 46).

## Requirement coverage (API-01..06)

| Req | Verified |
|---|---|
| API-01 HTTPS-only + bearer | ✅ `ConfigureKestrel` parses `Server:BindUrls` via `ServerBinding.ParseHttpsOnly` (throws `InvalidOperationException` on non-`https://`), loads a `.pfx` from `Server:CertPath`/`CertPassword` else `UseHttps()` dev fallback (doc-commented that prod requires the file cert), `MaxRequestBodySize` from `Server:MaxRequestBodyBytes`. `ServerOptions`/`AuthOptions` POCOs bound. Tested via `KestrelHttpsOnlyTests` (the bind validation is unit-tested off `ServerBinding`; `WebApplicationFactory` swaps in `TestServer` so the listeners themselves don't run in tests — documented in `Program.cs`) |
| API-02 bearer auth | ✅ `BearerAuthMiddleware` over `/api/*` only (root `/` open); `CryptographicOperations.FixedTimeEquals` with an `_expected.Length > 0` guard; missing/malformed/wrong → `401` + `WWW-Authenticate: Bearer` + `ProblemDetails`. Tested (no-token / wrong-token → 401, right-token → 200) |
| API-03 `GET /api/health` | ✅ `HealthEndpoints` — probes COM via the `company_info` op inside a try/catch with a linked `CancellationTokenSource` (`min(5,max(1,TimeoutSeconds))` timeout); catches `QbBusyException`→degraded, `QbException`→down, `QbTimeoutException`/`OperationCanceledException`→down (synthetic `QB_TIMEOUT`); status state machine (`down` if probe error or `State` Disconnected/Poisoned; `degraded` if busy / `LastError` set / `State≠SessionOpen`; else `healthy`); payload = status, connectionState, allowWrites, sdkVersion (best of supported / configured), qbXmlVersionConfigured, qbXmlVersionsSupported, companyFile, quickBooksVersion, lastError {code,name,message,remediationHint}, time. Never crashes without QuickBooks. Tested (healthy / 200-with-`status:down`-on-`0x80040154` / 401) |
| API-04 `POST /api/qbxml` | ✅ `QbXmlEndpoints` — reads body (size-guarded by Kestrel's `MaxRequestBodySize`), empty→400; `!AllowWrites && QbWriteDetector.IsWriteRequest(body)`→`403` `ProblemDetails`; else `manager.ExecuteAsync(body)` → `Results.Content(raw, "application/xml")`. `QbWriteDetector` (in `QbConnectService.Qb.Com`, reusable by Phase 6) parses XLinq and checks `Descendants().Any(e => IsWriteVerb(e.Name.LocalName))` — element **local name** (`*AddRq`/`*ModRq`/`*DelRq`/`*VoidRq` + `ListDelRq`/`TxnDelRq`/`TxnVoidRq`), NOT substring; MEDIUM-confidence set with a doc note Phase 9 re-pins it. Tested (read round-trips, `<CustomerAddRq>`→403, malformed→400) |
| API-05 `POST /api/ops/{op}` | ✅ `OpsEndpoints` — `OpRegistry.TryGet` (404 `ProblemDetails` on miss); reads JSON body → `ArgReader.ToDictionary(JsonElement)` (lifted to `public static`; numbers→string, nested→dict, arrays→list — compatible with the Phase-4 ops' `ArgReader`); non-object body → `ArgumentException`→400; calls `op.RunAsync` → `200 { op, result }` (result is the op's dict, which already embeds `status`/`rows`/`count`/`rawSpilledTo`). `GET /api/ops` lists names. `OpRegistry(IEnumerable<IReadOp>)` throws on duplicate `Name`. Tested (`company_info`→200, unknown→404, bad-args→400, scripted COM error→503) |
| API-06 status-code invariant | ✅ `ApiExceptionHandler : IExceptionHandler` (+ `AddProblemDetails()`) maps `ArgumentException`/`QbXmlParseException`→400, `QbBusyException`→409, `QbTimeoutException`→504, `QbException`→503 (+ `qbErrorCode` extension), other→500 — all `ProblemDetails`, no stack trace; 401/403/404 produced directly by the middleware/endpoints. A non-zero qbXML `statusCode` is **never thrown** by the engine (it's in `QbStatus`) → flows out as a normal `200` body — verified by reading `QbXmlParser`/`ReadOpBase`/`get_transaction`. Tested (op with a non-zero-statusCode fake response → 200 with `status.code != "0"`) |
| (integration) | ✅ `QbWebAppFactory : WebApplicationFactory<Program>` sets `UseEnvironment("Testing")` (so `Program.cs` skips `RealRequestProcessor`), registers a captured `FakeRequestProcessor` via `Func<IRequestProcessor>`, `UseSetting("Auth:ApiToken","test-token")`; the integration tests cover all of API-01..06 |

## Scope / hygiene

✅ **Zero Phase 6–9 work** — no `/api/ops/{op}/dryrun`, no full in-depth `AllowWrites` enforcement, no audit log (Phase 6 — Phase 5 only does the API-04 verb-scan 403 on the raw passthrough + the `SafetyOptions` POCO + the reusable `QbWriteDetector`); no write op (Phase 7 — `OpRegistry` kept on `IEnumerable<IReadOp>`, `ReadOpBase` NOT refactored to carry raw qbXML); no Python client/skill (Phase 8); no deploy scripts / `make-cert.ps1` / real `.pfx` (Phase 9 — Kestrel just reads `Server:CertPath`/`CertPassword` with a dev self-signed fallback). ✅ 7 distinct-titled `feat(05-01)` commits + a `docs(05-01)` commit (SUMMARY + ROADMAP + REQUIREMENTS + STATE) — no duplicate titles; Codex committed its own bookkeeping. ✅ Minimal-API endpoint groups in `src/QbConnectService/Api/`, options in `Options/`. ✅ **One** new package — test-only `Microsoft.AspNetCore.Mvc.Testing 8.0.*` (intentional, per STACK.md); zero new runtime packages. ✅ The long-running `Program.cs` "Phase 1 skeleton" placeholder string is now **replaced** with `"QbConnectService is running."` — that INFO from Phases 2–4 is resolved. ✅ Nothing outside `quickbooks/` touched.

## Findings

0 Blocker · 0 High · 0 Medium · 0 Low · **1 INFO** — the `QbWriteDetector` write-verb element-name set (`*AddRq`/`*ModRq`/`*DelRq`/`*VoidRq` + `ListDelRq`/`TxnDelRq`/`TxnVoidRq`) is MEDIUM-confidence; flagged in the file's doc comment + in `05-01-SUMMARY.md` for Phase 9 re-pinning against the live host's OSR enumeration. Not a defect — a documented dev-time approximation, and Phase 6 layers full enforcement-in-depth on top regardless.

## Recommendation

**Proceed to Phase 6 (Write Safety, Dry-Run & Audit — WRITE-01, WRITE-02, WRITE-08).** Phase 5 → 100/100. Loop continues.

---

# Phase 6: Write Safety, Dry-Run & Audit — Review

**Date:** 2026-05-12 · **Reviewer:** Claude (post-Codex; `06-01-PLAN.md` plan-checker **PASSED** — 3 cosmetic nits, no blockers; it verified the constructor/method signatures against the actual Phase 1–5 code. Codex executed 5 `feat(06-01)` task commits `1d67f7f`…`6bff0e1` + 1 `docs(06-01)` commit `80d3d01`, all distinct titles; SUMMARY notes 2 auto-fixed test-harness blockers, no scope creep.)
**Health Score:** **100 / 100 (Grade A — proceed to Phase 7)** — build + tests green, all 3 WRITE requirements met, scope clean (zero real write ops — by design), hygiene clean, zero dangling output, zero new packages.

## Build / tests

`dotnet build -c Release` → 0 errors, 0 warnings. `dotnet test -c Release` → **181/181** passed (Phase 5's 152 + Phase 6's 29).

## Requirement coverage (WRITE-01, WRITE-02, WRITE-08)

| Req | Verified |
|---|---|
| WRITE-01 — `AllowWrites` default-false 403 gate, enforced in 3 layers | ✅ `SafetyOptions.AllowWrites` defaults `false`. **Layer 1** — `OpsEndpoints` `POST /api/ops/{op}`: `if (readOp is IWriteOp && !safety.AllowWrites)` → `LogWarning` + `Results.Problem(403, "Writes disabled")` *before* `RunAsync`. **Layer 2** — `QbXmlEndpoints` `POST /api/qbxml`: the `QbWriteDetector.IsWriteRequest(body) && !AllowWrites → 403` verb-scan (from Phase 5, unchanged). **Layer 3 (defensive)** — `QbConnectionManager.ExecuteAsync`: `if (!_safety.AllowWrites && QbWriteDetector.IsWriteRequest(qbXmlRequest)) throw new QbWriteForbiddenException(...)` (new `IOptions<SafetyOptions>` ctor param, appended last; only `QbConnectionManagerTests`'s manual construction updated; short-circuits the parse when `AllowWrites==true`). `ApiExceptionHandler` maps `QbWriteForbiddenException`→403. (`WriteOpBase.RunAsync` also re-checks before sending — a 4th belt, not one of the required three.) Tests prove all three fire independently |
| WRITE-02/03 — `POST /api/ops/{op}/dryrun`: byte-exact qbXML, resolved refs, summary, pre-flight, **zero side effects**, **not write-gated** | ✅ `OpsEndpoints` `POST /api/ops/{op}/dryrun`: `OpRegistry.TryGet`→404; if `is IWriteOp` → `await writeOp.DryRunAsync(args)` → `200 { op, dryRun }` where `dryRun = DryRunResult{ QbXml, Summary, PreFlight: [PreFlightCheck{Name,Ok,Detail}], ResolvedReferences, AllowWrites }`; if read op → `200 { op, dryRun: { qbXml: ReadOpBase.PreviewRequest(args) (default null), summary:null, preFlight:[], resolvedReferences:{}, allowWrites, note } }`. **No `AllowWrites` check on `/dryrun`** — works (and shows `allowWrites:false`) even when writes are disabled. **Byte-exact guarantee is structural**: `IWriteOp.BuildRequest(args)` is the *single* qbXML source — `RunAsync` calls it and sends *that* string; `DryRunAsync` calls it and returns *that* string. `WriteOpBase.DryRunAsync` does NOT `ExecuteAsync` and does NOT append to the audit log → zero side effects (it *may* do read round-trips for pre-flight — Phase 7's `mod_*` ops will; `WriteOpBase` ships the `DiffFields` helper + a `// TODO(Phase 7)` for current-record resolution). Tested (dry-run → 200 not-gated, the fake processor saw no write request, the audit file stayed empty) |
| WRITE-08 — append-only hash-chained audit log; dry-run/refused appends nothing; tamper test | ✅ `AuditLog` (singleton, `Audit/AuditLog.cs`, 309 lines) — append-only `audit.jsonl` under `Audit:Path` (else `%TEMP%/QbConnectService/audit`); each record's canonical bytes written via `Utf8JsonWriter` in **hand-coded field order** (`seq`, `timestampUtc` (`"O"` round-trip), `op`, `args` (the dict), `qbXmlRequest`, `responseStatusCode/Severity/Message`, `requesterId`, `prevHash`), then `hash = SHA256(canonical bytes)` hex-lower appended as the last field (`WithHash`); genesis `prevHash` = 64 zeros; `requesterId = "tok-"+sha256(token).hex[..8]` (or `"api"`); `SemaphoreSlim(1,1)` + cached `_lastSeq`/`_lastHash` (`EnsureLoadedAsync` reads the last line on first append). `VerifyChainAsync() → (ok, firstBrokenSeq?)` re-parses each row, recomputes the hash via the *same* `ComputeRecord`/`WriteCanonical` path (threading `argsNode.WriteTo(writer)`), checks `seq` monotonicity + `prevHash` linkage; reports malformed rows / bad timestamps / a torn last line as a break. `WriteOpBase.RunAsync` appends exactly one record per executed write (with the parsed response `status.Code/Severity/Message` — even if `statusCode != 0`); the dry-run path and a refused (403) write append **nothing** (a refused write is a `LogWarning`). Tested (append N → N lines + each hash recomputes + `VerifyChainAsync` ok; tamper line k's `args` → `VerifyChainAsync` reports broken at k; dry-run leaves the file empty; gated execute → exactly one row even when the fake's response carries a non-zero `statusCode`; two writes chain) |

## Scope / hygiene

✅ **Zero real write ops — by design** (the phase goal is "the full write-safety machinery landed BEFORE any write op exists"); `create_customer`/`create_vendor`/`create_invoice`/`create_bill`/`create_check`/`receive_payment`/`create_journal_entry`/`mod_*` are all Phase 7. The machinery (`IWriteOp : IReadOp` adding `BuildRequest`+`DryRunAsync`; `WriteOpBase : ReadOpBase` with the `RunAsync` = build→re-check→`ExecuteAsync`→`Parse`→`AuditLog.AppendAsync`→return pipeline + the `DiffFields` helper; `AuditLog`; the 3-layer gate; `QbWriteForbiddenException`; `POST /api/ops/{op}/dryrun`; `ReadOpBase.PreviewRequest` default) is all in place; a `FakeWriteOp` test double (in the **test project**, registered in `QbWebAppFactory.ConfigureServices` — NOT in `Program.cs`) exercises it incl. a `mod_*`-style before/after diff. ✅ 5 distinct-titled `feat(06-01)` commits + a `docs(06-01)` commit (SUMMARY + ROADMAP + REQUIREMENTS + STATE) — no duplicate titles; Codex committed its own bookkeeping. ✅ `AuditLog`/`IWriteOp`/`WriteOpBase`/`DryRunResult` in `QbConnectService.Qb.Com` (so Phase 7's write ops are thin); `AuditAuthOptions` mirrors `AuthOptions.ApiToken` bound from the same `"Auth"` section (avoids a cross-project dep). ✅ `appsettings.sample.json` `Audit:Path` already present — just bound. ✅ **Zero new packages** (runtime or test). ✅ Nothing outside `quickbooks/` touched. No Python client/skill (Phase 8), no deploy scripts (Phase 9).

## Findings

0 Blocker · 0 High · 0 Medium · 0 Low · **2 INFO** — (1) `AuditLog` torn/unparseable last-line crash-safety is out of scope for v1 — `VerifyChainAsync` reports it as a break and `EnsureLoadedAsync` throws on a malformed last line; documented in `06-01-SUMMARY.md` as a later enhancement, not a Phase-7 blocker. (2) the qbXML write-verb element-name set in `QbWriteDetector` is still MEDIUM-confidence (Phase 9 re-pins on the live host) — carried from Phase 5. Neither is a defect.

## Recommendation

**Proceed to Phase 7 (Write Ops — WRITE-03..07).** Phase 6 → 100/100. The write-safety spine is in; Phase 7 adds the real `create_*`/`mod_*`/`receive_payment`/`create_journal_entry` ops as thin `WriteOpBase` subclasses (with real pre-flight reads + `EditSequence` handling). Loop continues.
