# Phase 1 Summary

## What was built

- A three-project .NET 8 solution under `quickbooks/QbConnectService/`: the ASP.NET Core host, the isolated `QbConnectService.Qb.Com` adapter project, and the xUnit test project.
- The mockable `IRequestProcessor` seam plus the `QbConnectionType` and `QbFileMode` enums, with the final file living at `src/QbConnectService.Qb.Com/Qb/IRequestProcessor.cs` in namespace `QbConnectService.Qb`.
- A compile-only `QBXMLRP2Lib.cs` `[ComImport]` stub with placeholder GUIDs, a Phase-1-stub `RealRequestProcessor` that throws `NotImplementedException`, and a `Qb.Com` README explaining both placeholders.
- The tri-mode host: `Program.cs` uses `WebApplication.CreateBuilder`, `AddWindowsService()`, `AddHostedService<QbConnectService.Worker>()`, a minimal root endpoint, and `public partial class Program`.
- `FakeRequestProcessor` plus four SVC-02 tests covering lifecycle calls, canned responses keyed by `*Rq` element name, scripted COM-style errors, and helpful failures for unscripted requests.
- `HostStartupTests` and `BuildConfigTests`, making the Generic Host startup path and the x86 / Windows-target build shape machine-verifiable.
- A path-filtered `windows-latest` GitHub Actions workflow and a top-level `quickbooks/QbConnectService/README.md`.

## Key execution decisions

- `Microsoft.Extensions.Hosting` and `Microsoft.Extensions.Hosting.WindowsServices` resolved to `8.0.1` from the requested `8.0.*` range.
- `IRequestProcessor.cs` ended up in `QbConnectService.Qb.Com` rather than the host project because the adapter cannot reference the host; the namespace stayed `QbConnectService.Qb`, and the host/tests consume it transitively through the existing host -> `Qb.Com` project reference.
- `BuildConfigTests` kept the `CorFlags.Requires32Bit` assertion and the `Machine.I386` assertion.
- The Windows-target assertion in `BuildConfigTests` uses `TargetPlatformAttribute("Windows7.0")` alongside `TargetFrameworkAttribute(".NETCoreApp,Version=v8.0")`, because on this SDK the framework attribute does not include the platform suffix even for `net8.0-windows`.

## Deviations from plan

- `QbConnectService.Tests.csproj` ended up targeting `net8.0-windows` with `PlatformTarget=x86` instead of plain `net8.0`. This was necessary because a plain `net8.0` test project cannot reference a `net8.0-windows` host, and the x86 host assembly could not load under the default x64 test host until the test project was also pinned to x86.
- Task 7 required an extra workflow-only commit after the first remote GitHub Actions run failed. The initial workflow restored without `-r win-x86`, so `windows-latest` did not download the required runtime packs before the `--no-restore` build. The follow-up commit changed restore to `dotnet restore QbConnectService.sln -r win-x86`, after which the workflow passed.

## CI runs

- Initial run (failed, restore/runtime-pack issue): <https://github.com/technijian-admin/tech-legal/actions/runs/25707918043>
- Final run (success): <https://github.com/technijian-admin/tech-legal/actions/runs/25708034197>

Final CI status for Phase 1: `quickbooks-ci` run `25708034197` completed with conclusion `success` on 2026-05-12.

## Placeholder-stub note for Phase 2 / Phase 9

- `src/QbConnectService.Qb.Com/Interop/QBXMLRP2Lib.cs` is intentionally a Phase-1 placeholder stub with placeholder GUIDs so the solution builds with no QuickBooks SDK installed. The real `tlbimp`-generated interop DLL is created on the QuickBooks host in Phase 9.
- `src/QbConnectService.Qb.Com/RealRequestProcessor.cs` is intentionally a Phase-1 stub that throws `NotImplementedException`. The real STA-pinned COM adapter over `QBXMLRP2.RequestProcessor` is built in Phase 2.
