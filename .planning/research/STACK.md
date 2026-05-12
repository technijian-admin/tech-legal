# Stack Research

**Domain:** Self-hosted Windows service wrapping QuickBooks Desktop SDK (QBXMLRP2 COM) behind a bearer-auth HTTPS REST API, in C#/.NET 8, plus a Python client library
**Researched:** 2026-05-11
**Confidence:** MEDIUM-HIGH (high on the .NET/ASP.NET Core stack; medium on exact QuickBooks SDK/qbXML version numbers — Intuit's docs are JS-rendered and would not yield to WebFetch, so SDK/qbXML specifics are corroborated from secondary sources, see Sources + "Open verification items")

---

## TL;DR — validated stack

The spec's stack is **sound and current**. Concrete picks:

- **Runtime:** .NET 8 (LTS), `net8.0-windows`, `PlatformTarget=x64`, `RuntimeIdentifier=win-x64`. Match the bitness of the installed QuickBooks/SDK (modern QuickBooks 2022+ ships a 64-bit `QBXMLRP2` — see version notes).
- **Web host:** ASP.NET Core Minimal API (or controllers — both fine; controllers match the spec's `Controllers/` layout) on Kestrel, HTTPS only.
- **Windows service hosting:** `Microsoft.Extensions.Hosting.WindowsServices` + `builder.Services.AddWindowsService(...)` (or `host.UseWindowsService()` if not using `WebApplicationBuilder`). It is a **no-op when not launched by the SCM**, so the same binary still runs from the CLI for dev and works under Task Scheduler. This directly satisfies the "identical binary in all launch modes" requirement in spec §3 and §6.
- **COM interop for QBXMLRP2:** a **`tlbimp`-generated `Interop.QBXMLRP2Lib.dll`** (equivalently: a Visual Studio "COM Reference" to *QBXMLRP2 1.0 Type Library* with `EmbedInteropTypes=false`), referenced by the *adapter* project only and **committed to the repo**. The interop DLL is pure metadata; it builds and tests run with **no QuickBooks SDK installed**. The actual `QBXMLRP2.RequestProcessor` COM class is only resolved/registered at *runtime* on the QuickBooks host.
- **The interface seam (the load-bearing requirement):** `IRequestProcessor` in the host project (no COM types in its signature — use plain `string`/`enum`/`int`), `RealRequestProcessor` in a *separate* `QbConnectService.Qb.Com` project (the only project that references `Interop.QBXMLRP2Lib`), wired in `Program.cs` only when running on Windows / not in test. Tests reference the host project + a `FakeRequestProcessor`, never the COM project.
- **Cert:** self-signed cert via `New-SelfSignedCertificate` → exported `.pfx`, loaded by Kestrel from `appsettings.json` (`Server:CertPath`/`Server:CertPassword`). Python side sets `QB_VERIFY_TLS=false` or points at the exported `.cer`.
- **Tests:** xUnit + `Microsoft.AspNetCore.Mvc.Testing` (`WebApplicationFactory`) for the integration layer; **NSubstitute** (or Moq) for `IRequestProcessor`; `Verify` (optional) or plain string-equality golden files for `QbXmlBuilder`/`QbXmlParser`.
- **Resilience:** `Polly` (via `Microsoft.Extensions.Http.Resilience` is overkill here — use raw `Polly` v8 `ResiliencePipeline`) for the single in-process retry-on-dead-ticket; a `SemaphoreSlim(1,1)` for serializing the SDK session (spec §2).
- **qbXML build/parse:** hand-rolled with `System.Xml.Linq` (`XDocument`). Do **not** pull in QBFC. Pin the spec version in the `<?qbxml version="…"?>` PI from config.
- **Python client:** `requests` + `urllib3 Retry`/`HTTPAdapter`, `python-dotenv` for `.env`, `pytest` + `responses` (or `requests-mock`) for tests, packaged as a plain `requirements.txt` module (no need for a wheel — it travels in-repo).

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| .NET | **8.0 (LTS)** | Runtime for the service | Current LTS as of 2026 (support to Nov 2026; .NET 10 LTS is also out but .NET 8 is the conservative pick and the one the spec names). Full COM-interop support on Windows; first-class Windows-service hosting. |
| ASP.NET Core | **8.0** | HTTPS REST API + Kestrel | Built into the .NET 8 SDK; Kestrel does HTTPS-only binds with a file `.pfx` trivially; minimal-API and controller styles both supported. |
| Target framework moniker | **`net8.0-windows`** | Enables Windows-only APIs (COM interop, `System.Management`, event log) | COM `[ComImport]`/`Marshal` calls require the Windows TFM. Set `<UseWindowsForms>`/`<UseWPF>` **off**. |
| `Microsoft.Extensions.Hosting.WindowsServices` | **8.0.x** (track the .NET 8 servicing line; 8.0.x is current — newer 9.0.x/10.0.x work on .NET 8 too but stick to 8.0.x) | Run the ASP.NET Core host as a Windows service | `AddWindowsService()` sets the SCM lifetime + Event Log logger and **does nothing when not started by the SCM** — so the exact same `.exe` runs from a console (dev) and under Task Scheduler (the session-0 fallback). No second build configuration. |
| `Microsoft.Extensions.Hosting` | **8.0.x** | Generic Host / DI / config / logging | Already transitively present via ASP.NET Core; lists it explicitly for the worker bits. |
| QuickBooks Desktop SDK | **16.0** (latest; `qbsdk16.0` installer from developer.intuit.com) | Provides & registers the `QBXMLRP2.RequestProcessor` COM server + OSR + samples on the **QuickBooks host machine only** | SDK 16.0 is the current release (SDK 15.0 was 2021; 16.0 shipped with the QuickBooks Desktop 2023 wave and is still current — Intuit has not shipped SDK 17). It is **not** a NuGet package and **not** a build dependency — it's a runtime prerequisite installed on `10.120.254.13`. Modern QuickBooks (2022+) installs a **64-bit** `QBXMLRP2`; the SDK 16.0 also offers a 64-bit type library. |
| qbXML spec version | request: **13.0** (broad-compat default) or up to **16.0** if QuickBooks Enterprise on the host is 2023/2024 | The XML dialect sent in `<?qbxml version="13.0"?>` | qbXML 16.0 is the newest spec version; QuickBooks Enterprise 2023 and 2024 both accept up to 16.0. But the service should *default* to a conservative version (13.0/14.0 covers everything from ~2014 on) and let `QbXml:Version` in config bump it. The host queries supported versions at runtime via a `HostQueryRq` — surface that in `GET /api/health`. |

### COM-interop layer (the "builds without the SDK" requirement)

| Choice | Recommendation | Why / How |
|--------|----------------|-----------|
| Interop approach | **`tlbimp`-generated `Interop.QBXMLRP2Lib.dll`, committed to the repo, referenced only by the COM-adapter project** (equivalent: a VS *COM Reference* to "QBXMLRP2 1.0 Type Library" with `<EmbedInteropTypes>false</EmbedInteropTypes>`). | The interop assembly is **pure metadata** — it carries the COM type signatures and the `[Guid]`/`[ComImport]` attributes, not the COM server itself. So the solution **compiles, restores, and runs all unit + integration tests on a machine with no QuickBooks SDK installed**. The real COM class (`QBXMLRP2.RequestProcessor`, ProgID-resolved via `Type.GetTypeFromProgID`/`new RequestProcessor()`) is only activated at runtime *on the QuickBooks host*, where the SDK installer has registered it. Generate the interop DLL once with `tlbimp "C:\Program Files\Common Files\Intuit\QuickBooks\QBXMLRP2.dll" /out:Interop.QBXMLRP2Lib.dll` (or let VS do it via Add COM Reference), then commit the produced DLL so CI never needs the SDK. |
| Late-bound `dynamic` / reflection | **Avoid.** | Works without the interop DLL, but you lose all compile-time safety on the `OpenConnection2 / BeginSession / ProcessRequest / EndSession / CloseConnection` calls, and it makes the `IRequestProcessor` adapter harder to read/maintain. The committed-interop-DLL approach gives you static typing *and* SDK-free builds, so `dynamic` buys nothing. |
| `Microsoft.Interop.QBSDK` / community NuGet | **Don't rely on it.** | There is no official Intuit NuGet for QBXMLRP2; community packages (e.g. `Interop.QBXMLRP2Lib` mirrors on NuGet) exist but are unmaintained and not authoritative. Generating the interop DLL yourself from the installed type library is reproducible and version-correct. |
| Project structure for the seam | `IRequestProcessor` lives in `QbConnectService` (host) with **no COM types in its surface** — methods take/return `string` (the raw qbXML), `bool`, `int`, and a small `enum QbOpenMode`. `RealRequestProcessor` (the `[SupportedOSPlatform("windows")]` adapter) lives in its own project/folder `Qb/Com/` that is the **only** thing referencing `Interop.QBXMLRP2Lib`. `Program.cs` registers `RealRequestProcessor` only at runtime (`if (OperatingSystem.IsWindows() && !env.IsEnvironment("Testing"))`); the test host registers `FakeRequestProcessor`. | Keeps the COM dependency at the very edge. The test assembly never transitively pulls the interop DLL, never touches `Marshal`/COM, and runs cross-platform if needed. Mirrors classic "ports & adapters" — `IRequestProcessor` is the port. |
| COM threading | Mark the host's STA needs explicitly: the SDK's `RequestProcessor` is **single-threaded / STA-affine**. Either run all COM calls on a dedicated STA thread you own, or (simpler) gate every call through `SemaphoreSlim(1,1)` *and* create/use the `RequestProcessor` from a single long-lived thread. `[STAThread]` on a worker thread + a message pump, or a `StaTaskScheduler`-style helper. | QuickBooks COM is notorious for misbehaving when hammered from thread-pool threads. The serialization the spec already mandates also makes this tractable. |

### Supporting Libraries (.NET)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Polly` | **8.x** (`ResiliencePipeline`) | The single retry on dead-ticket / QuickBooks-restarted-mid-session (spec §7) | Use the v8 pipeline API directly — *not* `Microsoft.Extensions.Http.Resilience` (that's HttpClient-centric and irrelevant; the retry is around the COM call, not an HTTP call). Keep it to **one** retry with a short backoff; never auto-retry QuickBooks validation errors. |
| `System.Xml.Linq` (in-box) | — | Build qbXML requests, parse qbXML responses, surface `statusCode`/`statusSeverity`/`statusMessage` | In-box; zero deps. Hand-roll `QbXmlBuilder`/`QbXmlParser` against it. |
| `Microsoft.Extensions.Configuration.Json` / `Binder` (in-box w/ ASP.NET Core) | — | `appsettings.json` + `appsettings.sample.json` strongly-typed options | Bind `Server`, `Auth`, `Qb`, `Safety`, `QbXml`, `Audit`, `Request` sections to options classes; validate on startup (`ValidateOnStart`). |
| `Microsoft.AspNetCore.Authentication` (in-box) — custom scheme **or** just middleware | — | Bearer-token check (`Authorization: Bearer <token>` → 401) | The spec's auth is a single static token, not JWT — a tiny `AuthenticationHandler` or a 15-line middleware comparing with `CryptographicOperations.FixedTimeEquals` is correct. Do **not** add `Microsoft.AspNetCore.Authentication.JwtBearer` — wrong tool. |
| `Microsoft.Extensions.Logging.EventLog` (pulled by `*.WindowsServices`) | 8.0.x | Service logs to Windows Event Log when running as a service | Already wired by `AddWindowsService`. Also add a rolling-file sink (`Serilog.Extensions.Hosting` + `Serilog.Sinks.File`, **optional**) since service stdout is invisible. |
| `Serilog` + `Serilog.AspNetCore` + `Serilog.Sinks.File` | latest 8.x/4.x | Structured request logging + the human-readable on-disk log | **Optional but recommended** — the audit log is a separate append-only writer (spec §5), but ordinary diagnostic logging needs to land in a file when running headless. If you'd rather stay in-box, `Microsoft.Extensions.Logging` + a custom file logger works too. |

### Development & test tools (.NET)

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| xUnit | **2.9.x** (xunit + xunit.runner.visualstudio) — or xUnit **v3** if you want the newer runner; 2.9.x is the safe default | Unit + integration test framework | Spec names xUnit explicitly. |
| `Microsoft.AspNetCore.Mvc.Testing` | **8.0.x** | `WebApplicationFactory<Program>` — boot the real host in-memory with `FakeRequestProcessor` and `AllowWrites=false`, hit `/api/health`, `/api/qbxml`, `/api/ops/{op}`, assert the 403, assert audit rows | Standard ASP.NET Core integration-test harness. Needs `Program.cs` to be partial-class-visible (`public partial class Program {}` or top-level + `InternalsVisibleTo`). |
| `NSubstitute` | **5.x** (or `Moq` 4.x) | Mock `IRequestProcessor` in `QbSession` state-machine tests | Either is fine; NSubstitute has a cleaner syntax and no recent "telemetry" controversy. Drive: connect→begin→process→end→close; dead-ticket→one reconnect; two concurrent calls don't interleave. |
| `Verify.Xunit` | **latest** | Golden-file (snapshot) tests for `QbXmlBuilder` output and `QbXmlParser` JSON | **Optional** — plain `Assert.Equal(expectedXml, actualXml)` against committed `.xml`/`.json` fixtures is just as good and has zero deps. Pick one. |
| `coverlet.collector` | latest | Test coverage | Standard. |
| `dotnet-sln` / `dotnet new` | .NET 8 SDK | Scaffolding | `dotnet new web` for the host, `dotnet new xunit` for tests, `dotnet new classlib` for the COM-adapter project. |
| QuickBooks SDK **OSR** (onscreen reference) + **SDKTestPlus3** | ships in SDK 16.0 | Discover qbXML request/response shapes; sandbox-test qbXML against a real company file before coding the op | These run **on the QuickBooks host**, not in CI. Invaluable for authoring `qbxml-cheatsheet.md` and the `QbXmlBuilder` cases. |

### Python client side

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| `requests` | **2.32.x** | HTTPS client | De-facto standard; trivial bearer header + `verify=` for the self-signed cert. |
| `urllib3` `Retry` + `requests.adapters.HTTPAdapter` | bundled with `requests` (urllib3 2.x) | Retries on connection errors / 5xx / 409 Busy with backoff | Mount a retrying adapter on the `Session`; `allowed_methods` should include POST for the idempotent reads but be careful with `create_*` (don't auto-retry writes — the dry-run/confirm flow handles that). |
| `python-dotenv` | **1.x** | Load `clients/.env` (`QB_API_BASE_URL`, `QB_API_TOKEN`, `QB_VERIFY_TLS`) | Matches the spec's `.env` / `.env.sample` pattern. |
| `pytest` | **8.x** | Test runner | Standard. |
| `responses` (or `requests-mock`) | latest | Stub the service's HTTP endpoints for `qb_client.py` tests | Test bearer header is sent, retries fire, dry-run helper posts to `/api/ops/{op}/dryrun`, 403 is surfaced cleanly. |
| (optional) `httpx` | 0.27.x | Alt client if async is ever wanted | **Not needed for v1** — `requests` is simpler and the calls are synchronous round-trips by design. Listed only as the fallback. |
| Packaging | `requirements.txt` (pinned, with hashes optional) | Distribution | The client travels *in the repo* (spec §9), so a plain pinned `requirements.txt` + `pip install -r quickbooks/clients/requirements.txt` is the right call. **Don't** build a wheel / publish to PyPI for v1 — adds release machinery for zero benefit. A `pyproject.toml` with `pip install -e .` is a nice-to-have if you want `import qb_client` to work from anywhere, but optional. |

---

## Installation

```powershell
# --- Service machine prerequisite (10.120.254.13), one-time, manual ---
#   Install QuickBooks Desktop SDK 16.0 from developer.intuit.com (registers QBXMLRP2 COM server,
#   installs OSR + SDKTestPlus3). NOT a build dependency — runtime only.
#   Then do the integrated-app pre-authorization steps (see register-integrated-app.md / spec §3).

# --- .NET solution scaffold (any dev box, NO QuickBooks SDK needed) ---
dotnet new sln  -n QbConnectService
dotnet new web      -o src/QbConnectService                 -f net8.0          # host (web TFM; bump to net8.0-windows in csproj)
dotnet new classlib -o src/QbConnectService.Qb.Com          -f net8.0-windows  # COM adapter (only project referencing the interop DLL)
dotnet new xunit    -o src/QbConnectService.Tests           -f net8.0
dotnet sln add src/**/**.csproj

# host project deps
cd src/QbConnectService
dotnet add package Microsoft.Extensions.Hosting.WindowsServices   # 8.0.x
dotnet add package Microsoft.Extensions.Hosting                    # 8.0.x (explicit)
dotnet add package Polly                                           # 8.x
# optional structured logging
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.File

# COM adapter project: add the COM reference (generates Interop.QBXMLRP2Lib.dll), then COMMIT that DLL.
# In VS: right-click project > Add > COM Reference > "QBXMLRP2 1.0 Type Library" (EmbedInteropTypes=false)
# Or CLI on a box that has the SDK:  tlbimp "%CommonProgramFiles%\Intuit\QuickBooks\QBXMLRP2.dll" /out:lib\Interop.QBXMLRP2Lib.dll
# then reference lib\Interop.QBXMLRP2Lib.dll and check it into git so CI never needs the SDK.

# test project deps
cd ../QbConnectService.Tests
dotnet add package Microsoft.AspNetCore.Mvc.Testing               # 8.0.x
dotnet add package NSubstitute                                    # 5.x
dotnet add package coverlet.collector
# dotnet add package Verify.Xunit   # optional snapshot testing

# --- HTTPS cert (on the service machine) ---
# scripts/make-cert.ps1:
#   $c = New-SelfSignedCertificate -DnsName "10.120.254.13" -CertStoreLocation Cert:\LocalMachine\My `
#        -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(5)
#   Export-PfxCertificate -Cert $c -FilePath qbconnect.pfx -Password (ConvertTo-SecureString -AsPlainText -Force "<pw>")
#   Export-Certificate     -Cert $c -FilePath qbconnect.cer    # hand this to the workstation for QB_VERIFY_TLS

# --- register the Windows service (scripts/install-service.ps1) ---
#   sc.exe create QbConnectService binPath= "C:\svc\QbConnectService.exe" obj= ".\svc_qbsdk" password= "<pw>" start= auto
#   sc.exe failure QbConnectService reset= 0 actions= restart/60000/restart/60000/restart/60000
# --- OR the session-0 fallback (scripts/run-as-task.ps1): a "At startup" scheduled task running the SAME exe as svc_qbsdk ---

# --- Python client ---
# quickbooks/clients/requirements.txt:
#   requests==2.32.*
#   python-dotenv==1.*
#   pytest==8.*        # dev
#   responses          # dev
pip install -r quickbooks/clients/requirements.txt
```

---

## Windows Service vs. Scheduled Task — the session-0 decision

This is a known QuickBooks-COM pitfall and the spec already calls it out (§3 "Known risk — Windows session 0", §7 last row). Stack-level guidance:

| Option | What it is | When it works | Trade-offs |
|--------|-----------|---------------|------------|
| **Windows Service** (`sc.exe create … obj=".\svc_qbsdk"`, `AddWindowsService()`) — **primary** | The ASP.NET Core host registered with the SCM, running as `svc_qbsdk`, auto-start, auto-restart on failure. | On modern QuickBooks (2022+) + SDK 16.0 + a correctly granted integrated app with "allow auto-login" bound to `svc_qbsdk` + the company file hosted multi-user, QuickBooks launches headless in session 0 and the SDK round-trips work in *most* deployments. | Session 0 has no interactive desktop; older QuickBooks builds, certain license-activation popups, or a mis-granted integrated app cause `BeginSession`/`OpenConnection` failures. SCM gives you the cleanest restart-on-crash story. |
| **Scheduled Task "At startup"** running the **same `.exe`** as `svc_qbsdk` — **documented fallback** (`scripts/run-as-task.ps1`) | A task-scheduler entry, trigger "At startup", "Run whether user is logged on or not", under `svc_qbsdk`. The process runs as a normal (non-service) process — `AddWindowsService()` is a **no-op** so it just runs the Kestrel host. | When the pure-service path proves flaky. A scheduled task still needs **no interactive logon**, but the process is not under SCM session-isolation rules in quite the same way and some QuickBooks setups are happier. | No SCM restart-on-crash (use the task's "If the task fails, restart every N min" + "Stop the existing instance"). Slightly fiddlier to monitor. |
| Run interactively / "session keeper" tooling | Auto-logon a console session and run there. | Last resort only. | Defeats "unattended"; out of scope per spec §10. Mention in README, don't build. |

**Stack consequence:** because `AddWindowsService()` is inert outside the SCM, **one published `.exe` covers all three launch modes** — only the wrapper script differs. Build `OutputType=exe`, `PublishSingleFile=true` (Release), `RuntimeIdentifier=win-x64`, self-contained. Make `Program.cs` register the COM adapter behind `OperatingSystem.IsWindows()` so the *same* code path is exercised in tests with the fake.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| .NET 8 (LTS) | .NET 10 (LTS, shipped Nov 2025) | If you want the newest LTS and don't mind a slightly newer toolchain — fully compatible with everything here. Stick with .NET 8 unless there's a reason; the spec names it. |
| Direct SDK via `QBXMLRP2.RequestProcessor` COM | QuickBooks **Web Connector** (QBWC, SOAP, polled) | Only as the documented README fallback (spec §10) — *not* built. QBWC avoids session-0 COM entirely (QBWC runs the COM, your app just exposes a SOAP endpoint it polls) but is async/polled and clunkier; the spec deliberately chose direct-SDK. |
| Hand-rolled qbXML with `XDocument` | **QBFC** (QuickBooks Foundation Classes — the OO COM wrapper that builds qbXML for you) | Never, for this project. QBFC is another COM dependency that would have to sit behind the interface too, it doesn't add value over `XDocument` for a service whose whole point is raw-qbXML passthrough + a thin op layer, and it makes the SDK-free-build story harder. |
| `tlbimp`-generated interop DLL (committed) | VS "COM Reference" with `EmbedInteropTypes=true` | Embedding interop types is fine for tiny apps but it bakes the COM type metadata into the host assembly and complicates the "COM only in the adapter project" boundary. Use `EmbedInteropTypes=false` + a referenced DLL so only the adapter project carries it. |
| Single static bearer token (custom middleware) | `Microsoft.AspNetCore.Authentication.JwtBearer` / API-key libraries (`AspNetCore.Authentication.ApiKey`) | If auth requirements ever grow (multiple tokens with scopes, expiry, rotation). For v1's single LAN token, a `FixedTimeEquals` comparison is correct and dependency-free. |
| `requests` (Python) | `httpx` | If the client ever needs async/HTTP-2. Not needed — calls are synchronous by design. |
| In-repo `requirements.txt` | `pyproject.toml` + build a wheel + publish | If `qb_client` ever needs to be consumed outside the `tech-legal` repo. Not the case in v1. |
| `Polly` v8 `ResiliencePipeline` | `Microsoft.Extensions.Http.Resilience` | That package wraps `HttpClient`; here the retry surrounds the *COM* call, so use bare Polly. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Late-bound `dynamic`/reflection for `QBXMLRP2.RequestProcessor` | Loses compile-time checking on the connection/session lifecycle calls; no upside once you have a committed metadata-only interop DLL (which already builds SDK-free). | `tlbimp`-generated `Interop.QBXMLRP2Lib.dll`, referenced only by the adapter project, committed to git. |
| Putting any COM type (`QBXMLRP2Lib.*`, `IRequestProcessor5`, etc.) in `IRequestProcessor`'s signature | Forces the host + test projects to reference the interop DLL, defeating "builds without the SDK" and dragging COM into unit tests. | `IRequestProcessor` surface is `string`/`bool`/`int`/`enum` only; COM types live exclusively inside `RealRequestProcessor`. |
| `EmbedInteropTypes=true` on the QBXMLRP2 reference | Bakes COM metadata into the consuming assembly; muddies the adapter boundary. | `EmbedInteropTypes=false` + reference the standalone interop DLL. |
| QBFC (QuickBooks Foundation Classes) | Extra COM dependency, no benefit for a raw-qbXML-passthrough service, complicates SDK-free builds. | `System.Xml.Linq` (`XDocument`) hand-built qbXML. |
| QuickBooks Web Connector / SOAP / a job queue | Async, polled, more moving parts — explicitly superseded by the direct-SDK design (spec §1, §10). | Direct in-process `QBXMLRP2.RequestProcessor`. Keep QBWC as a README fallback note only. |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | Wrong abstraction — auth here is a single shared LAN token, not a JWT issuer/audience model. | Tiny custom auth middleware/handler with `CryptographicOperations.FixedTimeEquals`. |
| Running COM calls from thread-pool / `Task.Run` threads ad hoc | QuickBooks COM is STA-affine and flaky under concurrency; spec already requires serialized execution. | One long-lived STA-pinned worker thread for all COM calls, plus `SemaphoreSlim(1,1)`. |
| `AnyCPU` / 32-bit build when QuickBooks 2022+ is 64-bit (or vice-versa) | COM activation fails across bitness boundaries (or needs a surrogate). | Match the installed QuickBooks/SDK bitness explicitly — modern installs are `x64`, so `PlatformTarget=x64`, `RuntimeIdentifier=win-x64`. Verify on the host. |
| `<PublishSingleFile>true</PublishSingleFile>` while *debugging* | Known issue: can't attach the debugger to a single-file .NET app. | Single-file only in Release; debug the non-single-file build. |
| Publishing `qb_client.py` to PyPI / building a wheel for v1 | Release machinery for zero benefit — the client lives in-repo. | Pinned `requirements.txt` + `pip install -r`. |
| Letting the build/test pipeline depend on the QuickBooks SDK being installed | CI would only run on a QuickBooks box; defeats the spec's hard requirement. | Commit the interop DLL; register `FakeRequestProcessor` in tests; `RealRequestProcessor` only loaded at runtime behind `OperatingSystem.IsWindows()`. |

---

## Stack Patterns by Variant

**If the QuickBooks host is QuickBooks Enterprise 2023 or 2024:**
- `QbXml:Version` may be set up to `16.0`; default it to `13.0` and only bump after confirming with a `HostQueryRq` (surface `supportedQBXMLVersion` list in `/api/health`).
- Expect a **64-bit** `QBXMLRP2` — build `x64`.

**If the host turns out to be an older QuickBooks (e.g. 2019–2021):**
- Cap `QbXml:Version` at what `HostQueryRq` reports (likely 13.0 or 14.0).
- It may be a **32-bit** `QBXMLRP2` — then build `x86` / `RuntimeIdentifier=win-x86`, or use a 32-bit COM surrogate. Confirm before committing to bitness (spec §11 "exact QuickBooks Enterprise year/version" open item).

**If the pure-Windows-Service launch proves unstable in session 0:**
- Switch the wrapper to `scripts/run-as-task.ps1` (Task Scheduler "At startup", run-whether-logged-on-or-not, as `svc_qbsdk`, restart-on-failure). **No code change** — `AddWindowsService()` is already a no-op outside the SCM.

**If you want zero third-party logging deps:**
- Skip Serilog; use `Microsoft.Extensions.Logging` + a minimal custom rolling-file `ILoggerProvider`. The audit log is a separate hand-written append-only writer regardless.

---

## Version Compatibility

| Package / component | Compatible with | Notes |
|---------------------|-----------------|-------|
| `Microsoft.Extensions.Hosting.WindowsServices` 8.0.x | .NET 8 host (`net8.0-windows`) | 9.0.x/10.0.x packages also load on .NET 8 but pin to the 8.0 servicing line for an LTS-only dependency graph. |
| `Microsoft.AspNetCore.Mvc.Testing` 8.0.x | ASP.NET Core 8 host | Must match the host's ASP.NET Core major version. |
| `Polly` 8.x | .NET 8 | v8 `ResiliencePipeline` API; v7 `Policy` API still works but is legacy. |
| `Interop.QBXMLRP2Lib.dll` (tlbimp'd from QBXMLRP2 1.0 type library) | the **bitness-matching** QuickBooks/SDK on the host | The interop *metadata* is bitness-agnostic; the **runtime COM activation** isn't — `x64` host process ↔ `x64` `QBXMLRP2`. |
| QuickBooks Desktop SDK 16.0 | QuickBooks Desktop / Enterprise ~2002→2024 (backward-compatible request processor); `QBXMLRP2` is the preferred RP over the legacy `QBXMLRP` | The SDK installs on the QuickBooks host; it is **not** referenced by the build. |
| qbXML request version 13.0 | QuickBooks Desktop/Enterprise ~2014→2024 | Broadest-compat default. 16.0 needs QuickBooks 2023+. Always reconcile against `HostQueryRq` at runtime. |
| `requests` 2.32.x | Python 3.8+ | urllib3 2.x bundled; `Retry` lives in `urllib3.util.retry`. |

---

## Open verification items (do during implementation/deploy — overlaps spec §11)

- **Confirm SDK 16.0 is the latest** and grab the exact `qbsdk16.0.exe` from `developer.intuit.com/app/developer/qbdesktop/docs/get-started/download-and-install-the-sdk` (Intuit's docs are JS-rendered and didn't yield to automated fetch; SDK 16.0 is corroborated by community references to "QBFC16" and "qbXML 16.0" but the release-notes PDF should be read on-box to confirm there's no 17.x).
- **Confirm the QuickBooks Enterprise year/version on `10.120.254.13`** → drives (a) the safe `QbXml:Version` ceiling and (b) the build bitness (`x64` vs `x86`). Verify by running `SDKTestPlus3` + a `HostQueryRq` once installed.
- **Confirm `QBXMLRP2.dll` path/bitness on the host** before generating the interop DLL (`%CommonProgramFiles%\Intuit\QuickBooks\QBXMLRP2.dll` typical) — the type library is the same, but you want to know the activation bitness.
- **Confirm the `svc_qbsdk` account** can be created on the host, that QuickBooks is licensed/launchable under it, and that it has "Log on as a service" rights (spec §11).

---

## Sources

- Microsoft Learn — *Create Windows Service using BackgroundService* (`learn.microsoft.com/dotnet/core/extensions/windows-service`, doc updated 2026-03) — **HIGH** — `Microsoft.Extensions.Hosting.WindowsServices`, `AddWindowsService()`, `sc.exe create/failure/start/stop/delete`, single-file publish, `RuntimeIdentifier=win-x64`, `OutputType=exe`, `BackgroundServiceExceptionBehavior`. (Doc shows `net10.0-windows`/9.0.x package versions in examples — same APIs apply on `net8.0-windows`/8.0.x.)
- Microsoft Learn — *Microsoft.Extensions.Hosting.WindowsServices* NuGet page & API docs — **HIGH** — confirms `AddWindowsService`/`UseWindowsService` are no-ops when not started by the SCM.
- Intuit Developer — QuickBooks Desktop SDK docs index, "Download and install the SDK", "SDK compatibility with QuickBooks releases", "Desktop SDK features", "Older versions of the Desktop SDK" (`developer.intuit.com/app/developer/qbdesktop/docs/...`) — **MEDIUM** (pages are JS-rendered; titles/structure confirmed via search, full content not machine-readable) — these are the authoritative sources for the SDK download, the SDK↔QuickBooks-release matrix, and the qbXML-version-per-release table; read on-box during deploy.
- Intuit Developer — *QuickBooks SDK Release Notes* PDF (`static.developer.intuit.com/qbSDK-current/doc/pdf/ReleaseNotes.pdf`) — **MEDIUM** — confirms QBXMLRP2 is the preferred Request Processor, "About Redistributing QBXMLRP2", 64-bit OS guidance; the fetched copy parsed as SDK 13.0-era content — re-read the *current* PDF on-box for the 16.0 specifics.
- Intuit Developer — *Release Notes, QuickBooks SDK 15.0 (10/08/2021)* and *14.0 (12/10/2020)* PDFs (`static.developer.intuit.com/resources/...`) — **HIGH** for those versions — establish the release cadence (≈one SDK per QuickBooks year), implying SDK 16.0 ≈ the QuickBooks 2023 wave.
- Intuit Developer community Q&A — "*what qbXML versions are compatible with QuickBooks Desktop Enterprise … the SDK 16 release notes don't mention it*" (`help.developer.intuit.com/s/question/0D5TR000008rNFe0AM`) — **MEDIUM** — independent confirmation that **SDK 16 / qbXML 16.0 exists** and is the current line, and that the release notes are vague on the per-Enterprise-edition matrix (hence: query `HostQueryRq` at runtime).
- Tek-Tips thread "*Calling QBFC16, 64-bit interface from VFP, 32-bit code*" — **LOW/corroborating** — confirms SDK 16 ships both 32-bit and 64-bit interfaces and that bitness mismatch is a real activation issue.
- ConsoliBYTE Wiki — `quickbooks_qbxml_versions`, `quickbooks_integration_csharp` (`wiki.consolibyte.com`) — **LOW** (server was intermittently unreachable during research) — community reference for the qbXML-version table and C# COM-interop patterns (`Interop.QBXMLRP2Lib`, `OpenConnection2`/`BeginSession`/`ProcessRequest`/`EndSession`/`CloseConnection`); verify against Intuit docs.
- Apideck blog — *Build an integration with the QuickBooks Desktop API* (2025/2026) — **LOW/corroborating** — uses `qbXML version="13.0"` in examples, supporting 13.0 as a sane broad-compat default.
- .NET version lifecycle (`dotnet.microsoft.com/platform/support/policy/dotnet-core`) — **HIGH** — .NET 8 = LTS, supported through Nov 2026; .NET 10 = LTS, shipped Nov 2025.

---
*Stack research for: self-hosted QuickBooks Desktop SDK (QBXMLRP2 COM) → bearer-auth HTTPS REST service in .NET 8, with a Python client*
*Researched: 2026-05-11*
