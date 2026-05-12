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
