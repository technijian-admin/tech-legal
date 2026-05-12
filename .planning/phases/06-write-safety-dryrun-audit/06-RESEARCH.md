# Phase 6: Write Safety, Dry-Run & Audit - Research

**Researched:** 2026-05-11
**Domain:** Write-safety machinery for the QbConnectService — the `AllowWrites` gate enforced in depth, the `/api/ops/{op}/dryrun` endpoint, and an append-only hash-chained audit log — landed *before* any real write op (those are Phase 7).
**Confidence:** HIGH. This phase adds nothing exotic: it's plumbing on top of the existing .NET 8 + Minimal-API + `IRequestProcessor`-fake stack already proven through Phases 1–5. The only "stale-knowledge" risk areas (qbXML write-verb set, qbXML element/enum names) are explicitly out of scope here (re-pinned in Phase 9). No new NuGet packages. No QuickBooks SDK needed — the fake + `WebApplicationFactory` + a test-project `FakeWriteOp` exercise everything.

## Summary

Phase 6 builds the **write-safety machinery** with **no real write op** (that's by design — flag it loudly for the reviewer). Three deliverables: (1) the `IWriteOp : IReadOp` shape + `WriteOpBase` (the gate→build→execute→parse→audit pipeline) so Phase-7 write ops are thin; (2) the `POST /api/ops/{op}/dryrun` endpoint — byte-exact qbXML + resolved-reference echo + plain-English summary + pre-flight validation, **zero side effects**, **not** write-gated; (3) the `AuditLog` — an append-only, SHA-256 hash-chained JSONL file at `<Audit:Path>/audit.jsonl`, one record per *executed* write, with a `VerifyChainAsync` that detects tampering. Plus the `AllowWrites` gate enforced in **three** distinct places (the ops endpoint for write ops, the existing `/api/qbxml` verb-scan, and defensively in `QbConnectionManager`) with a test proving each fires independently.

Everything is buildable + testable with `dotnet build` / `dotnet test` and **no QuickBooks installed**. The work is deliberately incremental — six atomic tasks, each ending green, each its own commit (commit-per-task, per the established Codex pattern). The two heaviest tasks are the `AuditLog` (hash chain + thread-safe append + verify) and the `IWriteOp`/`WriteOpBase` shape (because it has to be right enough that Phase 7's seven write ops + all `mod_*` just slot in).

**Primary recommendation:** Add `IWriteOp : IReadOp` with `string BuildRequest(args)` (pure) + `Task<DryRunResult> DryRunAsync(args, ct)` (read round-trips OK, never executes a write, never audits); a `WriteOpBase` whose `RunAsync` = `BuildRequest` → re-check `AllowWrites` → `QbConnectionManager.ExecuteAsync` → `QbXmlParser.Parse` → `AuditLog.AppendAsync` → return; a singleton `AuditLog` (JSONL, SHA-256 chain, `SemaphoreSlim(1,1)`, cached last hash, `VerifyChainAsync`); `POST /api/ops/{op}/dryrun` in `OpsEndpoints` (write-op → full `DryRunResult`; read-op → just the would-be request; never write-gated); the `AllowWrites` 403 produced directly by `POST /api/ops/{op}` when the op `is IWriteOp && !AllowWrites`; `QbConnectionManager` gains an `IOptions<SafetyOptions>` ctor param and throws a new `QbWriteForbiddenException` (mapped to 403 in `ApiExceptionHandler`) if a write request reaches `ExecuteAsync` while writes are off; a `FakeWriteOp : IWriteOp` lives in the **test project** to exercise the machinery.

---

## Standard Stack

No new dependencies. Everything is already in the solution.

### Core (already present — Phase 6 just uses it)
| Library / API | Version | Purpose | Why |
|---|---|---|---|
| `System.Text.Json` (`Utf8JsonWriter`, `JsonSerializer`) | in-box (.NET 8) | Serialize audit records to canonical JSONL; parse args | Already the project's JSON stack (`ArgReader`, endpoints). For the **canonical** record bytes the hash covers, write fields with `Utf8JsonWriter` in a **fixed, hand-coded order** — do *not* rely on reflection property order (it's deterministic in .NET 7+ but brittle to refactors). |
| `System.Security.Cryptography.SHA256` | in-box (.NET 8) | Hash-chain each audit record | `SHA256.HashData(ReadOnlySpan<byte>)` (static, no instance/dispose needed). Hex-encode with `Convert.ToHexStringLower` (.NET 9+) — on .NET 8 use `Convert.ToHexString(...).ToLowerInvariant()`. |
| `System.IO` (`File.AppendAllTextAsync`, `File.ReadLinesAsync`, `StreamWriter`) | in-box | Append-only JSONL file; read back for verify / last-hash | One file, append `record-json + "\n"`. Use `File.AppendAllText` (creates if missing) under the lock; `File.ReadLinesAsync` for `VerifyChainAsync`. |
| `SemaphoreSlim(1,1)` | in-box | Serialize concurrent audit appends | Same pattern `QbConnectionManager` uses for the COM gate. The audit append must be atomic w.r.t. reading the previous hash. |
| `Microsoft.Extensions.Options` (`IOptions<T>`, `Configure<T>`) | in-box | Bind `Audit:Path` → `AuditOptions`; inject `SafetyOptions` into `QbConnectionManager` | Same pattern as every other options POCO (`QbXmlOptions`, `ServerOptions`, `SafetyOptions`). |
| ASP.NET Core Minimal APIs + `ProblemDetails` + `IExceptionHandler` | in-box | The `/dryrun` endpoint; the 403; map `QbWriteForbiddenException` | Phase 5 already wired `AddProblemDetails()` + `AddExceptionHandler<ApiExceptionHandler>()` + `MapGroup("/api")` route groups. Phase 6 extends `OpsEndpoints` and `ApiExceptionHandler`. |
| xUnit + `Microsoft.AspNetCore.Mvc.Testing` (`WebApplicationFactory<Program>`) | already referenced | Integration tests for `/dryrun`, the 403, the audit path | `QbWebAppFactory` exists; new tests build on it. To exercise write machinery without a real write op, register a `FakeWriteOp : IWriteOp` via `ConfigureServices` (or add it to `QbWebAppFactory`). |

### Alternatives Considered
| Instead of | Could Use | Why not (for v1) |
|---|---|---|
| Single `audit.jsonl` file | Daily-rotated files (`audit-2026-05-11.jsonl`) | Rotation complicates the chain (chain must span files or reset per file). v1 = one file; rotation is a documented v2 note. The Phase-3 `QbResponseSpiller` already writes oversized raw responses *beside* the audit log — that's a separate concern, not the audit file itself. |
| Hand-coded canonical JSON via `Utf8JsonWriter` | `JsonSerializer.Serialize` with a custom property-ordering `JsonTypeInfoResolver` | Overkill; the record has ~10 fixed fields. Hand-writing them in a known order is simpler, faster, and immune to refactor surprises. |
| `QbConnectionManager` takes `IOptions<SafetyOptions>` | A separate `IQbWriteGuard` service it consults | Extra indirection for no gain; the manager is already a singleton and already takes three `IOptions<>` params. One more is the least-churn change. (See Open Question 1 for the exact test-construction updates.) |
| Refused-write gets an audit row | Refused-write logged as `LogWarning` only | "Audit log = executed writes only" keeps the chain meaning unambiguous (every row is something QuickBooks actually saw). A 403'd write was never sent — it's not part of "what the bot did to the books." Log it at `Warning`; don't chain it. (Flag for the planner: if the reviewer wants refused-writes auditable, that's a one-line addition, but recommend against for v1.) |

**Installation:** none. `dotnet build` / `dotnet test` only.

---

## Architecture Patterns

### Where things live (folders / namespaces — match the established layout)

