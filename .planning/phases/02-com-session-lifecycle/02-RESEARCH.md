# Phase 2: COM Session Lifecycle - Research

**Researched:** 2026-05-11
**Domain:** STA-pinned in-process COM lifecycle management (`QBXMLRP2.RequestProcessor`), single-threaded session serialization, dead-ticket reconnect, HRESULT translation — in C#/.NET 8 (`net8.0-windows`, x86), behind the Phase-1 `IRequestProcessor` seam.
**Confidence:** HIGH — the COM lifecycle, STA-thread-pump pattern, HRESULT family, and `IAsyncDisposable`/DI mechanics are all well-trodden and cross-checked against project research + Microsoft docs. The only LOW-confidence area is exact behaviour against the *real* QBXMLRP2 type library, which is deliberately Phase 9's problem (placeholder GUIDs in `QBXMLRP2Lib.cs` mean Phase 2's `RealRequestProcessor` is "written correctly against the declared shape" but cannot actually activate COM until Phase 9 — that's expected and called out below).

> This phase is executed by **Codex CLI** from the PLAN.md, then reviewed by Claude. Be concrete: the PLAN should hand Codex class designs, method signatures, threading code, and a green-the-whole-way test order. Phase 2 needs **no QuickBooks** — everything is tested against `FakeRequestProcessor`.

---

## Summary

Phase 2 builds the **COM session lifecycle layer** for the QuickBooks integration: `QbConnectionManager` (a long-lived singleton owning the `OpenConnection → BeginSession → ProcessRequest → EndSession → CloseConnection` lifecycle), a **dedicated STA worker thread** that all `IRequestProcessor` calls run on, a `SemaphoreSlim(1,1)` serialization gate, a **watchdog timeout** that abandons a wedged `ProcessRequest`, a **dead-ticket reconnect** that *rebuilds the COM object* and retries exactly once, a `QbErrors` static map from the `0x8004xxxx` HRESULT family (+ `REGDB_E_CLASSNOTREG` / `RequestProcessor2`-cast failures) to `(code, message, remediationHint)`, the real `RealRequestProcessor` adapter over the Phase-1 `QBXMLRP2Lib.cs` placeholder interop, and the DI wiring in `Program.cs`.

