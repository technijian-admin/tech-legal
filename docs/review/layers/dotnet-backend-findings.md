# .NET Backend (Phase 1 skeleton) — Review Findings

**Reviewed:** 2026-05-12
**Component:** `quickbooks/QbConnectService/` — .NET 8 solution skeleton + mockable COM seam + fakes + CI (Phase 1 of 9)
**Files reviewed:** 16 tracked source files (3 `.csproj` + `.sln`, `Program.cs`, `Worker.cs`, `IRequestProcessor.cs`, `QBXMLRP2Lib.cs`, `RealRequestProcessor.cs`, `FakeRequestProcessor.cs`, 3 test files, `appsettings.sample.json`, 2 READMEs, `.github/workflows/quickbooks-ci.yml`, appended `.gitignore`)
**Findings:** 0 Blocker | 0 High | 0 Medium | 2 Low — **both RESOLVED 2026-05-12** (+ 3 Info, documented)
**Build:** `dotnet build -c Release` PASS (0/0) · `dotnet test -c Release` PASS (7/7) · CI run `25708034197` PASS
**Health (post-remediation):** 100/100

## Blocker

_None._

## High

_None._

## Medium

_None._

## Low

### [LOW] Phase-1 output left uncommitted by the executor
**File**: `.planning/phases/01-foundation-mockable-com-seam/01-01-PLAN.md` (modified), `.planning/phases/01-foundation-mockable-com-seam/01-01-SUMMARY.md` (untracked)
**Category**: Process hygiene
**Issue**: Codex ticked the task checkboxes in `01-01-PLAN.md` and wrote `01-01-SUMMARY.md` (per the plan's `<output>` block) but did not commit them. They sit dirty in a working tree shared with unrelated automated work.
**Fix**: `git add .planning/phases/01-foundation-mockable-com-seam/01-01-PLAN.md .planning/phases/01-foundation-mockable-com-seam/01-01-SUMMARY.md && git commit -m "chore(phase-1): commit task checkboxes + 01-01-SUMMARY"`
**Time**: 1 min

### [LOW] Build artifacts present in the working tree
**File**: `quickbooks/QbConnectService/**/bin/`, `**/obj/`, `publish/`
**Category**: Housekeeping
**Issue**: `dotnet build`/`publish` left `bin`/`obj`/`publish` directories in the checkout. They are correctly gitignored (verified: `git ls-files` shows only the 16 source files), so this is cosmetic — but it's noise in a checkout that another team's automated process also writes to.
**Fix** (optional): `git clean -fdX quickbooks/` (or `-fdnX` to preview).
**Time**: 1 min

## Info — documented decisions / deviations (no action required)

### [INFO] Test project targets `net8.0-windows` + `PlatformTarget=x86` (plan said plain `net8.0`)
`QbConnectService.Tests.csproj` deviates from the plan's `net8.0`. Justified in `01-01-SUMMARY.md`: a `net8.0` test project cannot reference a `net8.0-windows` host, and the x86 host assembly cannot load under the default x64 test host — so the test project was pinned to `net8.0-windows`/`x86` too. Tests pass; the seam (`IRequestProcessor`) is still seen transitively via the host project reference; the test project still references **only** the host (never `Qb.Com`). Reasonable.

### [INFO] Extra CI-only commit (`3d6426c`) after the first remote Actions run failed
The initial `quickbooks-ci.yml` ran `dotnet restore QbConnectService.sln` without `-r win-x86`, so `windows-latest` didn't fetch the x86 runtime packs before the `--no-restore` build → failure (run `25707918043`). Codex's follow-up changed restore to `dotnet restore QbConnectService.sln -r win-x86`; the re-run (`25708034197`) passed. The plan anticipated CI flakiness with a comment; this was a real config gap, correctly fixed.

### [INFO] `IRequestProcessor.cs` lives in `QbConnectService.Qb.Com` (namespace stays `QbConnectService.Qb`)
The plan flagged this contingency (the adapter can't reference the host, so the interface can't live in the host if `RealRequestProcessor` is to implement it). Codex placed it in `Qb.Com/Qb/IRequestProcessor.cs`, namespace `QbConnectService.Qb`; host + tests see it transitively. No fourth "contracts" project — correct call. Note for the Phase 2 author: the interface and the (currently-throwing) `RealRequestProcessor` are co-located in `Qb.Com`.

## What was verified positively

- **Seam quality** — `IRequestProcessor` has the planned 7-method, primitive-only surface (`string`/`bool`/`int`/`string[]`/two enums), extends `IDisposable`, with XML docs mapping each method to its `QBXMLRP2` counterpart. Zero COM types leak.
- **Interop confinement (SVC-01)** — `[ComImport]` appears **only** in `Qb.Com/Interop/QBXMLRP2Lib.cs`; that file carries a prominent "PHASE-1 STUB / REVIEWER FLAG" header (placeholder GUIDs, replaced by `tlbimp` output in Phase 9). Host references `Qb.Com`; tests reference only the host. The solution builds + the full suite runs with **no QuickBooks SDK installed**.
- **`FakeRequestProcessor` (SVC-02)** — implements `IRequestProcessor` in the test project; canned responses keyed by the top-level `*Rq` element name (parsed with `XDocument`); a `Queue<Exception>` for scriptable errors with `EnqueueComError(hresult, msg)`; a `CallLog`; helpful `InvalidOperationException` on an unscripted request. Four tests cover lifecycle, canned-response-by-element-name, scripted-`COMException`-then-drained (the dead-ticket-then-retry shape Phase 2 needs), and unscripted-request-throws.
- **Tri-mode host (SVC-04)** — `Program.cs`: `WebApplication.CreateBuilder` + `AddWindowsService(o => o.ServiceName = "QbConnectService")` + `AddHostedService<Worker>()` + `app.MapGet("/", …)` placeholder + `public partial class Program {}` (for Phase 5's `WebApplicationFactory`). Forward-looking comment for the Phase 2 `QbConnectionManager`/`RealRequestProcessor` registration. `Worker` is a heartbeat `BackgroundService` that logs start/heartbeat/stop and handles cancellation cleanly. `HostStartupTests` proves clean start/stop.
- **x86 build (SVC-03)** — host `.csproj`: `net8.0-windows`, `OutputType=Exe`, `PlatformTarget=x86`, `RuntimeIdentifier=win-x86`, Release-conditioned `PublishSingleFile`/`SelfContained`/`IncludeNativeLibrariesForSelfExtract`, `InvariantGlobalization`, the two `Microsoft.Extensions.Hosting*` packages, the `Qb.Com` project reference, `appsettings.sample.json` copied to output. `BuildConfigTests` asserts `Machine.I386` + `CorFlags.Requires32Bit` + `net8.0` framework + `windows` platform — passing. `dotnet publish -r win-x86 -p:PublishSingleFile=true` produces a single `QbConnectService.exe`.
- **CI (SVC-05)** — `quickbooks-ci.yml`: `windows-latest`, path-filtered to `quickbooks/QbConnectService/**` + the workflow file, `checkout@v4` + `setup-dotnet@v4` (`8.0.x`), restore (`-r win-x86`) → build (Release, `--no-restore`) → test (`--no-build`, coverage) → publish smoke. Green.
- **`appsettings.sample.json`** — all the future config keys present as obvious placeholders: `Server:BindUrls`, `Auth:ApiToken`, `Qb:CompanyFilePath`/`AppId`/`AppName`/`OwnerIdZero`, `Safety:AllowWrites=false`, `QbXml:Version=16.0`, `Audit:Path`, `Request:TimeoutSeconds`, plus a `Logging` section. No real `appsettings.json`.

## Summary

- Total findings: 2 (both LOW), 3 INFO
- Estimated fix effort: ~2 min (commit the dangling Phase-1 files; optional `git clean`)
- Key risks: none — Phase 1 is solid; proceed to Phase 2 after committing LOW-1.
