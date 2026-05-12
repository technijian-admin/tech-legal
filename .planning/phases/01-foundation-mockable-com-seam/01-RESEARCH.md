# Phase 1: Foundation & Mockable COM Seam - Research

**Researched:** 2026-05-11
**Domain:** .NET 8 solution scaffolding, COM-interop isolation (QBXMLRP2 / `tlbimp`), tri-mode hosting (`Microsoft.Extensions.Hosting.WindowsServices`), x86 single-file publish, xUnit, GitHub Actions CI
**Confidence:** HIGH on the .NET/host/CI mechanics (Context7-class docs + the project's own STACK.md/ARCHITECTURE.md, which were themselves verified); HIGH on the seam design (it's the load-bearing decision and is well-specified upstream); MEDIUM on the exact bitness (`x86` is the SVC-03 requirement and the safe default for the 32-bit QB SDK, but the live host's QuickBooks Enterprise year is unconfirmed — see Open Questions; this does not block Phase 1)

> This document does **not** re-litigate the design. The authoritative sources are `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` (§6 layout, §8 testing) and `.planning/research/{STACK,ARCHITECTURE,PITFALLS}.md`. This is the *Phase-1-only* slice of that, turned into concrete instructions for a Codex executor working from a `PLAN.md`.

---

## Summary

Phase 1 builds the **skeleton + the mockable COM seam + fakes + CI** — nothing else. Specifically: a `dotnet`-scaffolded solution under `tech-legal/quickbooks/QbConnectService/` with three projects (host, COM adapter, tests); a hand-rolled `IRequestProcessor` interface whose surface is **only** `string`/`bool`/`int`/`enum` (so it leaks no COM types); a `FakeRequestProcessor` implementing it with canned qbXML responses and a scriptable error queue; a `Program.cs` that uses `Host.CreateApplicationBuilder` + `AddWindowsService()` so the **one published x86 exe runs unchanged as console / Windows-service / Task-Scheduler process**; project settings (`net8.0-windows`, `PlatformTarget=x86`, `RuntimeIdentifier=win-x86`, `PublishSingleFile=true` in Release) for the x86 single-file build; a `.github/workflows/quickbooks-ci.yml` that does `dotnet restore/build/test` on a `windows-latest` runner with no QuickBooks installed; and the repo hygiene (append to the existing `.gitignore`, no nested git repo, commit-per-task).

The single most important constraint — the reason this phase exists — is **"the solution builds and the full test suite runs on a Windows box with no QuickBooks SDK installed."** That is achieved by: (a) the `tlbimp`-generated `Interop.QBXMLRP2Lib.dll` being **pure metadata** (it carries the COM type signatures, not the COM server), (b) committing that DLL to the repo (or, since we can't run `tlbimp` here, committing a hand-written minimal `[ComImport]` interface stub instead — see decision below), (c) referencing it **only** from the isolated `QbConnectService.Qb.Com` project with `<EmbedInteropTypes>false</EmbedInteropTypes>`, and (d) the host project + the test project never referencing it — they depend on `IRequestProcessor` and (in tests) `FakeRequestProcessor`. The `RealRequestProcessor` COM adapter is *referenced* by the build (so it compiles) but only *activated* at runtime on the QuickBooks host; in Phase 1 it can be a stub that throws `PlatformNotSupportedException` or `NotImplementedException` — Phase 2 fills it in. Tests pass because they never go near it.

**Primary recommendation:** Scaffold the three projects exactly as `.planning/research/ARCHITECTURE.md` §"Recommended Project Structure" shows (paring it to the Phase-1 subset); commit a hand-written `Interop/QBXMLRP2Lib.cs` `[ComImport]` interface in the `Qb.Com` project (replaced by a real `tlbimp`-generated DLL during Phase 9 on the QB host) so there is a buildable solution *now* with no SDK; make `IRequestProcessor` the seam with a 6-method surface; ship `FakeRequestProcessor` + one test that exercises it + one "host starts and stops cleanly" test + one build-config assertion test; wire `AddWindowsService()` in `Program.cs`; set the `.csproj` x86/single-file properties; add the GitHub Actions workflow; append the three gitignore lines. One commit per task.

---

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why standard |
|---|---|---|---|
| .NET SDK | **10.0.107** (already installed on this box) builds **`net8.0-windows`** target | Build toolchain | A newer SDK builds older TFMs fine; the *target* is `net8.0-windows` (LTS, named by the spec, SVC-03). CI must `actions/setup-dotnet` an SDK that can build net8.0 (8.0.x or 9.0.x or 10.0.x — pin **8.0.x** in CI for an LTS-only graph; the local box's 10.0.107 also works). |
| ASP.NET Core | **8.0** (via the `net8.0-windows` TFM + `<FrameworkReference Include="Microsoft.AspNetCore.App"/>` *or* `Microsoft.NET.Sdk.Web`) | HTTP host (no endpoints in Phase 1 — just the host shell) | Phase 1 needs the *host* to exist (so SVC-04 tri-mode is real and testable) but no controllers/Kestrel-HTTPS yet (that's Phase 5). Using `Microsoft.NET.Sdk.Web` from the start is cleanest — it brings ASP.NET Core in and `WebApplication.CreateBuilder` supports `AddWindowsService()`. |
| `Microsoft.Extensions.Hosting.WindowsServices` | **8.0.x** (track the .NET 8 servicing line; pin e.g. `8.0.1`) | `builder.Services.AddWindowsService()` → SCM lifetime + EventLog logger; **no-op when not launched by the SCM** | This is *the* mechanism behind SVC-04: same exe = console (dev) + Windows service + scheduled task, zero code change. Confirmed by Microsoft Learn "Create Windows Service using BackgroundService" and the package docs. |
| `Microsoft.Extensions.Hosting` | **8.0.x** | Generic Host / DI / config / logging | Transitively present via ASP.NET Core; reference explicitly so the worker bits are visible. |
| xUnit | **2.9.x** (`xunit` + `xunit.runner.visualstudio` + `Microsoft.NET.Test.Sdk`) | Unit-test framework | Named by the spec §8. xUnit v3 also works; 2.9.x is the conservative default. |
| `coverlet.collector` | latest | Coverage collector (`dotnet test --collect:"XPlat Code Coverage"`) | Standard, zero-friction. Optional for Phase 1 but cheap. |
| GitHub Actions `actions/checkout` | **v4** | Check out the repo in CI | Current major. |
| GitHub Actions `actions/setup-dotnet` | **v4** | Install the .NET SDK on the runner | Current major; `dotnet-version: '8.0.x'`. (Note: there have been transient "can't download 8.x SDK" hiccups on Windows runners in 2025 — if CI flakes on the install, that's a known upstream issue, retry or pin a patch version.) |

### Supporting (Phase 1 only — deliberately minimal)

| Library | Version | Purpose | When |
|---|---|---|---|
| `Microsoft.AspNetCore.Mvc.Testing` | 8.0.x | `WebApplicationFactory<Program>` for the "host starts cleanly" integration test | Add it in Phase 1 *only if* you want the host-start test to use `WebApplicationFactory`. Simpler alternative for Phase 1: a plain `Host`/`WebApplication` `StartAsync`/`StopAsync` test with no factory. Either is acceptable; the factory becomes load-bearing in Phase 5. **Recommend: skip the factory in Phase 1, use a direct `StartAsync`/`StopAsync` smoke test**, to keep the test project's dependency graph tiny. |
| `NSubstitute` / `Polly` / `Serilog` / `Microsoft.AspNetCore.Authentication.*` | — | **NOT in Phase 1.** | Phases 2 (NSubstitute, Polly, QbErrors), 5 (auth), and the optional Serilog logging all come later. Do not pull them now. |

### Alternatives considered (and rejected for Phase 1)

| Instead of | Could use | Verdict |
|---|---|---|
| Hand-written `[ComImport]` interface stub committed now | `tlbimp`-generated `Interop.QBXMLRP2Lib.dll` committed now | The `tlbimp` route is the STACK.md recommendation **and the long-term answer** — but `tlbimp` requires either the QuickBooks SDK or at least `QBXMLRP2.dll` to run, and **neither is present on the build box**. So Phase 1 commits a small hand-written `[ComImport]`-decorated interface (`QBXMLRP2Lib.cs` with the right `[Guid]`/`[ComImport]`/`[InterfaceType]` attributes for `IRequestProcessor5`/`RequestProcessor2`) inside the `Qb.Com` project. It compiles SDK-free, gives static typing, and is **swapped for the real `tlbimp`-generated DLL during Phase 9 on the QB host** (note this explicitly in the Phase-1 PLAN and in the `Qb.Com` project README/comment). This is a known, supported pattern (you don't need the interop assembly to *declare* a COM interface; you need it — or your own declarations — to *call* one). |
| `Microsoft.NET.Sdk.Web` for the host | `Microsoft.NET.Sdk.Worker` (`dotnet new worker`) | Worker SDK is lighter, but the project *will* host an ASP.NET Core API in Phase 5 — start with `Sdk.Web` so the host shape doesn't churn. `AddWindowsService()` works with both. |
| Three projects (host / `Qb.Com` / tests) | Two projects (host+adapter together / tests) | **No** — merging the COM adapter into the host means the host references the interop metadata, which drags COM into the test project transitively and weakens "builds without the SDK." Keep `Qb.Com` separate. This is SVC-01's literal wording ("referenced only by a separate `Qb.Com` adapter project"). |
| `PublishSingleFile` always-on | Single-file only in Release config | Single-file breaks the debugger attach (known .NET issue). Gate `<PublishSingleFile>true</PublishSingleFile>` behind `'$(Configuration)' == 'Release'`. |

**Installation (executor commands — run from `tech-legal/quickbooks/QbConnectService/`):**

```powershell
# scaffold
dotnet new sln  -n QbConnectService
dotnet new web      -o src/QbConnectService                 -f net8.0          # host  (TFM bumped to net8.0-windows in the csproj)
dotnet new classlib -o src/QbConnectService.Qb.Com          -f net8.0-windows  # COM adapter (ONLY project with the interop reference)
dotnet new xunit    -o src/QbConnectService.Tests           -f net8.0
dotnet sln add src/QbConnectService/QbConnectService.csproj src/QbConnectService.Qb.Com/QbConnectService.Qb.Com.csproj src/QbConnectService.Tests/QbConnectService.Tests.csproj

# host deps
dotnet add src/QbConnectService package Microsoft.Extensions.Hosting.WindowsServices --version 8.0.*
dotnet add src/QbConnectService package Microsoft.Extensions.Hosting               --version 8.0.*

# project references (host -> Qb.Com ; tests -> host  — tests must NOT reference Qb.Com)
dotnet add src/QbConnectService reference src/QbConnectService.Qb.Com/QbConnectService.Qb.Com.csproj
dotnet add src/QbConnectService.Tests reference src/QbConnectService/QbConnectService.csproj

# test deps (xunit + runner + Test.Sdk come from `dotnet new xunit`; add coverage)
dotnet add src/QbConnectService.Tests package coverlet.collector
```

Then hand-edit the three `.csproj` files (see Code Examples) and add `Interop/QBXMLRP2Lib.cs` to `Qb.Com`.

---

## Architecture Patterns

### Recommended directory tree (Phase-1 subset of spec §6 / ARCHITECTURE.md)

```
tech-legal/quickbooks/QbConnectService/
├── QbConnectService.sln
├── .gitignore                              # OPTIONAL local one; or rely on the repo-root .gitignore (recommend: repo-root)
├── src/
│   ├── QbConnectService/                   # ASP.NET Core host — net8.0-windows, x86
│   │   ├── QbConnectService.csproj
│   │   ├── Program.cs                      # Host.CreateApplicationBuilder / WebApplication.CreateBuilder + AddWindowsService()
│   │   ├── Worker.cs                        # a trivial BackgroundService heartbeat (logs "alive" every N s) — placeholder, no endpoints
│   │   ├── Qb/
│   │   │   └── IRequestProcessor.cs        # THE SEAM — string/bool/int/enum only, no COM types
│   │   ├── appsettings.json                # committed in Phase 1? NO — see note. Commit appsettings.sample.json only.
│   │   └── appsettings.sample.json         # committed; documents the (future) config keys with placeholders
│   ├── QbConnectService.Qb.Com/            # COM adapter — net8.0-windows; the ONLY project referencing the interop metadata
│   │   ├── QbConnectService.Qb.Com.csproj
│   │   ├── Interop/
│   │   │   └── QBXMLRP2Lib.cs              # hand-written [ComImport] interface stub (→ replaced by tlbimp DLL in Phase 9)
│   │   ├── RealRequestProcessor.cs         # [SupportedOSPlatform("windows")] adapter — Phase 1: throws NotImplementedException; Phase 2 fills it
│   │   └── README.md                        # one paragraph: "this is the only COM-touching project; the Interop stub is replaced by a tlbimp-generated Interop.QBXMLRP2Lib.dll on the QB host in Phase 9"
│   └── QbConnectService.Tests/             # xUnit — net8.0; references the host only, never Qb.Com
│       ├── QbConnectService.Tests.csproj
│       ├── Fakes/
│       │   └── FakeRequestProcessor.cs     # implements IRequestProcessor — canned responses + scriptable error queue
│       ├── FakeRequestProcessorTests.cs    # exercises the fake (SVC-02)
│       ├── HostStartupTests.cs             # builds the Host, StartAsync, assert running, StopAsync — clean (SVC-04)
│       └── BuildConfigTests.cs             # reflection assertion: host assembly is x86 / targets net8.0-windows (SVC-03)  [optional but recommended]
├── README.md                                # stub now; deploy runbook grows in Phase 9
└── scripts/                                 # empty/absent in Phase 1; populated in Phase 9
```

> **`appsettings.json` note:** the spec says the *real* `appsettings.json` is gitignored and `appsettings.sample.json` is committed. In Phase 1 there's no real config to speak of — recommend: commit `appsettings.sample.json` (with the future keys as placeholders, copied from spec §6) and add `quickbooks/QbConnectService/src/QbConnectService/appsettings.json` to `.gitignore` now (gitignore-before-the-file, per PITFALLS #18). Do **not** commit a real `appsettings.json`.

### Pattern 1: The `IRequestProcessor` seam (COM only at the edge)

**What:** A hand-rolled C# interface, one method per real `QBXMLRP2.RequestProcessor` COM method, **with no COM types in its signature** — every parameter/return is `string`, `bool`, `int`, or a plain C# `enum` defined alongside it. `RealRequestProcessor` (in `Qb.Com`) is the only class that imports the COM type; `FakeRequestProcessor` (in tests) is a plain object. The host registers one or the other in DI; the test host registers the fake.

**When to use:** Always, here. It's SVC-01/SVC-02. If a COM type ever appears in `IRequestProcessor`'s surface, the host + test projects must reference the interop metadata and "builds without the SDK" is broken.

**Minimal Phase-1 surface** (enough to model `OpenConnection2 / BeginSession / ProcessRequest / EndSession / CloseConnection` for Phase 2 to build on; do **not** implement the manager now — just define the seam):

```csharp
// src/QbConnectService/Qb/IRequestProcessor.cs
namespace QbConnectService.Qb;

/// <summary>Connection type passed to OpenConnection2. Mirrors QBXMLRPConnectionType.</summary>
public enum QbConnectionType
{
    Unknown = 0,
    LocalQBD = 1,          // localQBD — in-process, QuickBooks on the same box (the only one this service uses)
    LocalQBDLaunchUI = 2,  // localQBDLaunchUI — attended apps only; never used here
    RemoteQBD = 3,
    RemoteQBOE = 4,
}

/// <summary>File open mode passed to BeginSession. Mirrors QBFileMode.</summary>
public enum QbFileMode
{
    DoNotCare = 0,   // qbFileOpenDoNotCare — the only mode this service uses
    SingleUser = 1,  // qbFileOpenSingleUser — NEVER used (would lock humans out)
    MultiUser = 2,   // qbFileOpenMultiUser
}

/// <summary>
/// Thin, mockable seam over QBXMLRP2.RequestProcessor. NO COM types in this surface — string/bool/int/enum only,
/// so the host and test assemblies build with no QuickBooks SDK installed. The only implementation that touches
/// COM is QbConnectService.Qb.Com.RealRequestProcessor; FakeRequestProcessor (tests) is a plain object.
/// </summary>
public interface IRequestProcessor : IDisposable
{
    /// <summary>OpenConnection2(appId, appName, connectionType).</summary>
    void OpenConnection(string appId, string appName, QbConnectionType connectionType);

    /// <summary>BeginSession(companyFilePath, openMode) -> session ticket. Empty companyFilePath = "use the open file".</summary>
    string BeginSession(string companyFilePath, QbFileMode openMode);

    /// <summary>ProcessRequest(ticket, qbXmlRequest) -> raw qbXML response string.</summary>
    string ProcessRequest(string ticket, string qbXmlRequest);

    /// <summary>QBXMLVersionsForSession(ticket) -> the qbXML spec versions this session accepts (e.g. ["13.0","16.0"]).</summary>
    string[] GetSupportedQbXmlVersions(string ticket);

    /// <summary>EndSession(ticket).</summary>
    void EndSession(string ticket);

    /// <summary>CloseConnection().</summary>
    void CloseConnection();

    /// <summary>Wraps RequestProcessor2.AuthPreferences.PutUnattendedModePref in the real impl; no-op in the fake.</summary>
    void SetUnattendedModePreference(bool required);
}
```

> Notes for the planner: this is intentionally a *little* richer than the bare 5 COM calls — it adds `GetSupportedQbXmlVersions` (Phase 2/5 need it for `/api/health` and the startup version self-check, PITFALLS #7) and `SetUnattendedModePreference` (Phase 2/9 unattended mode). All still primitive-typed. `IDisposable` lets the host/manager release the COM object via `Dispose` without the interface knowing about `Marshal.FinalReleaseComObject`. Don't gold-plate beyond this in Phase 1.

### Pattern 2: `FakeRequestProcessor` — canned responses + scriptable errors

**What:** A plain C# class implementing `IRequestProcessor`, holding (a) a dictionary mapping a *request key* → canned qbXML response string, and (b) a `Queue<Exception>` of pre-loaded errors to throw on the next call(s). The "request key" should be the **top-level `*Rq` element name** parsed out of the incoming qbXML (e.g. `CompanyQueryRq`, `CustomerAddRq`) — robust and matches how the real qbXML round-trip is keyed. Fall back to a default canned response (or throw an "unscripted request" error) if no key matches.

**Why this design:** Keying by `*Rq` element name (not by exact string match) means Phase 3+ tests can set up `fake.AddResponse("CompanyQueryRq", File.ReadAllText("fixtures/company-info.xml"))` without caring about whitespace/attribute order in the request the builder produced. The error queue lets Phase 2 tests script "dead ticket on the 1st `ProcessRequest`, success on the retry" by enqueuing one `COMException(unchecked((int)0x8004040D))` then leaving the queue empty.

**Phase-1 scope:** the fake exists and is exercised by *one* test. It doesn't need every canned response yet — Phase 3/4/5 tests add fixtures as needed. Phase 1's test just proves: a scripted error is thrown then drained; a canned response keyed by `*Rq` name comes back; `BeginSession` returns a fake ticket; lifecycle calls don't throw.

```csharp
// src/QbConnectService.Tests/Fakes/FakeRequestProcessor.cs
using System.Runtime.InteropServices;
using System.Xml.Linq;
using QbConnectService.Qb;

namespace QbConnectService.Tests.Fakes;

public sealed class FakeRequestProcessor : IRequestProcessor
{
    private readonly Dictionary<string, string> _responses = new(StringComparer.OrdinalIgnoreCase);
    private readonly Queue<Exception> _errors = new();
    public List<string> CallLog { get; } = new();
    public string[] SupportedQbXmlVersions { get; set; } = ["13.0", "16.0"];
    public bool UnattendedModePreference { get; private set; }

    /// <summary>Register a canned qbXML response keyed by the top-level *Rq element name (e.g. "CompanyQueryRq").</summary>
    public FakeRequestProcessor AddResponse(string requestElementName, string qbXmlResponse)
    { _responses[requestElementName] = qbXmlResponse; return this; }

    /// <summary>Make the SOON-est lifecycle/process call throw this. Enqueue several to script a sequence.</summary>
    public FakeRequestProcessor EnqueueError(Exception ex) { _errors.Enqueue(ex); return this; }

    /// <summary>Convenience: enqueue a COMException with a QuickBooks-style HRESULT (e.g. 0x8004040D = invalid ticket).</summary>
    public FakeRequestProcessor EnqueueComError(int hresult, string? message = null)
        => EnqueueError(new COMException(message ?? $"Fake QuickBooks COM error 0x{hresult:X8}", hresult));

    private void ThrowIfScripted([System.Runtime.CompilerServices.CallerMemberName] string caller = "")
    { CallLog.Add(caller); if (_errors.Count > 0) throw _errors.Dequeue(); }

    public void OpenConnection(string appId, string appName, QbConnectionType type) => ThrowIfScripted();
    public string BeginSession(string companyFilePath, QbFileMode mode) { ThrowIfScripted(); return "FAKE-TICKET-0001"; }
    public string[] GetSupportedQbXmlVersions(string ticket) { ThrowIfScripted(); return SupportedQbXmlVersions; }
    public void EndSession(string ticket) => ThrowIfScripted();
    public void CloseConnection() => ThrowIfScripted();
    public void SetUnattendedModePreference(bool required) { ThrowIfScripted(); UnattendedModePreference = required; }
    public void Dispose() => CallLog.Add(nameof(Dispose));

    public string ProcessRequest(string ticket, string qbXmlRequest)
    {
        ThrowIfScripted();
        var rqName = TryGetRequestElementName(qbXmlRequest);
        if (rqName is not null && _responses.TryGetValue(rqName, out var canned)) return canned;
        if (_responses.TryGetValue("*", out var fallback)) return fallback;
        throw new InvalidOperationException($"FakeRequestProcessor: no canned response for request '{rqName ?? "<unparsed>"}'. Call AddResponse(...).");
    }

    private static string? TryGetRequestElementName(string qbXml)
    {
        try
        {
            var doc = XDocument.Parse(qbXml);
            // <QBXML><QBXMLMsgsRq onError="..."><FooRq>...</FooRq></QBXMLMsgsRq></QBXML>
            return doc.Root?.Element("QBXMLMsgsRq")?.Elements().FirstOrDefault()?.Name.LocalName
                ?? doc.Descendants().FirstOrDefault(e => e.Name.LocalName.EndsWith("Rq", StringComparison.Ordinal))?.Name.LocalName;
        }
        catch { return null; }
    }
}
```

### Pattern 3: Tri-mode host — `AddWindowsService()` as a no-op outside the SCM

**What:** `Program.cs` builds a Generic/Web host, calls `builder.Services.AddWindowsService(...)`, and runs. When the process is launched from a console or by Task Scheduler, `AddWindowsService()` detects it's *not* under the Service Control Manager and does nothing — the host just runs normally (and `RunAsync`/`Run` blocks until Ctrl-C or process kill). When launched by the SCM, it installs the `WindowsServiceLifetime` and an EventLog logger. **One published exe, three launch modes, zero code branches.** (SVC-04.)

**Phase-1 endpoints:** none required — Phase 5 owns the REST API. For Phase 1, the host just needs to *start and run*. Recommend a trivial `Worker : BackgroundService` that logs a heartbeat every ~30 s (so "is it alive" is observable in console/EventLog) and nothing else. Do **not** add a `/healthz` endpoint or any Kestrel HTTPS binding in Phase 1 — that's scope creep into Phase 5. (If you used `Microsoft.NET.Sdk.Web`, Kestrel will bind a default HTTP port; that's fine and harmless for now, or set `builder.WebHost.UseKestrel()` aside and just `app.Run()` — keep it boring.)

```csharp
// src/QbConnectService/Program.cs
using QbConnectService;

var builder = WebApplication.CreateBuilder(args);

// SVC-04: same exe runs as console / Windows service / scheduled task — this is a no-op when not launched by the SCM.
builder.Services.AddWindowsService(o => o.ServiceName = "QbConnectService");

// Phase 1 placeholder: a heartbeat hosted service. Real endpoints (health/qbxml/ops) land in Phase 5.
builder.Services.AddHostedService<Worker>();

// Phase 2 will register the real QbConnectionManager + (on Windows, non-test) RealRequestProcessor here.
// builder.Services.AddSingleton<IRequestProcessor>(sp => OperatingSystem.IsWindows() && !sp.GetRequiredService<IHostEnvironment>().IsEnvironment("Testing")
//     ? new QbConnectService.Qb.Com.RealRequestProcessor(...) : new FakeRequestProcessor());

var app = builder.Build();
app.MapGet("/", () => "QbConnectService (Phase 1 skeleton). REST API arrives in Phase 5.");  // harmless; or omit
app.Run();

// Needed so QbConnectService.Tests can use WebApplicationFactory<Program> later (Phase 5). Harmless now.
public partial class Program { }
```

```csharp
// src/QbConnectService/Worker.cs
namespace QbConnectService;

public sealed class Worker(ILogger<Worker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("QbConnectService worker started ({Time:o})", DateTimeOffset.UtcNow);
        while (!stoppingToken.IsCancellationRequested)
        {
            logger.LogDebug("QbConnectService alive ({Time:o})", DateTimeOffset.UtcNow);
            try { await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken); } catch (OperationCanceledException) { break; }
        }
        logger.LogInformation("QbConnectService worker stopping");
    }
}
```

### Anti-patterns to avoid in Phase 1

- **Putting any COM type (`QBXMLRP2Lib.*`, `IRequestProcessor5`, `RequestProcessor2`) in `IRequestProcessor`'s signature.** Breaks SDK-free build. Surface = `string`/`bool`/`int`/`enum` only. (PITFALLS, STACK "What NOT to Use".)
- **The test project referencing `QbConnectService.Qb.Com`.** It must reference only the host. If a test needs the COM adapter type, the seam is wrong.
- **Building the host as AnyCPU/x64.** SVC-03 says x86 (the QB SDK COM is 32-bit; an x64 host gets `0x80040154 Class not registered` even though it *is* registered — note this for Phase 2/9, but the *setting* lands now). Set `PlatformTarget=x86` + `RuntimeIdentifier=win-x86`.
- **`PublishSingleFile=true` unconditionally.** Breaks debugger attach. Gate it to Release. (STACK "What NOT to Use".)
- **Implementing `QbConnectionManager`, `QbErrors`, `QbXmlBuilder`/`Parser`, controllers, Kestrel HTTPS, auth, the audit log, or any op.** All Phase 2–7. Phase 1 is skeleton + seam + fakes + CI, full stop. (ROADMAP §"Phase 1".)
- **Committing a real `appsettings.json` or any machine-specifics.** Commit `appsettings.sample.json` only; gitignore the real file now. (PITFALLS #18.)
- **Adding `quickbooks/QbConnectService/` as a nested git repo** (e.g. running `git init` there, or `dotnet new` leaving a `.git`). One repo. The executor should `git add` specific paths, never `git add -A`/`.`.
- **`tlbimp` at build time / a NuGet `Interop.QBXMLRP2Lib` package.** No build-time SDK dependency, and the community NuGet mirrors are unmaintained. Commit a hand-written `[ComImport]` stub now; swap for a real `tlbimp` DLL in Phase 9 on the QB host. (STACK.)

---

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| "Run the same exe as console / Windows service / scheduled task" | A `ServiceBase` subclass + a separate console entry point + `#if SERVICE` | `Microsoft.Extensions.Hosting.WindowsServices` → `AddWindowsService()` | It's a no-op outside the SCM; one exe, zero branches. This is exactly SVC-04. |
| Windows-service install/uninstall | A custom installer | `sc.exe create … binPath= "…\QbConnectService.exe" obj= ".\svc_qbsdk" password= "…" start= auto` + `sc.exe failure … actions= restart/60000/…` | Standard, scriptable. (Phase 9 — `install-service.ps1` — *not* Phase 1; mentioned so the executor doesn't invent something now.) |
| Test framework / runner / coverage | A custom test harness | xUnit 2.9.x + `xunit.runner.visualstudio` + `Microsoft.NET.Test.Sdk` + `coverlet.collector` | `dotnet new xunit` wires it; `dotnet test` runs it. |
| Parsing the `*Rq` element name out of qbXML in the fake | Regex/substring hunting | `System.Xml.Linq.XDocument.Parse` then walk `QBXML/QBXMLMsgsRq/<first child>` | In-box, robust to whitespace/attribute order — and the real builder/parser in Phase 3 use `XDocument` too. |
| CI for a .NET solution on Windows | A bespoke build script | GitHub Actions `windows-latest` + `actions/checkout@v4` + `actions/setup-dotnet@v4` + `dotnet restore/build/test` | The repo's CI home is `.github/workflows/` (does not exist yet — Phase 1 creates it). |

**Key insight:** Every one of these has a one-liner blessed answer in the .NET/GitHub ecosystem. Phase 1's job is to *wire the blessed answers together correctly*, not to invent anything. The only thing genuinely hand-written in Phase 1 is `IRequestProcessor` (a ~6-method interface) and `FakeRequestProcessor` (a ~60-line class) and the `[ComImport]` interop stub — and even those follow well-known patterns.

---

## Common Pitfalls (Phase-1-relevant slice of `.planning/research/PITFALLS.md`)

### Pitfall 1: `tlbimp` can't run on the build box → "we can't make a buildable solution"
**What goes wrong:** Executor follows STACK.md's "commit the `tlbimp`-generated `Interop.QBXMLRP2Lib.dll`" verbatim, discovers `tlbimp` needs `QBXMLRP2.dll` (i.e. the SDK), which isn't installed here, and gets stuck.
**How to avoid:** Phase 1 commits a **hand-written `[ComImport]` interface declaration** (`src/QbConnectService.Qb.Com/Interop/QBXMLRP2Lib.cs`) — the real `tlbimp`-generated DLL replaces it during Phase 9 on the QB host. A `[ComImport]` interface declaration does not require the type library to compile. The `PLAN.md` must say this explicitly so the executor doesn't hunt for the SDK.
**Warning sign:** Executor tries `tlbimp …` and it errors with "could not load type library."

### Pitfall 2: AnyCPU/x64 build (SVC-03 says x86)
**What goes wrong:** Default `dotnet new` projects are AnyCPU. The COM activation (`0x80040154`) fails on the host much later (Phase 2/9), and the single-file publish produces a 64-bit exe. The *root cause* is a Phase-1 omission.
**How to avoid:** In the host `.csproj`: `<PlatformTarget>x86</PlatformTarget>` and `<RuntimeIdentifier>win-x86</RuntimeIdentifier>` (the latter so `dotnet publish -r win-x86` is the documented command and self-contained single-file works). Add a `BuildConfigTests` reflection test that asserts the built host assembly's `PEKind`/`ImageFileMachine` is `I386`/x86 and its target framework attribute is `net8.0-windows` — this *makes SVC-03 verifiable in CI* without QuickBooks. The pure builder/parser/test assemblies can stay AnyCPU; only the host that does COM needs x86.
**Warning sign:** `dotnet publish` output exe runs but `corflags`/reflection says it's x64; `BuildConfigTests` would catch it.

### Pitfall 3: `PublishSingleFile` breaks the debugger
**What goes wrong:** `<PublishSingleFile>true</PublishSingleFile>` set unconditionally → can't attach the debugger to a debug build.
**How to avoid:** `<PublishSingleFile Condition="'$(Configuration)' == 'Release'">true</PublishSingleFile>`. Also set `<SelfContained>true</SelfContained>` + `<IncludeNativeLibrariesForSelfExtract>true</IncludeNativeLibrariesForSelfExtract>` for the single-file Release build; document the publish command (`dotnet publish src/QbConnectService -c Release -r win-x86`).
**Warning sign:** "single-file apps don't support debugging" error in VS.

### Pitfall 4: Test project transitively picks up the interop metadata
**What goes wrong:** Someone adds a `ProjectReference` from `QbConnectService.Tests` to `QbConnectService.Qb.Com` "for convenience," and now the test assembly carries COM type metadata — `<EmbedInteropTypes>` games, and "builds without the SDK" gets murky.
**How to avoid:** Tests reference **only** `QbConnectService` (which references `Qb.Com`, but the interop reference in `Qb.Com` is `<EmbedInteropTypes>false</EmbedInteropTypes>` and not re-exposed publicly — `RealRequestProcessor` is the only public type, behind `IRequestProcessor`). The fake lives *in the test project*. A `dotnet build` on a clean Windows runner with no QuickBooks is the proof — that's exactly what CI does (SVC-05).
**Warning sign:** `dotnet list reference` on the tests project shows `Qb.Com`.

### Pitfall 5: `appsettings.json` / `.env` accidentally committed (PITFALLS #18)
**What goes wrong:** Real config (eventually holds the bearer token, company-file path) gets tracked.
**How to avoid:** Append to the **existing** repo-root `.gitignore` *now*, before any real config file exists: `quickbooks/QbConnectService/src/QbConnectService/appsettings.json`, `quickbooks/clients/.env`, plus build artifacts (`bin/`, `obj/` under `quickbooks/`). Commit only `appsettings.sample.json`. Don't clobber the existing `.gitignore` — append.
**Warning sign:** `git status` shows `appsettings.json` as untracked-and-about-to-be-added.

### Pitfall 6: CI flakes installing the .NET 8 SDK on the Windows runner
**What goes wrong:** `actions/setup-dotnet@v4` with `dotnet-version: '8.0.x'` intermittently fails to download the SDK from Microsoft's builds server (a real 2025 issue on Windows hosted runners).
**How to avoid:** It's mostly transient — `actions/setup-dotnet@v4` is still the right action. If it recurs, pin a specific patch (`'8.0.404'` or similar) and/or rely on the SDK preinstalled on `windows-latest`. Not a Phase-1 blocker; note it in the PLAN so the executor doesn't panic on a red CI run that's an infra hiccup.
**Warning sign:** CI log: "Failed to download … dotnet-sdk-8.0.x … from https://builds.dotnet.microsoft.com".

### Pitfall 7 (forward-looking, set now): qbXML version PI (PITFALLS #7)
Not a Phase-1 task, but the `IRequestProcessor` seam includes `GetSupportedQbXmlVersions` so Phase 2/5 can do the `HostQueryRq` / startup self-check. Just make sure Phase 1 *includes that method on the interface* (and the fake returns a plausible `["13.0","16.0"]`) so Phase 2 isn't blocked.

---

## Code Examples

### `src/QbConnectService/QbConnectService.csproj` (host — x86, single-file in Release)

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0-windows</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <RootNamespace>QbConnectService</RootNamespace>
    <AssemblyName>QbConnectService</AssemblyName>
    <OutputType>Exe</OutputType>

    <!-- SVC-03: x86 to match the 32-bit QuickBooks SDK COM server -->
    <PlatformTarget>x86</PlatformTarget>
    <RuntimeIdentifier>win-x86</RuntimeIdentifier>

    <!-- SVC-03: single-file publish — Release only (single-file breaks the debugger) -->
    <PublishSingleFile Condition="'$(Configuration)' == 'Release'">true</PublishSingleFile>
    <SelfContained Condition="'$(Configuration)' == 'Release'">true</SelfContained>
    <IncludeNativeLibrariesForSelfExtract Condition="'$(Configuration)' == 'Release'">true</IncludeNativeLibrariesForSelfExtract>
    <InvariantGlobalization>true</InvariantGlobalization>

    <!-- not a desktop app -->
    <UseWindowsForms>false</UseWindowsForms>
    <UseWPF>false</UseWPF>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Extensions.Hosting.WindowsServices" Version="8.0.1" />
    <PackageReference Include="Microsoft.Extensions.Hosting" Version="8.0.1" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\QbConnectService.Qb.Com\QbConnectService.Qb.Com.csproj" />
  </ItemGroup>

  <ItemGroup>
    <None Update="appsettings.sample.json" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
```
> Verify the exact patch version of `Microsoft.Extensions.Hosting.WindowsServices` 8.0.x at scaffold time (`dotnet add package … --version 8.0.*` resolves the latest 8.0 patch — `8.0.1` shown is illustrative). Don't pin a 9.0.x/10.0.x just because it loads on net8.0; keep the LTS line.

### `src/QbConnectService.Qb.Com/QbConnectService.Qb.Com.csproj` (COM adapter — the ONLY interop-bearing project)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0-windows</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <RootNamespace>QbConnectService.Qb.Com</RootNamespace>
    <!-- COM activation is x86-only; keep this project's bitness consistent with the host -->
    <PlatformTarget>x86</PlatformTarget>
    <!-- Required to allow [ComImport]/runtime COM activation -->
    <EnableComHosting>false</EnableComHosting>
    <AllowUnsafeBlocks>false</AllowUnsafeBlocks>
  </PropertyGroup>

  <!-- Phase 1: a hand-written [ComImport] interface stub in Interop/QBXMLRP2Lib.cs.
       Phase 9 (on the QB host): replace with a tlbimp-generated Interop.QBXMLRP2Lib.dll referenced like:
       <ItemGroup><Reference Include="Interop.QBXMLRP2Lib"><HintPath>lib\Interop.QBXMLRP2Lib.dll</HintPath><EmbedInteropTypes>false</EmbedInteropTypes></Reference></ItemGroup>
       ...and delete Interop/QBXMLRP2Lib.cs. -->
</Project>
```

### `src/QbConnectService.Qb.Com/Interop/QBXMLRP2Lib.cs` (hand-written stub — Phase 1)

```csharp
// PHASE-1 STUB. This hand-written [ComImport] declaration lets the solution build with NO QuickBooks SDK installed.
// In Phase 9, on the QuickBooks host, regenerate the real interop:
//   tlbimp "%CommonProgramFiles%\Intuit\QuickBooks\QBXMLRP2.dll" /out:..\lib\Interop.QBXMLRP2Lib.dll
// then reference that DLL (EmbedInteropTypes=false) and delete this file.
using System.Runtime.InteropServices;

namespace QbConnectService.Qb.Com.Interop;

// GUIDs below are the published QBXMLRP2 1.0 type-library GUIDs. VERIFY against the on-box type library in Phase 9
// (tlbimp output is authoritative); they are stable across SDK versions but treat as "confirm on deploy".
[ComImport, Guid("AFB73F0F-5C0E-4D8D-9B47-7E2DAB6C3CDB"), CoClass(typeof(RequestProcessor2Class))]
public interface RequestProcessor2 : IRequestProcessor2 { }

[ComImport, Guid("F4C82CBC-3A2C-4B6C-9F2D-1B4C0F0F0F0F"), ClassInterface(ClassInterfaceType.None)]
public class RequestProcessor2Class { }

[ComImport, Guid("0C68E2A5-9F2A-4D2E-9C2A-2C0C0C0C0C0C"),
 InterfaceType(ComInterfaceType.InterfaceIsDual)]
public interface IRequestProcessor2
{
    void OpenConnection2([In, MarshalAs(UnmanagedType.BStr)] string appID,
                         [In, MarshalAs(UnmanagedType.BStr)] string appName,
                         [In] int connectionType /* QBXMLRPConnectionType */);
    [return: MarshalAs(UnmanagedType.BStr)]
    string BeginSession([In, MarshalAs(UnmanagedType.BStr)] string qbCompanyFileName,
                        [In] int qbFileMode /* QBFileMode */);
    [return: MarshalAs(UnmanagedType.BStr)]
    string ProcessRequest([In, MarshalAs(UnmanagedType.BStr)] string ticket,
                          [In, MarshalAs(UnmanagedType.BStr)] string requestXML);
    [return: MarshalAs(UnmanagedType.BStr)]
    string QBXMLVersionsForSession([In, MarshalAs(UnmanagedType.BStr)] string ticket);
    void EndSession([In, MarshalAs(UnmanagedType.BStr)] string ticket);
    void CloseConnection();
    // AuthPreferences.PutUnattendedModePref lives on a sub-object in the real lib; in Phase 9 the tlbimp DLL exposes it.
}
```
> **Important caveat for the planner:** the GUIDs above are *placeholders that compile* — they are NOT verified against the real QBXMLRP2 type library, and the real interface shape (sub-objects like `AuthPreferences`, the exact method order) will differ. That's fine: this file's *only* job in Phase 1 is "the solution compiles SDK-free." `RealRequestProcessor` in Phase 1 just throws `NotImplementedException`. Phase 9 replaces this whole file with the `tlbimp` output. The `PLAN.md` should flag this clearly so a reviewer doesn't mistake the stub for "done COM interop."

### `src/QbConnectService.Qb.Com/RealRequestProcessor.cs` (Phase-1 stub)

```csharp
using System.Runtime.Versioning;
using QbConnectService.Qb;

namespace QbConnectService.Qb.Com;

/// <summary>
/// PHASE 1: stub only. The real COM adapter over QBXMLRP2.RequestProcessor — STA-pinned, x86 — is built in Phase 2.
/// This type is the ONLY thing in the solution that will touch a COM type; it lives in the isolated Qb.Com project.
/// </summary>
[SupportedOSPlatform("windows")]
public sealed class RealRequestProcessor : IRequestProcessor
{
    private const string NotYet = "RealRequestProcessor is implemented in Phase 2 (COM Session Lifecycle). " +
                                  "Phase 1 ships only the seam (IRequestProcessor) and FakeRequestProcessor.";
    public void OpenConnection(string appId, string appName, QbConnectionType type) => throw new NotImplementedException(NotYet);
    public string BeginSession(string companyFilePath, QbFileMode mode) => throw new NotImplementedException(NotYet);
    public string ProcessRequest(string ticket, string qbXmlRequest) => throw new NotImplementedException(NotYet);
    public string[] GetSupportedQbXmlVersions(string ticket) => throw new NotImplementedException(NotYet);
    public void EndSession(string ticket) => throw new NotImplementedException(NotYet);
    public void CloseConnection() => throw new NotImplementedException(NotYet);
    public void SetUnattendedModePreference(bool required) => throw new NotImplementedException(NotYet);
    public void Dispose() { }
}
```

### `src/QbConnectService.Tests/QbConnectService.Tests.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>     <!-- tests don't need -windows; keep AnyCPU -->
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.*" />
    <PackageReference Include="xunit" Version="2.9.*" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.*" />
    <PackageReference Include="coverlet.collector" Version="6.*" />
  </ItemGroup>
  <ItemGroup>
    <!-- ONLY the host. NEVER QbConnectService.Qb.Com. -->
    <ProjectReference Include="..\QbConnectService\QbConnectService.csproj" />
  </ItemGroup>
</Project>
```
> Note: a `net8.0` test project referencing a `net8.0-windows` host project is fine — the host's `windows` flavor is satisfied because tests run on Windows. If the test runner complains, change the test TFM to `net8.0-windows` (harmless).

### `src/QbConnectService.Tests/FakeRequestProcessorTests.cs` (SVC-02 — the test that exercises the fake)

```csharp
using System.Runtime.InteropServices;
using QbConnectService.Qb;
using QbConnectService.Tests.Fakes;
using Xunit;

public class FakeRequestProcessorTests
{
    [Fact]
    public void Lifecycle_calls_do_not_throw_and_BeginSession_returns_a_ticket()
    {
        IRequestProcessor rp = new FakeRequestProcessor();
        rp.OpenConnection("app-id", "QbConnectService", QbConnectionType.LocalQBD);
        var ticket = rp.BeginSession(companyFilePath: "", QbFileMode.DoNotCare);
        Assert.False(string.IsNullOrWhiteSpace(ticket));
        Assert.Contains("13.0", rp.GetSupportedQbXmlVersions(ticket));
        rp.EndSession(ticket);
        rp.CloseConnection();
        rp.Dispose();
    }

    [Fact]
    public void Canned_response_is_returned_keyed_by_request_element_name()
    {
        var fake = new FakeRequestProcessor()
            .AddResponse("CompanyQueryRq",
                "<?xml version=\"1.0\"?><QBXML><QBXMLMsgsRs><CompanyQueryRs statusCode=\"0\" statusSeverity=\"Info\" statusMessage=\"OK\">" +
                "<CompanyRet><CompanyName>Acme</CompanyName></CompanyRet></CompanyQueryRs></QBXMLMsgsRs></QBXML>");
        var ticket = fake.BeginSession("", QbFileMode.DoNotCare);
        var resp = fake.ProcessRequest(ticket,
            "<?qbxml version=\"13.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CompanyQueryRq/></QBXMLMsgsRq></QBXML>");
        Assert.Contains("Acme", resp);
    }

    [Fact]
    public void Scripted_COM_error_is_thrown_then_drained()
    {
        var fake = new FakeRequestProcessor().EnqueueComError(unchecked((int)0x8004040D), "invalid ticket");
        // first call throws...
        var ex = Assert.Throws<COMException>(() => fake.BeginSession("", QbFileMode.DoNotCare));
        Assert.Equal(unchecked((int)0x8004040D), ex.HResult);
        // ...and the queue is now empty, so the next call succeeds (this is exactly the "dead ticket then retry" shape Phase 2 needs)
        var ticket = fake.BeginSession("", QbFileMode.DoNotCare);
        Assert.False(string.IsNullOrWhiteSpace(ticket));
    }

    [Fact]
    public void Unscripted_request_throws_a_helpful_error()
    {
        var fake = new FakeRequestProcessor();
        var ticket = fake.BeginSession("", QbFileMode.DoNotCare);
        Assert.Throws<InvalidOperationException>(() =>
            fake.ProcessRequest(ticket, "<?qbxml version=\"13.0\"?><QBXML><QBXMLMsgsRq><CustomerAddRq/></QBXMLMsgsRq></QBXML>"));
    }
}
```

### `src/QbConnectService.Tests/HostStartupTests.cs` (SVC-04 — host starts & stops cleanly)

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Xunit;

public class HostStartupTests
{
    [Fact]
    public async Task Generic_host_with_the_worker_starts_and_stops_cleanly()
    {
        // Build the same host shape Program.cs builds, minus Kestrel — proves AddHostedService<Worker> + lifetime work.
        using var host = Host.CreateDefaultBuilder()
            .ConfigureServices(s => s.AddHostedService<QbConnectService.Worker>())
            .Build();
        await host.StartAsync();
        var lifetime = host.Services.GetRequiredService<IHostApplicationLifetime>();
        Assert.False(lifetime.ApplicationStopping.IsCancellationRequested);
        await host.StopAsync(TimeSpan.FromSeconds(5));   // must complete without throwing
    }
}
```
> Alternative (heavier): use `WebApplicationFactory<Program>` from `Microsoft.AspNetCore.Mvc.Testing` to boot the *actual* `Program.cs` and assert a 200 from `GET /`. Recommend the lighter version above for Phase 1; the factory pattern lands in Phase 5 where the API exists.

### `src/QbConnectService.Tests/BuildConfigTests.cs` (SVC-03 — make x86 / net8.0-windows verifiable in CI)

```csharp
using System.Reflection;
using System.Reflection.PortableExecutable;
using System.Runtime.Versioning;
using Xunit;

public class BuildConfigTests
{
    [Fact]
    public void Host_assembly_targets_net8_0_windows()
    {
        var asm = typeof(QbConnectService.Worker).Assembly;
        var tfm = asm.GetCustomAttribute<TargetFrameworkAttribute>()?.FrameworkName ?? "";
        Assert.Contains(".NETCoreApp,Version=v8.0", tfm);
        Assert.Contains("windows", tfm, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Host_assembly_is_x86()
    {
        var asmPath = typeof(QbConnectService.Worker).Assembly.Location;
        using var fs = File.OpenRead(asmPath);
        using var pe = new PEReader(fs);
        var h = pe.PEHeaders;
        // x86: machine == I386 and the "32-bit required" CorFlags bit is set
        Assert.Equal(Machine.I386, h.CoffHeader.Machine);
        Assert.True(h.CorHeader is not null && h.CorHeader.Flags.HasFlag(CorFlags.Requires32Bit));
    }
}
```
> If `Requires32Bit` proves finicky with the SDK's defaults, the `Machine.I386` check alone is a sufficient SVC-03 guard; keep at least that one.

### `.github/workflows/quickbooks-ci.yml` (SVC-05 — CI green with no QuickBooks)

```yaml
name: quickbooks-ci

on:
  push:
    branches: ["**"]
    paths:
      - "quickbooks/QbConnectService/**"
      - ".github/workflows/quickbooks-ci.yml"
  pull_request:
    paths:
      - "quickbooks/QbConnectService/**"
      - ".github/workflows/quickbooks-ci.yml"

jobs:
  build-test:
    runs-on: windows-latest          # required: x86 publish + Windows-only TFM; the runner has NO QuickBooks SDK — that's the point
    defaults:
      run:
        working-directory: quickbooks/QbConnectService
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0.x"     # builds the net8.0-windows target; LTS-only graph

      - name: Restore
        run: dotnet restore QbConnectService.sln

      - name: Build (Release)
        run: dotnet build QbConnectService.sln -c Release --no-restore

      - name: Test
        run: dotnet test QbConnectService.sln -c Release --no-build --verbosity normal --collect:"XPlat Code Coverage"

      # Optional sanity check that the x86 single-file publish actually works (no QuickBooks needed to publish):
      - name: Publish (x86 single-file) — smoke
        run: dotnet publish src/QbConnectService -c Release -r win-x86 --self-contained true -p:PublishSingleFile=true -o publish
```
> Path-filtering to `quickbooks/QbConnectService/**` is recommended — the `tech-legal` repo has unrelated content (India HR work, client folders), so don't run .NET CI on every push. Branch filter `["**"]` so it runs on the feature branch too. Verify on first run that `windows-latest` + `setup-dotnet@v4` + `8.0.x` resolves cleanly (PITFALLS #6).

### `.gitignore` — APPEND these lines (don't rewrite the file)

The current repo-root `.gitignore` is:
```
# Secrets are stored in OneDrive, not in repo
# keys/ folder contains only reference pointers

__pycache__/
*.pyc
.gitnexus
```
Append (Codex: `Add-Content` / append-only, never overwrite):
```
# --- QuickBooks Direct-SDK service (added Phase 1) ---
quickbooks/QbConnectService/src/QbConnectService/appsettings.json
quickbooks/clients/.env
# .NET build artifacts
quickbooks/**/bin/
quickbooks/**/obj/
quickbooks/QbConnectService/publish/
quickbooks/QbConnectService/**/*.user
```

---

## State of the Art

| Old approach | Current approach | When changed | Impact |
|---|---|---|---|
| `ServiceBase` subclass + separate console host + build configs/`#if` for "service vs console" | `Microsoft.Extensions.Hosting.WindowsServices` + `AddWindowsService()` (no-op outside the SCM) | .NET Core 3.0+ / mature in .NET 6–8 | One exe, all launch modes — exactly SVC-04. Don't write a `ServiceBase`. |
| `dynamic`/late-bound reflection to call COM, or `EmbedInteropTypes=true` baking metadata into the host | `tlbimp`-generated interop DLL (or a hand-written `[ComImport]` declaration) referenced only by an isolated adapter project with `EmbedInteropTypes=false` | long-standing best practice; reaffirmed in STACK.md | Static typing on the COM lifecycle + SDK-free build + clean adapter boundary. |
| `csc`/`msbuild` invoked by hand-rolled CI scripts | `dotnet restore/build/test` driven by GitHub Actions `actions/setup-dotnet@v4` on `windows-latest` | standard since ~2020 | The repo's CI home is `.github/workflows/` (created in Phase 1). |
| `appsettings.json` with secrets committed "for now" | gitignored real `appsettings.json` + committed `appsettings.sample.json`; gitignore-before-the-file | repo policy + PITFALLS #18 | Phase 1 sets this up so secrets never enter history. |

**Deprecated / not to use here:** `tlbimp` at build time (needs the SDK; not on the build box) → commit a stub now, real DLL in Phase 9. Community NuGet `Interop.QBXMLRP2Lib` mirrors → unmaintained, don't depend on them. `Microsoft.Extensions.Http.Resilience` for the (later) COM retry → wrong tool (it wraps `HttpClient`); Phase 2 uses bare `Polly` v8. None of these are Phase-1 actions anyway — listed so the executor doesn't reach for them.

---

## Open Questions

1. **Exact bitness of the QuickBooks Enterprise install on `10.120.254.13` (x86 vs x64 COM).**
   - What we know: SVC-03 says **x86**, and a 32-bit `QBXMLRP2` is the conservative assumption (modern QuickBooks 2022+ ships a 64-bit `QBXMLRP2` too, but the SDK still offers a 32-bit type library; STACK.md flags this as an open verify-on-deploy item). The build/COM activation must match the host.
   - What's unclear: the actual year/version on the host (PROJECT.md §Context, spec §11).
   - Recommendation for Phase 1: **build x86** as the requirement states — it works in CI regardless (CI doesn't activate COM), it's the spec, and if the host turns out 64-bit, flipping `PlatformTarget`/`RuntimeIdentifier` is a one-line change in Phase 2/9. Do not block Phase 1 on this; just leave a comment in the host `.csproj` noting "x86 per SVC-03; reconfirm host bitness in Phase 9."

2. **Whether to use `Microsoft.NET.Sdk.Web` or `Microsoft.NET.Sdk.Worker` for the host in Phase 1.**
   - What we know: the project *will* be an ASP.NET Core API (Phase 5). `AddWindowsService()` works with both. `Sdk.Web` + `WebApplication.CreateBuilder` is the smoother long-term path.
   - Recommendation: **`Sdk.Web`** (`dotnet new web`). It brings Kestrel along — harmless in Phase 1 (a default HTTP bind, or just `app.Run()` with the trivial `MapGet("/")`). Avoids re-shaping the host in Phase 5.

3. **`appsettings.sample.json` contents in Phase 1.**
   - What we know: spec §6 lists the future config keys (`Server:BindUrls`, `Auth:ApiToken`, `Qb:CompanyFilePath`, `Safety:AllowWrites`, `QbXml:Version`, `Audit:Path`, `Request:TimeoutSeconds`, …).
   - Recommendation: commit `appsettings.sample.json` with **all** those keys present as placeholders/comments now (it documents the surface and lets Phase 5+ just fill values). The real `appsettings.json` stays gitignored and absent.

---

## Suggested Task Breakdown for the PLAN (ordered, each = one commit)

> This is a *suggestion* for the planner — adjust granularity to taste, but keep "each task = one buildable, committable step" and "commit-per-task" (PROJECT.md build pipeline). Every task's verification must be runnable with **no QuickBooks installed**.

| # | Task | Key actions | Verification (no QuickBooks) |
|---|------|-------------|------------------------------|
| **1-1** | Solution scaffold | `dotnet new sln` + `dotnet new web` (host, `net8.0-windows`) + `dotnet new classlib` (`Qb.Com`, `net8.0-windows`) + `dotnet new xunit` (tests, `net8.0`); `dotnet sln add` all three; add project refs (host→`Qb.Com`, tests→host). Set the host `.csproj` x86 + single-file-in-Release properties. Append `.gitignore` lines. Commit `appsettings.sample.json` (placeholder keys). | `dotnet build QbConnectService.sln` succeeds; `dotnet list reference` shows tests→host only (NOT `Qb.Com`); `git status` clean of any real `appsettings.json`. |
| **1-2** | The COM seam | Add `src/QbConnectService/Qb/IRequestProcessor.cs` (the 6+ method interface + `QbConnectionType`/`QbFileMode` enums — primitive surface only). | `dotnet build` succeeds; a grep/review confirms no COM types in `IRequestProcessor.cs`. |
| **1-3** | Interop stub + RealRequestProcessor stub | Add `src/QbConnectService.Qb.Com/Interop/QBXMLRP2Lib.cs` (hand-written `[ComImport]` declaration, with the "replaced by tlbimp in Phase 9" comment) + `RealRequestProcessor.cs` (implements `IRequestProcessor`, every method `throw new NotImplementedException(...)`, `[SupportedOSPlatform("windows")]`) + a short `Qb.Com/README.md`. | `dotnet build` succeeds with NO QuickBooks SDK present (this is the SVC-01 proof at task level). |
| **1-4** | Tri-mode host wiring | `Program.cs`: `WebApplication.CreateBuilder` + `AddWindowsService(o => o.ServiceName = "QbConnectService")` + `AddHostedService<Worker>()` + `public partial class Program {}`; add `Worker.cs` (heartbeat `BackgroundService`). | `dotnet run --project src/QbConnectService` starts, logs the heartbeat, Ctrl-C stops cleanly; `dotnet publish src/QbConnectService -c Release -r win-x86 -p:PublishSingleFile=true` produces a single `QbConnectService.exe`. |
| **1-5** | `FakeRequestProcessor` + its test | Add `src/QbConnectService.Tests/Fakes/FakeRequestProcessor.cs` (canned-response dict keyed by `*Rq` element name + scriptable error queue) + `FakeRequestProcessorTests.cs` (lifecycle-no-throw, canned-response-by-key, scripted-COM-error-then-drained, unscripted-request-throws). | `dotnet test` passes; the fake test is the SVC-02 evidence. |
| **1-6** | Host-start + build-config tests | `HostStartupTests.cs` (build host, `StartAsync`/`StopAsync` clean) + `BuildConfigTests.cs` (host assembly is x86 / `net8.0-windows`). | `dotnet test` passes — SVC-04 and SVC-03 now machine-verified in CI. |
| **1-7** | CI workflow | Add `.github/workflows/quickbooks-ci.yml` (`windows-latest`, `checkout@v4`, `setup-dotnet@v4` `8.0.x`, `dotnet restore/build/test`, optional x86 publish smoke, path-filtered to `quickbooks/QbConnectService/**`). | Push the branch; the workflow runs and is green with no QuickBooks on the runner — SVC-05. (If `setup-dotnet` flakes downloading 8.0.x, retry / pin a patch — known infra issue, not a code defect.) |
| **1-8** *(optional)* | Stub `README.md` for `QbConnectService/` | One paragraph: what this is, "deploy runbook lands in Phase 9," pointer to the design spec. | Reviewer reads it. |

**Phase-1 done-ness check** (maps to ROADMAP §"Phase 1" success criteria): `dotnet build` + `dotnet test` succeed on a clean Windows box with no QuickBooks (SVC-01); only `Qb.Com` references the interop declaration (SVC-01); `FakeRequestProcessor` implements `IRequestProcessor`, returns canned responses, scripts errors, and a test exercises it (SVC-02); host targets `net8.0-windows`, publishes as a single x86 exe, and that exe runs as console / can be SCM-registered / can be Task-Scheduler-launched with no code change (SVC-03, SVC-04); CI runs on push, builds, tests, green without QuickBooks (SVC-05). **QuickBooks SDK itself is a runtime-only dependency for Phase 9 — not needed, not referenced, anywhere in Phases 1–8.**

---

## Sources

### Primary (HIGH confidence)
- **Project design spec** — `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` §6 (component/file layout), §3 (unattended/session-0, "identical binary all launch modes"), §8 (testing strategy). The spec of record.
- **`.planning/research/STACK.md`** — validated stack: `net8.0-windows`, `AddWindowsService()` no-op-outside-SCM, `tlbimp`-interop-DLL-committed pattern, `IRequestProcessor` primitive surface, x86 publish, `PublishSingleFile` Release-only, xUnit 2.9.x, the "what NOT to use" list. (This research's load-bearing source — itself MEDIUM-HIGH per its own header.)
- **`.planning/research/ARCHITECTURE.md`** — `IRequestProcessor` seam pattern (#1), recommended project structure, "Qb/ holds the entire COM-adjacent surface; controllers stay dumb," the suggested build order (Phase 1 = "seam + fake + pure-core skeleton + tests + CI").
- **`.planning/research/PITFALLS.md`** — Phase-1-relevant: #18 (config-committed), #5/#6 (x86/STA — the x86 *setting* is Phase 1), the "config hygiene" / "bitness" lines of the "Looks Done But Isn't" checklist; the P1 phase legend.
- **`.planning/REQUIREMENTS.md` SVC-01..SVC-05** and **`.planning/ROADMAP.md` Phase 1** — the exact success criteria.
- Microsoft Learn — *Create Windows Service using BackgroundService* (`learn.microsoft.com/dotnet/core/extensions/windows-service`) — `Microsoft.Extensions.Hosting.WindowsServices`, `AddWindowsService()`, `sc.exe create/failure`, single-file publish, `RuntimeIdentifier=win-x86`, `OutputType=exe`. (Cited via STACK.md; doc examples show 9.x/10.x package versions but the APIs apply on `net8.0-windows`/8.0.x.) — **HIGH**

### Secondary (MEDIUM confidence)
- **WebSearch (2026-05-11):** `actions/setup-dotnet@v4` is current; `dotnet-version: '8.0.x'` is the right value; there have been transient SDK-download failures on Windows hosted runners in 2025 (retry / pin a patch). Sources: github.com/actions/setup-dotnet (README) and its issues #491, #588, #611.
- **Repo inspection (2026-05-11):** repo root has no `.github/` dir yet; `.gitignore` is the 6-line file quoted above; `quickbooks/` currently contains only `dev/` (`MULTI-LLM.md`, `run-codex-phase.ps1`); `.planning/phases/01-foundation-mockable-com-seam/` exists and is empty; local SDK is .NET 10.0.107; git remote is `github.com/technijian-admin/tech-legal`; current branch `quickbooks/direct-sdk-integration-2026-05-11`. — **HIGH** (direct observation)

### Tertiary (LOW confidence — flagged for validation)
- The placeholder GUIDs / interface shape in the Phase-1 `QBXMLRP2Lib.cs` stub are *not* verified against the real QBXMLRP2 type library — they exist only to compile. Real interop is regenerated via `tlbimp` on the QB host in Phase 9. (This is by design; the stub's only Phase-1 job is "solution builds SDK-free.")
- Exact 8.0.x patch versions for `Microsoft.Extensions.Hosting[.WindowsServices]` — resolve at scaffold time with `dotnet add package … --version 8.0.*`; don't hardcode `8.0.1` blindly.

## Metadata

**Confidence breakdown:**
- Standard stack / project layout — **HIGH** — `dotnet`-scaffold mechanics + the project's own (verified) STACK/ARCHITECTURE docs + direct repo inspection.
- Tri-mode host (`AddWindowsService()` no-op outside SCM) — **HIGH** — Microsoft Learn + STACK.md, well-established.
- The `IRequestProcessor` seam & `FakeRequestProcessor` design — **HIGH** — load-bearing decision, thoroughly specified upstream; the surface here is a concrete instantiation of it.
- Interop-without-the-SDK approach (hand-written `[ComImport]` stub now, `tlbimp` DLL in Phase 9) — **MEDIUM-HIGH** — the *strategy* is sound and standard; the *specific stub GUIDs* are placeholders (acknowledged), which doesn't matter for Phase 1's build-only goal.
- x86 build — **HIGH that it's the requirement (SVC-03) and the safe default**; **MEDIUM** that the live host is actually 32-bit (unconfirmed — Phase 9 verify item; doesn't block Phase 1).
- CI workflow — **HIGH** on shape; **MEDIUM** on `setup-dotnet@v4` + `8.0.x` reliability on `windows-latest` (occasional 2025 download flakes — retryable infra issue).

**Research date:** 2026-05-11
**Valid until:** ~2026-06-10 (stable .NET/GitHub-Actions territory; re-check `actions/setup-dotnet` major version and the `Microsoft.Extensions.Hosting.WindowsServices` 8.0.x patch line if revisiting after that).