The architecture is **already decided** by `.planning/research/ARCHITECTURE.md` §"Connection lifecycle" + `PITFALLS.md` #5/#6/#12 + `STACK.md` ("Polly v8 for the one retry, STA-thread + SemaphoreSlim(1,1)"). The job here is to turn those decisions into code:
- **One STA thread owns everything COM.** `QbConnectionManager` owns the thread; `RealRequestProcessor` is "dumb" — it just forwards `IRequestProcessor` calls to the COM RCW and assumes it's being called on the right thread. The thread is a `Thread { ApartmentState = STA, IsBackground = true }` running a pump over a `BlockingCollection<Action>` (or a single-consumer `Channel`). Callers marshal work onto it via `TaskCompletionSource<T>`.
- **Serialization gate = `SemaphoreSlim(1,1)`**, taken by `QbConnectionManager.Execute(...)` *before* it dispatches to the STA thread; a concurrent caller `WaitAsync(busyTimeout, ct)` and on timeout gets a distinguishable **"busy"** outcome (a `QbBusyException`). The 409 HTTP mapping is Phase 5; Phase 2 just throws/returns the distinguishable outcome.
- **Watchdog**: a `CancellationToken` *cannot* cancel a blocking COM call. So the watchdog is a guard timeout on the *wait for the STA result* — when it fires, the manager (a) returns a clear `QbTimeoutException`, (b) marks the session **poisoned**, (c) on the next `Execute` rebuilds the COM object before retrying. The wedged STA thread call may still be in-flight; the rebuild path discards the old `RealRequestProcessor`/RCW and spins up a *new* one on a *new* STA thread (the old thread is abandoned — acceptable; it's a background thread).
- **Dead-ticket reconnect**: catch the dead-ticket HRESULT family on `ProcessRequest` (and on `BeginSession`), tear down (`EndSession` best-effort, `CloseConnection` best-effort, `Marshal.FinalReleaseComObject` the old RCW, `IDisposable.Dispose` the old `RealRequestProcessor`), build a *new* `RealRequestProcessor`, `OpenConnection` + `BeginSession` again, retry the request **exactly once**. Second failure → surface the QuickBooks error verbatim (no second retry). **Use a hand-rolled single retry, not Polly** — see Q2.
- **`QbErrors`**: a `static IReadOnlyDictionary<int, QbError>` keyed by HRESULT, where `QbError` is a `record (int Code, string Name, string Message, string RemediationHint)`. The full table is in `PITFALLS.md` Pitfall 4 — reproduce it verbatim. Detection: `COMException.HResult` (and `.ErrorCode` — same value as a `uint`); `InvalidCastException` for the `RequestProcessor2` cast; a generic fallback `QbError` for unknown codes.

**Primary recommendation:** `QbConnectionManager` owns the single STA thread + the `SemaphoreSlim(1,1)`; `RealRequestProcessor` is a thin forwarder; reconnect & watchdog both funnel into one "tear down + rebuild the COM object + re-open" routine; one hand-rolled retry; `QbErrors` is a static dictionary lifted straight from `PITFALLS.md`; register `QbConnectionManager` as a singleton `IAsyncDisposable`, lazy-connect on first `Execute` (never on startup), register `RealRequestProcessor` only when `OperatingSystem.IsWindows() && !env.IsEnvironment("Testing")`.

---

## Standard Stack

### Core (already in the project — no new packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `System.Threading` (`Thread`, `SemaphoreSlim`) — in-box | net8.0 | STA worker thread + serialization gate | `Thread` is the *only* way to get an STA apartment in .NET (the thread pool is MTA; `Task.Run` cannot be STA). `SemaphoreSlim(1,1)` is the standard async-friendly mutex. |
| `System.Collections.Concurrent` (`BlockingCollection<Action>`) — in-box | net8.0 | The work-queue the STA thread pumps | Standard producer/consumer; `GetConsumingEnumerable()` blocks until work arrives. (`Channel<T>` is the async-first alternative but `BlockingCollection` is fine here since the *consumer* is a dedicated blocking thread and the COM calls are synchronous.) |
| `System.Threading.Tasks` (`TaskCompletionSource<T>`) — in-box | net8.0 | Marshal a result/exception back from the STA thread to the async caller | Standard "run this on another thread, await the result" bridge. Use `TaskCreationOptions.RunContinuationsAsynchronously` to avoid running continuations on the STA thread. |
| `System.Runtime.InteropServices` (`Marshal.FinalReleaseComObject`, `COMException`) — in-box | net8.0 | RCW teardown, HRESULT extraction | `FinalReleaseComObject` is the documented way to deterministically release an RCW so `QBW.exe` can exit (PITFALLS.md #12). `COMException.HResult` carries the `0x8004xxxx` code. |
| `System.Runtime.Versioning` (`[SupportedOSPlatform("windows")]`) — in-box | net8.0 | Annotate `RealRequestProcessor` | Already present on the Phase-1 stub; keep it. |
| `Microsoft.Extensions.Options` (`IOptions<T>`, `ValidateOnStart`) — in-box w/ host | 8.0.x | Bind a `QbOptions` POCO from `appsettings.json` | Standard config binding; lets `QbConnectionManager` take `IOptions<QbOptions>` in its ctor. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Polly` | 8.x (`ResiliencePipeline`) | (NOT recommended for Phase 2's retry — see Q2) | `STACK.md` lists Polly v8 "for the one retry", but for a *single* reconnect-and-retry-once around a stateful COM rebuild, a hand-rolled `try/catch` is clearer and the retry needs to do bespoke teardown/rebuild between attempts (not a simple "call again"). **Do not add the Polly package in Phase 2.** If a future phase wants Polly for HTTP retries (`qb_client.py` is Python; the .NET side has no HTTP-out), revisit then. Flag this as a deliberate deviation from `STACK.md` for the planner. |
| `Microsoft.Extensions.Logging` (`ILogger<QbConnectionManager>`) — in-box | 8.0.x | Log lifecycle transitions, reconnect attempts, the mapped HRESULT on error, point to `qbsdklog.txt` | The host already has logging wired (Phase 1). Log at Information for connect/disconnect/reconnect; Warning for a poisoned session / busy-timeout; Error for a surfaced HRESULT (include the `QbErrors` mapped text + remediation). |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Thread`+`BlockingCollection<Action>` pump | `StaTaskScheduler` (ParallelExtensionsExtras) / `Dispatcher` (WPF) | `StaTaskScheduler` is a NuGet/snippet dependency for what's ~40 lines; `Dispatcher` drags in WPF assemblies. Hand-roll the pump — it's small, dependency-free, and you control the lifetime precisely (needed for the "abandon the thread on watchdog timeout, spin a new one" rebuild). |
| `BlockingCollection<Action>` | `System.Threading.Channels.Channel<Action>` (unbounded, single-reader) | Channel is the modern async-first primitive, but the STA consumer is a dedicated *blocking* thread, so `BlockingCollection.GetConsumingEnumerable()` is the natural fit and slightly less ceremony. Either is acceptable; recommend `BlockingCollection` for the consumer-is-a-blocking-thread case. |
| Hand-rolled single retry | `Polly` v8 `ResiliencePipeline` with `MaxRetryAttempts = 1` | Polly's retry just re-invokes the same delegate; here the second attempt must run a *different* code path (teardown + rebuild + re-open before the retried `ProcessRequest`). You'd end up wrapping the rebuild inside the delegate anyway. Hand-rolled is clearer and one fewer dependency. |
| `Marshal.FinalReleaseComObject` | `Marshal.ReleaseComObject` (decrements by 1) | `FinalReleaseComObject` sets the RCW ref count to 0 in one call — correct for "we own this RCW exclusively and we're done with it." Use it. (Both are obsolete-warning-free on .NET 8 *for the .NET Framework-style use*; they're only marked obsolete in some analyzer configs — verify the build is clean; if a warning appears, `#pragma warning disable` it with a comment, since there is no replacement for deterministic RCW release.) |

**Installation:** None. Phase 2 adds **zero NuGet packages** — everything is in-box or already referenced.

---

## Architecture Patterns

### Recommended file layout (additions to Phase 1's tree)

```
quickbooks/QbConnectService/src/
├── QbConnectService/                       # host
│   ├── Program.cs                          # MODIFIED — DI wiring (Q5)
│   ├── appsettings.sample.json             # MODIFIED — new Qb:* / Request:* keys (Q6)
│   └── (no new files here unless QbOptions lives here — see note)
├── QbConnectService.Qb.Com/                # adapter project (the ONLY one referencing the interop)
│   ├── Interop/QBXMLRP2Lib.cs              # UNCHANGED — Phase-1 placeholder stub
│   ├── Qb/IRequestProcessor.cs             # UNCHANGED — the seam
│   ├── RealRequestProcessor.cs             # REWRITTEN — real STA-assuming COM forwarder (Q4)
│   ├── QbConnectionManager.cs              # NEW — the singleton lifecycle manager (Q1)
│   ├── QbErrors.cs                         # NEW — static HRESULT map (Q3)
│   ├── QbOptions.cs                        # NEW — config POCO (Q6)  [see note on placement]
│   ├── QbConnectionState.cs                # NEW — the state enum (Q1)
│   ├── QbBusyException.cs                  # NEW — distinguishable "busy/timeout" outcome (Q1)
│   ├── QbTimeoutException.cs               # NEW — watchdog-timeout outcome (Q1)
│   └── QbException.cs                      # NEW — wraps a surfaced HRESULT + its QbError (Q1/Q3)
└── QbConnectService.Tests/
    ├── Fakes/FakeRequestProcessor.cs       # MODIFIED — small extensions (Q7)
    ├── QbConnectionManagerTests.cs         # NEW — the lifecycle/serialization/reconnect/watchdog matrix (Q7)
    ├── QbErrorsTests.cs                     # NEW — code → message mapping unit tests (Q7)
    └── RealRequestProcessorSmokeTests.cs   # NEW — "activation failure → mapped error, not raw COMException" (Q4/Q7)
```

**Placement note (`QbOptions` / the exception types):** they can live in either `QbConnectService.Qb.Com` or the host. **Recommend `QbConnectService.Qb.Com`** — `QbConnectionManager` lives there (it's COM-adjacent, behind the seam), takes `IOptions<QbOptions>` in its ctor, and throws `QbBusyException`/`QbTimeoutException`/`QbException`. The host references `Qb.Com` already (Phase 1), and the test project references the host (so it gets `Qb.Com` transitively). Keeping everything in one project avoids a new project reference and matches `ARCHITECTURE.md`'s "`Qb/` holds the entire COM-adjacent surface." `QbConnectionManager` itself does **not** reference `QBXMLRP2Lib.cs` — it only touches `IRequestProcessor` — so it stays testable against `FakeRequestProcessor`. Only `RealRequestProcessor` imports the interop.

> Note: Phase 1 already put `IRequestProcessor.cs` in `QbConnectService.Qb.Com` (namespace `QbConnectService.Qb`) for exactly this reason. Keep the `QbConnectService.Qb` namespace for the new types so consumers don't need extra `using`s.

### Pattern 1: STA worker thread + work-queue pump (owned by `QbConnectionManager`)

**What:** A single long-lived background thread set to `ApartmentState.STA`. It loops over a `BlockingCollection<Action>`; each `Action` is "run this COM call and complete its `TaskCompletionSource`." Callers (always inside the `SemaphoreSlim`) enqueue work and `await` the TCS.

**When:** Always, for *every* `IRequestProcessor` call (`OpenConnection`, `BeginSession`, `ProcessRequest`, `GetSupportedQbXmlVersions`, `EndSession`, `CloseConnection`, `SetUnattendedModePreference`) — and the `new RealRequestProcessor()` construction itself, since the RCW must be created on the same STA thread it's used from (PITFALLS.md #5).

**Sketch (concrete C# — give this to Codex as the reference):**
```csharp
// QbConnectService.Qb.Com/StaThread.cs  (internal helper inside QbConnectionManager, or its own file)
internal sealed class StaThread : IDisposable
{
    private readonly BlockingCollection<Action> _queue = new();
    private readonly Thread _thread;

    public StaThread(string name)
    {
        _thread = new Thread(Pump) { IsBackground = true, Name = name };
        _thread.SetApartmentState(ApartmentState.STA);   // must be before Start()
        _thread.Start();
    }

    private void Pump()
    {
        foreach (var work in _queue.GetConsumingEnumerable())
        {
            try { work(); } catch { /* the work item already captured the exception into its TCS */ }
        }
    }

    public Task<T> Run<T>(Func<T> func, CancellationToken ct = default)
    {
        var tcs = new TaskCompletionSource<T>(TaskCreationOptions.RunContinuationsAsynchronously);
        // ct here is best-effort: it can cancel the *wait*, not the in-flight COM call.
        ct.Register(() => tcs.TrySetCanceled(ct));
        _queue.Add(() =>
        {
            try { tcs.TrySetResult(func()); }
            catch (Exception ex) { tcs.TrySetException(ex); }
        });
        return tcs.Task;
    }

    public Task Run(Action action, CancellationToken ct = default)
        => Run<object?>(() => { action(); return null; }, ct);

    public void Dispose() => _queue.CompleteAdding();   // pump exits; thread ends (it's a background thread anyway)
}
```
- **Watchdog**: the caller does `await staThread.Run(() => rp.ProcessRequest(ticket, xml)).WaitAsync(timeout)` (`Task.WaitAsync(TimeSpan)` is in-box on .NET 8). On `TimeoutException` from `WaitAsync`, the manager throws `QbTimeoutException`, marks itself poisoned, and **does not** wait for the still-running work item — it will rebuild on next `Execute` (a fresh `StaThread` + fresh `RealRequestProcessor`; the wedged thread is abandoned, which is fine for a background thread, and `QBW.exe` may linger — that's the price of a wedged COM call and is documented in PITFALLS.md #12 as a known monitoring item).
- **Important**: never `await` continuations on the STA thread (hence `RunContinuationsAsynchronously`), or you'll deadlock the pump.

### Pattern 2: `SemaphoreSlim(1,1)` serialization gate + lazy connect

**What:** `QbConnectionManager.Execute(string qbXmlRequest)` does:
```
await _gate.WaitAsync(_busyTimeout, ct)   // bounded — on false → throw QbBusyException
try {
    EnsureConnected();                     // lazy: if state == Disconnected (or Poisoned), build RealRequestProcessor on the STA thread, OpenConnection, BeginSession
    return await ProcessWithRetry(qbXmlRequest);   // the one-retry-on-dead-ticket logic (Pattern 3)
}
finally { _gate.Release(); }
```
- `WaitAsync(TimeSpan, CancellationToken)` returning `false` is the **busy** signal — translate to `throw new QbBusyException(...)`. (Phase 5 turns that into HTTP 409.)
- `GetSupportedQbXmlVersions()` and the health-probe go through the same gate (they're COM calls too).
- **Lazy connect**: never connect in the ctor or in `StartAsync` — the host must boot even if QuickBooks isn't there. First `Execute` (or first health-probe-that-asks-to-connect) triggers `EnsureConnected`. If `OpenConnection`/`BeginSession` throw, surface the mapped error and stay `Disconnected` so the next call retries from scratch.

### Pattern 3: Tear-down + rebuild + retry-exactly-once

**What:** `ProcessWithRetry`:
```csharp
private async Task<string> ProcessWithRetry(string qbXmlRequest)
{
    try
    {
        return await _sta.Run(() => _rp!.ProcessRequest(_ticket!, qbXmlRequest)).WaitAsync(_requestTimeout);
    }
    catch (TimeoutException) { Poison(); throw new QbTimeoutException(_requestTimeout); }
    catch (COMException ex) when (QbErrors.IsDeadTicket(ex.HResult))
    {
        // attempt #2: rebuild the COM object (NOT just BeginSession), re-open, retry once
        await RebuildConnectionAsync();
        try
        {
            return await _sta.Run(() => _rp!.ProcessRequest(_ticket!, qbXmlRequest)).WaitAsync(_requestTimeout);
        }
        catch (TimeoutException) { Poison(); throw new QbTimeoutException(_requestTimeout); }
        catch (COMException ex2) { throw QbException.From(ex2); }   // verbatim; NO 3rd attempt
        // any non-COMException on the retry also bubbles
    }
    catch (COMException ex) { throw QbException.From(ex); }   // non-dead-ticket COM error → surface verbatim, no retry
}
```
- `RebuildConnectionAsync()` = on the STA thread: best-effort `EndSession(_ticket)` (swallow), best-effort `CloseConnection()` (swallow), `Marshal.FinalReleaseComObject(_rp.ComObject)` *or* `_rp.Dispose()` (which does the FinalRelease internally — recommend `Dispose()` owns it), then `_rp = new RealRequestProcessor()`, `_rp.SetUnattendedModePreference(true)` (per `ARCHITECTURE.md` — only the real impl does anything; harmless), `_rp.OpenConnection(appId, appName, LocalQBD)`, `_ticket = _rp.BeginSession(companyFilePath, DoNotCare)`. If the watchdog poisoned the session instead, `EnsureConnected` does the *same* rebuild on the next `Execute` — share one private `RebuildConnectionAsync`/`ConnectAsync` routine.
- **The dead-ticket set** (which HRESULTs trigger the rebuild-and-retry) — see Q2 below. Be conservative: only the genuine "session/ticket dropped" codes. Everything else surfaces verbatim on the first failure.

### Pattern 4: `RealRequestProcessor` as a dumb forwarder (no thread management of its own)

**What:** `RealRequestProcessor` does **not** own a thread. It assumes every method is called on the STA thread that constructed it (`QbConnectionManager` guarantees this). Its ctor does `_rp = (IRequestProcessor2)new RequestProcessor2();` (the Phase-1 placeholder types). Each method forwards: `OpenConnection(...) → _rp.OpenConnection2(appId, appName, (int)connectionType)`, `BeginSession(...) → _rp.BeginSession(companyFilePath, (int)openMode)`, `ProcessRequest(...) → _rp.ProcessRequest(ticket, xml)`, `GetSupportedQbXmlVersions(...) → _rp.QBXMLVersionsForSession(ticket)`, `EndSession(...) → _rp.EndSession(ticket)`, `CloseConnection() → _rp.CloseConnection()`, `SetUnattendedModePreference(b) → _rp.AuthPreferences().PutUnattendedModePref(b)`. `Dispose()` does `if (_rp is not null) Marshal.FinalReleaseComObject(_rp); _rp = null;`. `[SupportedOSPlatform("windows")]` on the class. **Wrap the ctor's COM activation** so a `REGDB_E_CLASSNOTREG` or the `RequestProcessor2`-cast `InvalidCastException` becomes a `QbException` carrying the `QbErrors` mapping — that's the one thing the Phase-2 smoke test can assert (Q4).

> **Why the manager owns the thread, not the adapter:** keeps `RealRequestProcessor` trivially correct (it's just COM-forwarding), keeps the single-STA-thread invariant in *one* place, and lets the manager rebuild the adapter (and even a fresh STA thread) without the adapter knowing. This is the recommendation in `ARCHITECTURE.md` and `STACK.md`.

### Anti-Patterns to Avoid
- **Touching the RCW from any thread other than the STA pump.** Includes `Dispose`/`FinalReleaseComObject` — that must also run on the STA thread (enqueue it). PITFALLS.md #5.
- **Re-`BeginSession` on a dead RCW.** The reconnect must `new RequestProcessor2()` — the old COM proxy may be dead. PITFALLS.md #6, ROADMAP "reconnect rebuilds COM."
- **More than one retry.** Exactly one. Second failure surfaces verbatim. SESS-03.
- **Trying to cancel a blocking COM call with a `CancellationToken`.** It can't. The watchdog cancels the *wait* and poisons the session. PITFALLS.md #6 ("watchdog timeout tears the session down").
- **Connecting in the ctor / `StartAsync`.** The host must start even when QuickBooks isn't reachable. Lazy-connect on first use only.
- **`SingleUser` mode anywhere.** `OpenMode = DoNotCare`, `connectionType = LocalQBD`. SESS-01. (`QbFileMode.SingleUser` exists in the enum only for completeness — never pass it.)
- **Letting `appsettings.sample.json` carry machine-specifics.** It already has placeholders; only *add* the new keys with safe defaults.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Getting an STA apartment | A custom apartment-init hack | `new Thread(...).SetApartmentState(ApartmentState.STA)` *before* `Start()` (or `[STAThread]` on the entry method) | The only supported way; the thread pool / `Task.Run` are MTA-only. |
| Async mutex / serialization | A `lock` + `Monitor.Wait` loop, or a hand-rolled queue | `SemaphoreSlim(1,1)` with `WaitAsync(timeout, ct)` | Standard, async-friendly, gives the bounded-wait "busy" signal for free. |
| Producer/consumer queue for the pump | A `Queue<T>` + `ManualResetEvent` dance | `BlockingCollection<Action>` + `GetConsumingEnumerable()` (or `Channel<T>`) | Battle-tested; correct blocking/wakeup semantics. |
| Run-on-other-thread + await result | Polling a shared field; `Thread.Join` | `TaskCompletionSource<T>` (with `RunContinuationsAsynchronously`) | The canonical thread→async bridge; avoids continuation-on-STA-thread deadlocks. |
| Per-call timeout on an awaitable | A `Task.WhenAny(task, Task.Delay(...))` + manual cleanup | `task.WaitAsync(TimeSpan)` / `WaitAsync(TimeSpan, CancellationToken)` | In-box since .NET 6; throws `TimeoutException`; less to get wrong. |
| Deterministic RCW release | `GC.Collect()` + finalizers | `Marshal.FinalReleaseComObject(rcw)` on the STA thread, in `finally` | Documented mechanism so `QBW.exe` can exit; finalizer timing is non-deterministic and runs on the wrong thread. PITFALLS.md #12. |
| HRESULT → human text | Inlined `switch` scattered through the manager | A single `QbErrors` static dictionary `int → QbError record` | One source of truth; unit-testable per code (SESS-04 demands a test per code); reused by Phase 5's `/api/health`. |
| Config binding + validation | `IConfiguration["Qb:..."]` string-fishing | `services.Configure<QbOptions>(config.GetSection("Qb"))` + `.ValidateOnStart()`; ctor takes `IOptions<QbOptions>` | Strongly-typed, fail-fast, testable; the host already does this pattern. |

**Key insight:** The hard parts of this phase are *concurrency correctness* (one STA thread, one in-flight call, no continuation-on-pump deadlocks) and *COM lifetime* (rebuild-don't-revive, FinalRelease-on-the-right-thread). The .NET BCL has the exact primitives; the bug surface is in *composing* them, not in the primitives.

---

## Common Pitfalls

(Phase-specific subset of `.planning/research/PITFALLS.md` — those are the load-bearing ones for Phase 2. Reproduced with the Phase-2 angle.)

### Pitfall 1: COM call from a thread-pool / MTA thread → intermittent `RPC_E_*` / `InvalidComObjectException`
**What goes wrong:** Works for the first few calls, then degrades — apartment mismatch corrupts the COM proxy.
**Why:** ASP.NET Core handlers run MTA; the RCW must be created and used on one STA thread for its whole life.
**How to avoid:** `QbConnectionManager` owns one STA `Thread`; *all* `IRequestProcessor` calls (and the `new RealRequestProcessor()` construction) go through its pump. `RealRequestProcessor` never spawns a thread. Verify in tests: assert (via the fake's call log or a thread-id capture) that calls happen on a single, non-pool thread (the fake can record `Thread.CurrentThread.ManagedThreadId` per call).
**Warning signs:** flaky behaviour only under concurrent requests; `BadImageFormatException` (that's the *bitness* problem — already handled, x86 in Phase 1).

### Pitfall 2: Eternal session / concurrency → stale ticket (`0x8004040D`) and garbled responses
**What goes wrong:** Held session goes stale after QuickBooks restarts; or two `ProcessRequest`s overlap and corrupt the session.
**How to avoid:** `SemaphoreSlim(1,1)` — exactly one round-trip in flight; concurrent caller bounded-waits then `QbBusyException`. On *any* dead-ticket COM error: rebuild the COM object + re-open + retry **once**. Watchdog timeout per call. (SESS-02, SESS-03, SESS-05.)
**Warning signs:** `0x8004040D` after idle; queue depth growing.

### Pitfall 3: Reconnect that re-`BeginSession`s on a dead RCW
**What goes wrong:** The retry "succeeds" at calling `BeginSession` on a corpse, then fails again or hangs.
**How to avoid:** Reconnect = `EndSession`(best-effort) → `CloseConnection`(best-effort) → `Dispose`/`FinalReleaseComObject` the old `RealRequestProcessor` → `new RealRequestProcessor()` → `OpenConnection` → `BeginSession`. **Rebuild the object.** (ROADMAP success-criterion #3; SESS-03.)
**Verification:** the `FakeRequestProcessor`-based test: enqueue a dead-ticket `COMException` for the first `ProcessRequest`, then assert the call log shows `[..., ProcessRequest, EndSession, CloseConnection, Dispose, OpenConnection, BeginSession, ProcessRequest]` and the second `ProcessRequest` returns the canned response. (Needs the fake to be re-usable as a "new" instance after `Dispose`, OR — cleaner — the manager takes an `IRequestProcessor` *factory* (`Func<IRequestProcessor>`) so the test supplies a factory that hands out a fresh fake each time. **Recommend the factory approach** — see Q4/Q7.)

### Pitfall 4: Opaque HRESULTs → operators can't self-diagnose
**What goes wrong:** API/health surface raw `0x80040408` with no text.
**How to avoid:** `QbErrors` complete map (table below), unit-tested per code; manager attaches the mapped `(Message, RemediationHint)` to every `QbException` it throws. (SESS-04; the `/api/health` surfacing is Phase 5 — Phase 2 just produces the mapping and uses it in thrown exceptions.)

### Pitfall 5: Watchdog can't cancel a blocking COM call
**What goes wrong:** A `ProcessRequest` stuck behind a modal dialog (`0x80040414`) wedges the queue forever.
**How to avoid:** Timeout the *wait* (`Task.WaitAsync(TimeSpan)`), not the COM call; on timeout → `QbTimeoutException`, mark poisoned, rebuild (fresh STA thread + fresh adapter) on next `Execute`. Accept that the abandoned thread/`QBW.exe` may linger (documented). (SESS-05.)
**Verification:** the fake can be told to block `ProcessRequest` (e.g. a `ManualResetEventSlim` the test never sets, or a `Func<string,string>` hook that `Thread.Sleep`s longer than the timeout); assert `QbTimeoutException` is thrown within ~the timeout, and that the *next* `Execute` triggers a fresh connect (new fake from the factory, fresh `OpenConnection`/`BeginSession` in the log).

### Pitfall 6: `qbsdklog.txt` ignored
**What goes wrong:** Most COM failures are explained in the SDK's own log; nobody knows it exists.
**How to avoid:** On any surfaced COM error, the manager logs (via `ILogger`) a line pointing at `qbsdklog.txt` (path is `%ProgramData%\Intuit\QuickBooks\` for `svc_qbsdk`, but exact path is environment-specific — just mention it). README detail is Phase 9; Phase 2 just emits the hint in the log message.

### Pitfall 7 (Phase-2-specific): the placeholder GUIDs make `RealRequestProcessor` un-activatable until Phase 9
**What goes wrong:** Anyone running `RealRequestProcessor` on a real box before Phase 9 gets `REGDB_E_CLASSNOTREG` (the placeholder `Guid("...E003")` for `RequestProcessor2` isn't a registered CLSID).
**Why it's OK:** Phase 2's job is to write the adapter *correctly against the declared interface shape*; real activation is Phase 9 (regenerate the interop DLL via `tlbimp` on the QuickBooks host, swap GUIDs, delete the stub). Phase 2's smoke test should therefore assert the *failure mode* — "COM activation throws a `QbException` with the `REGDB_E_CLASSNOTREG` mapping, not a bare `COMException`" — which is true *today* with the placeholder GUIDs (activation will fail because the CLSID isn't registered) and *will still be true* in Phase 9 if the SDK isn't installed. Don't try to assert a successful activation. **Flag in the plan:** the smoke test is "wrap-the-activation-failure-usefully", nothing more.

---

## Code Examples

### `QbErrors` — the static map (lift verbatim from PITFALLS.md Pitfall 4)

```csharp
// QbConnectService.Qb.Com/QbErrors.cs
namespace QbConnectService.Qb;

/// <param name="Code">HRESULT (e.g. unchecked((int)0x80040401))</param>
public sealed record QbError(int Code, string Name, string Message, string RemediationHint);

public static class QbErrors
{
    // unchecked((int)0x8004xxxx) so the literal fits an int and matches COMException.HResult
    private static readonly IReadOnlyDictionary<int, QbError> Map = new Dictionary<int, QbError>
    {
        [unchecked((int)0x80040401)] = new(unchecked((int)0x80040401), "QB_ACCESS_FAILED",
            "Could not access QuickBooks (connection attempt failed; the QuickBooks install may be incomplete or broken).",
            "Check QuickBooks is installed/repaired under the service account; check the session-0 setup; see qbsdklog.txt."),
        [unchecked((int)0x80040402)] = new(unchecked((int)0x80040402), "QB_UNEXPECTED_ERROR",
            "Unexpected QuickBooks SDK error — see qbsdklog.txt for details.",
            "Pull qbsdklog.txt from the QuickBooks host."),
        [unchecked((int)0x80040408)] = new(unchecked((int)0x80040408), "QB_COULD_NOT_START",
            "Could not start QuickBooks (launch failed; install incomplete or session-0 instability).",
            "Pre-launch QuickBooks under the service account; verify the scheduled-task launch path; see qbsdklog.txt."),
        [unchecked((int)0x8004040A)] = new(unchecked((int)0x8004040A), "QB_DIFFERENT_FILE_OPEN",
            "A different company file is already open on this machine.",
            "Close the other company file, or fix Qb:CompanyFilePath."),
        [unchecked((int)0x8004040D)] = new(unchecked((int)0x8004040D), "QB_INVALID_TICKET",
            "Invalid or expired session ticket (the session was dropped, e.g. QuickBooks restarted).",
            "Transient — the service rebuilds the connection and retries once automatically."),
        [unchecked((int)0x80040410)] = new(unchecked((int)0x80040410), "QB_MODE_MISMATCH",
            "The company file is open in a mode other than the one specified.",
            "A human has the file open single-user; switch the file to multi-user (hosted) mode."),
        [unchecked((int)0x80040414)] = new(unchecked((int)0x80040414), "QB_MODAL_DIALOG",
            "A modal dialog is showing in the QuickBooks UI, blocking the SDK.",
            "Dismiss the dialog on the QuickBooks host and find what is popping it (often an update prompt)."),
        [unchecked((int)0x80040416)] = new(unchecked((int)0x80040416), "QB_NO_FILE_SPECIFIED",
            "QuickBooks is not running and BeginSession did not receive a company-file path.",
            "Set Qb:CompanyFilePath to the full path of the .QBW (UNC if on a share)."),
        [unchecked((int)0x8004041A)] = new(unchecked((int)0x8004041A), "QB_NO_PERMISSION",
            "This application does not have permission to access this company file.",
            "Re-run register-integrated-app.md (Admin, single-user mode)."),
        [unchecked((int)0x80040420)] = new(unchecked((int)0x80040420), "QB_ACCESS_DENIED",
            "The QuickBooks user has denied access (integrated app not authorized / revoked / waiting for permission).",
            "Re-run register-integrated-app.md; check the integrated-apps list in QuickBooks."),
        [unchecked((int)0x80040421)] = new(unchecked((int)0x80040421), "QB_PASSTHROUGH",
            "Message passed through from QuickBooks.",
            "Read the message text; usually a QuickBooks-side condition."),
        [unchecked((int)0x80040422)] = new(unchecked((int)0x80040422), "QB_REQUIRES_SINGLE_USER",
            "This application requires single-user file access mode.",
            "Another app/user shares the file; coordinate access."),
        // non-0x8004xxxx COM-activation failures:
        [unchecked((int)0x80040154)] = new(unchecked((int)0x80040154), "REGDB_E_CLASSNOTREG",
            "QBXMLRP2.RequestProcessor is not registered (QuickBooks SDK not installed, or a 32/64-bit interop mismatch).",
            "Install the QuickBooks SDK on the host; confirm the service runs as x86; see Phase 9 deploy notes."),
    };

    // dead-ticket / dropped-session family that triggers rebuild-and-retry-once:
    private static readonly HashSet<int> DeadTicket = new()
    {
        unchecked((int)0x8004040D),   // invalid ticket
        // 0x80040422 (requires single-user) is NOT a dead ticket — a retry won't help; surface verbatim.
        // Be conservative: 0x8004040D is the canonical one. If on-box experience (Phase 9) shows others
        // (e.g. some 0x8004041x in a dropped-RPC scenario), add them then with evidence — do NOT speculatively widen here.
    };

    public static bool IsDeadTicket(int hresult) => DeadTicket.Contains(hresult);

    public static QbError Lookup(int hresult) =>
        Map.TryGetValue(hresult, out var e)
            ? e
            : new QbError(hresult, "QB_UNKNOWN",
                $"Unmapped QuickBooks/COM error 0x{hresult:X8}.",
                "See qbsdklog.txt on the QuickBooks host; consult the QuickBooks SDK error reference.");

    // Also handle the InvalidCastException("...RequestProcessor2...") case explicitly:
    public static QbError CastFailure(string detail) =>
        new(unchecked((int)0x80040154), "QB_RP2_CAST_FAILED",
            $"Unable to cast the COM object to RequestProcessor2 ({detail}). The QBXMLRP2 type library is missing or the wrong bitness.",
            "Install/repair the QuickBooks SDK on the host; confirm x86; regenerate Interop.QBXMLRP2Lib.dll on the host (Phase 9).");
}
```
> Source for the table contents: `.planning/research/PITFALLS.md` Pitfall 4 (which cross-checked QODBC + ConsoliBYTE + Intuit-derived "Status codes in response messages"). Names like `QB_ACCESS_FAILED` are this project's labels, not Intuit's — fine, they're for logs/health.
> **Note on `0x800404C5` (stale `EditSequence`)**: that's a *qbXML-level* error (it comes back inside the `<...Rs statusCode="...">`, not as a COM HRESULT), so it is **not** in `QbErrors` and **not** handled in Phase 2 — it's Phase 7's concern (`WRITE-07`). Don't add it here.

### `QbException` / `QbBusyException` / `QbTimeoutException`

```csharp
// QbConnectService.Qb.Com/QbExceptions.cs  (or one file each)
namespace QbConnectService.Qb;

public class QbException : Exception
{
    public QbError Error { get; }
    public QbException(QbError error, Exception? inner = null)
        : base($"{error.Name} (0x{error.Code:X8}): {error.Message} — {error.RemediationHint}", inner)
        => Error = error;

    public static QbException From(System.Runtime.InteropServices.COMException ex)
        => new(QbErrors.Lookup(ex.HResult), ex);
}

/// Thrown when the SemaphoreSlim(1,1) busy-wait times out — Phase 5 maps to HTTP 409.
public sealed class QbBusyException : Exception
{
    public TimeSpan WaitedFor { get; }
    public QbBusyException(TimeSpan waitedFor)
        : base($"QuickBooks is busy with another request; waited {waitedFor.TotalSeconds:F0}s.") => WaitedFor = waitedFor;
}

/// Thrown when a single ProcessRequest exceeds Request:TimeoutSeconds — the session is then poisoned.
public sealed class QbTimeoutException : Exception
{
    public TimeSpan Timeout { get; }
    public QbTimeoutException(TimeSpan timeout)
        : base($"QuickBooks request exceeded the {timeout.TotalSeconds:F0}s timeout; the session has been reset.") => Timeout = timeout;
}
```

### `QbOptions` + binding

```csharp
// QbConnectService.Qb.Com/QbOptions.cs
namespace QbConnectService.Qb;

public sealed class QbOptions
{
    public string CompanyFilePath { get; set; } = "";          // empty allowed at config-time; surfaced as a clear error if QB not running
    public string AppId { get; set; } = "";
    public string AppName { get; set; } = "QbConnectService";
    public bool OwnerIdZero { get; set; }                       // Phase 3 uses it; harmless to bind now
    public QbConnectionType ConnectionType { get; set; } = QbConnectionType.LocalQBD;   // never SingleUser-equivalent
    public QbFileMode OpenMode { get; set; } = QbFileMode.DoNotCare;
}

public sealed class RequestOptions
{
    public int TimeoutSeconds { get; set; } = 60;              // per-call watchdog
    public int BusyWaitSeconds { get; set; } = 10;            // bounded wait on the SemaphoreSlim before 409 Busy
}
```
```csharp
// in Program.cs
builder.Services.Configure<QbOptions>(builder.Configuration.GetSection("Qb"));
builder.Services.Configure<RequestOptions>(builder.Configuration.GetSection("Request"));
```
> `OpenMode`/`ConnectionType` are bindable from config but the manager should **assert** `OpenMode != SingleUser` (and just always pass `DoNotCare` + `LocalQBD` per SESS-01 unless there's a deliberate config override — recommend: read them, but if `OpenMode == SingleUser` log a warning and force `DoNotCare`). The simplest safe choice for Phase 2: ignore the config knobs and hard-code `DoNotCare`/`LocalQBD` in the manager, expose them as options only for future flexibility. Pick one and tell Codex which — **recommend: hard-code in the manager, bind the options for completeness/health-reporting**.

### `appsettings.sample.json` additions

```jsonc
// add to the existing "Qb" object:
"Qb": {
  "CompanyFilePath": "C:\\path\\to\\company.QBW",
  "AppId": "REPLACE-WITH-APP-ID",
  "AppName": "QbConnectService",
  "OwnerIdZero": false,
  "ConnectionType": "LocalQBD",      // LocalQBD | LocalQBDLaunchUI — never SingleUser; default LocalQBD
  "OpenMode": "DoNotCare"            // DoNotCare | MultiUser — never SingleUser; default DoNotCare
},
// extend the existing "Request" object:
"Request": {
  "TimeoutSeconds": 60,              // per-call watchdog (ProcessRequest)
  "BusyWaitSeconds": 10             // how long a concurrent caller waits for the session before 409 Busy
}
```
(Enum binding from string works out of the box with `Configure<T>` + `EnumConverter`; `"DoNotCare"` etc. bind to `QbFileMode.DoNotCare`.)

### DI wiring in `Program.cs` (replace the Phase-1 comment block)

```csharp
// --- Phase 2: COM session lifecycle ---
builder.Services.Configure<QbOptions>(builder.Configuration.GetSection("Qb"));
builder.Services.Configure<RequestOptions>(builder.Configuration.GetSection("Request"));

// The COM adapter is registered ONLY on Windows and ONLY outside the test host.
// The test host (WebApplicationFactory, future) sets ASPNETCORE_ENVIRONMENT=Testing and registers FakeRequestProcessor instead.
if (OperatingSystem.IsWindows() && !builder.Environment.IsEnvironment("Testing"))
{
    // factory, not a singleton instance — the manager rebuilds the adapter on dead-ticket/timeout
    builder.Services.AddSingleton<Func<IRequestProcessor>>(_ => () => new QbConnectService.Qb.Com.RealRequestProcessor());
}
// If neither branch ran (non-Windows dev box, or Testing env without an override), QbConnectionManager
// will throw a clear "no IRequestProcessor factory registered" on first Execute — that's acceptable; the
// host still starts (lazy connect).  Recommended: also register a default that throws-with-a-clear-message
// so the failure is obvious, OR let Testing always inject the fake (see Q5).

builder.Services.AddSingleton<QbConnectionManager>();   // implements IAsyncDisposable; CloseConnection on shutdown
```
> **`Func<IRequestProcessor>` vs `IRequestProcessor` registration:** registering a *factory* (rather than a singleton instance) is what lets `QbConnectionManager.RebuildConnectionAsync` get a fresh adapter. In tests, the test supplies `Func<IRequestProcessor>` returning a fresh `FakeRequestProcessor` each call (capture the *list* of created fakes in the test so it can assert against the latest one). See Q4/Q7.

### `QbConnectionManager` skeleton (the shape — give Codex this)

```csharp
// QbConnectService.Qb.Com/QbConnectionManager.cs
namespace QbConnectService.Qb;

public enum QbConnectionState { Disconnected, Connecting, SessionOpen, Poisoned }

public sealed class QbConnectionManager : IAsyncDisposable
{
    private readonly Func<IRequestProcessor> _factory;
    private readonly QbOptions _qb;
    private readonly RequestOptions _req;
    private readonly ILogger<QbConnectionManager> _log;

    private readonly SemaphoreSlim _gate = new(1, 1);
    private StaThread _sta;                          // recreated on rebuild-after-timeout
    private IRequestProcessor? _rp;                  // the current adapter (created on the STA thread)
    private string? _ticket;
    private QbConnectionState _state = QbConnectionState.Disconnected;
    public QbError? LastError { get; private set; }  // Phase 5's /api/health reads this
    public QbConnectionState State => _state;

    public QbConnectionManager(Func<IRequestProcessor> factory, IOptions<QbOptions> qb, IOptions<RequestOptions> req, ILogger<QbConnectionManager> log)
    { _factory = factory; _qb = qb.Value; _req = req.Value; _log = log; _sta = new StaThread("qb-com-sta"); }

    public async Task<string> ExecuteAsync(string qbXmlRequest, CancellationToken ct = default)
    {
        if (!await _gate.WaitAsync(TimeSpan.FromSeconds(_req.BusyWaitSeconds), ct))
            throw new QbBusyException(TimeSpan.FromSeconds(_req.BusyWaitSeconds));
        try
        {
            await EnsureConnectedAsync();
            return await ProcessWithRetryAsync(qbXmlRequest);
        }
        catch (QbException qx) { LastError = qx.Error; throw; }
        finally { _gate.Release(); }
    }

    public async Task<string[]> GetSupportedQbXmlVersionsAsync(CancellationToken ct = default)
    {
        if (!await _gate.WaitAsync(TimeSpan.FromSeconds(_req.BusyWaitSeconds), ct))
            throw new QbBusyException(TimeSpan.FromSeconds(_req.BusyWaitSeconds));
        try { await EnsureConnectedAsync(); return await _sta.Run(() => _rp!.GetSupportedQbXmlVersions(_ticket!)).WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds)); }
        catch (COMException ex) { var qx = QbException.From(ex); LastError = qx.Error; throw qx; }
        finally { _gate.Release(); }
    }

    // EnsureConnectedAsync(): if state is Disconnected or Poisoned -> ConnectAsync() (which does the rebuild on Poisoned).
    // ConnectAsync()/RebuildConnectionAsync(): the shared teardown(best-effort)+ new adapter + OpenConnection + BeginSession routine, all on _sta.
    //   On Poisoned: also `_sta.Dispose(); _sta = new StaThread(...)` first (the old thread may be wedged).
    // ProcessWithRetryAsync(): Pattern 3 above.
    // DisposeAsync(): on _sta -> best-effort EndSession + CloseConnection + _rp?.Dispose(); then _sta.Dispose(); _gate.Dispose().

    public async ValueTask DisposeAsync()
    {
        try { await _gate.WaitAsync(TimeSpan.FromSeconds(5)); } catch { }
        try { if (_rp is not null) { await _sta.Run(() => { try { _rp.EndSession(_ticket!); } catch { } try { _rp.CloseConnection(); } catch { } _rp.Dispose(); }); } } catch { }
        _sta.Dispose(); _gate.Dispose();
    }
}
```
> **`IAsyncDisposable` vs `IHostedService`:** register as a **singleton implementing `IAsyncDisposable`** — the DI container disposes singletons (including async ones) on host shutdown, so `CloseConnection` runs cleanly. **Do not** also make it `IHostedService` with a `StartAsync` that connects — that would crash the host if QuickBooks isn't there. (If you want the manager to appear in `IEnumerable<IHostedService>` for some reason, an `IHostedService` with a *no-op* `StartAsync` and the teardown in `StopAsync` is an alternative — but `IAsyncDisposable` is simpler and sufficient. Recommend `IAsyncDisposable` only.)
> Naming: spec/research use both `Execute` and `ExecuteAsync` — pick `ExecuteAsync` (async convention) and a sync-free public surface.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Marshal.ReleaseComObject` in a loop until 0 | `Marshal.FinalReleaseComObject` (one call) | .NET Framework 2.0+ (long-standing) | One call; correct for exclusively-owned RCWs. |
| `Task.WhenAny(task, Task.Delay(timeout))` for a timeout | `task.WaitAsync(TimeSpan)` / `WaitAsync(TimeSpan, CancellationToken)` | .NET 6 | Less boilerplate; throws `TimeoutException`; no leaked delay task. |
| Polly v7 `Policy.Handle<...>().Retry(1)` | Polly v8 `ResiliencePipeline` | Polly 8 (2023) | Not used in Phase 2 (hand-rolled retry) — noted only so the planner doesn't reach for v7 docs. |
| `BlockingCollection<T>` for async producer/consumer | `Channel<T>` | .NET Core 3.0 | For Phase 2 the consumer is a *blocking* dedicated thread, so `BlockingCollection` is still the natural choice; `Channel` is the pick when both ends are async. Either is fine. |

**Deprecated/outdated:** nothing in scope. `Marshal.FinalReleaseComObject`/`ReleaseComObject` carry a `[Obsolete]`-style analyzer note in *some* SDK analyzer rule sets ("not supported on .NET Core" was the old story; it *is* supported on Windows .NET 8 — they work) — if the build emits CA1416/SYSLIB warnings here, suppress narrowly with a comment; there is no replacement for deterministic RCW release.

---

## Open Questions

1. **Exact dead-ticket HRESULT set.**
   - What we know: `0x8004040D` ("invalid ticket") is the canonical dropped-session code per PITFALLS.md. The spec says "QuickBooks restarted mid-session → dead ticket → one retry."
   - What's unclear: whether other codes (some `0x8004041x` in an RPC-disconnect scenario, or `RPC_E_*` `0x800706xx`) should also trigger the rebuild-and-retry. PITFALLS.md is firm only on `0x8004040D`.
   - Recommendation: **start conservative** — only `0x8004040D` triggers rebuild-and-retry. Everything else surfaces verbatim on the first failure. Add others in Phase 9 *with on-box evidence*, not speculatively. The `QbErrors.DeadTicket` set is the single place to widen it.

2. **Polly vs hand-rolled retry.**
   - `STACK.md` says "Polly v8 for the one retry." But the retry must run bespoke teardown/rebuild between attempts (not "call the same delegate again").
   - Recommendation: **hand-rolled** single retry (Pattern 3). Don't add the Polly package in Phase 2. Note this as a deliberate, justified deviation from `STACK.md` so the planner/reviewer isn't surprised.

3. **`RealRequestProcessor` smoke test scope.**
   - It can't be unit-tested without QuickBooks, and the placeholder GUIDs guarantee activation fails (CLSID not registered).
   - Recommendation: one test — "constructing `RealRequestProcessor` (which activates COM) throws `QbException` with the `REGDB_E_CLASSNOTREG` mapping, not a bare `COMException`/`InvalidCastException`." This is true today and stays true if the SDK is absent in Phase 9. Skip it with `[Fact(Skip=...)]`-on-non-Windows if needed (it's `[SupportedOSPlatform("windows")]`). Don't attempt to assert successful activation.

4. **Does `QbConnectionManager` take `IRequestProcessor` or `Func<IRequestProcessor>`?**
   - It must rebuild the adapter on dead-ticket/timeout.
   - Recommendation: **`Func<IRequestProcessor>` factory.** In production, `() => new RealRequestProcessor()`. In tests, a factory returning a fresh `FakeRequestProcessor` each call, with the test capturing the created instances so it can assert against "the current one." This keeps the manager's rebuild logic clean and the tests honest about "a *new* COM object."

5. **How the test host injects `FakeRequestProcessor`.**
   - Phase 5 will use `WebApplicationFactory`; Phase 2's tests instantiate `QbConnectionManager` directly with a fake factory (no host needed).
   - Recommendation: for the *manager* tests, direct construction with a fake factory + `Options.Create(new QbOptions{...})` + `Options.Create(new RequestOptions{...})` + `NullLogger<QbConnectionManager>.Instance`. For the *DI-resolves* host-startup test (last task), either set `ASPNETCORE_ENVIRONMENT=Testing` and have `Program.cs` skip the Real registration (then the test adds its own `Func<IRequestProcessor>` via `ConfigureServices`), or just assert "on a non-Windows CI runner the host builds and `QbConnectionManager` resolves as a singleton" — the existing CI is `windows-latest` though, so prefer the `Testing`-environment override pattern. Phase 5 will formalize the `WebApplicationFactory` substitution; Phase 2 only needs "the registrations resolve and the host starts."

6. **Config knobs vs hard-coded `DoNotCare`/`LocalQBD`.**
   - SESS-01 says "`OpenMode = DoNotCare`, `connectionType = localQBD`, never SingleUser" — that's a hard requirement, not a config choice.
   - Recommendation: **hard-code `DoNotCare`/`LocalQBD` in the manager.** Still add `Qb:OpenMode`/`Qb:ConnectionType` to `appsettings.sample.json` and bind them (for health-reporting / future use), but the manager passes the hard-coded safe values and (if a config override is present and is `SingleUser`) logs a warning and ignores it. Simplest correct choice.

---

## Sources

### Primary (HIGH confidence)
- `.planning/research/ARCHITECTURE.md` — the `QbConnectionManager` design, persistent-session-vs-per-request decision, OpenMode/connectionType choices, reconnect-rebuilds-COM, the STA-worker + SemaphoreSlim(1,1) pattern, anti-patterns 1/2/5/6. (Project's own validated research; HIGH.)
- `.planning/research/PITFALLS.md` — Pitfall 4 (the full HRESULT table — lifted verbatim into `QbErrors`), Pitfall 5 (STA/x86 threading), Pitfall 6 (eternal-session/concurrency, reconnect rebuilds COM, watchdog), Pitfall 12 (RCW leaks / `FinalReleaseComObject`), Pitfall 15 (`qbsdklog.txt`). (HIGH on the HRESULT family — cross-checked QODBC + ConsoliBYTE + Intuit "Status codes in response messages".)
- `.planning/research/STACK.md` — STA-thread + `SemaphoreSlim(1,1)`, x86 build, "Polly v8 for the one retry" (Phase 2 deviates — hand-rolled), `IRequestProcessor` seam, `[SupportedOSPlatform("windows")]`, no QBFC. (HIGH on the .NET stack.)
- `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` §2/§3/§5/§7/§8 — serialized single-threaded session, `DoNotCare`, auto-reconnect-one-retry, `409 Busy`, `Request:TimeoutSeconds`, `QbSession` state-machine testing against a mock `IRequestProcessor`, `QbErrors` known-codes test. (HIGH — the spec of record.)
- Phase 1 code — `IRequestProcessor.cs` (the seam: 7 methods + `QbConnectionType`/`QbFileMode` enums, `IDisposable`), `QBXMLRP2Lib.cs` (placeholder `[ComImport]` `IRequestProcessor2`/`IAuthPreferences`/`RequestProcessor2` with placeholder GUIDs), `RealRequestProcessor.cs` (throwing stub to be rewritten), `FakeRequestProcessor.cs` (canned responses by `*Rq` element name, `Queue<Exception>` + `EnqueueComError(hresult,msg)`, `CallLog`), `Program.cs` (Phase-2 comment marker, `public partial class Program`), `appsettings.sample.json`, the three `.csproj`s (host = `net8.0-windows`/x86/`Microsoft.NET.Sdk.Web`; tests = `net8.0-windows`/x86, references **only** the host), `01-01-SUMMARY.md`. (HIGH — read directly.)
- `.planning/REQUIREMENTS.md` SESS-01..05; `.planning/ROADMAP.md` Phase 2 success criteria. (HIGH.)
- Microsoft Learn — `Thread.SetApartmentState`/`STAThreadAttribute`, `BlockingCollection<T>` (use `Channel<T>` for async producer/consumer), `Task.WaitAsync`, `Marshal.FinalReleaseComObject`. (HIGH — standard BCL behaviour, well-established; cross-checked via search 2026-05-11.)

### Secondary (MEDIUM confidence)
- WebSearch (2026-05-11) "dedicated STA thread for COM interop BlockingCollection work queue" — confirms the "single STA thread + consumer queue + message pumping" pattern is the standard approach for driving STA COM objects from a multi-threaded app. (MEDIUM — community + MS docs corroboration; the pattern is uncontroversial.)

### Tertiary (LOW confidence)
- None relied upon. The one genuinely-unverifiable area (real QBXMLRP2 type-library shape, real activation behaviour) is deliberately Phase 9's scope; Phase 2 codes against the declared placeholder shape and tests only the failure mode.

---

## Suggested Ordered Task Breakdown (for the PLAN — atomic, one commit each, suite green throughout)

Each task is verifiable with **no QuickBooks** (against `FakeRequestProcessor` or, for `RealRequestProcessor`, the activation-failure path). Order so each builds on the prior.

1. **`QbOptions` + `RequestOptions` POCOs + `appsettings.sample.json` keys + bind in `Program.cs`.** New file `QbOptions.cs` (in `Qb.Com`, namespace `QbConnectService.Qb`); add `Qb:ConnectionType`/`Qb:OpenMode` + `Request:BusyWaitSeconds` to `appsettings.sample.json`; `builder.Services.Configure<QbOptions>(...)`/`Configure<RequestOptions>(...)` in `Program.cs`. Test: a tiny config-binding test (load the sample json, bind, assert `OpenMode==DoNotCare`, `ConnectionType==LocalQBD`, `TimeoutSeconds==60`, `BusyWaitSeconds==10`). Verifies: SESS-01 config plumbing; the host still builds.

2. **`QbErrors` static map + `QbError` record + `QbException`/`QbBusyException`/`QbTimeoutException` + `QbErrorsTests`.** New `QbErrors.cs`, `QbExceptions.cs`. Unit tests: one `[Theory]` case per HRESULT in the table (code → expected `Name`; assert `Message`/`RemediationHint` non-empty); `Lookup` of an unmapped code returns the generic `QB_UNKNOWN`; `IsDeadTicket(0x8004040D)` true, `IsDeadTicket(0x80040420)` false; `QbException.From(new COMException("x", 0x80040408))` carries the `QB_COULD_NOT_START` error. Verifies: SESS-04 (the mapping + per-code test the spec demands).

3. **`StaThread` helper + (optionally) fold into step 4.** New `StaThread.cs` (internal). Tests: `Run<T>(func)` returns the value; `Run` marshals onto a single thread (assert `Thread.CurrentThread.ManagedThreadId` is the same across N calls and `!= the test thread`, and `GetApartmentState()==STA`); `Run(throwingFunc)` faults the task with that exception (not an unobserved exception); `Run(slowFunc).WaitAsync(shortTimeout)` throws `TimeoutException`; `Dispose()` stops the pump. Verifies: SESS-02 (the STA-thread substrate). *(If the planner prefers, merge this into step 4 — but a standalone `StaThread` with its own tests keeps the concurrency primitive isolated and is the cleaner cut.)*

4. **`QbConnectionManager` happy-path lifecycle + `QbConnectionManagerTests` (part 1).** New `QbConnectionManager.cs` + `QbConnectionState.cs`. Takes `Func<IRequestProcessor>`, `IOptions<QbOptions>`, `IOptions<RequestOptions>`, `ILogger<>`. Implements: `ExecuteAsync` (gate → lazy `EnsureConnectedAsync` → `_sta.Run(ProcessRequest)` with `WaitAsync` watchdog), `GetSupportedQbXmlVersionsAsync`, `IAsyncDisposable`. Tests against a fake factory: (a) first `ExecuteAsync` triggers `OpenConnection → BeginSession → ProcessRequest` in that order (assert via `CallLog`); (b) the args passed are `OpenMode=DoNotCare`, `connectionType=LocalQBD` (needs the **fake extension** — see step 4a); (c) a second `ExecuteAsync` reuses the session (no second `OpenConnection`/`BeginSession`); (d) `DisposeAsync` runs `EndSession → CloseConnection → Dispose`; (e) `GetSupportedQbXmlVersionsAsync` returns the fake's list. Verifies: SESS-01.
   - **4a (within this task or its own): extend `FakeRequestProcessor`** — record the `OpenConnection` args (`appId`, `appName`, `connectionType`) and the `BeginSession` args (`companyFilePath`, `openMode`) into public properties (or onto the `CallLog` as structured entries); add a `Func<string,string>? ProcessRequestHook` so a test can make `ProcessRequest` block/sleep (for the watchdog test) or count attempts; keep the existing canned-response + `EnqueueComError` behaviour. (The fake lives in the test project — extending it is in-scope. Prefer extending the fake over weakening the assertions.)

5. **Concurrency / serialization test + `QbBusyException` path.** No new production file (the gate is already in step 4) — *unless* the `BusyWaitSeconds` wiring wasn't done in 4; do it here. Tests: two `ExecuteAsync` calls started near-simultaneously on different threads — assert the fake's `ProcessRequest` calls do **not** interleave (the fake's hook can record enter/exit timestamps or a "currently inside" flag and fail if re-entered); a third call while the first is held (with `BusyWaitSeconds` set to a small value and the first deliberately slow) throws `QbBusyException`. Verifies: SESS-02.

6. **Dead-ticket rebuild + retry-exactly-once (`ProcessWithRetryAsync`) + tests.** Add `ProcessWithRetryAsync` + the shared `RebuildConnectionAsync`/`ConnectAsync` teardown-and-reopen routine to `QbConnectionManager`. Tests against the fake factory (factory hands out a fresh fake each `new`): (a) enqueue a dead-ticket `COMException(0x8004040D)` on the first fake's first `ProcessRequest` — assert: the *new* fake's `CallLog` shows `OpenConnection → BeginSession → ProcessRequest` (the rebuild), the old fake saw `EndSession`/`CloseConnection`/`Dispose` best-effort, and the call ultimately returns the canned response; (b) enqueue a dead-ticket error on the first fake *and* on the second fake's first `ProcessRequest` — assert a `QbException` (mapped `QB_INVALID_TICKET`) is thrown, exactly **two** `ProcessRequest` attempts total (one per fake), no third; (c) a non-dead-ticket `COMException(0x80040408)` on the first `ProcessRequest` — assert it surfaces immediately as `QbException(QB_COULD_NOT_START)`, **no** rebuild, one attempt. Verifies: SESS-03.

7. **Watchdog timeout + poisoned-session rebuild + tests.** Add: `WaitAsync(TimeSpan.FromSeconds(_req.TimeoutSeconds))` around the `_sta.Run(ProcessRequest)`; on `TimeoutException` → `Poison()` (set state `Poisoned`, dispose+recreate `_sta`, null the adapter) → throw `QbTimeoutException`; `EnsureConnectedAsync` treats `Poisoned` like `Disconnected` and rebuilds. Tests: set `Request:TimeoutSeconds` to ~1; make the fake's `ProcessRequest` block longer (hook with `Thread.Sleep`/an unset event) — assert `QbTimeoutException` thrown within ~the timeout; then a fresh fake (from the factory) and the *next* `ExecuteAsync` succeeds with a clean `OpenConnection → BeginSession → ProcessRequest` log (proving the poisoned session was rebuilt and not wedged). Verifies: SESS-05.

8. **`RealRequestProcessor` real implementation + smoke test.** Rewrite `RealRequestProcessor.cs`: ctor activates `(IRequestProcessor2)new RequestProcessor2()` wrapped in try/catch → on `COMException`/`InvalidCastException` throw `QbException` (`QbErrors.Lookup(ex.HResult)` or `QbErrors.CastFailure(...)`); forward each `IRequestProcessor` method to the COM object; `SetUnattendedModePreference` via `_rp.AuthPreferences().PutUnattendedModePref(b)`; `Dispose()` → `Marshal.FinalReleaseComObject`; `[SupportedOSPlatform("windows")]`. Smoke test (`[Fact]`, Windows-only): `Assert.Throws<QbException>(() => new RealRequestProcessor())` and assert `ex.Error.Name` is `REGDB_E_CLASSNOTREG` or `QB_RP2_CAST_FAILED` (not a bare `COMException`). Plan note: the placeholder GUIDs guarantee this fails-cleanly; real activation is Phase 9. Verifies: SESS-03/SESS-04 wrap-the-activation-failure; the adapter is written against the declared interface shape.

9. **DI wiring in `Program.cs` + host-startup-resolves test.** Replace the Phase-1 comment in `Program.cs` with: `Configure<QbOptions>`/`Configure<RequestOptions>` (if not already from step 1); the `if (OperatingSystem.IsWindows() && !env.IsEnvironment("Testing")) services.AddSingleton<Func<IRequestProcessor>>(_ => () => new RealRequestProcessor());`; `services.AddSingleton<QbConnectionManager>();`. Update `HostStartupTests` (or add a new one): build the host with `ASPNETCORE_ENVIRONMENT=Testing` and a `ConfigureServices` that adds a `Func<IRequestProcessor>` returning a `FakeRequestProcessor`; assert `host.Services.GetRequiredService<QbConnectionManager>()` resolves and is a singleton, the host starts and stops cleanly, and `DisposeAsync` is invoked on shutdown (the fake's `CallLog` shows `Dispose` after stop — only if a connection was opened; if lazy and never used, just assert it disposes without throwing). Verifies: SESS-01..05 wired into the running host; the host still boots with no QuickBooks.

**Build-order rationale (one line):** *options → errors → STA primitive → manager happy-path (+fake extension) → serialization → reconnect → watchdog → real adapter → DI wiring* — each task compiles and keeps the whole xUnit suite green, the manager is fully exercised against the fake before the real adapter is touched, and the DI wiring comes last so the "host starts with no QuickBooks" property is preserved at every step.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new packages; all in-box primitives, cross-checked against MS docs + project research.
- Architecture (manager design, STA pump, reconnect, watchdog, DI): HIGH — the design is pre-decided in `ARCHITECTURE.md`/`PITFALLS.md`/`STACK.md`; this is the codification, and the patterns (STA-thread pump, `SemaphoreSlim(1,1)` gate, `TaskCompletionSource` bridge, `IAsyncDisposable` singleton) are all standard.
- Pitfalls: HIGH — the HRESULT table is lifted verbatim from `PITFALLS.md` (itself cross-checked), and the threading/RCW pitfalls are well-established.
- The one LOW spot — real QBXMLRP2 activation — is deliberately out of Phase 2's scope (Phase 9), and the plan handles it by testing only the clean-failure path; this is called out explicitly so the reviewer doesn't flag a missing "real COM works" test.

**Research date:** 2026-05-11
**Valid until:** ~2026-06-10 (30 days — stable .NET BCL territory; nothing fast-moving). The dead-ticket HRESULT set may want widening with Phase-9 on-box evidence — that's the only thing likely to change.