```
quickbooks/QbConnectService/src/
├── QbConnectService.Qb.Com/                    # the COM-adjacent + ops library
│   ├── Audit/
│   │   ├── AuditOptions.cs                     # { Path }  bound from "Audit"
│   │   ├── AuditRecord.cs                      # the record POCO/record-struct + canonical-bytes
│   │   └── AuditLog.cs                         # append-only, SHA-256 hash-chained JSONL; AppendAsync / VerifyChainAsync
│   ├── QbExceptions.cs                         # + QbWriteForbiddenException
│   ├── QbConnectionManager.cs                  # + IOptions<SafetyOptions> ctor param + defensive write check
│   └── Qb/Ops/
│       ├── IWriteOp.cs                         # interface IWriteOp : IReadOp
│       ├── WriteOpBase.cs                      # gate→build→execute→parse→audit pipeline; dry-run helpers
│       └── DryRunResult.cs                     # the dry-run payload record (+ PreFlightCheck)
├── QbConnectService/
│   ├── Api/OpsEndpoints.cs                     # + POST /ops/{op}/dryrun ; + AllowWrites gate on POST /ops/{op}
│   ├── Api/ApiExceptionHandler.cs              # + QbWriteForbiddenException => 403
│   └── Program.cs                              # + Configure<AuditOptions> ; + AddSingleton<AuditLog> ; (QbConnectionManager ctor change is transparent — already AddSingleton)
└── QbConnectService.Tests/
    ├── Fakes/FakeWriteOp.cs                    # IWriteOp test double — known qbXML, exercises the pipeline
    ├── AuditLogTests.cs                        # append N → N lines; each hash recomputes; VerifyChainAsync ok; tamper → broken seq; dry-run appends nothing
    ├── WriteOpBaseTests.cs                     # BuildRequest pure; RunAsync gate→execute→parse→audit; DryRunAsync = build+preflight, no execute/no audit
    ├── QbConnectionManagerWriteGuardTests.cs   # ExecuteAsync(<CustomerAddRq>) + AllowWrites=false → QbWriteForbiddenException; AllowWrites=true → passes
    ├── DryRunEndpointTests.cs                  # POST /api/ops/{fakeWriteOp}/dryrun → 200 w/ qbxml+summary+preflight+allowWrites:false; NOT write-gated; fake saw no write; audit file empty
    └── WriteSafetyTests.cs                     # the three layers fire independently (ops-endpoint 403, /api/qbxml 403, manager exception) + WriteExecuteTests: AllowWrites=true → 200, byte-exact request, exactly one audit row even if response statusCode != 0
```

Rationale:
- **`Audit/` subfolder under `QbConnectService.Qb.Com`** — not a separate project. The project research's ARCHITECTURE.md put `Audit/` separate from `Qb/` *conceptually*, but the existing solution keeps everything (`SafetyOptions`, `QbWriteDetector`, all ops) in the one `Qb.Com` library; adding a third project is churn. Namespace: `QbConnectService.Qb` (matches `QbConnectionManager`, `QbWriteDetector`, `SafetyOptions`) — or `QbConnectService.Qb.Audit` if the planner prefers; recommend `QbConnectService.Qb` to avoid a `using` churn (everything else is already `QbConnectService.Qb` or `QbConnectService.Qb.Ops`).
- **`IWriteOp`/`WriteOpBase`/`DryRunResult` in `Qb/Ops/`** next to `IReadOp`/`ReadOpBase`/`ArgReader`/`OpRegistry` — same folder, namespace `QbConnectService.Qb.Ops`.
- **`FakeWriteOp` in the test project** — Phase 6 ships **no production write op**. The test double proves the machinery; Phase 7 ships the real ones.

### Pattern 1: `IWriteOp : IReadOp` — write ops are read ops with two more members

```csharp
// QbConnectService.Qb.Com/Qb/Ops/IWriteOp.cs
namespace QbConnectService.Qb.Ops;

public interface IWriteOp : IReadOp
{
    /// Byte-exact qbXML this op WOULD send for these args. Pure: no I/O, no COM, deterministic.
    /// Throws ArgumentException on bad/missing args (same contract as the read ops' arg validation).
    /// RunAsync and DryRunAsync both call this — the preview is byte-for-byte what gets sent.
    string BuildRequest(IReadOnlyDictionary<string, object?> args);

    /// Build the request + run pre-flight validation (which MAY do read round-trips: resolve names→IDs,
    /// check referenced entities exist, fetch the current record + EditSequence for a mod_* diff, etc.)
    /// MUST NOT execute a write request and MUST NOT append to the audit log. Zero side effects.
    Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default);
}
```

`RunAsync` (inherited from `IReadOp`) for a write op = the full pipeline (implemented once in `WriteOpBase`):

```csharp
// QbConnectService.Qb.Com/Qb/Ops/WriteOpBase.cs
public abstract class WriteOpBase(
    QbXmlBuilder builder,
    QbConnectionManager manager,
    QbXmlParser xmlParser,
    QbReportParser reportParser,
    QbListExecutor listExecutor,
    AuditLog audit,
    IOptions<SafetyOptions> safety)
    : ReadOpBase(builder, manager, xmlParser, reportParser, listExecutor), IWriteOp
{
    protected readonly AuditLog _audit = audit;
    protected readonly SafetyOptions _safety = safety.Value;

    public abstract string BuildRequest(IReadOnlyDictionary<string, object?> args);

    // Default DryRunAsync: build + AllowWrites echo + (no preflight checks). Real write ops override
    // to add reference resolution / balance checks / mod_* diffs. Phase 6 ships only the base + FakeWriteOp.
    public virtual Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
        => Task.FromResult(new DryRunResult(
            QbXml: BuildRequest(args),
            Summary: $"{Name}: would send the qbXML below.",
            PreFlight: Array.Empty<PreFlightCheck>(),
            ResolvedReferences: new Dictionary<string, object?>(),
            AllowWrites: _safety.AllowWrites));

    public override async Task<object?> RunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
    {
        var requestXml = BuildRequest(args);                              // pure; ArgumentException → 400

        if (!_safety.AllowWrites)                                          // belt #4 (extra defense; layers 1 & 3 are the required two)
            throw new QbWriteForbiddenException($"{Name} is a write op and Safety:AllowWrites is false.");

        var rawResponse = await _manager.ExecuteAsync(requestXml, ct);     // single COM chokepoint; layer 3 also re-checks
        var parsed = _xmlParser.Parse(rawResponse);                        // statusCode != 0 is a business outcome, NOT an exception

        var status = parsed.First.Status;                                  // (or parsed.Message — pick the message-level status for the audit row)
        var seq = await _audit.AppendAsync(new AuditRecord(
            Op: Name, Args: args, QbXmlRequest: requestXml,
            ResponseStatusCode: status.Code, ResponseStatusSeverity: status.Severity, ResponseStatusMessage: status.Message),
            ct);

        return new Dictionary<string, object?>
        {
            ["status"]    = status,
            ["rows"]      = parsed.First.Rows,
            ["auditSeq"]  = seq,
            ["rawSpilledTo"] = parsed.RawSpilledTo,
        };
    }

    // --- dry-run helpers Phase-7 ops reuse (sketch — implement what's cheap, stub the rest with a clear TODO) ---
    // protected async Task<XElement?> ResolveCurrentRecordAsync(string queryRq, string idElement, string idValue, CancellationToken ct) { ... QuerySingleAsync ... }
    // protected static PreFlightCheck DiffFields(string label, IReadOnlyDictionary<string,string?> before, IReadOnlyDictionary<string,string?> after) { ... }
}
```

```csharp
// QbConnectService.Qb.Com/Qb/Ops/DryRunResult.cs
public sealed record DryRunResult(
    string QbXml,
    string Summary,
    IReadOnlyList<PreFlightCheck> PreFlight,
    IReadOnlyDictionary<string, object?> ResolvedReferences,
    bool AllowWrites);

public sealed record PreFlightCheck(string Name, bool Ok, string Detail);
```

