# Phase 5: REST API, Auth & Health - Research

**Researched:** 2026-05-11
**Domain:** ASP.NET Core 8 minimal-API HTTPS surface (Kestrel HTTPS-only + `.pfx`), custom static-bearer auth middleware, global exception → `ProblemDetails` mapping, an `OpRegistry` over `IEnumerable<IReadOp>`, a non-crashing `/api/health` COM-liveness probe, a raw `/api/qbxml` passthrough with an element-name write-verb 403 gate, and `WebApplicationFactory<Program>` integration tests.
**Confidence:** HIGH on the ASP.NET Core / Kestrel / `WebApplicationFactory` / `ProblemDetails` mechanics (official docs + the existing codebase); MEDIUM on the exact qbXML write-verb element-name set (Intuit OSR pages are JS-rendered; the `*AddRq` / `*ModRq` / `ListDelRq` / `TxnDelRq` / `TxnVoidRq` shape is corroborated from Intuit's "Modify, delete, and void requests and responses" page but the *complete* enumeration of `Del`/`Void` request elements should be re-pinned against the OSR on the QuickBooks host in Phase 9).

---

## Summary

Phase 5 puts the HTTPS/bearer REST surface on top of the fully-built Phases 1–4 engine. Everything it needs already exists: `QbConnectionManager.ExecuteAsync(rawQbXml)` / `GetSupportedQbXmlVersionsAsync()` / `State` / `LastError`, the 12 `IReadOp` singletons (already registered so `OpRegistry` is just `IEnumerable<IReadOp>` → dictionary), `QbXmlBuilder`/`QbXmlParser`, the `QbException`/`QbBusyException`/`QbTimeoutException` family with mapped `QbError`, and `public partial class Program {}` (already present for `WebApplicationFactory<Program>`). The host project is `Microsoft.NET.Sdk.Web` on `net8.0-windows`, x86, with the Phase-1 placeholder `app.MapGet("/", ...)`.

The standard approach: **minimal-API endpoints grouped under `/api`** (not MVC controllers — lighter, consistent with the existing `app.MapGet`, and the spec's `Controllers/` folder was a sketch, not a mandate — flag for the planner), **Kestrel configured from an `appsettings`/`Server` POCO** (HTTPS-only, file `.pfx` from `Server:CertPath`/`CertPassword`, dev/test fallback to an in-memory self-signed cert when `CertPath` is empty), a **~30-line custom `BearerAuthMiddleware`** comparing the token with `CryptographicOperations.FixedTimeEquals` after a length check (NOT `AddJwtBearer`), a **global `IExceptionHandler` (or `app.UseExceptionHandler`) writing `ProblemDetails`** with the `ArgumentException`→400 / `QbBusyException`→409 / `QbTimeoutException`→504 / `QbException`→503 / else→500 mapping, an **`OpRegistry`** built from injected `IEnumerable<IReadOp>` (throws on duplicate `Name`), a **`/api/health`** that probes COM liveness inside a try/catch with a short timeout (so a missing/unregistered `RealRequestProcessor` → `REGDB_E_CLASSNOTREG` → `QbException` → caught → `status:"down"`), a **`/api/qbxml`** raw passthrough that XLinq-parses the body and 403s if any descendant element's *local name* matches the write-verb pattern while `Safety:AllowWrites==false`, a **`/api/ops/{op}`** that JSON-deserializes the body into `IReadOnlyDictionary<string,object?>` (reusing the exact `ArgReader`-compatible conversion already in `ArgReader.ToDictionary`/`ConvertJson`) and calls `op.RunAsync`, and **`WebApplicationFactory<Program>`** integration tests (one new test-only NuGet: `Microsoft.AspNetCore.Mvc.Testing` 8.0.x) using `EnvironmentName="Testing"` so `Program.cs` skips `RealRequestProcessor`, registering a captured `FakeRequestProcessor`, and overriding `Auth:ApiToken` via `UseSetting`.

**Primary recommendation:** Build the `/api/*` surface as minimal-API endpoint groups in a small `Api/` folder (one static extension class per endpoint group: `HealthEndpoints`, `QbXmlEndpoints`, `OpsEndpoints`), keep auth + exception handling as two small middlewares, do `SafetyOptions`/`ServerOptions`/`AuthOptions` POCOs + a `QbWriteDetector` helper in `QbConnectService.Qb.Com` (so Phase 6 reuses it), and ship a `QbWebAppFactory : WebApplicationFactory<Program>` with the captured fake. 8 atomic tasks (one commit each), all `dotnet build`/`dotnet test` green with no QuickBooks.

---

## Standard Stack

### Core (all in-box with `Microsoft.NET.Sdk.Web` / .NET 8 — no new runtime deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ASP.NET Core minimal APIs (`WebApplication` / `MapGet` / `MapPost` / `MapGroup`) | 8.0 (in `Microsoft.NET.Sdk.Web`) | The `/api/health`, `/api/qbxml`, `/api/ops/{op}` endpoints | Already the pattern in `Program.cs`; lighter than MVC for ~3 endpoints; `MapGroup("/api")` lets the bearer middleware + endpoint metadata attach to the whole prefix. |
| Kestrel + `KestrelServerOptions` / `ListenOptions.UseHttps` | 8.0 | HTTPS-only bind from `Server:BindUrls` + file `.pfx` | In-box; `serverOptions.Listen(IPAddress.Any, port, lo => lo.UseHttps(certPath, certPassword))` or the `"Kestrel:Endpoints"` config block. We must construct it from our own `Server` section (not the framework's `Kestrel` section) so the spec's `Server:BindUrls`/`Server:CertPath`/`Server:CertPassword` stay authoritative. |
| `System.Security.Cryptography.CryptographicOperations.FixedTimeEquals` | in-box | Constant-time bearer-token compare | Spec/STACK.md mandate; prevents timing side-channels on token comparison. |
| `System.Security.Cryptography.X509Certificates.X509CertificateLoader` / `CertificateRequest` | in-box (.NET 8 / 9) | Load the `.pfx` (or, dev/test, mint an in-memory self-signed cert) | `.NET 9` deprecated `new X509Certificate2(path, pwd)` in favour of `X509CertificateLoader.LoadPkcs12FromFile(...)`; .NET 8 still has `new X509Certificate2(...)` — use whichever the SDK on the box accepts; for the dev/test fallback, `CertificateRequest.CreateSelfSigned(...)` (or just leave `UseHttps()` with no args → the ASP.NET Core dev cert). |
| `Microsoft.AspNetCore.Http.ProblemDetails` / `Results.Problem` / `IProblemDetailsService` | in-box | RFC 7807 error bodies for 4xx/5xx | `builder.Services.AddProblemDetails();` + `app.UseExceptionHandler();` (or an `IExceptionHandler`). The ASP.NET-idiomatic error shape — recommended for all the mapped HTTP errors. |
| `System.Xml.Linq` (`XDocument`/`XElement`) | in-box | Parse the raw `/api/qbxml` body to scan descendant element *local names* for write verbs | Already used everywhere in `QbXmlBuilder`/`QbXmlParser`/`FakeRequestProcessor`; element-name detection (not substring/regex on the text) is exactly what the requirement demands. |
| `System.Text.Json` (`JsonDocument`/`JsonElement`/`JsonSerializer`) | in-box | Deserialize the `/api/ops/{op}` request body into `IReadOnlyDictionary<string,object?>` | `ArgReader` already has the exact `JsonElement` → `Dictionary<string,object?>` conversion (`ToDictionary`/`ConvertJson` — numbers become *strings*, nested objects → dicts, arrays → `List<object?>`); reuse/lift it so the dispatched op gets values it already knows how to read. |

### Supporting (test-only — one new NuGet, planned for in STACK.md)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Microsoft.AspNetCore.Mvc.Testing` | **8.0.x** (latest 8.0 servicing is 8.0.21; pin `8.0.*` to match the host's ASP.NET Core 8 + the existing `Microsoft.NET.Test.Sdk` 17.8.0 / xunit 2.5.3) | `WebApplicationFactory<Program>` — boot the real host in-memory with the fake processor + a test bearer token, hit `/api/*`, assert | The standard ASP.NET Core integration-test harness. **Must match the host's ASP.NET Core major version (8).** Do NOT take a 9.x/10.x version on a net8 host. Add it to `QbConnectService.Tests.csproj` only. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Minimal-API endpoint groups | Attribute-routed MVC controllers in `Controllers/` (the spec's sketch) | Controllers are more "structured" but add `AddControllers()`/`MapControllers()`, model-binding ceremony, and break the consistency with the existing `app.MapGet`. Recommend minimal API; if the planner prefers controllers, that's fine — the requirements don't care. **Flag for the planner.** |
| Custom `BearerAuthMiddleware` | `AddAuthentication().AddJwtBearer(...)` / `AspNetCore.Authentication.ApiKey` | Wrong abstraction for a single static LAN token (STACK.md + spec both say so). A ~30-line middleware with `FixedTimeEquals` is correct and dependency-free. |
| `IExceptionHandler` + `AddProblemDetails` + `UseExceptionHandler` | A hand-rolled `try/catch` middleware writing JSON | `IExceptionHandler` (.NET 8) is the modern, testable shape and gives `ProblemDetails` for free; a manual middleware also works. Either is fine — recommend `IExceptionHandler` *or* a small middleware, planner's call; just keep it in one place. |
| Returning raw XML from `/api/qbxml` as `Content-Type: application/xml` | Returning `200 { "rawQbXml": "..." }` JSON | API-04/API-05 say `/api/qbxml` returns "the raw qbXML response". **Recommend returning the raw XML directly** as `Results.Content(rawResponse, "application/xml")` (or `text/xml`) — it's the literal "passthrough" and the Python client/skill can hand it straight to `XDocument`. (`/api/ops/{op}` returns JSON; only `/api/qbxml` returns XML.) |
| `app.MapGroup("/api").AddEndpointFilter(...)` for auth | A pipeline middleware branched on `context.Request.Path.StartsWithSegments("/api")` | A middleware is simpler to reason about (runs before routing, short-circuits cleanly with a 401 + `WWW-Authenticate`) and is what the test asserts against. An endpoint filter on the `/api` group also works. Recommend the middleware. |

**Installation:**
```bash
# In QbConnectService.Tests.csproj only (test project):
dotnet add package Microsoft.AspNetCore.Mvc.Testing --version 8.0.*
# Host project: NOTHING new — Microsoft.NET.Sdk.Web already brings ASP.NET Core 8,
# ProblemDetails, Kestrel HTTPS, System.Text.Json, System.Xml.Linq, FixedTimeEquals.
```

---

## Architecture Patterns

### Recommended file layout (additive — nothing existing moves)

```
QbConnectService/src/QbConnectService/
├── Program.cs                          # + ConfigureKestrel, Configure<ServerOptions/AuthOptions/SafetyOptions>,
│                                        #   AddProblemDetails, AddSingleton<OpRegistry>, UseExceptionHandler,
│                                        #   app.UseMiddleware<BearerAuthMiddleware>(), app.Map*Endpoints()
│                                        #   (keep app.MapGet("/", ...) as the trivial unauthenticated liveness string)
├── Api/
│   ├── HealthEndpoints.cs              # app.MapHealthEndpoints() -> GET /api/health
│   ├── QbXmlEndpoints.cs               # app.MapQbXmlEndpoints() -> POST /api/qbxml
│   ├── OpsEndpoints.cs                 # app.MapOpsEndpoints()   -> POST /api/ops/{op}  (+ GET /api/ops list-names, optional)
│   ├── BearerAuthMiddleware.cs         # the FixedTimeEquals bearer gate over the /api prefix
│   └── ApiExceptionHandler.cs          # IExceptionHandler -> ProblemDetails mapping
├── Options/                            # (or keep in Qb.Com next to QbOptions — planner's call)
│   ├── ServerOptions.cs                # BindUrls, CertPath, CertPassword, MaxRequestBodyBytes
│   └── AuthOptions.cs                  # ApiToken
└── appsettings.sample.json             # + Server:CertPath, Server:CertPassword, Server:MaxRequestBodyBytes

QbConnectService.Qb.Com/
├── SafetyOptions.cs                    # SafetyOptions { bool AllowWrites = false }  (bound from "Safety")
├── Ops/OpRegistry.cs                   # IEnumerable<IReadOp> -> IReadOnlyDictionary<string,IReadOp>; TryGet/Names; throw on dup
└── QbWriteDetector.cs                  # static bool IsWriteRequest(string rawQbXml) — XLinq local-name scan; Phase 6 reuses

QbConnectService.Tests/
├── QbWebAppFactory.cs                  # WebApplicationFactory<Program>: EnvironmentName="Testing",
│                                        #   ConfigureServices -> AddSingleton<Func<IRequestProcessor>>(captured fake),
│                                        #   UseSetting("Auth:ApiToken","test-token") + Safety:AllowWrites etc.
├── HealthEndpointTests.cs
├── BearerAuthTests.cs
├── QbXmlEndpointTests.cs               # round-trip read + 403 write-verb scan
├── OpsEndpointTests.cs                 # 200 result, 404 unknown op, 200-with-nonzero-statusCode, 400 bad args, 503/409 mapping
└── QbConnectService.Tests.csproj       # + Microsoft.AspNetCore.Mvc.Testing 8.0.*
```

### Pattern 1: Kestrel HTTPS-only from a `Server` POCO (reject plain HTTP)

`Program.cs`, after `WebApplication.CreateBuilder(args)` and the existing `Configure<...>` calls:

```csharp
builder.Services.Configure<ServerOptions>(builder.Configuration.GetSection("Server"));
builder.Services.Configure<AuthOptions>(builder.Configuration.GetSection("Auth"));
builder.Services.Configure<QbConnectService.Qb.SafetyOptions>(builder.Configuration.GetSection("Safety"));

builder.WebHost.ConfigureKestrel((ctx, k) =>
{
    var server = ctx.Configuration.GetSection("Server").Get<ServerOptions>() ?? new ServerOptions();
    if (server.MaxRequestBodyBytes > 0) k.Limits.MaxRequestBodySize = server.MaxRequestBodyBytes;

    foreach (var url in (server.BindUrls ?? "https://+:8443").Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
    {
        var uri = new Uri(url.Replace("+", "0.0.0.0").Replace("*", "0.0.0.0"));   // "+"/"*" -> bind-all
        if (!string.Equals(uri.Scheme, "https", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException($"Server:BindUrls must be https only; got '{url}'.");   // API-01: refuse plain HTTP

        k.Listen(IPAddress.Parse(uri.Host == "0.0.0.0" ? "0.0.0.0" : uri.Host), uri.Port, lo =>
        {
            if (!string.IsNullOrWhiteSpace(server.CertPath))
                lo.UseHttps(server.CertPath, server.CertPassword);                // PROD: file .pfx (Phase 9 make-cert.ps1)
            else
                lo.UseHttps();                                                     // DEV/TEST: ASP.NET Core dev cert / in-memory self-signed
        });
    }
});
```
- **Why:** API-01 needs HTTPS-only from a configurable URL/port + a file `.pfx`; plain HTTP must be *refused* (the `throw` enforces it). The dev/test fallback (`UseHttps()` with no args) keeps `WebApplicationFactory` working with zero cert plumbing — the in-memory `TestServer` doesn't do real TLS anyway, so a `WebApplicationFactory` test never exercises a real cert; that's fine, it's covered by a "binding throws on http://" unit test instead.
- **Note for the planner:** `WebApplicationFactory` overrides the server with an in-memory `TestServer`, so `ConfigureKestrel` is *not invoked* during integration tests — which means the "rejects plain HTTP" behaviour is tested by a small standalone unit test that builds the app with `Server:BindUrls=http://...` and asserts the startup throws (e.g. `Assert.Throws` around `app.Build()` / `app.StartAsync()` with a `Host`/`WebApplication` constructed directly), not via `WebApplicationFactory`. Document the limit.
- **Cert API caveat:** `new X509Certificate2(path, password)` is obsolete on .NET 9 SDK (`SYSLIB0057`); `lo.UseHttps(string path, string? password)` overload still works on .NET 8/9 (it does the loading internally) — prefer that overload over constructing the cert yourself. If you do need the object, use `X509CertificateLoader.LoadPkcs12FromFile(path, password)` on .NET 9, `new X509Certificate2(path, password)` on .NET 8.

### Pattern 2: Custom static-bearer middleware over `/api` (NOT JwtBearer)

```csharp
public sealed class BearerAuthMiddleware(RequestDelegate next, IOptions<AuthOptions> auth, ILogger<BearerAuthMiddleware> log)
{
    private readonly byte[] _expected = Encoding.UTF8.GetBytes(auth.Value.ApiToken ?? string.Empty);

    public async Task Invoke(HttpContext ctx)
    {
        if (!ctx.Request.Path.StartsWithSegments("/api"))
        {
            await next(ctx);
            return;
        }

        var header = ctx.Request.Headers.Authorization.ToString();
        const string scheme = "Bearer ";
        if (header.StartsWith(scheme, StringComparison.Ordinal))
        {
            var presented = Encoding.UTF8.GetBytes(header[scheme.Length..].Trim());
            // FixedTimeEquals already constant-time, but it returns false on length mismatch — fine; no early length leak needed
            if (_expected.Length > 0 && CryptographicOperations.FixedTimeEquals(presented, _expected))
            {
                await next(ctx);
                return;
            }
        }

        ctx.Response.StatusCode = StatusCodes.Status401Unauthorized;
        ctx.Response.Headers.WWWAuthenticate = "Bearer";
        await Results.Problem(statusCode: 401, title: "Unauthorized", detail: "Missing or invalid bearer token.")
                    .ExecuteAsync(ctx);
    }
}
```
- **Pipeline order in `Program.cs`:** `app.UseExceptionHandler();` → `app.UseMiddleware<BearerAuthMiddleware>();` → endpoints. (Exception handler outermost so even a middleware bug → `ProblemDetails`; auth before routing/endpoints.) Don't add `UseAuthentication`/`UseAuthorization` at all — there's no auth scheme.
- **Does `/api/health` require the token? — YES (recommend).** Health leaks the company-file name, QuickBooks version, edition — keep all of `/api/*` (including `/api/health`) behind the token; the root `/` stays the trivial unauthenticated string for "is the process up". Do NOT add a separate unauthenticated `/healthz` — extra surface for no benefit; the spec's health endpoint is `/api/health` and it's fine that it needs the token. (Flag: if the planner *wants* an unauthenticated liveness ping, make it the existing `/` — already there.)
- `CryptographicOperations.FixedTimeEquals(ReadOnlySpan<byte>, ReadOnlySpan<byte>)` returns `false` (not throw) when lengths differ, and does so in constant time — so the "length check first" is optional; just guard `_expected.Length > 0` so an unconfigured/empty token never matches an empty presented token.

### Pattern 3: Global exception → `ProblemDetails` (the API-06 invariant)

```csharp
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
// ...
app.UseExceptionHandler();

public sealed class ApiExceptionHandler(IProblemDetailsService pds) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext ctx, Exception ex, CancellationToken ct)
    {
        var (status, title) = ex switch
        {
            ArgumentException                 => (StatusCodes.Status400BadRequest,        "Bad request"),
            QbBusyException                   => (StatusCodes.Status409Conflict,          "QuickBooks busy"),
            QbTimeoutException                => (StatusCodes.Status504GatewayTimeout,    "QuickBooks timeout"),
            QbException                       => (StatusCodes.Status503ServiceUnavailable,"QuickBooks unavailable"),
            QbXmlParseException               => (StatusCodes.Status400BadRequest,        "Malformed qbXML"),   // bad body on /api/qbxml
            _                                 => (StatusCodes.Status500InternalServerError, "Unexpected error"),
        };
        ctx.Response.StatusCode = status;
        return await pds.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = ctx,
            ProblemDetails = new ProblemDetails
            {
                Status = status, Title = title,
                Detail = ex is QbException q ? $"{q.Error.Name}: {q.Error.Message} ({q.Error.RemediationHint})" : ex.Message,
                // optionally Extensions["qbErrorCode"] = $"0x{q.Error.Code:X8}"
            }
        });
        // never include stack trace in the body
    }
}
```
- **401 (bad token) / 403 (AllowWrites) / 404 (unknown op)** are produced *directly* by the middleware/endpoints, NOT via exceptions — so they don't go through this handler. (404 for unknown op: the endpoint returns `Results.Problem(statusCode: 404, ...)`; route-not-matched 404s for unknown *paths* are the framework's plain 404.)
- **API-06 confirmed by reading the engine:** a non-zero `statusCode` from QuickBooks is **never thrown** — `QbXmlParser.Parse` puts it in `QbStatus` (`responseElement.Attribute("statusCode")`), `ReadOpBase`'s ops return it inside their result dict (`["status"] = ...Status`), and `GetTransactionOp`/the list ops surface zero-row results as success. The only throwers are `QbConnectionManager` (COM/`COMException`→`QbException`, watchdog→`QbTimeoutException`, busy→`QbBusyException`) and `ArgReader`/the ops (`ArgumentException` on bad/missing args, `RunQueryOp` whitelist). So a `statusCode!=0` naturally flows out as a normal `200` body — **the only thing Phase 5 must NOT do is map `QbStatus.IsError` to an HTTP error.** Add an explicit test (`InvoiceAddRs.error.qbxml` fixture already exists, or a `*QueryRs` with a non-zero status) asserting `200` + `status.code != "0"` in the JSON.
- `QbException` → **503** (QuickBooks is the unavailable dependency, incl. `REGDB_E_CLASSNOTREG` 0x80040154 when the SDK isn't installed / interop bitness mismatch). `QbTimeoutException` → **504** (gateway timeout — QuickBooks is the "gateway"). `QbBusyException` → **409** (another request holds the single-slot gate). These three map cleanly because the manager already throws exactly these types; the test can script the `FakeRequestProcessor` to `EnqueueComError(unchecked((int)0x80040154))` (it has `EnqueueComError`) → the manager wraps it `QbException.From` → 503.

### Pattern 4: `OpRegistry` over the existing `IEnumerable<IReadOp>`

```csharp
public sealed class OpRegistry
{
    private readonly IReadOnlyDictionary<string, IReadOp> _byName;
    public OpRegistry(IEnumerable<IReadOp> ops)
    {
        var dict = new Dictionary<string, IReadOp>(StringComparer.Ordinal);
        foreach (var op in ops)
            if (!dict.TryAdd(op.Name, op))
                throw new InvalidOperationException($"Duplicate op name '{op.Name}'.");
        _byName = dict;
    }
    public bool TryGet(string name, [NotNullWhen(true)] out IReadOp? op) => _byName.TryGetValue(name, out op);
    public IReadOnlyCollection<string> Names => _byName.Keys.ToArray();
}
// Program.cs:  builder.Services.AddSingleton<OpRegistry>();   // the 12 AddSingleton<IReadOp,...>() already exist
```
- **Phase 7 plug-in:** Phase 7's write ops also need to be dispatchable here. **Recommended least-churn option:** keep the `IReadOp` interface *as the dispatch interface* and have Phase 7's write ops also implement `IReadOp` (despite the name) **OR** introduce a marker base `IQbOp { string Name; Task<object?> RunAsync(...); }` that `IReadOp` extends and `OpRegistry` keys on `IEnumerable<IQbOp>`. Either is small. **Recommendation: do NOT refactor Phase 4 now** — keep `OpRegistry` taking `IEnumerable<IReadOp>` in Phase 5; when Phase 7 lands, either (a) it adds `IWriteOp : IReadOp` (write ops are also "ops"), or (b) Phase 7 widens `OpRegistry` to a union. Flag this explicitly for the planner so Phase 7's planner makes the call; don't pre-build it. (Note: the `/api/ops/{op}/dryrun` endpoint and the safety gate on named write ops are **Phase 6** — Phase 5 does NOT add `/dryrun` or write-op dispatch.)
- **`/api/ops/{op}` argument binding — reuse `ArgReader.ToDictionary`:** the ops consume `IReadOnlyDictionary<string,object?>` and `ArgReader.String/.Bool/.Date/.Dict` already understand both raw CLR values *and* `JsonElement`. Cleanest: in `OpsEndpoints`, read the body as `JsonDocument` (allow empty body → empty args), then `ArgReader.ToDictionary(doc.RootElement)` if the root is an object (else 400 "request body must be a JSON object"). `ArgReader.ToDictionary`/`ConvertJson` are currently `private` — **lift them to `public static`** (or add `public static IReadOnlyDictionary<string,object?> FromJson(JsonElement)`). That conversion already does the right thing: numbers→`string` (so `ArgReader.Date` parses the string), nested object→`Dictionary<string,object?>`, array→`List<object?>`, bool/null preserved — and `RunQueryOp.AddFilters` already walks nested dicts/lists. **Do not** `JsonSerializer.Deserialize<Dictionary<string,object?>>` directly — that leaves `JsonElement` values unboxed and dates as `JsonElement`, which `ArgReader` *does* handle, but the existing `ToDictionary` path is the one the Phase-4 tests exercise; reuse it for consistency.
- **`/api/ops/{op}` response shape (API-05):** `200 { "op": "<name>", "result": <op's returned object> }`. API-05 says "parsed JSON **plus** the raw qbXML **plus** the status fields" — but the ops return `object?` (a dict) that **already embeds `status`** (and `rows`/`count`/`rawSpilledTo` etc.), and they do NOT carry the raw qbXML verbatim. **Recommendation (lighter reading of API-05):** the op's result dict (which includes `status`) satisfies "parsed JSON + status fields"; verbatim raw qbXML is what `/api/qbxml` is for — accept ops as parsed-only and return `{ op, result }`. If the reviewer insists on raw-too, the fallback is to extend `ReadOpBase` to optionally stash the raw response on the result — but that's a Phase-4 surface change; **recommend the lighter reading and flag it for the planner/reviewer** (the requirement's "plus the raw qbXML" is ambiguous given the Phase-4 contract that already shipped at 100/100).

### Pattern 5: `/api/qbxml` raw passthrough + element-name write-verb 403

```csharp
group.MapPost("/qbxml", async (HttpContext ctx, QbConnectionManager mgr, IOptions<SafetyOptions> safety, IOptions<ServerOptions> server, CancellationToken ct) =>
{
    // Kestrel's MaxRequestBodySize already guards size (set from Server:MaxRequestBodyBytes); reading the body will throw
    // BadHttpRequestException (-> 413) if exceeded. Optionally also enforce explicitly with a length check.
    string body;
    using (var reader = new StreamReader(ctx.Request.Body, Encoding.UTF8))
        body = await reader.ReadToEndAsync(ct);

    if (!safety.Value.AllowWrites && QbWriteDetector.IsWriteRequest(body))
        return Results.Problem(statusCode: 403, title: "Writes disabled",
            detail: "Safety:AllowWrites is false; this qbXML contains an Add/Mod/Del/Void request. Set AllowWrites=true to enable.");

    var raw = await mgr.ExecuteAsync(body, ct);          // QbException/QbBusy/QbTimeout -> the global handler -> 503/409/504
    return Results.Content(raw, "application/xml");       // API-04/API-06: raw qbXML response verbatim; non-zero statusCode is in the body, still 200
});
```

`QbWriteDetector` (in `QbConnectService.Qb.Com` so Phase 6 reuses it):
```csharp
public static class QbWriteDetector
{
    // Detect by ELEMENT LOCAL NAME, never substring/regex on the raw text (a <!-- ItemAddRq --> comment must NOT trip it).
    public static bool IsWriteRequest(string rawQbXml)
    {
        XDocument doc;
        try { doc = XDocument.Parse(rawQbXml); }
        catch (System.Xml.XmlException ex) { throw new QbXmlParseException($"Malformed qbXML request: {ex.Message}"); } // -> 400
        return doc.Descendants().Any(e => IsWriteVerb(e.Name.LocalName));
    }

    private static bool IsWriteVerb(string localName) =>
        localName.EndsWith("AddRq",  StringComparison.Ordinal) ||
        localName.EndsWith("ModRq",  StringComparison.Ordinal) ||
        localName.EndsWith("DelRq",  StringComparison.Ordinal) ||   // covers ListDelRq, TxnDelRq, *AddDelRq, DataExtDelRq, etc.
        localName.EndsWith("VoidRq", StringComparison.Ordinal) ||   // covers TxnVoidRq
        localName is "ListDelRq" or "TxnDelRq" or "TxnVoidRq";       // explicit belt-and-suspenders for the generic ones
}
```
- **The write-verb element-name set (qbXML / Intuit OSR — MEDIUM confidence):** every entity write request follows `<Entity>AddRq` / `<Entity>ModRq` (e.g. `CustomerAddRq`, `InvoiceModRq`, `ItemServiceAddRq`, `JournalEntryAddRq`, `DataExtAddRq`/`DataExtModRq`). There are **generic** delete/void requests: **`ListDelRq`** (delete a list entry — takes a `ListDelType` + ListID), **`TxnDelRq`** (delete a transaction — `TxnDelType` + TxnID), **`TxnVoidRq`** (void a transaction — `TxnVoidType` + TxnID). Also `DataExtDelRq` (delete a custom-field value). There is no `*DeleteRq` long-form. So `EndsWith("AddRq")|EndsWith("ModRq")|EndsWith("DelRq")|EndsWith("VoidRq")` plus the explicit `ListDelRq`/`TxnDelRq`/`TxnVoidRq` set covers it. **Phase 9 should re-pin the exact OSR enumeration on the host** — but this pattern is the standard one and matches the spec's "`Add`/`Mod`/`Del`/`Void`" wording. Source: Intuit "Modify, delete, and void requests and responses" (developer.intuit.com) confirms `ListDelRq`, `TxnDelRq`, `TxnVoidRq`. (Note: pure-read requests are `*QueryRq` and `*ReportQueryRq` — `ReportQueryRq` ends in `Rq` but contains `Query`, so the verb scan never trips on reads.)
- **Size guard:** set `KestrelServerOptions.Limits.MaxRequestBodySize` from `Server:MaxRequestBodyBytes` (add this key — recommend a few MB, e.g. `5_000_000`, mirroring `QbXml:MaxResponseBytes`). When exceeded, Kestrel throws `BadHttpRequestException` → maps to 413; optionally also `[RequestSizeLimit]`-equivalent per-endpoint. The simplest correct thing: one global `Limits.MaxRequestBodySize`. (Don't conflate request-size with `QbXml:MaxResponseBytes`, which is the *response* spill threshold — different concern.)

### Pattern 6: `WebApplicationFactory<Program>` harness

`Program.cs` already ends with `public partial class Program {}` — that's all `WebApplicationFactory<Program>` needs (HIGH confidence; the framework looks up the `Program` entry-point type, which top-level statements make `internal`, hence the `public partial` shim). And `Program.cs` already does `if (OperatingSystem.IsWindows() && !builder.Environment.IsEnvironment("Testing")) AddSingleton<Func<IRequestProcessor>>(... RealRequestProcessor)` — so setting `EnvironmentName="Testing"` skips the COM adapter and lets the test register its own.

```csharp
public sealed class QbWebAppFactory : WebApplicationFactory<Program>
{
    public FakeRequestProcessor Fake { get; } = new();
    public const string Token = "test-token";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("Auth:ApiToken", Token);
        builder.UseSetting("Safety:AllowWrites", "false");
        builder.UseSetting("Qb:CompanyFilePath", @"C:\co.QBW");
        builder.UseSetting("Request:TimeoutSeconds", "30");
        builder.UseSetting("Request:BusyWaitSeconds", "5");
        // (no Server:* needed — TestServer ignores Kestrel; ConfigureKestrel won't even run)
        builder.ConfigureServices(services =>
        {
            services.AddSingleton<Func<IRequestProcessor>>(_ => () => Fake);   // capture the SAME instance the test asserts against
        });
    }
}
// usage in a test:
//   await using var f = new QbWebAppFactory();
//   f.Fake.AddResponse("CompanyQueryRq", "<?xml ...><QBXML><QBXMLMsgsRs><CompanyQueryRs statusCode=\"0\" ...>...</CompanyQueryRs></QBXMLMsgsRs></QBXML>");
//   var c = f.CreateClient();
//   c.DefaultRequestHeaders.Authorization = new("Bearer", QbWebAppFactory.Token);
//   var r = await c.PostAsync("/api/ops/company_info", new StringContent("{}", Encoding.UTF8, "application/json"));
```
- **Reusing the existing fixtures:** the `QbConnectService.Tests/Fixtures/qbxml/*.qbxml` golden files are already copied to output (`CopyToOutputDirectory=PreserveNewest`) — integration tests can `File.ReadAllText` a response fixture and `f.Fake.AddResponse("CompanyQueryRq", fixtureText)`. For multi-message ops (`company_info` sends `HostQueryRq` + `CompanyQueryRq` in one `ProcessRequest` call) the fake keys off the *first* request element name — `HostCompanyQueryRs.qbxml` is the combined-response fixture; register it under whichever key the fake will look up (the fake parses the first `Rq` child → `HostQueryRq`).
- **Scripting failures:** `f.Fake.EnqueueComError(unchecked((int)0x80040154))` → next COM call throws `COMException` with that HRESULT → `QbConnectionManager` wraps via `QbException.From` → `ApiExceptionHandler` → 503. For 409: harder to script via the fake alone (the busy path is in the manager's gate); the simplest testable 409 is a focused unit test on the manager (already done in Phase 2) — at the API level, prefer testing 401/403/404/400/503/200-nonzero-status (the cleanly scriptable ones) and treat 409/504 as covered by Phase 2's `QbConnectionManagerTests`. Flag: if a 409 integration test is wanted, the fake would need a `ProcessRequestHook` that blocks on a `ManualResetEvent` so a second concurrent request hits the bounded `BusyWaitSeconds` — doable but fiddly; document as optional.

### Anti-Patterns to Avoid

- **Mapping `QbStatus.IsError` (a non-zero qbXML `statusCode`) to an HTTP 4xx/5xx.** It's a *business outcome* — return `200` with the status block in the body (API-06). The engine never throws on it; don't reintroduce it at the API layer.
- **Substring/regex on the raw `/api/qbxml` text to detect write verbs** (`body.Contains("AddRq")`). A `<!-- ItemAddRq -->` comment or a string literal would false-positive; an element literally named `CustomerAddRq` is what must trip it. Parse with XLinq and check `e.Name.LocalName`.
- **`AddJwtBearer` / `AddAuthentication` / `AddAuthorization`** for a single static token — wrong tool, dead weight. A ~30-line middleware with `FixedTimeEquals` is correct.
- **Putting the cert password / token / bind URL in source.** They live in `appsettings.json` (gitignored) with the committed `appsettings.sample.json`; code reads config only. (Phase-1 anti-pattern #4 — keep it.)
- **Mixing `Kestrel:Endpoints` config with `Server:BindUrls`.** Pick one — the spec's `Server:*` section is authoritative; build Kestrel from it explicitly and don't also leave a `Kestrel` section that would silently override.
- **Loading the cert with `new X509Certificate2(path, pwd)` on a .NET 9 SDK** — it's obsolete (`SYSLIB0057`); use `lo.UseHttps(path, password)` (does it internally) or `X509CertificateLoader`.
- **Forgetting to set `EnvironmentName="Testing"` in `WebApplicationFactory`** — then `Program.cs` registers `RealRequestProcessor`, the COM activation throws `REGDB_E_CLASSNOTREG` on the CI box, and `/api/health` (or any op) 503s spuriously. The env name is the switch the host already keys on.
- **Reading `ctx.Request.Body` twice** without `EnableBuffering()` — for `/api/qbxml` read it once into a string; for `/api/ops/{op}` read once into a `JsonDocument`. Don't both model-bind and re-read.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Constant-time token compare | A `for` loop XOR-ing bytes | `CryptographicOperations.FixedTimeEquals` (in-box) | Subtle to get right; the framework's is audited and returns false (constant-time) on length mismatch too. |
| RFC-7807 error bodies | A custom `{ error, message }` JSON shape | `AddProblemDetails()` + `IProblemDetailsService` / `Results.Problem(...)` | The ASP.NET-idiomatic shape; clients (and the Python `qb_client`) expect `ProblemDetails`; gives `type`/`title`/`status`/`detail`/`traceId` for free. |
| HTTPS bind / cert loading | Manual `TcpListener` + `SslStream` | `KestrelServerOptions.Listen(..., lo => lo.UseHttps(pfx, pwd))` | Kestrel does ALPN/HTTP2/cert chain/renegotiation correctly; you only choose the `.pfx`. |
| JSON-object → `IReadOnlyDictionary<string,object?>` (preserving nested objects/arrays/types) | A new recursive converter | The existing `ArgReader.ToDictionary`/`ConvertJson` (lift to public) | It's already the conversion the Phase-4 ops were written and tested against; numbers→string, nested→dict, array→list — exactly what `ArgReader.String/.Date/.Dict` and `RunQueryOp.AddFilters` consume. |
| In-memory test HTTP server | A real socket + a real cert + `HttpClient` against `localhost:port` | `WebApplicationFactory<Program>` + `factory.CreateClient()` | `TestServer` is in-process (no TLS, no port), fast, deterministic; `Program.cs` already has the `public partial class Program {}` shim. |
| qbXML body parsing for the write-verb scan | A regex / string search | `XDocument.Parse(...).Descendants()` + `e.Name.LocalName` | Element-name detection is the requirement; XLinq is already a project dependency and ignores comments/literals. |

**Key insight:** Phase 5 adds *zero* runtime dependencies — `Microsoft.NET.Sdk.Web` already ships everything (Kestrel HTTPS, `ProblemDetails`, `System.Text.Json`, `System.Xml.Linq`, `FixedTimeEquals`); the only new package is the *test-only* `Microsoft.AspNetCore.Mvc.Testing` 8.0.x. The biggest "don't hand-roll" is the arg-binding: reuse `ArgReader`'s existing JSON conversion rather than inventing a parallel one.

---

## Common Pitfalls

### Pitfall 1: `/api/health` crashes (or 503s) when QuickBooks isn't installed
**What goes wrong:** A naive health endpoint calls `manager.GetSupportedQbXmlVersionsAsync()` (or runs `company_info`), the COM activation throws `COMException(REGDB_E_CLASSNOTREG)` → `QbException` → propagates → `/api/health` returns 503 (or the unhandled path 500s). On a CI box with no SDK that's *every* health call.
**Why it happens:** Health is supposed to *report* "down", not *be* down. The probe must be wrapped.
**How to avoid:** Inside the endpoint, do the probe in a try/catch with a short timeout (e.g. a `CancellationTokenSource(TimeSpan.FromSeconds(min(5, Request:TimeoutSeconds)))` passed to `GetSupportedQbXmlVersionsAsync`/`ExecuteAsync` for a tiny `HostQueryRq` — or reuse the `company_info` op). On any exception (`QbException`/`QbBusyException`/`QbTimeoutException`/`OperationCanceledException`) → `status:"down"`, `connectionState = manager.State`, `lastError = manager.LastError` (or build a `QbError` from the caught `QbException`), QB-derived fields null, and **return `200`** (a health endpoint that returns `200` with `status:"down"` is correct — the HTTP layer is healthy; the *dependency* is down). The recommended state machine:
  - `"healthy"` — the probe COM round-trip succeeded (got supported-versions / `HostRet`) AND `manager.State == SessionOpen` AND `manager.LastError == null`.
  - `"degraded"` — the probe succeeded but `manager.LastError != null` (a recent error that recovered), or `manager.State == SessionOpen` but the probe timed out/was throttled.
  - `"down"` — the probe threw, or `manager.State` is `Disconnected`/`Poisoned`.
**Warning signs:** A `WebApplicationFactory` health test that fails on CI but passes locally (QuickBooks installed locally); a 503 from `/api/health`.

**Recommended `/api/health` JSON payload (API-03):**
```json
{
  "status": "healthy",                // "healthy" | "degraded" | "down"
  "connectionState": "SessionOpen",   // QbConnectionState: Disconnected|Connecting|SessionOpen|Poisoned
  "allowWrites": false,               // SafetyOptions.AllowWrites
  "sdkVersion": "16.0",               // best-effort: HostRet.SupportedQBXMLVersionList max, or the configured QbXml:Version, or null
  "qbXmlVersionConfigured": "16.0",   // QbXmlOptions.Version
  "qbXmlVersionsSupported": ["13.0","14.0","15.0","16.0"],   // best-effort from HostQueryRq; [] / null if probe failed
  "companyFile": "Acme, Inc.",        // best-effort from CompanyRet.CompanyName (or Qb:CompanyFilePath); null if probe failed
  "quickBooksVersion": "QuickBooks Enterprise Solutions 24.0",  // best-effort HostRet.ProductName + Major.Minor; null if probe failed
  "lastError": { "code": "0x80040420", "name": "QB_ACCESS_DENIED", "message": "...", "remediationHint": "..." } | null,
  "time": "2026-05-11T18:22:05Z"      // UtcNow
}
```
The "best-effort" QB-derived fields come from one `HostQueryRq` + `CompanyQueryRq` round-trip (or just reuse `CompanyInfoOp.RunAsync` and pick fields off its result dict) inside the try/catch. `manager.GetSupportedQbXmlVersionsAsync()` already exists for the supported-versions list (it calls `IRequestProcessor.GetSupportedQbXmlVersions(ticket)`), but it *does* go through `EnsureConnectedAsync` → COM activation, so it must be inside the same try/catch.

### Pitfall 2: `WebApplicationFactory` boots the *real* COM adapter
**What goes wrong:** Forgetting `UseEnvironment("Testing")` → `Program.cs`'s `if (OperatingSystem.IsWindows() && !env.IsEnvironment("Testing"))` is true → it registers `Func<IRequestProcessor>` → `RealRequestProcessor` → and the test's `ConfigureServices` `AddSingleton<Func<IRequestProcessor>>` may or may not win the "last registration" race. On a non-Windows CI runner the `OperatingSystem.IsWindows()` guard already skips it — but the dev box is Windows.
**Why it happens:** The host's tri-mode wiring keys on the env name; the test must set it.
**How to avoid:** `builder.UseEnvironment("Testing")` in `ConfigureWebHost` (the existing `HostStartupTests` use a bare `Host.CreateDefaultBuilder()` so they sidestep this; the new `WebApplicationFactory` tests must set it). Belt-and-suspenders: in `ConfigureServices`, `services.RemoveAll<Func<IRequestProcessor>>()` then `AddSingleton(...)` the fake — but the env-name route is cleaner and is what the host already expects.

### Pitfall 3: The `/api/ops/{op}` body deserialization swallows or mangles types
**What goes wrong:** `JsonSerializer.Deserialize<Dictionary<string,object?>>(body)` leaves values as `JsonElement` — which `ArgReader` *does* handle — but a new ad-hoc converter that turns numbers into `double`/`long` (instead of leaving them as strings) breaks `ArgReader.Date` (it parses a *string*) and date-as-number edge cases; an unknown date format throws `ArgumentException` → 400 (which is correct, but only if the conversion preserved the string).
**Why it happens:** Re-inventing the JSON→dict conversion instead of reusing `ArgReader.ToDictionary`.
**How to avoid:** Lift `ArgReader.ToDictionary`/`ConvertJson` to public and call it. It already does: number→`string`, object→`Dictionary<string,object?>`, array→`List<object?>`, bool/null preserved. An empty/absent body → empty args dict (don't 400 on empty body — many ops take no args, e.g. `company_info`). A non-object root (e.g. `[]` or `"x"`) → `ArgumentException("request body must be a JSON object")` → 400.

### Pitfall 4: `/api/qbxml` returns the wrong content type / re-wraps the XML
**What goes wrong:** Returning `Results.Ok(rawResponse)` JSON-encodes the XML string (quotes-escaped, useless); or returning `text/plain`; or wrapping in `{ rawQbXml: "..." }` when the spec says "returns the raw qbXML response".
**How to avoid:** `Results.Content(rawResponse, "application/xml")` (or `"text/xml"`). The client gets exactly what QuickBooks returned, byte-for-byte. (Only `/api/ops/{op}` returns JSON.)

### Pitfall 5: Plain-HTTP bind silently accepted
**What goes wrong:** `Server:BindUrls` misconfigured to `http://...` and the service happily serves cleartext on a LAN — defeats API-01.
**How to avoid:** In `ConfigureKestrel`, after parsing each URL, `if (uri.Scheme != "https") throw`. A unit test builds the app with `Server:BindUrls=http://localhost:1234` and asserts startup throws.

---

## Code Examples

### `Program.cs` additions (sketch — minimal API)
```csharp
// Source: ASP.NET Core 8 minimal API + Kestrel HTTPS docs (learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel/endpoints?view=aspnetcore-8.0)
//         + Integration tests in ASP.NET Core (learn.microsoft.com/aspnet/core/test/integration-tests?view=aspnetcore-8.0)
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddWindowsService(o => o.ServiceName = "QbConnectService");
builder.Services.AddHostedService<QbConnectService.Worker>();

builder.Services.Configure<QbOptions>(builder.Configuration.GetSection("Qb"));
builder.Services.Configure<QbXmlOptions>(builder.Configuration.GetSection("QbXml"));
builder.Services.Configure<RequestOptions>(builder.Configuration.GetSection("Request"));
builder.Services.Configure<ServerOptions>(builder.Configuration.GetSection("Server"));
builder.Services.Configure<AuthOptions>(builder.Configuration.GetSection("Auth"));
builder.Services.Configure<SafetyOptions>(builder.Configuration.GetSection("Safety"));

builder.Services.AddSingleton<QbXmlBuilder>();
builder.Services.AddSingleton<QbXmlParser>();
builder.Services.AddSingleton<QbReportParser>();
builder.Services.AddSingleton<QbResponseSpiller>();
builder.Services.AddSingleton<QbListExecutor>();
if (OperatingSystem.IsWindows() && !builder.Environment.IsEnvironment("Testing"))
    builder.Services.AddSingleton<Func<IRequestProcessor>>(_ => () => new QbConnectService.Qb.Com.RealRequestProcessor());
builder.Services.AddSingleton<QbConnectionManager>();
builder.Services.AddSingleton<IReadOp, CompanyInfoOp>();   // ...and the other 11 (unchanged)
builder.Services.AddSingleton<OpRegistry>();

builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();

builder.WebHost.ConfigureKestrel((ctx, k) => { /* Pattern 1 */ });

var app = builder.Build();
app.UseExceptionHandler();
app.UseMiddleware<BearerAuthMiddleware>();
app.MapGet("/", () => "QbConnectService is running.");   // trivial unauthenticated liveness
var api = app.MapGroup("/api");
api.MapHealthEndpoints();   // GET /api/health
api.MapQbXmlEndpoints();    // POST /api/qbxml
api.MapOpsEndpoints();      // POST /api/ops/{op}  (+ optional GET /api/ops -> { ops: [names] })
app.Run();

public partial class Program { }   // already present — required for WebApplicationFactory<Program>
```

### A `WebApplicationFactory` integration test
```csharp
// Source: learn.microsoft.com/aspnet/core/test/integration-tests?view=aspnetcore-8.0
[Fact]
public async Task ops_unknown_op_returns_404()
{
    await using var f = new QbWebAppFactory();
    var c = f.CreateClient();
    c.DefaultRequestHeaders.Authorization = new("Bearer", QbWebAppFactory.Token);
    var r = await c.PostAsync("/api/ops/does_not_exist", new StringContent("{}", Encoding.UTF8, "application/json"));
    Assert.Equal(HttpStatusCode.NotFound, r.StatusCode);
}

[Fact]
public async Task qbxml_with_CustomerAddRq_is_403_when_writes_disabled()
{
    await using var f = new QbWebAppFactory();              // Safety:AllowWrites = "false"
    var c = f.CreateClient();
    c.DefaultRequestHeaders.Authorization = new("Bearer", QbWebAppFactory.Token);
    var body = "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CustomerAddRq><CustomerAdd><Name>Acme</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>";
    var r = await c.PostAsync("/api/qbxml", new StringContent(body, Encoding.UTF8, "application/xml"));
    Assert.Equal(HttpStatusCode.Forbidden, r.StatusCode);
}

[Fact]
public async Task missing_token_is_401_with_www_authenticate()
{
    await using var f = new QbWebAppFactory();
    var r = await f.CreateClient().GetAsync("/api/health");
    Assert.Equal(HttpStatusCode.Unauthorized, r.StatusCode);
    Assert.Contains("Bearer", r.Headers.WwwAuthenticate.ToString());
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Startup.cs` + `IWebHostBuilder` | `WebApplicationBuilder` / minimal hosting (already in this codebase) | .NET 6 (2021) | One `Program.cs`; `MapGroup`/`MapGet`/`MapPost` for endpoints; `builder.WebHost.ConfigureKestrel(...)` still available. |
| Custom error middleware writing ad-hoc JSON | `AddProblemDetails()` + `IExceptionHandler` + `UseExceptionHandler()` | `IExceptionHandler` added in .NET 8 (2023) | RFC-7807 bodies; testable handler class; the recommended shape. |
| `new X509Certificate2(path, password)` | `X509CertificateLoader.LoadPkcs12FromFile(path, password)` (or just `lo.UseHttps(path, password)` which does it internally) | .NET 9 marks the constructor obsolete (`SYSLIB0057`); .NET 8 still allows it | If the build SDK is .NET 9, the old constructor warns; prefer the `UseHttps(path, pwd)` overload. |
| `TestServer` wired by hand | `WebApplicationFactory<TEntryPoint>` from `Microsoft.AspNetCore.Mvc.Testing` | Stable since .NET 3.x; current 8.0.x for net8 hosts | One factory class; `CreateClient()`; `ConfigureWebHost` to swap services + settings. |

**Deprecated/outdated:**
- `Microsoft.AspNetCore.Authentication.JwtBearer` — *not deprecated*, just the wrong tool here (single static token, not a JWT issuer). Don't add it.
- `new X509Certificate2(byte[]/string, string)` — obsolete on .NET 9 SDK; use `lo.UseHttps(path, password)` or `X509CertificateLoader`.

---

## Open Questions

1. **Does API-05's "returns parsed JSON plus the raw qbXML plus the status fields" require the *raw* qbXML for `/api/ops/{op}`?**
   - What we know: the Phase-4 ops return `object?` (a dict) that already embeds `status` (and `rows`/`count`/`rawSpilledTo`), but NOT the raw qbXML verbatim. `ReadOpBase` discards the raw string after parsing.
   - What's unclear: whether the reviewer reads API-05 strictly (raw too) or loosely (parsed + status is enough; raw is what `/api/qbxml` is for).
   - Recommendation: ship `/api/ops/{op}` returning `{ op, result }` where `result` is the op's dict (which has `status`); document that verbatim raw qbXML for arbitrary requests is `/api/qbxml`'s job. If the reviewer pushes back, the small forward-fix is to add an optional `rawQbXml` to `ReadOpBase`'s result on a Phase-6/7 pass. **Flag for the planner — decide before generating PLAN.md.**

2. **Controllers vs minimal API.** The spec's `Controllers/` folder is a sketch; the requirements (API-01..06) are agnostic. Recommendation: minimal-API endpoint groups (lighter, consistent with the existing `app.MapGet`). Planner picks; either passes review.

3. **`Where do `ServerOptions`/`AuthOptions`/`SafetyOptions` live?** `SafetyOptions` should be in `QbConnectService.Qb.Com` (Phase 6's defensive-in-depth gate in the manager + `QbWriteDetector` reuse it). `ServerOptions`/`AuthOptions` are host-only — either an `Options/` folder in the host or alongside the existing `QbOptions` in `Qb.Com`. Recommendation: `SafetyOptions` + `QbWriteDetector` in `Qb.Com`; `ServerOptions`/`AuthOptions` in the host. Planner's call.

4. **Exact qbXML write-verb element-name enumeration.** MEDIUM confidence: `*AddRq` / `*ModRq` / `ListDelRq` / `TxnDelRq` / `TxnVoidRq` / `DataExtDelRq` (and `*DelRq` generally) is the standard set per Intuit's "Modify, delete, and void requests and responses" page, but the OSR is JS-rendered and wasn't machine-readable. The `EndsWith("AddRq"|"ModRq"|"DelRq"|"VoidRq")` + explicit generic-name list is the right pattern; **Phase 9 re-pins the precise OSR list on the host.** (Reads are `*QueryRq`/`*ReportQueryRq` — never match the verb scan.)

5. **Testing 409/504 at the API level.** The busy/timeout paths live in `QbConnectionManager` (already unit-tested in Phase 2) and are hard to script through `FakeRequestProcessor` alone. Recommendation: at the API level, test 401/403/404/400/503/200-with-nonzero-status (cleanly scriptable); rely on Phase 2's `QbConnectionManagerTests` for the 409/504 cause. If a 409 integration test is wanted, a blocking `ProcessRequestHook` + a second concurrent request works but is fiddly — optional.

---

## Suggested Ordered Task Breakdown (8 atomic tasks — one commit each; every step `dotnet build` + `dotnet test` green, no QuickBooks)

1. **Options + Kestrel HTTPS-only + appsettings keys.** Add `ServerOptions { BindUrls, CertPath, CertPassword, MaxRequestBodyBytes }` (host) and `SafetyOptions { AllowWrites=false }` (`Qb.Com`) and `AuthOptions { ApiToken }` (host); `Configure<...>` them in `Program.cs`; `builder.WebHost.ConfigureKestrel(...)` building listeners from `Server:BindUrls` (https-only — `throw` on `http://`), file `.pfx` from `Server:CertPath`/`CertPassword` else `lo.UseHttps()` dev fallback, `Limits.MaxRequestBodySize` from `Server:MaxRequestBodyBytes`; add `Server:CertPath`/`Server:CertPassword`/`Server:MaxRequestBodyBytes` to `appsettings.sample.json` (and document prod needs the file cert). Tests: `ServerOptions`/`AuthOptions`/`SafetyOptions` bind from config (mirror `QbOptionsBindingTests`); a "startup throws when `Server:BindUrls` is `http://...`" test.
2. **`BearerAuthMiddleware` + `/api` prefix wiring.** The `FixedTimeEquals` middleware (Pattern 2), applied to `/api/*`, 401 + `WWW-Authenticate: Bearer` + `ProblemDetails` body, short-circuit. Wire `app.UseMiddleware<BearerAuthMiddleware>()` after the exception handler. (Endpoints don't exist yet — add a temporary `api.MapGet("/ping", ...)` or land this together with task 4's first endpoint; recommend landing the middleware *with* task 4 if a standalone test needs an `/api/*` route — or add a throwaway `/api/ping` removed in task 4. Planner's call; keeping task 2 = "middleware + a trivial `/api/ping` to test it" is fine.)
3. **Global exception → `ProblemDetails`.** `AddProblemDetails()` + `AddExceptionHandler<ApiExceptionHandler>()` + `app.UseExceptionHandler()`; the `ArgumentException`→400 / `QbXmlParseException`→400 / `QbBusyException`→409 / `QbTimeoutException`→504 / `QbException`→503 / else→500 mapping (Pattern 3), no stack trace in the body. Tests: a tiny `/api/_throw?kind=...` test-only endpoint *or* (better) defer the assertions to tasks 5–7 where real ops throw the real exceptions. Recommendation: implement the handler here, assert it via task 6/7's qbXML/ops tests (e.g. `/api/qbxml` with the fake scripted to `EnqueueComError(0x80040154)` → 503).
4. **`OpRegistry` + DI + `GET /api/ops`.** `OpRegistry(IEnumerable<IReadOp>)` → dict, throw on dup, `TryGet`/`Names`; `AddSingleton<OpRegistry>()`; optional `GET /api/ops` → `{ ops: [names] }`. Tests: registry resolves, has all 12 names, throws on a duplicate-name fake op; `GET /api/ops` with token → 200 list, without → 401.
5. **`GET /api/health`.** `HealthEndpoints.MapHealthEndpoints()`; the liveness probe (a `HostQueryRq`+`CompanyQueryRq` round-trip — or reuse `CompanyInfoOp` — inside try/catch with a short `CancellationTokenSource`), the `healthy`/`degraded`/`down` state machine, the payload (Pitfall 1). Tests (`WebApplicationFactory`, env=Testing, captured fake): fake scripted to return `HostCompanyQueryRs.qbxml` → 200 `status:"healthy"`, expected fields; fake scripted `EnqueueComError(0x80040154)` → 200 `status:"down"`, `lastError` populated, QB fields null; no token → 401. (This is also the first task that *needs* the `WebApplicationFactory` harness — so task 8's `QbWebAppFactory` may be pulled forward to here; recommend creating `QbWebAppFactory` + the `Microsoft.AspNetCore.Mvc.Testing` package add as the *first sub-step of task 5* and growing it.)
6. **`POST /api/qbxml`.** `QbXmlEndpoints.MapQbXmlEndpoints()` — read body as string, `QbWriteDetector.IsWriteRequest` (new helper in `Qb.Com`, XLinq local-name scan — Pattern 5), 403 if `!AllowWrites && IsWriteRequest`, else `manager.ExecuteAsync` → `Results.Content(raw, "application/xml")`; malformed body → `QbXmlParseException` → 400. `QbWriteDetector` unit tests (`CustomerAddRq` → true; `InvoiceModRq` → true; `ListDelRq`/`TxnDelRq`/`TxnVoidRq` → true; `CustomerQueryRq` → false; `<!-- ItemAddRq -->` comment → false; an element literally `<CustomerAddRq>` inside → true; malformed → throws). Integration tests: a read qbXML round-trips → the fake's canned `CustomerQueryRs`; a `<CustomerAddRq>` body with `AllowWrites=false` → 403; fake scripted `EnqueueComError(0x80040154)` → 503.
7. **`POST /api/ops/{op}`.** `OpsEndpoints.MapOpsEndpoints()` — `registry.TryGet(op)` else 404; read body → `JsonDocument`, `ArgReader.ToDictionary(root)` (lift to public) — empty body → empty args, non-object root → 400; `op.RunAsync(args, ct)`; `200 { op, result }`. (Named-op write-gating + `/dryrun` are Phase 6 — NOT here.) Integration tests: `company_info` (fake → `HostCompanyQueryRs.qbxml`) → 200 with `result.companyName` etc.; unknown op `/api/ops/nope` → 404; an op whose fake `*QueryRs` has `statusCode != "0"` → **200** with `result.status.code != "0"` (API-06); `report` with neither range nor macro → `ArgumentException` → 400; `EnqueueComError(0x80040154)` mid-op → 503.
8. **`QbWebAppFactory` consolidation + `Microsoft.AspNetCore.Mvc.Testing` package add + end-to-end sweep.** (If `QbWebAppFactory` was created in task 5, this task = "round out the integration-test matrix covering API-01..06 + final `dotnet test` sweep + update STATE.md/ROADMAP checkbox" — Codex commits its own SUMMARY per the established pattern.) The package add (`Microsoft.AspNetCore.Mvc.Testing` `8.0.*` in `QbConnectService.Tests.csproj`) goes wherever the first `WebApplicationFactory` test lands (task 5).

(Could compress 2+3 into one "middleware layer" task and 6+7 into one "endpoints" task → 6 tasks; 8 is the safe granular default. The `QbWebAppFactory` + package add should be created the first time a `WebApplicationFactory` test is needed — task 5.)

---

## Sources

### Primary (HIGH confidence)
- `learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel/endpoints?view=aspnetcore-8.0` — Kestrel endpoint config, `ConfigureKestrel`, `ListenOptions.UseHttps(path, password)`, the `"Kestrel:Endpoints"` / `HttpsInlineCertFile` config block, HTTPS-only binds.
- `learn.microsoft.com/aspnet/core/test/integration-tests?view=aspnetcore-8.0` + `learn.microsoft.com/dotnet/api/microsoft.aspnetcore.mvc.testing.webapplicationfactory-1?view=aspnetcore-8.0` — `WebApplicationFactory<TEntryPoint>`, `ConfigureWebHost`, `UseEnvironment`, `UseSetting`, `CreateClient`, the `public partial class Program {}` requirement.
- `nuget.org/packages/Microsoft.AspNetCore.Mvc.Testing` — version stream: 8.0.x is current for net8 hosts (latest 8.0 servicing 8.0.21); 9.x/10.x are for net9/net10. Pin `8.0.*`.
- The existing codebase (`Program.cs`, `QbConnectionManager.cs`, `QbErrors.cs`, `QbExceptions.cs`, `QbXmlParser.cs`, `QbXmlBuilder.cs`, `Qb/Ops/*` incl. `IReadOp`/`ReadOpBase`/`ArgReader`/`CompanyInfoOp`/`RunQueryOp`, `FakeRequestProcessor.cs`, `HostStartupTests.cs`, `OpRegistrationTests.cs`, both `.csproj` files, `appsettings.sample.json`) — the actual contracts Phase 5 builds on. HIGH (read directly).
- ASP.NET Core `ProblemDetails` / `IExceptionHandler` / `IProblemDetailsService` — in-box .NET 8 (`AddProblemDetails`, `UseExceptionHandler`, `IExceptionHandler` added in .NET 8). HIGH (framework docs + .NET 8 release notes).
- `.planning/research/STACK.md` + `.planning/research/ARCHITECTURE.md` — the validated stack/architecture for this project (custom bearer middleware with `FixedTimeEquals` not JwtBearer; `WebApplicationFactory` + `Microsoft.AspNetCore.Mvc.Testing`; the "statusCode!=0 is a 200 body" invariant; the `/api/health` shape; `AllowWrites=false` element-name verb-scan). HIGH (the planning record).

### Secondary (MEDIUM confidence)
- `developer.intuit.com/app/developer/qbdesktop/docs/develop/exploring-the-quickbooks-desktop-sdk/modify-delete-and-void-requests-and-responses` — confirms the generic `ListDelRq` / `TxnDelRq` / `TxnVoidRq` request elements and the `*AddRq`/`*ModRq` per-entity pattern. (Page is JS-rendered; the element names were extracted via WebFetch's summarizer — the *complete* OSR enumeration of `Del`/`Void` requests should be re-pinned on the host in Phase 9.)
- `apideck.com/blog/build-an-integration-with-quickbooks-desktop-in-2025` and the Intuit `QBXML_SDK_Samples` GitHub repo — corroborate the qbXML request/response element-name conventions and `qbXML version="..."` PI usage.

### Tertiary (LOW confidence — flag for validation)
- General community posts on ASP.NET Core 8 integration testing / Kestrel HTTPS — used only to corroborate the official docs; the official Microsoft Learn pages above are authoritative.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all in-box ASP.NET Core 8 + one well-known test NuGet; verified against official docs and the existing csproj/code.
- Architecture (endpoints, middleware, exception handler, `OpRegistry`, `WebApplicationFactory` harness): HIGH — straight ASP.NET Core 8 patterns + the existing engine's already-shipped contracts.
- `/api/health` liveness state machine + payload: MEDIUM-HIGH — the "wrap the probe, return 200 with status:down" approach is the standard one and matches API-03; the exact `healthy`/`degraded`/`down` thresholds are a recommendation, not a spec mandate.
- qbXML write-verb element-name set: MEDIUM — `*AddRq`/`*ModRq`/`ListDelRq`/`TxnDelRq`/`TxnVoidRq`/`DataExtDelRq` is the standard set per Intuit docs, but the OSR is JS-rendered; Phase 9 should re-pin the precise enumeration on the host.
- API-05 "raw qbXML for `/api/ops/{op}`" interpretation: open question flagged for the planner/reviewer.

**Research date:** 2026-05-11
**Valid until:** ~2026-06-10 (stable — ASP.NET Core 8 is LTS; the only moving piece is the `Microsoft.AspNetCore.Mvc.Testing` 8.0.x servicing patch number, which `8.0.*` floats automatically).
