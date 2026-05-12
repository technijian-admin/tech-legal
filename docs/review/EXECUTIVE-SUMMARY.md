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