**Why this shape:** `BuildRequest` is the single source of truth for the qbXML — `DryRunAsync` and `RunAsync` both call it, so "the preview is byte-for-byte what gets sent" is structurally guaranteed (the project research's anti-pattern #7 — "dry-run drifts from real"). `DryRunAsync` returning a record (not a raw `object?`) gives the endpoint a typed shape. `WriteOpBase : ReadOpBase` reuses every read helper (`QuerySingleAsync` for pre-flight reads, `_builder`/`_manager`/`_xmlParser`). `OpRegistry` already holds ops as `IReadOp` — write ops register as `IReadOp` *and* are `is IWriteOp`; the endpoints pattern-match.

> **Decide & flag (Open Question 2):** sync vs async pre-flight. Recommendation above = **async** (`DryRunAsync` returns `Task<DryRunResult>`) because entity-existence / current-record fetches need a read round-trip through `QbConnectionManager`. `BuildRequest` itself stays **sync + pure**. The base `DryRunAsync` does no reads (so its `Task.FromResult` is fine for Phase 6); Phase-7 ops override and `await` their pre-flight reads.

### Pattern 2: The audit log — append-only, SHA-256 hash-chained JSONL

```csharp
// QbConnectService.Qb.Com/Audit/AuditOptions.cs
public sealed class AuditOptions
{
    /// Directory for the append-only audit log. The file is <Path>/audit.jsonl.
    public string Path { get; set; } = string.Empty;   // appsettings.sample.json already has Audit:Path
}

// QbConnectService.Qb.Com/Audit/AuditRecord.cs  — the "input" half (seq/prevHash/hash are computed by AuditLog)
public sealed record AuditRecord(
    string Op,
    IReadOnlyDictionary<string, object?> Args,
    string QbXmlRequest,
    string ResponseStatusCode,
    string ResponseStatusSeverity,
    string ResponseStatusMessage);

// The persisted line shape (one JSON object per line):
// { "seq": 1, "timestampUtc": "2026-05-11T17:04:09.123Z", "op": "create_customer",
//   "args": { ... }, "qbXmlRequest": "<?xml ...?>...", "responseStatusCode": "0",
//   "responseStatusSeverity": "Info", "responseStatusMessage": "Status OK",
//   "requesterId": "tok-1a2b3c4d", "prevHash": "0000...0000", "hash": "<sha256 hex of this object minus hash>" }
```

```csharp
// QbConnectService.Qb.Com/Audit/AuditLog.cs  (sketch)
public sealed class AuditLog
{
    private const string GenesisPrevHash = "0000000000000000000000000000000000000000000000000000000000000000"; // 64 zeros
    private readonly string _filePath;
    private readonly string _requesterId;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private readonly ILogger<AuditLog> _log;
    private long _lastSeq = -1;            // -1 = not yet loaded
    private string _lastHash = GenesisPrevHash;

    public AuditLog(IOptions<AuditOptions> audit, IOptions<AuthOptions> auth, ILogger<AuditLog> log)
    {
        var dir = string.IsNullOrWhiteSpace(audit.Value.Path)
            ? Path.Combine(Path.GetTempPath(), "QbConnectService", "audit")   // sane fallback (mirrors QbResponseSpiller's spill fallback)
            : audit.Value.Path;
        _filePath = Path.Combine(dir, "audit.jsonl");
        _requesterId = DeriveRequesterId(auth.Value.ApiToken);                 // "tok-" + sha256(token).hex[..8]; "api" if token blank
        _log = log;
    }

    public async Task<long> AppendAsync(AuditRecord rec, CancellationToken ct = default)
    {
        await _gate.WaitAsync(ct);
        try
        {
            await EnsureLoadedAsync(ct);                       // first call: read the file (if any), set _lastSeq/_lastHash
            var seq = _lastSeq + 1;
            var ts = DateTime.UtcNow;
            var (canonicalJson, hash) = ComputeRecord(seq, ts, rec, _requesterId, _lastHash);   // canonical JSON minus "hash", SHA-256 hex
            var line = InsertHash(canonicalJson, hash) + "\n"; // append "hash" as the last property
            Directory.CreateDirectory(Path.GetDirectoryName(_filePath)!);
            await File.AppendAllTextAsync(_filePath, line, ct);
            _lastSeq = seq; _lastHash = hash;
            return seq;
        }
        finally { _gate.Release(); }
    }

    public async Task<(bool Ok, long? FirstBrokenSeq)> VerifyChainAsync(CancellationToken ct = default)
    {
        await _gate.WaitAsync(ct);
        try
        {
            if (!File.Exists(_filePath)) return (true, null);
            var prev = GenesisPrevHash; long expectedSeq = 0;
            await foreach (var line in File.ReadLinesAsync(_filePath, ct))
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                var obj = JsonNode.Parse(line)!.AsObject();
                var seq = (long)obj["seq"]!;
                var storedHash = (string)obj["hash"]!;
                var storedPrev = (string)obj["prevHash"]!;
                var recomputed = HashOf(StripHashProperty(obj));     // re-serialize canonically minus "hash", SHA-256
                if (seq != expectedSeq || storedPrev != prev || recomputed != storedHash) return (false, seq);
                prev = storedHash; expectedSeq = seq + 1;
            }
            return (true, null);
        }
        finally { _gate.Release(); }
    }
}
```

Key decisions inside the audit log:
- **One file** `audit.jsonl` under `Audit:Path` (the sample config already has the key). If the path is blank, fall back to `%TEMP%\QbConnectService\audit` (mirrors how `QbResponseSpiller` falls back). Rotation = documented v2 note.
- **JSONL** (one canonical-JSON object per line) — grep-able, append-only, trivially streamable for `VerifyChainAsync`. Append `record + "\n"`.
- **Hash chain:** `hash = SHA256(canonical-JSON-of-the-record-with-the-"hash"-property-omitted)`, hex-lowercased; `prevHash` = the previous record's `hash`; **genesis `prevHash` = 64 zeros** (a fixed, non-null constant — easier to test than `null`). Build the canonical JSON with `Utf8JsonWriter` writing the fields in a **fixed order**: `seq, timestampUtc, op, args, qbXmlRequest, responseStatusCode, responseStatusSeverity, responseStatusMessage, requesterId, prevHash` — then compute the hash, then append `hash` as the 11th property. (Do **not** sort `args` keys — `args` is whatever the caller sent; serialize it as-is. The hash covers the bytes you actually wrote, so as long as `AppendAsync` and `VerifyChainAsync` serialize it the *same* way, it's stable. Recommend: in `VerifyChainAsync`, re-serialize the parsed `JsonNode` with the same `Utf8JsonWriter` field order rather than trusting the on-disk byte layout — that makes the verify robust to whitespace.)
- **Thread-safety:** `SemaphoreSlim(1,1)` around the whole append (read-cached-last-hash → compute → write). The audit log is a **singleton**. Cache `_lastSeq`/`_lastHash` in memory after the first load so steady-state appends don't re-read the file. (`VerifyChainAsync` also takes the gate so it can't race an append.)
- **`requesterId`:** `"tok-" + SHA256(ApiToken).hex[..8]` (so a token rotation shows up in the log without ever logging the token itself); `"api"` if the configured token is blank. Bind `IOptions<AuthOptions>` into `AuditLog` to get the token. (`AuthOptions.ApiToken` already exists from Phase 5.)
- **`timestampUtc`:** `DateTime.UtcNow`, ISO-8601 with `Z` (round-trip `"O"` format or `XmlConvert.ToString(..., Utc)`); never local time (project research pitfall #20).
- **What's recorded:** exactly the fields above — `op`, the `args` dict (as JSON), the `qbXmlRequest` byte-exact, the response `statusCode`/`statusSeverity`/`statusMessage` (even when `statusCode != 0` — a QuickBooks-rejected write still gets a row, with its error status — project research ARCHITECTURE.md "audit append is on the post-COM path, success or rejection alike"), `requesterId`, the chain `prevHash`/`hash`, and `seq`.
- **Who appends:** only `WriteOpBase.RunAsync`, after `ExecuteAsync` returns and `Parse` succeeds. The `/dryrun` path appends **nothing**. A 403'd (never-executed) write appends **nothing** (logged at `Warning` instead — see Alternatives table; flag for the reviewer).

### Pattern 3: `AllowWrites` enforced in depth — exactly three layers

| Layer | Where | What it does | Produced how |
|---|---|---|---|
| **1. Ops endpoint** | `OpsEndpoints.MapPost("/ops/{op}", ...)` | After `OpRegistry.TryGet` resolves the op: `if (op is IWriteOp && !safety.Value.AllowWrites) → 403 ProblemDetails` — **before** `RunAsync` | `Results.Problem(403, "Writes disabled", "...")` directly — **no exception** (clean) |
| **2. Raw passthrough** | `QbXmlEndpoints.MapPost("/qbxml", ...)` | **Already exists** (Phase 5): `if (!AllowWrites && QbWriteDetector.IsWriteRequest(body)) → 403` — element-name verb scan, not substring | `Results.Problem(403, "Writes disabled", "...")` directly — already there; Phase 6 just adds a test if not already covered |
| **3. Connection manager (defensive)** | `QbConnectionManager.ExecuteAsync(qbXmlRequest, ct)` | Before sending: `if (!_safety.AllowWrites && QbWriteDetector.IsWriteRequest(qbXmlRequest)) throw new QbWriteForbiddenException(...)` — catches a write that somehow got past layers 1 & 2 (a bug, a future code path) | `throw QbWriteForbiddenException` → `ApiExceptionHandler` maps to **403** |
| (4. `WriteOpBase.RunAsync` re-check) | `WriteOpBase.RunAsync` | `if (!_safety.AllowWrites) throw QbWriteForbiddenException` before `ExecuteAsync` | extra belt; **not** one of the required three — the spec says "in the ops controller, in the raw passthrough, and defensively in the connection manager" = exactly layers 1, 2, 3 |

**`QbConnectionManager` change (the only edit to a Phase-2 file):**
- Add `IOptions<SafetyOptions> safety` as a **new ctor param** (recommend last position to minimize diff noise, or wherever reads cleanest). `QbConnectionManager` is already `AddSingleton<QbConnectionManager>()` so DI resolves the new param automatically — **no `Program.cs` change needed** for the manager itself (you do need `Configure<AuditOptions>` + `AddSingleton<AuditLog>` for the audit log).
- In `ExecuteAsync`, **short-circuit on `AllowWrites == true`** (the common case — don't parse the request XML at all when writes are on): `if (!_safety.AllowWrites && QbWriteDetector.IsWriteRequest(qbXmlRequest)) throw new QbWriteForbiddenException(...)`. Do this **before** taking the `_gate` (it's pure validation; mirrors how `ReadOpBase` builds before the gate).
- **Test-construction updates:** `QbConnectionManagerTests.CreateManager(...)` constructs `new QbConnectionManager(Factory, Options.Create(qbOptions), Options.Create(requestOptions), NullLogger<...>.Instance)` — add `Options.Create(new SafetyOptions { AllowWrites = ... })` to that one helper. Grep for `new QbConnectionManager(` — as of Phase 5 the **only** manual-construction site is `QbConnectionManagerTests` (the integration tests get it from DI via `WebApplicationFactory`, which is unaffected). `RealRequestProcessorSmokeTests` and `OpRegistrationTests` do **not** construct it manually (verified). One file to touch. (If the planner finds another site, add the param there too.)

**`QbWriteForbiddenException` (new, in `QbExceptions.cs`):**
```csharp
public sealed class QbWriteForbiddenException : Exception
{
    public QbWriteForbiddenException(string message) : base(message) { }
}
```
**`ApiExceptionHandler` (add one switch arm, before the generic `_ =>`):**
```csharp
QbWriteForbiddenException => (StatusCodes.Status403Forbidden, "Writes disabled"),
```
(It's not a `QbException` subclass, so the existing `ex is QbException qb ? ... : ex.Message` detail line already does the right thing — `ex.Message`. Don't make it a `QbException` subclass — that family maps to 503.)

### Pattern 4: `POST /api/ops/{op}/dryrun` — preview, never execute, never write-gated

```csharp
// in OpsEndpoints.MapOpsEndpoints — add alongside the existing POST /ops/{op}
app.MapPost("/ops/{op}/dryrun", async (
    string op, HttpContext ctx, OpRegistry registry, CancellationToken ct) =>
{
    if (!registry.TryGet(op, out var resolved))
        return Results.Problem(StatusCodes.Status404NotFound, title: "Unknown op",
            detail: $"No op named '{op}'. GET /api/ops for the list.");

    var args = await ReadArgsAsync(ctx, ct);                  // reuse the existing private helper

    if (resolved is IWriteOp wop)
    {
        var dryRun = await wop.DryRunAsync(args, ct);         // may do read round-trips; NEVER executes a write; NEVER audits
        return Results.Ok(new { op, dryRun });
    }

    // Read op: no side effects anyway — return the request it would build, so the agent can preview it.
    // ReadOpBase doesn't currently expose its would-be request; recommend a small addition (see below) OR 400 here.
    return Results.Ok(new { op, dryRun = new { qbxml = (string?)null, note = "dry-run preview is available for write ops; this is a read op (calling it has no side effects)." } });
    // ALTERNATIVE if you'd rather not touch ReadOpBase: return Results.Problem(400, "Not a write op", "...").
});
```

Key points:
- **404** if the op doesn't exist (same as `POST /ops/{op}`).
- **Not write-gated** — works when `AllowWrites=false`; in fact `dryRun.allowWrites:false` shows up in the result so the caller knows the real execute would be 403'd. **Do not** add the layer-1 gate to `/dryrun`.
- **`ArgumentException`** from `BuildRequest`/`DryRunAsync` → `ApiExceptionHandler` maps to **400** (already). A `QbException` from a pre-flight *read* → **503** (already). A `QbWriteForbiddenException` should be **impossible** here (dry-run never executes a write) — if `DryRunAsync` is implemented correctly it never calls `ExecuteAsync` with a write request.
- **Read-op handling — decide & flag (Open Question 3):** Recommend `/dryrun` *works for any op* and for a read op just returns the would-be request (a "show me the qbXML" tool). That needs `ReadOpBase` to expose the request it would build for a given args dict — currently each read op builds its `XElement` inside `RunAsync`, so this would be a small refactor (extract a `protected virtual XElement BuildRequestElement(args)` or similar in each op, or a `string PreviewRequest(args)` on `ReadOpBase` that returns `null` by default and ops override). **If that refactor is more than trivial, just return a 400 (or the `note` stub above) for read ops and move on** — the *required* behavior (WRITE-02) is the write-op dry-run; read-op preview is a nice-to-have. The planner should pick: (a) `ReadOpBase.PreviewRequest` returning `null` by default + endpoint returns whatever it gets, or (b) 400 on read ops. Recommend (a) with a `null`-returning default so it's zero-churn for the 12 existing ops and Phase-7 ops can fill it in if useful.

### Anti-patterns to avoid (from the project research, sharpened for Phase 6)

- **Dry-run drift.** `/dryrun` and `RunAsync` must both call `IWriteOp.BuildRequest` — never rebuild the qbXML two different ways. Golden-ish test: `FakeWriteOp.BuildRequest` returns a fixed string; the `WriteExecuteTests` assert the fake's `ProcessRequests[0]` equals exactly that string.
- **Substring write detection.** Already handled — `QbWriteDetector.IsWriteRequest` parses element local names. Layer 3 reuses it. Never `body.Contains("Add")`.
- **Auditing a write that never happened.** The audit append is *after* `ExecuteAsync` returns. A 403'd write, a `QbBusyException`, a `QbTimeoutException`, a COM failure → no audit row. (A QuickBooks *business* rejection — `statusCode != 0` — DID reach QuickBooks, so it *does* get a row, with the error status. That's the line: "did QuickBooks see it?".)
- **Mutable / unverifiable audit log.** Append-only file, never rewrite a line, hash-chained, `VerifyChainAsync` tested against a deliberately-tampered line. (NTFS ACLs on the directory are a Phase-9/deploy concern, not Phase 6.)
- **Health-check-style lie.** Not relevant here, but: don't have `/dryrun` claim "preflight ok" without actually running the preflight. Phase 6's base `DryRunResult` has an empty `PreFlight` array — that's honest (no checks run). Phase 7's real ops fill it in.

---

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Hashing | Custom hash / truncated MD5 / non-crypto hash | `System.Security.Cryptography.SHA256.HashData(span)` | In-box, fast, static (no dispose), the obvious choice for an integrity chain. |
| Hex encoding | Manual `byte → "x2"` loop | `Convert.ToHexString(bytes).ToLowerInvariant()` (.NET 8) / `Convert.ToHexStringLower(bytes)` (.NET 9+) | In-box, allocation-light, no off-by-one. |
| JSON serialization of the record | Manual string concat with `\"` escaping | `Utf8JsonWriter` (for the canonical bytes) / `JsonSerializer` (for `args`) | qbXML inside `qbXmlRequest` contains `<`, `>`, `&`, `"`, newlines — proper JSON escaping is non-negotiable; hand-rolling it is a bug factory. |
| JSONL append | `FileStream` with manual flush/lock dance | `File.AppendAllTextAsync` under a `SemaphoreSlim(1,1)` | `AppendAllText` opens-appends-closes atomically per call; the semaphore gives you the cross-call ordering for the hash chain. Don't keep a long-lived `StreamWriter` open — it complicates crash-safety for no win at this volume. |
| Reading the chain back | Load the whole file into a string and split | `File.ReadLinesAsync` (streams line-by-line) | The audit log can get large; stream it. |
| Options binding | `Configuration["Audit:Path"]` reads scattered through code | `services.Configure<AuditOptions>(config.GetSection("Audit"))` + `IOptions<AuditOptions>` | Matches every other options POCO in the solution; one place; testable via `WebApplicationFactory.UseSetting`. |
| Write-verb detection | A new scanner | `QbWriteDetector.IsWriteRequest` (already exists, element-name-based) | Phase 5 built it precisely so Phase 6 reuses it. |
| 403 on a write op at the endpoint | Throwing an exception the handler catches | `Results.Problem(403, ...)` directly | The endpoint *knows* statically the op is a write and writes are off — no need to round-trip through exception machinery. (The *manager's* defensive check is the one that uses an exception, because there the caller is "whoever called `ExecuteAsync`".) |
| Constant-time token compare | A new one for `requesterId` | (n/a) | `requesterId` is a *hash prefix of* the token written to a log — there's no comparison happening, no timing concern. The actual token compare is Phase 5's `BearerAuthMiddleware` with `CryptographicOperations.FixedTimeEquals` — untouched. |

**Key insight:** Phase 6 is 90% glue between things that already exist. The only genuinely new *logic* is the hash chain (≈30 lines) and the `WriteOpBase` pipeline (≈40 lines). Everything else is wiring, an endpoint, an exception, and tests.

---

## Common Pitfalls

### Pitfall 1: Breaking Phase-2's `QbConnectionManagerTests` by changing the ctor
**What goes wrong:** Adding `IOptions<SafetyOptions>` to `QbConnectionManager`'s ctor breaks `QbConnectionManagerTests.CreateManager` (which constructs it by hand) → red build.
**Why:** Manual construction in tests doesn't go through DI.
**Avoid:** Update `CreateManager` in the *same task* that changes the ctor; grep `new QbConnectionManager(` first to confirm it's the only site (it is, as of Phase 5). Default the test's `SafetyOptions` to `AllowWrites = true` so every *existing* manager test (which uses read-ish `CompanyQueryRq`) is unaffected, and add *new* tests for the `false` case. (Note `CompanyQueryRq` isn't a write verb anyway, so even `AllowWrites = false` wouldn't trip the new check on the existing tests — but `true` is the clearer intent for "this test isn't about the write gate".)

### Pitfall 2: The hash chain isn't reproducible (canonical-bytes drift)
**What goes wrong:** `VerifyChainAsync` recomputes a different hash than what's on disk, because the re-serialization orders properties differently or escapes a character differently than the `AppendAsync` write did.
**Why:** Relying on reflection property order, or `JsonNode.ToJsonString()` defaults, or culture-sensitive number formatting.
**Avoid:** Use **one** `static` helper that takes the record fields (or a parsed `JsonObject` minus `hash`) and writes them with `Utf8JsonWriter` in a **hard-coded field order**, invariant culture, `Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping`? — actually *no*, keep the default (strict) encoder, just be consistent. Both `AppendAsync` and `VerifyChainAsync` call that same helper. Test it: append a record, read the line, re-run the helper on the parsed-minus-hash, assert it equals the stored hash. Then flip one byte of `args` on disk and assert `VerifyChainAsync` returns `(false, thatSeq)`.

### Pitfall 3: `/dryrun` accidentally executing a write
**What goes wrong:** `DryRunAsync` calls `_manager.ExecuteAsync(BuildRequest(args))` "to test it" → it actually writes (if `AllowWrites=true`) or 403s (if false). Either way the dry-run lied / had a side effect.
**Why:** Sloppy implementation of the pre-flight reads — using `ExecuteAsync` with the *write* request instead of a *read* query.
**Avoid:** `DryRunAsync` may only `ExecuteAsync` **read** qbXML (a `*QueryRq` to resolve a name or fetch a `mod_*` target). It must never `ExecuteAsync` the request `BuildRequest` returned. Test: `POST /api/ops/{fakeWriteOp}/dryrun` → assert `factory.Fake.ProcessRequests` contains no write request (or, simplest: `FakeWriteOp.DryRunAsync` does no reads at all, so assert `ProcessRequests` is empty) **and** the audit file doesn't exist / is empty.

### Pitfall 4: Audit row written for a write QuickBooks never saw
**What goes wrong:** A `QbTimeoutException` / `QbBusyException` / COM failure bubbles out of `ExecuteAsync`, but the audit append already ran (or runs in a `finally`).
**Why:** Putting `AuditLog.AppendAsync` before/around `ExecuteAsync` instead of strictly after a successful return + parse.
**Avoid:** `RunAsync`: `ExecuteAsync` → (on success) `Parse` → `AppendAsync`. If `ExecuteAsync` throws, the exception propagates *before* any audit call. Test: script the fake to `EnqueueComError`, `POST /api/ops/{fakeWriteOp}` with `AllowWrites=true` → 503, audit file empty.

### Pitfall 5: First append on a fresh box throws because the directory doesn't exist
**What goes wrong:** `Audit:Path` = `C:\ProgramData\QbConnectService\audit` which doesn't exist yet → `DirectoryNotFoundException`.
**Why:** `File.AppendAllText` creates the *file* but not parent *directories*.
**Avoid:** `Directory.CreateDirectory(Path.GetDirectoryName(_filePath)!)` before the first append (idempotent — safe to call every time, it's cheap; or guard with a flag). Tests run with `Audit:Path` pointed at a fresh `Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString())` so each test starts with a clean log; verify the dir gets created.

### Pitfall 6: Reviewer flags "Phase 6 has no real write op" as incomplete
**What goes wrong:** The 100/100 reviewer sees `IWriteOp` with zero implementations and dings the phase.
**Why:** It *looks* unfinished.
**Avoid:** This is **by design** — the roadmap goal is literally "the full write-safety machinery landed *before* any write op exists." State it explicitly in `06-01-PLAN.md` and in the SUMMARY: "Phase 6 ships the `IWriteOp`/`WriteOpBase`/dry-run/audit/gate machinery + a `FakeWriteOp` in the **test project** to exercise it; the real `create_*`/`mod_*` ops are Phase 7 (WRITE-03..07)." Have the plan-checker confirm this framing so the reviewer expects it.

### Pitfall 7: Iterator/`mod_*` knowledge leaking in prematurely
**What goes wrong:** Trying to build the `mod_*` before/after diff helper *fully* in Phase 6 — but there's no real `mod_*` op to test it against, and the qbXML element names aren't pinned.
**Why:** Over-reaching.
**Avoid:** Phase 6 provides the *shape* (`PreFlightCheck`, a `DiffFields` static helper, maybe a `ResolveCurrentRecordAsync` helper on `WriteOpBase`) and proves the *machinery* with `FakeWriteOp` doing a `mod_*`-style synthetic diff. The real `*QueryRq`-by-`TxnID`-then-`*ModRq`-with-fresh-`EditSequence` flow (and the `0x800404C5` stale-edit-sequence handling) is **Phase 7**. The dry-run/audit machinery should be *aware* that `0x800404C5` is a qbXML status code, not a COM HRESULT (project research PITFALLS.md) — but it doesn't *handle* it here; the audit row just records whatever `statusCode` came back, stale-edit-sequence or not.

---

## Code Examples

### `FakeWriteOp` test double (lives in `QbConnectService.Tests/Fakes/`)
```csharp
// Exercises the WriteOpBase pipeline without a real write op. Knows a fixed qbXML so byte-exactness is testable.
public sealed class FakeWriteOp : WriteOpBase
{
    public const string OpName = "fake_create";
    public const string KnownRequestXml =
        "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\">" +
        "<CustomerAddRq><CustomerAdd><Name>FAKE</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>";

    public FakeWriteOp(QbXmlBuilder b, QbConnectionManager m, QbXmlParser p, QbReportParser rp, QbListExecutor le, AuditLog a, IOptions<SafetyOptions> s)
        : base(b, m, p, rp, le, a, s) { }

    public override string Name => OpName;
    public override string BuildRequest(IReadOnlyDictionary<string, object?> args) => KnownRequestXml;

    // Optional: override DryRunAsync to add a synthetic preflight + a fake mod-style diff, to prove that machinery.
    public override Task<DryRunResult> DryRunAsync(IReadOnlyDictionary<string, object?> args, CancellationToken ct = default)
        => Task.FromResult(new DryRunResult(
            QbXml: KnownRequestXml,
            Summary: "fake_create: would create customer 'FAKE'.",
            PreFlight: new[] { new PreFlightCheck("name-not-empty", true, "name = 'FAKE'") },
            ResolvedReferences: new Dictionary<string, object?> { ["customer"] = "FAKE (no ListID — new)" },
            AllowWrites: /* from base._safety.AllowWrites — expose via a protected getter or just read it here */));
}
```
Register it in tests via `factory.ConfigureServices(s => s.AddSingleton<IReadOp, FakeWriteOp>())` (it's `IReadOp` because that's what `OpRegistry` collects, and it's `is IWriteOp` so the endpoints find it). Or add it to `QbWebAppFactory` behind a flag.

### `AuditLog` canonical-bytes + hash helper (the load-bearing bit)
```csharp
private static (string CanonicalJsonMinusHash, string Hash) ComputeRecord(
    long seq, DateTime tsUtc, AuditRecord rec, string requesterId, string prevHash)
{
    using var ms = new MemoryStream();
    using (var w = new Utf8JsonWriter(ms))
    {
        w.WriteStartObject();
        w.WriteNumber("seq", seq);
        w.WriteString("timestampUtc", tsUtc.ToString("O", CultureInfo.InvariantCulture));   // ...Z
        w.WriteString("op", rec.Op);
        w.WritePropertyName("args"); JsonSerializer.Serialize(w, rec.Args);                  // as-sent; not key-sorted
        w.WriteString("qbXmlRequest", rec.QbXmlRequest);
        w.WriteString("responseStatusCode", rec.ResponseStatusCode);
        w.WriteString("responseStatusSeverity", rec.ResponseStatusSeverity);
        w.WriteString("responseStatusMessage", rec.ResponseStatusMessage);
        w.WriteString("requesterId", requesterId);
        w.WriteString("prevHash", prevHash);
        w.WriteEndObject();
    }
    var canonical = Encoding.UTF8.GetString(ms.ToArray());
    var hash = Convert.ToHexString(SHA256.HashData(ms.ToArray())).ToLowerInvariant();
    return (canonical, hash);
}
// The on-disk line = canonical with `,"hash":"<hash>"` spliced in before the final `}` (or: re-emit with hash as the 11th property).
// VerifyChainAsync: parse the line as JsonObject, lift seq/prevHash/hash/timestampUtc/op/args/..., re-run ComputeRecord(...) on them, compare.
```

### `DryRunEndpointTests` skeleton
```csharp
[Fact]
public async Task dryrun_for_write_op_returns_preview_and_does_not_execute_or_audit()
{
    var auditDir = Path.Combine(Path.GetTempPath(), "qbtest", Guid.NewGuid().ToString());
    await using var factory = new QbWebAppFactory();   // (extend it to take an auditDir + register FakeWriteOp, or use ConfigureServices/UseSetting)
    // factory.UseSetting("Audit:Path", auditDir); factory.UseSetting("Safety:AllowWrites", "false");
    using var client = /* authorized */;
    var resp = await client.PostAsync($"/api/ops/{FakeWriteOp.OpName}/dryrun", new StringContent("{}", Encoding.UTF8, "application/json"));
    Assert.Equal(HttpStatusCode.OK, resp.StatusCode);
    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    var dry = doc.RootElement.GetProperty("dryRun");
    Assert.Equal(FakeWriteOp.KnownRequestXml, dry.GetProperty("qbXml").GetString());
    Assert.False(dry.GetProperty("allowWrites").GetBoolean());
    Assert.False(string.IsNullOrWhiteSpace(dry.GetProperty("summary").GetString()));
    Assert.Empty(factory.Fake.ProcessRequests);                          // nothing sent
    Assert.False(File.Exists(Path.Combine(auditDir, "audit.jsonl")));    // nothing audited
}
```

### `WriteExecuteTests` skeleton (the `AllowWrites=true` happy path)
```csharp
[Fact]
public async Task write_op_with_allowwrites_true_executes_byte_exact_and_writes_exactly_one_audit_row_even_on_qb_error()
{
    var auditDir = ...; await using var factory = WriteFactory(auditDir, allowWrites: true);   // registers FakeWriteOp, Audit:Path=auditDir
    // FakeWriteOp's BuildRequest is CustomerAddRq → script the fake for that:
    factory.Fake.AddResponse("CustomerAddRq",
        "<QBXML><QBXMLMsgsRs><CustomerAddRs statusCode=\"3140\" statusSeverity=\"Error\" statusMessage=\"There is an invalid reference.\"/></QBXMLMsgsRs></QBXML>");
    using var client = /* authorized */;
    var resp = await client.PostAsync($"/api/ops/{FakeWriteOp.OpName}", new StringContent("{}", Encoding.UTF8, "application/json"));
    Assert.Equal(HttpStatusCode.OK, resp.StatusCode);                                   // QB business error is still 200 (API-06)
    Assert.Equal(FakeWriteOp.KnownRequestXml, Assert.Single(factory.Fake.ProcessRequests));   // byte-exact
    var lines = await File.ReadAllLinesAsync(Path.Combine(auditDir, "audit.jsonl"));
    var row = Assert.Single(lines);
    using var rec = JsonDocument.Parse(row);
    Assert.Equal(FakeWriteOp.OpName, rec.RootElement.GetProperty("op").GetString());
    Assert.Equal("3140", rec.RootElement.GetProperty("responseStatusCode").GetString());      // the QB error IS recorded
    Assert.Equal(new string('0', 64), rec.RootElement.GetProperty("prevHash").GetString());   // genesis
}
```

### `WriteSafetyTests` — the three layers, independently
```csharp
[Fact] // layer 1: ops endpoint
public async Task ops_endpoint_403s_a_write_op_when_writes_disabled()
{
    await using var f = WriteFactory(allowWrites: false);
    using var c = /* authorized */;
    var r = await c.PostAsync($"/api/ops/{FakeWriteOp.OpName}", new StringContent("{}", Encoding.UTF8, "application/json"));
    Assert.Equal(HttpStatusCode.Forbidden, r.StatusCode);
    Assert.Empty(f.Fake.ProcessRequests);   // never reached the manager
}

[Fact] // layer 2: raw passthrough (already exists in QbXmlEndpointTests; re-assert here or rely on that)
public async Task qbxml_passthrough_403s_a_write_request_when_writes_disabled() { /* CustomerAddRq body → 403 */ }

[Fact] // layer 3: defensively in the connection manager (unit test, no HTTP)
public async Task connection_manager_throws_QbWriteForbidden_for_a_write_request_when_writes_disabled()
{
    var mgr = new QbConnectionManager(() => new FakeRequestProcessor(),
        Options.Create(new QbOptions { AppId="app", AppName="x", CompanyFilePath=@"C:\co.QBW" }),
        Options.Create(new RequestOptions { TimeoutSeconds=30, BusyWaitSeconds=5 }),
        Options.Create(new SafetyOptions { AllowWrites = false }),
        NullLogger<QbConnectionManager>.Instance);
    await Assert.ThrowsAsync<QbWriteForbiddenException>(() => mgr.ExecuteAsync(
        "<?xml version=\"1.0\"?><?qbxml version=\"16.0\"?><QBXML><QBXMLMsgsRq onError=\"stopOnError\"><CustomerAddRq/></QBXMLMsgsRq></QBXML>"));
    await mgr.DisposeAsync();
    // and the converse: AllowWrites=true → the fake's canned response comes back, no exception.
}
```

---

## State of the Art

| Old approach | Current approach | Impact for Phase 6 |
|---|---|---|
| Reflection-ordered JSON serialization for "canonical" bytes | Explicit field order via `Utf8JsonWriter` | Use `Utf8JsonWriter` with hand-coded order; don't trust `[JsonPropertyOrder]` or class-member order for the hash. (Member order *is* deterministic in .NET 7+, but a refactor that reorders fields would silently invalidate every prior hash — too fragile for an integrity chain.) |
| `using var sha = SHA256.Create(); sha.ComputeHash(...)` | `SHA256.HashData(ReadOnlySpan<byte>)` static | Cleaner; no instance/dispose. |
| Manual `byte[].Select(b => b.ToString("x2"))` join | `Convert.ToHexString(bytes).ToLowerInvariant()` (.NET 8) | One line, no allocation surprises. (.NET 9 added `Convert.ToHexStringLower` — but the project targets `net8.0-windows`, so use the `.ToLowerInvariant()` form.) |
| MVC controllers | Minimal-API route groups | Phase 5 decision; `/dryrun` is a `MapPost` in `OpsEndpoints`, not a controller action. |
| Exception-driven 403 everywhere | 403 produced directly at the endpoint when the condition is statically known; exception only for the *defensive* manager layer | Cleaner control flow; the `ProblemDetails` mapping in `ApiExceptionHandler` is the catch-all for the (rare) manager throw. |

**Deprecated / not applicable:** nothing new is deprecated here. The qbXML write-verb set in `QbWriteDetector` is flagged MEDIUM-confidence and re-pinned in Phase 9 — **don't re-research it in Phase 6** (the project context is explicit on this).

---

## Open Questions

1. **`QbConnectionManager` ctor change vs. test churn.**
   - What we know: the manager is `AddSingleton<QbConnectionManager>()`, so a new `IOptions<SafetyOptions>` ctor param resolves from DI automatically. The only manual-construction site (as of Phase 5) is `QbConnectionManagerTests.CreateManager`.
   - What's unclear: whether the planner wants the param appended last (smaller diff) or inserted near the other `IOptions<>` params (more "natural"). Either works; recommend **appended last** to keep the diff minimal and the existing test's argument list mostly intact.
   - Recommendation: append last; update `CreateManager` in the same task; default the test's `SafetyOptions.AllowWrites = true` so existing tests are unaffected; add the new `false`-case test.

2. **Pre-flight: sync or async; does `WriteOpBase` need the engine for dry-run?**
   - What we know: entity-existence and `mod_*` current-record fetches need a read round-trip through `QbConnectionManager`; name→ID resolution does too. `BuildRequest` itself is pure.
   - What's unclear: how much of the pre-flight helper surface to build *now* (Phase 6 has no real write op to use it).
   - Recommendation: `DryRunAsync` is **async** and returns `Task<DryRunResult>`; `WriteOpBase : ReadOpBase` so it already has `_manager`/`_builder`/`_xmlParser`/`QuerySingleAsync`. Build the *shape* (`DryRunResult`, `PreFlightCheck`, an empty-by-default base `DryRunAsync`) + maybe one `protected static PreFlightCheck DiffFields(...)` helper and one `protected Task<ParsedQbXmlResponse> ResolveCurrentRecordAsync(...)` helper *if cheap*; otherwise leave the helpers as a clearly-marked TODO for Phase 7. Prove the machinery with `FakeWriteOp`.

3. **Does `/api/ops/{op}/dryrun` accept read ops?**
   - What we know: WRITE-02/03 only require the *write-op* dry-run; reads have no side effects so a dry-run of a read is just "show me the qbXML I'd send."
   - What's unclear: whether exposing a read op's would-be request is worth a small `ReadOpBase` refactor (currently each read op builds its `XElement` inside `RunAsync`).
   - Recommendation: **`/dryrun` works for any op.** For a write op → full `DryRunResult`. For a read op → return the would-be request *if* `ReadOpBase` can cheaply expose it (add a `protected virtual string? PreviewRequest(IReadOnlyDictionary<string,object?> args) => null;` on `ReadOpBase` — zero churn for the 12 existing ops, they just don't override it yet; the endpoint returns `{ op, dryRun = { qbxml = previewOrNull, note = "..." } }`). If even that feels like scope creep, **400 on read ops** is acceptable — flag the choice in the plan. Either way, `/dryrun` is **never write-gated** and **never executes anything**.

4. **Refused-write audit row?**
   - What we know: the spec says "every *executed* write appends a record"; the project research says log 403'd attempts too (PITFALLS.md security section) — but as a *log line*, not necessarily in the *chained audit file*.
   - Recommendation: **v1 = audit file is executed-writes-only** (every row = something QuickBooks saw; the chain meaning stays clean). A refused write → `_log.LogWarning("Refused write op {Op}: Safety:AllowWrites is false.", op)`. If the reviewer insists, adding a separate un-chained `audit-refused.jsonl` or a `{ "event": "write-refused", ... }` line is a small follow-up — but recommend against for v1. Flag for the planner.

5. **`AuditLog` crash-safety / partial line on power loss.**
   - What we know: `File.AppendAllTextAsync` writes the whole `line` (including the trailing `\n`) in one call; a crash mid-write could leave a partial last line.
   - Recommendation: out of scope for v1 — `VerifyChainAsync` skips blank/unparseable trailing lines? No — better: it should *report* a malformed last line as a break (so it's visible), and a future task can add "tolerate a torn last line on startup." For Phase 6, just: `VerifyChainAsync` returns `(false, lastSeq+1)` (or similar) if the last line doesn't parse; document it as a known edge. Don't over-engineer fsync/temp-file-rename now.

---

## Suggested Ordered Task Breakdown

Six atomic tasks. Each ends with `dotnet build` (Debug + Release) and `dotnet test` **green with no QuickBooks installed**, and is its own commit (`feat(06-01): ...`, distinct titles — the established Codex pattern). Tasks 1 and 2 are the heavy ones (audit log + `IWriteOp` shape); 3–5 are small; 6 is consolidation + docs.

| # | Task | Builds | Tests | Why this slot |
|---|---|---|---|---|
| **1** | **Audit log + options.** `AuditOptions { Path }` POCO; `Configure<AuditOptions>` from `"Audit"` (the sample config already has `Audit:Path` — just bind it, no `appsettings.sample.json` edit needed unless adding a comment); `AuditRecord` record; `AuditLog` (singleton: append-only `audit.jsonl`, SHA-256 hash chain w/ 64-zero genesis, `Utf8JsonWriter` canonical bytes in fixed order, `SemaphoreSlim(1,1)`, cached `_lastSeq`/`_lastHash`, `AppendAsync` → `seq`, `VerifyChainAsync` → `(ok, firstBrokenSeq?)`, `requesterId` from `AuthOptions.ApiToken`, dir-create-on-first-append, `%TEMP%` fallback if `Path` blank); `AddSingleton<AuditLog>()` in `Program.cs`. | `AuditLogTests`: append N records → file has N lines; each line's `hash` recomputes via the same helper; `prevHash` links; `VerifyChainAsync` → `(true, null)`; tamper line k's `args` (or `responseStatusMessage`) on disk → `VerifyChainAsync` → `(false, k)`; genesis row's `prevHash` is 64 zeros; `requesterId` is `tok-…` (not the raw token); blank `Audit:Path` → falls back without throwing. | Foundational — everything else (the write pipeline) appends to it. No dependency on the op shape. |
| **2** | **`IWriteOp` + `WriteOpBase` + `DryRunResult` + `QbWriteForbiddenException` + `FakeWriteOp`.** `IWriteOp : IReadOp` (`BuildRequest`, `DryRunAsync`); `DryRunResult` + `PreFlightCheck` records; `WriteOpBase : ReadOpBase, IWriteOp` (ctor adds `AuditLog` + `IOptions<SafetyOptions>`; `RunAsync` = `BuildRequest` → re-check `AllowWrites` (throw `QbWriteForbiddenException`) → `_manager.ExecuteAsync` → `_xmlParser.Parse` → `_audit.AppendAsync` → return `{status,rows,auditSeq,rawSpilledTo}`; `DryRunAsync` virtual default = `{ BuildRequest, summary, [], {}, AllowWrites }`; optional `DiffFields`/`ResolveCurrentRecordAsync` helpers or TODO); `QbWriteForbiddenException` in `QbExceptions.cs`; `FakeWriteOp : WriteOpBase` in the **test project** (`Name = "fake_create"`, `BuildRequest` returns a known `CustomerAddRq` qbXML, `DryRunAsync` overridden with a synthetic preflight + resolved-ref). | `WriteOpBaseTests` (against a hand-built `WriteOpBase` or `FakeWriteOp` + a `FakeRequestProcessor`-backed `QbConnectionManager` + a temp-dir `AuditLog`): `BuildRequest` is deterministic & pure; `RunAsync` with `AllowWrites=true` → executes the byte-exact request, parses, appends exactly one audit row (with the response status, even if `statusCode != 0`), returns `auditSeq`; `RunAsync` with `AllowWrites=false` → `QbWriteForbiddenException`, **no** `ExecuteAsync`, **no** audit row; `DryRunAsync` → returns the same `qbXml` as `BuildRequest`, `allowWrites` reflects the option, **no** `ExecuteAsync`, **no** audit row; `ExecuteAsync` throwing (script the fake to error) → exception propagates, **no** audit row. | The op shape — must be right enough that Phase 7's 7 create_* + all mod_* slot in. Depends on #1 (uses `AuditLog`). |
| **3** | **`QbConnectionManager` defensive `AllowWrites` check.** Add `IOptions<SafetyOptions>` ctor param (appended last); in `ExecuteAsync`, before the `_gate`: `if (!_safety.AllowWrites && QbWriteDetector.IsWriteRequest(qbXmlRequest)) throw new QbWriteForbiddenException(...)` (short-circuit when `AllowWrites==true` — don't parse); update `QbConnectionManagerTests.CreateManager` to pass `Options.Create(new SafetyOptions { AllowWrites = true })` (existing tests unaffected). | New `QbConnectionManagerWriteGuardTests` (or add to the existing file): `ExecuteAsync(<CustomerAddRq qbXml>)` + `AllowWrites=false` → `QbWriteForbiddenException`; `AllowWrites=true` → the fake's canned response comes back, call log shows `ProcessRequest`; a *read* qbXML (`CompanyQueryRq`) + `AllowWrites=false` → goes through (not a write verb). Existing `QbConnectionManagerTests` still green. | Layer 3 of the gate. Independent of #2 (uses `QbWriteDetector` + the new exception type from #2 — so #2 before #3, or fold the exception into #3; recommend #2 first since it owns `QbExceptions.cs`). |
| **4** | **Ops-endpoint `AllowWrites` gate (layer 1) + `ApiExceptionHandler` mapping.** In `OpsEndpoints.MapPost("/ops/{op}", ...)`: after `TryGet`, `if (resolved is IWriteOp && !safety.Value.AllowWrites) return Results.Problem(403, "Writes disabled", "...")` — before `RunAsync` (inject `IOptions<SafetyOptions> safety` into the handler lambda); add `QbWriteForbiddenException => (403, "Writes disabled")` to `ApiExceptionHandler`'s switch. | Add to `OpsEndpointTests` (or a new `WriteSafetyTests`): `POST /api/ops/{fakeWriteOp}` with `AllowWrites=false` → 403, `factory.Fake.ProcessRequests` empty (never reached the manager); with `AllowWrites=true` → not 403 (proceeds — covered fully in #6); a *read* op with `AllowWrites=false` → still 200 (the gate only fires for `IWriteOp`). `ApiExceptionHandlerTests`: a `QbWriteForbiddenException` → 403 `ProblemDetails`. | Layer 1 of the gate + the handler arm. Depends on #2 (`IWriteOp`, `FakeWriteOp`) and #3 (the exception). |
| **5** | **`POST /api/ops/{op}/dryrun` endpoint.** In `OpsEndpoints`: `MapPost("/ops/{op}/dryrun", ...)` — `TryGet`→404; reuse `ReadArgsAsync`; `is IWriteOp wop` → `Results.Ok(new { op, dryRun = await wop.DryRunAsync(args, ct) })`; read op → recommend `ReadOpBase.PreviewRequest(args)` returning `null` by default + `Results.Ok(new { op, dryRun = new { qbxml = preview, note = "..." } })` (OR `Results.Problem(400, ...)` — pick one, flag it). **Not** write-gated. `ArgumentException`→400 / `QbException`→503 via the existing handler. | `DryRunEndpointTests`: `POST /api/ops/{fakeWriteOp}/dryrun` with `AllowWrites=false` → 200, `dryRun.qbXml == FakeWriteOp.KnownRequestXml`, `dryRun.summary` non-empty, `dryRun.allowWrites == false`, `dryRun.preflight` present; `factory.Fake.ProcessRequests` empty (nothing executed); audit file doesn't exist (nothing audited); `POST /api/ops/nope/dryrun` → 404; (if read-op preview chosen) `POST /api/ops/company_info/dryrun` → 200 with a `qbxml` or `null`+note; bad args → 400. | The dry-run endpoint. Depends on #2 (`IWriteOp.DryRunAsync`). Independent of #4. |
| **6** | **Consolidation + happy-path + docs.** `WriteExecuteTests`: with `AllowWrites=true`, `POST /api/ops/{fakeWriteOp}` → 200 `{op, result}`, the fake saw exactly the byte-exact `BuildRequest` output as `ProcessRequests[0]`, the audit file gained **exactly one** record with `op=fake_create` and the response `statusCode`/severity/message (script the fake's `CustomerAddRq` response with `statusCode != 0` to prove the row is written even on a QB business error — and the HTTP status is still 200 per API-06); `prevHash` is genesis on row 1; a second write → row 2 with `prevHash == row1.hash`. `WriteSafetyTests` consolidation: the three layers fire independently (one test each). Final sweep: `dotnet build -c Debug && dotnet build -c Release && dotnet test` green; write `06-01-SUMMARY.md` (flag "no real write op by design — Phase 7"); update `ROADMAP.md` (Phase 6 checkbox + Progress table), `REQUIREMENTS.md` (WRITE-01/02/08 → Done), `STATE.md` (completed-phases entry). | (the tests above) | Proves the whole machinery end-to-end and closes the phase. Depends on #1–#5. |

**Compression note:** #3 and #4 could merge (both are "the gate"), and #1+#2 are the natural pair; if the planner wants fewer/larger tasks, #1+#2 (machinery), #3+#4 (gate layers 1 & 3), #5 (dry-run), #6 (consolidation) is a clean 4-task split. Six is the more conservative, more reviewable shape — recommend six.

**Counts to expect:** test count grows by ~15–25 (5 new test files). Zero new NuGet packages. Files added: ~9 production (`AuditOptions`, `AuditRecord`, `AuditLog`, `IWriteOp`, `WriteOpBase`, `DryRunResult`(+`PreFlightCheck`), `QbWriteForbiddenException` (into existing `QbExceptions.cs`)) + ~6 test (`FakeWriteOp`, `AuditLogTests`, `WriteOpBaseTests`, `QbConnectionManagerWriteGuardTests`, `DryRunEndpointTests`, `WriteSafetyTests`/`WriteExecuteTests`). Files edited: `Program.cs` (+2 lines), `OpsEndpoints.cs` (+gate, +`/dryrun`), `ApiExceptionHandler.cs` (+1 arm), `QbConnectionManager.cs` (+ctor param, +check), `QbExceptions.cs` (+exception), `QbConnectionManagerTests.cs` (ctor-arg update), maybe `ReadOpBase.cs` (+`PreviewRequest` default), maybe `QbWebAppFactory.cs` (register `FakeWriteOp` + take an `auditDir`).

---

## Sources

### Primary (HIGH confidence)
- **The repo itself** — read directly: `quickbooks/QbConnectService/src/QbConnectService/Program.cs`, `Api/OpsEndpoints.cs`, `Api/QbXmlEndpoints.cs`, `Api/ApiExceptionHandler.cs`, `appsettings.sample.json`; `QbConnectService.Qb.Com/QbConnectionManager.cs`, `QbWriteDetector.cs`, `QbExceptions.cs`, `SafetyOptions.cs`, `QbXmlBuilder.cs`, `QbXmlOptions.cs`, `QbXmlModels.cs`, `Qb/Ops/{IReadOp,ReadOpBase,ArgReader,OpRegistry}.cs`; `QbConnectService.Tests/{QbWebAppFactory,QbConnectionManagerTests,OpsEndpointTests,QbXmlEndpointTests}.cs`, `Tests/Fakes/FakeRequestProcessor.cs`. — the exact shapes Phase 6 plugs into.
- **Design spec** — `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` §5 (write-safety model: `AllowWrites` default-false → 403 for `create_*`/`mod_*`/raw-Add/Mod/Del/Void; mandatory dry-run; immutable audit log; never auto-retry QB errors), §2 (REST API table incl. `/api/ops/{op}/dryrun`), §6 (`Audit:Path` config; layout incl. `Audit/AuditLog.cs`), §8 (testing strategy).
- **Project research** — `.planning/research/ARCHITECTURE.md` (`AuditLog` placement, write path only, success-or-rejection; `AllowWrites` checked in two places + defensively in the manager; dry-run-as-endpoint-not-flag; "preview is byte-for-byte what gets sent"), `.planning/research/PITFALLS.md` (immutable hash-chained audit log, log 403'd attempts, element-name write detection not substring, UTC timestamps, `0x800404C5` is a qbXML status code), `.planning/research/FEATURES.md` ("what a good dry-run looks like": byte-exact qbXML + resolved-reference echo + plain-English summary + pre-flight validation + zero side effects + endpoint not write-gated; `mod_*` is full-replace + needs a prior read + returns a new `EditSequence`).
- **Roadmap / Requirements / State** — `.planning/ROADMAP.md` (Phase 6 goal "full write-safety machinery landed *before* any write op exists" + 4 success criteria), `.planning/REQUIREMENTS.md` (WRITE-01: default-false, 403 in ops controller + raw passthrough + defensively in the manager; WRITE-02: byte-exact qbXML + resolved-ref echo + English summary + before/after diff for `mod_*` + pre-flight + zero side effects + `/dryrun` not write-gated; WRITE-08: every executed write → append-only hash-chained audit row, dry-run writes nothing), `.planning/STATE.md` (Phases 1–5 inventory; 152/152 tests; the 100/100 quality bar; Phase 7 owns the write-op-dispatch widening).
- **.NET 8 BCL** (training knowledge, cross-checked) — `SHA256.HashData(ReadOnlySpan<byte>)` (static), `Convert.ToHexString` + `.ToLowerInvariant()` (`.NET 9` `Convert.ToHexStringLower` not available on `net8.0`), `Utf8JsonWriter` for deterministic field-ordered JSON, `System.Text.Json` deterministic-but-refactor-fragile member ordering, `File.AppendAllTextAsync`/`File.ReadLinesAsync`, `SemaphoreSlim(1,1)`, `IOptions<T>`/`Configure<T>`, Minimal-API `Results.Problem`/`Results.Ok`, `IExceptionHandler`/`AddProblemDetails`, `WebApplicationFactory<Program>` — all already in use in this solution (Phases 1–5).

### Secondary (MEDIUM confidence)
- WebSearch — "System.Text.Json property ordering / deterministic serialization (.NET 7+)": confirms member-order serialization is deterministic since .NET 7 but that explicit ordering (`[JsonPropertyOrder]` / custom resolver / `Utf8JsonWriter`) is the recommended approach when you need a *stable* order — supports the recommendation to hand-write the canonical audit bytes rather than rely on reflection order. Sources: [code-maze: Property Ordering in C# JSON Serialization](https://code-maze.com/csharp-property-ordering-json-serialization/), [makolyte: Property order with System.Text.Json](https://makolyte.com/system-text-json-control-the-order-that-properties-get-serialized/), [Microsoft Learn: JsonPropertyOrderAttribute](https://learn.microsoft.com/en-us/dotnet/api/system.text.json.serialization.jsonpropertyorderattribute.order?view=net-8.0), [dotnet/runtime#728](https://github.com/dotnet/runtime/issues/728).

### Tertiary (LOW confidence)
- None. Everything in this phase is either repo-internal (HIGH) or standard in-box .NET (HIGH/MEDIUM). The qbXML write-verb set and qbXML element/enum names are explicitly **out of scope** for Phase 6 (re-pinned in Phase 9) — not researched here.

---

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — zero new dependencies; all in-box .NET 8 + the existing solution's patterns.
- Architecture (`IWriteOp` shape, `WriteOpBase` pipeline, audit-log design, three-layer gate, `/dryrun` endpoint): **HIGH** — driven directly by the design spec §5, the project research's ARCHITECTURE/FEATURES/PITFALLS, the Phase-1–5 code, and the explicit Phase-6 scope in the orchestrator brief; the few real choices (folder/namespace, ctor-param vs guard service, refused-write logging, read-op `/dryrun`) are called out as Open Questions with recommendations.
- Pitfalls: **HIGH** — they're consequences of the codebase's existing shape (ctor churn, canonical-bytes drift, audit-after-execute ordering, dir-create, "no real write op looks unfinished"), not speculative.

**Research date:** 2026-05-11
**Valid until:** ~30 days (stable — no fast-moving deps; the only thing that could shift is the Phase-5 code surface if it's edited before Phase 6 lands, but that's not expected).
