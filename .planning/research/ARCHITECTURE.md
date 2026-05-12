# Architecture Research

**Domain:** qbXML / QuickBooks Desktop (Enterprise) integration service — ASP.NET Core Windows service wrapping the `QBXMLRP2.RequestProcessor` COM component, exposing a bearer-auth REST API, plus a Python client and a Claude skill.
**Researched:** 2026-05-11
**Confidence:** HIGH for the COM lifecycle and component decomposition (well-trodden pattern, confirmed by Intuit docs + multiple community implementations); MEDIUM for the session-0 / unattended-service mechanics (real, documented, but environment-fragile and best confirmed on the actual host).

> This document **validates and sharpens** the architecture already laid out in `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md`. It does not redesign. Where this file disagrees with the spec, it says so explicitly; otherwise it is confirming the spec's choices and adding the dependency reasoning the roadmap needs.

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Workstation (repo home — where Claude runs)                                   │
│                                                                                │
│  .claude/skills/quickbooks-accounting/  ──drives──▶  quickbooks/clients/       │
│                                                        qb_client.py            │
│                                                          │  HTTPS + Bearer     │
└──────────────────────────────────────────────────────────┼─────────────────────┘
                                                            │  (LAN only)
┌───────────────────────────────────────────────────────────▼─────────────────────┐
│  10.120.254.13  —  QuickBooks Enterprise host                                    │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │  QbConnectService  (ASP.NET Core / .NET 8, runs as Windows service or task) │ │
│  │                                                                            │ │
│  │   Kestrel + HTTPS  ──▶  Bearer-auth middleware  ──▶  Controllers            │ │
│  │        ▲                                              │                    │ │
│  │        │                                  ┌───────────┴─────────────┐      │ │
│  │     Health   QbXml (/api/qbxml)     Ops (/api/ops/{op}, /dryrun)     │      │ │
│  │        │           │                       │                        │      │ │
│  │        │           │                 QbXmlBuilder (op → qbXML)       │      │ │
│  │        │           │                       │                        │      │ │
│  │        │           ▼                       ▼                        │      │ │
│  │        │   ┌────────────────────────────────────────────┐           │      │ │
│  │        └──▶│  QbConnectionManager  (singleton, owns the  │           │      │ │
│  │            │  COM session; SERIALIZES all ProcessRequest │◀── AuditLog (writes)│ │
│  │            │  via a single-slot lock / SemaphoreSlim(1)) │           │      │ │
│  │            └──────────────────┬─────────────────────────┘           │      │ │
│  │                               │ IRequestProcessor                   │      │ │
│  │              ┌────────────────┴───────────────┐                     │      │ │
│  │     RealRequestProcessor (COM)        FakeRequestProcessor (tests)    │      │ │
│  │              │                                                       │      │ │
│  │              ▼ raw qbXML response string                              │      │ │
│  │        QbXmlParser  (response → clean JSON; surfaces statusCode/      │      │ │
│  │                      statusSeverity/statusMessage; QbErrors maps      │      │ │
│  │                      0x8004xxxx COM HRESULTs to readable text)        │      │ │
│  └──────────────┼─────────────────────────────────────────────────────────────┘ │
│                 │ in-process COM call                                            │
│         QBXMLRP2.RequestProcessor  ──▶  QuickBooks Enterprise (qbw32.exe)         │
│                                          company file hosted MULTI-USER (.QBW)    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Talks to | Typical implementation |
|-----------|----------------|----------|------------------------|
| **`IRequestProcessor`** | Thin, mockable seam over the COM type. Exactly the methods used: `OpenConnection2(appId, appName, connectionType)`, `BeginSession(companyFile, openMode)`, `ProcessRequest(ticket, qbXml) → string`, `EndSession(ticket)`, `CloseConnection()`. *Optional but recommended:* expose `AuthPreferences.PutUnattendedModePref` so the real impl can set unattended mode. | Used by `QbConnectionManager` | C# interface; one method per COM call. The seam is the whole reason the solution builds/tests without the SDK installed. |
| **`RealRequestProcessor`** | Adapter that holds the actual `QBXMLRP2.RequestProcessor` COM object (created via `Type.GetTypeFromProgID("QBXMLRP2.RequestProcessor")` + `Activator.CreateInstance`) and forwards calls. Owns COM object cleanup (`Marshal.FinalReleaseComObject`). **Must run on an STA-friendly call path** and almost certainly **x86** (QuickBooks SDK is 32-bit). | `QBXMLRP2.RequestProcessor` | `[ComImport]`/`dynamic`/late-bound COM interop. Lives behind `IRequestProcessor`. |
| **`FakeRequestProcessor`** | In-memory test double. Returns canned qbXML responses keyed by request type; can simulate dead-ticket / restart, slow calls, error responses. | Used by tests + the host in "no-SDK" runs | Plain C# class; the host registers it when `Qb:UseFakeProcessor=true` or when COM activation fails. |
| **`QbConnectionManager`** *(spec calls this `QbSession` — same thing; "Manager" better signals it's a long-lived singleton, not a per-call object)* | Owns the **connection + session lifecycle and the serialization gate**. State machine: `Disconnected → Connected (OpenConnection2) → InSession (BeginSession→ticket) → [ProcessRequest…] → EndSession → CloseConnection`. Detects dead tickets / `0x80040401`/`0x8004041C`-class errors, tears down, re-opens on next request (one retry). Holds a `SemaphoreSlim(1,1)` so only one `ProcessRequest` is ever in flight (QuickBooks' SDK session is single-threaded). Enforces `Request:TimeoutSeconds`; on timeout, returns 409/504 and considers the session suspect. | `IRequestProcessor`, `AuditLog`, controllers | Singleton service; `async` wrapper around blocking COM calls dispatched to a dedicated STA worker thread. |
| **`QbXmlBuilder`** | Pure function layer: `(op, validated args) → qbXML request string` with the correct `<?qbxml version="QbXml:Version"?>` PI and `<QBXMLMsgsRq onError="...">` envelope. One builder method per op in the v1 catalog. No I/O, no COM — trivially unit-testable with golden files. | Called by `OpsController` | C# string/`XmlWriter` builders; one file, one method per op. |
| **`QbXmlParser`** | Pure function layer: raw qbXML response string → clean JSON DTO; **always** surfaces `statusCode` / `statusSeverity` / `statusMessage` from `<...Rs>` elements (a `statusCode != 0` is a *business* error, not a transport error — it must not be swallowed). Handles list pagination markers (`iterator`, `iteratorRemainingCount`). | Called by `OpsController` (and `QbXmlController` for the "also return parsed" path) | C# `XDocument`/`XmlReader`; one parse method per response type, plus a generic status extractor. |
| **`QbErrors`** | Static map: known `0x8004xxxx` COM HRESULTs → human-readable cause + remediation pointer (e.g. `0x80040420` → "integrated app not authorized / waiting for permission → see register-integrated-app.md"; `0x80040401` → "QuickBooks not running / can't launch"). Used to enrich both `/api/health` and error responses. | Called by `QbConnectionManager`, controllers | Static `Dictionary<uint,string>` or `enum` + switch. |
| **`AuditLog`** | Append-only writer. Every **executed write** (and only writes) appends: timestamp, op, args, qbXML sent, response `statusCode`/`statusSeverity`/`statusMessage`, token id. Immutable (open for append, never rewrite; ideally one file per day, fsync on write). Oversize raw responses get spilled to a sibling file and referenced. | Called by `QbConnectionManager`/`OpsController` after a write executes | Simple file appender; JSON-lines format recommended for grep-ability. |
| **`HealthController`** (`GET /api/health`) | Liveness + diagnostics: company-file name, QuickBooks version, SDK version, current open mode, last error (via `QbErrors`), `Safety:AllowWrites` flag, whether a session is currently held. Does **not** open a session if none exists unless asked (a probe param) — health checks shouldn't fight humans for the file. | `QbConnectionManager` | Thin ASP.NET Core controller. |
| **`QbXmlController`** (`POST /api/qbxml`) | Raw qbXML passthrough. Size-guarded. **Write-gate aware**: if `Safety:AllowWrites=false` and the body contains an `Add`/`Mod`/`Del`/`Void`/`Void...` request element, return 403 before touching COM. Returns raw qbXML response (and optionally parsed). | `QbConnectionManager` | Thin controller; the only "scan the body for write verbs" logic lives here and in `OpsController`. |
| **`OpsController`** (`POST /api/ops/{op}`, `POST /api/ops/{op}/dryrun`) | Validates args for `{op}` → `QbXmlBuilder` → (dryrun: return qbXML + plain-English summary, stop) / (real: `QbConnectionManager.Execute` → `QbXmlParser` → return JSON + raw qbXML; if it's a write, `AuditLog.Append`). 403 on any write op when `AllowWrites=false`. | `QbXmlBuilder`, `QbConnectionManager`, `QbXmlParser`, `AuditLog` | Thin controller; one `{op}` registry mapping name → (validator, builder method, isWrite flag, summary formatter). |
| **Bearer-auth middleware** | Rejects (401) any request without `Authorization: Bearer <Auth:ApiToken>`. Runs before all controllers; `/api/health` is **also** behind it (no anonymous endpoints — this is a LAN-internal box but defense in depth costs nothing). | Wraps everything | ASP.NET Core middleware or a minimal `AuthenticationHandler`; constant-time token compare. |
| **`qb_client.py`** (workstation) | HTTPS client: bearer header, TLS verify per `QB_VERIFY_TLS`, retries with backoff on 5xx/connection errors (**never** retry 4xx — a QuickBooks business error is final), `dryrun(op, args)` + `execute(op, args)` helpers, raw `qbxml(xml)` passthrough. | `QbConnectService` REST API | `requests` (or `httpx`); reads `.env`. |
| **`quickbooks-accounting` skill** | Drives `qb_client.py`. Enforces the write-safety workflow: dryrun → show user qbXML + summary → only on explicit confirm, call `execute`. References `qbxml-cheatsheet.md` + `setup-and-troubleshooting.md`. | `qb_client.py` | `SKILL.md` + `references/`. |

**Boundary rules that matter:**
- **Builder and Parser are pure** (no COM, no I/O). This is what makes the read pipeline buildable and unit-testable on a dev box with no QuickBooks. Keep them that way.
- **All COM access funnels through `QbConnectionManager` → `IRequestProcessor`.** Controllers never touch COM directly. The serialization gate lives in exactly one place.
- **`AllowWrites` is checked in two places** (`OpsController` for named ops, `QbXmlController` for raw verb-scanning) — and *also* defensively at the `QbConnectionManager` boundary (belt-and-suspenders: a write that somehow reaches Execute with `AllowWrites=false` should still be refused).
- **Audit log writes happen on the success path of a write, after the COM call returns** — so a failed write that QuickBooks rejected still gets logged (with its error status), but a write that never reached QuickBooks (network/auth fail) does not pretend to have happened.

---

## Recommended Project Structure

(Confirms the spec's `§6` layout — reproduced here with the one rename and a couple of additions noted.)

```
tech-legal/quickbooks/
├── QbConnectService/
│   ├── QbConnectService.sln
│   ├── src/
│   │   ├── QbConnectService/                  # ASP.NET Core host (.NET 8, x86 build — SDK is 32-bit)
│   │   │   ├── Program.cs                     # DI wiring, Kestrel HTTPS, auth middleware, singleton QbConnectionManager
│   │   │   ├── Controllers/
│   │   │   │   ├── HealthController.cs
│   │   │   │   ├── QbXmlController.cs         # POST /api/qbxml  (+ write-verb scan)
│   │   │   │   └── OpsController.cs           # POST /api/ops/{op} , /api/ops/{op}/dryrun
│   │   │   ├── Qb/
│   │   │   │   ├── IRequestProcessor.cs       # the mockable seam (OpenConnection2/BeginSession/ProcessRequest/EndSession/CloseConnection [+ UnattendedModePref])
│   │   │   │   ├── RealRequestProcessor.cs    # COM adapter over QBXMLRP2.RequestProcessor (STA worker)
│   │   │   │   ├── FakeRequestProcessor.cs    # in-memory double (also usable in the host via config flag)
│   │   │   │   ├── QbConnectionManager.cs     # spec's "QbSession" — singleton, lifecycle state machine, SemaphoreSlim(1), reconnect, timeout
│   │   │   │   ├── QbXmlBuilder.cs            # op → qbXML (pure)
│   │   │   │   ├── QbXmlParser.cs             # qbXML → JSON, surfaces status* (pure)
│   │   │   │   └── QbErrors.cs                # 0x8004xxxx → message + remediation
│   │   │   ├── Audit/
│   │   │   │   └── AuditLog.cs                # append-only JSON-lines writer
│   │   │   ├── Ops/
│   │   │   │   └── OpRegistry.cs              # name → (validate, build, isWrite, summarize) — single source of truth for the catalog
│   │   │   └── appsettings.sample.json        # committed; appsettings.json gitignored
│   │   └── QbConnectService.Tests/            # xUnit
│   ├── scripts/
│   │   ├── make-cert.ps1                      # self-signed cert for the HTTPS bind
│   │   ├── install-service.ps1                # New-Service running as svc_qbsdk
│   │   ├── uninstall-service.ps1
│   │   └── run-as-task.ps1                    # FALLBACK launch path (startup scheduled task under svc_qbsdk)
│   ├── README.md                              # deploy runbook + troubleshooting + QBWC-fallback note
│   └── register-integrated-app.md             # the manual QuickBooks-side authorization steps
├── clients/
│   ├── qb_client.py
│   ├── examples/                              # pull P&L, list invoices, create-customer dry-run
│   ├── .env.sample                            # committed; .env gitignored
│   └── requirements.txt
└── ../.claude/skills/quickbooks-accounting/
    ├── SKILL.md
    └── references/{qbxml-cheatsheet.md, setup-and-troubleshooting.md}
```

### Structure rationale
- **`Qb/` holds the entire COM-adjacent surface** — interface, two implementations, manager, builder, parser, errors. One folder = "everything QuickBooks." Controllers stay dumb.
- **`Ops/OpRegistry.cs` exists so the op catalog has one home.** Adding `create_check` later = one registry entry + one builder method + one parser method + golden files. No controller edits.
- **`Audit/` separate from `Qb/`** — auditing is a cross-cutting concern, not a QuickBooks concept; keeping it separate keeps the dependency arrow one-directional.
- **Tests project is a sibling, not nested** — standard .NET convention; lets the test project reference `FakeRequestProcessor` and the host without circular refs.

---

## Architectural Patterns

### Pattern 1: Anti-corruption seam over the COM type (`IRequestProcessor`)

**What:** Every COM call the service makes goes through a hand-rolled interface with one method per real COM method. `RealRequestProcessor` is the only file that imports the COM type; `FakeRequestProcessor` is a plain object.
**When to use:** Always, here — it is the load-bearing decision that lets the solution compile, unit-test, and even run (`/api/health`, builder/parser, the 403 gate) on a developer machine with no QuickBooks SDK installed. CI never needs QuickBooks.
**Trade-offs:** You hand-maintain the interface (small — ~6 methods). You must remember the real impl is x86/COM/STA and the fake isn't, so a test passing with the fake doesn't prove the COM path works — hence the manual smoke list in the spec's §8.
**Sketch:**
```csharp
public interface IRequestProcessor {
    void OpenConnection2(string appId, string appName, QBXMLRPConnectionType type);
    string BeginSession(string companyFile, QBFileMode mode);   // returns ticket
    string ProcessRequest(string ticket, string qbXmlRequest);  // returns raw qbXML response
    void EndSession(string ticket);
    void CloseConnection();
    void SetUnattendedModePref(bool required);                  // wraps AuthPreferences (real impl); no-op in fake
}
```

### Pattern 2: Single long-lived session + a one-slot serialization gate

**What:** `QbConnectionManager` is a singleton. It opens `OpenConnection2` + `BeginSession` **once** (lazily, on first request) and keeps the ticket. Every `ProcessRequest` is wrapped in `await _gate.WaitAsync()` / `_gate.Release()` where `_gate = new SemaphoreSlim(1,1)`, so exactly one round-trip is ever in flight. COM calls run on a dedicated STA worker thread; the async wrapper marshals to it.
**When to use:** This is the right default for a single QuickBooks file with low-to-moderate request volume — opening/closing a session per request is *slow* (QuickBooks may have to spin up `qbw32.exe`), and QuickBooks itself only allows one session per connection anyway. (See "open-per-request vs persistent" below for when the calculus flips — it doesn't for this project.)
**Trade-offs:** A held session means the manager must be robust to QuickBooks restarting under it (dead ticket) — hence reconnect-on-next-request with one retry. A held session can also block a human from switching the file to single-user mode; that's *acceptable* and *expected* given the multi-user hosting requirement. Concurrent callers queue (bounded wait → `409 Busy`); fine for a skill-driven, human-paced workload.

### Pattern 3: Pure builder/parser, impure manager (hexagonal-ish)

**What:** Domain logic (turn an op into qbXML; turn qbXML into JSON) is pure and has no dependencies. Side effects (COM, files, network, time) live in the manager, the audit log, and the controllers. Tests exercise the pure core with golden files and the side-effecting core with the fake processor + an in-memory `WebApplicationFactory`.
**When to use:** Always — it's why §8's test pyramid works. The "golden file" discipline (`(op,args) → expected.qbxml`, `sample-response.qbxml → expected.json`) catches qbXML-shape regressions for free.
**Trade-offs:** Slight ceremony (DTOs, mapping). Worth it: qbXML is finicky and silent — a malformed request comes back as a `statusCode` you'd otherwise miss.

### Pattern 4: Dry-run as a first-class endpoint, not a flag

**What:** `/api/ops/{op}/dryrun` runs the *exact* builder path and returns the qbXML + a plain-English summary, then **stops** — it never calls the manager. `/api/ops/{op}` runs builder → manager → parser → (audit if write). The skill *always* calls dryrun first for writes and only calls the real endpoint after explicit user confirmation.
**When to use:** Any time writes are dangerous and a human/agent is in the loop — which is exactly this project's posture (`AllowWrites=false` default, immutable audit, "no silent auto-apply, ever").
**Trade-offs:** Two endpoints per write op instead of one. Cheap, and the symmetry (dryrun shares the builder code path verbatim) means dryrun output is *trustworthy* — what you preview is byte-for-byte what gets sent.

---

## Data Flow

### Read op (e.g. `report ProfitAndLoss`)

```
skill → qb_client.execute("report", {type:"ProfitAndLoss", dateMacro:"ThisMonth"})
   → HTTPS POST /api/ops/report   (Bearer)
      → auth middleware (401 if bad token)
      → OpsController: validate args  →  QbXmlBuilder.BuildReport(args)  →  qbXML string
      → QbConnectionManager.Execute(qbXml):
            await gate.WaitAsync()
            ensure connected+session (OpenConnection2 + BeginSession if needed; reconnect if dead ticket)
            ticket = current ; raw = RealRequestProcessor.ProcessRequest(ticket, qbXml)   ← in-process COM → QuickBooks
            gate.Release()
      → QbXmlParser.ParseReport(raw)  →  { columns, rows, statusCode:0, ... }
      ← 200 { parsed: {...}, rawQbXml: "<...>", status: {...} }
   ← qb_client returns parsed JSON
← skill renders it
```

### Write op (e.g. `create_customer`) — the two-step path

```
STEP 1 (always):
skill → qb_client.dryrun("create_customer", {name:"Acme", ...})
   → POST /api/ops/create_customer/dryrun
      → OpsController: validate  →  QbXmlBuilder.BuildCustomerAdd(args)  →  qbXML
      ← 200 { qbXml:"<CustomerAddRq>...", summary:"Create customer 'Acme' with address ..." }
   ← skill shows the qbXml + summary to the user, asks "confirm?"

STEP 2 (only after explicit confirm AND only if Safety:AllowWrites=true on the server):
skill → qb_client.execute("create_customer", {...})
   → POST /api/ops/create_customer
      → OpsController: AllowWrites? → no ⇒ 403 (stop).  yes ⇒ continue
      → QbXmlBuilder.BuildCustomerAdd(args)  →  qbXML
      → QbConnectionManager.Execute(qbXml)  →  raw qbXML response   (COM → QuickBooks)
      → QbXmlParser.ParseCustomerAdd(raw)  →  { listId, editSequence, statusCode, statusSeverity, statusMessage }
      → AuditLog.Append({ ts, op:"create_customer", args, qbXmlSent, statusCode, statusSeverity, statusMessage, tokenId })
      ← 200 { parsed:{...}, rawQbXml:"<...>", status:{ code, severity, message } }
   ← qb_client returns it; 4xx/business-errors are surfaced verbatim, never retried
```

**Key invariants in the flow:**
1. Builder runs before the gate is taken — argument-validation failures never occupy the COM slot.
2. Only `ProcessRequest` (and lifecycle calls) are inside the gate; parsing happens after release.
3. A `statusCode != 0` in the response is returned to the caller as a normal `200` body with the status block populated — it is a *QuickBooks business outcome*, not an HTTP error. (HTTP 4xx/5xx are reserved for transport/auth/safety-gate/COM-unavailable conditions.)
4. Audit append is on the post-COM path for writes, success or QuickBooks-rejection alike.

---

## Connection lifecycle — the decision, with reasoning

**Recommendation: one persistent connection + session, opened lazily, with reconnect-on-dead-ticket. Open mode `DoNotCare`.** This confirms the spec.

### Persistent session vs open-per-request

| | Persistent (recommended) | Open-per-request |
|---|---|---|
| Latency | First call may be slow (launches `qbw32.exe`); every subsequent call is fast | *Every* call pays the session-open cost; if QuickBooks isn't running, that means launching it each time — seconds, sometimes tens of seconds |
| Robustness | Must detect dead ticket after a QuickBooks restart and re-open (one retry) — manageable | Naturally self-healing (always re-opens) — but the cost above makes it impractical |
| Contention with humans | Holding a session can block a user switching the file to single-user mode | Window between calls is "free" — but irrelevant here, the file is hosted multi-user |
| Fit for this project | ✅ Skill-driven, human-paced, single file, want low latency on bursts of reads | ❌ Only makes sense if calls are very rare and QuickBooks is *always* already up — not a safe assumption for an unattended box |

So: **persistent.** Concretely — lazy connect on first request; keep `connTicket` (from `OpenConnection2`) and `sessionTicket` (from `BeginSession`); on any call, if the ticket is dead (caught COM error in the `0x80040401`/`0x8004041C` / "ticket invalid" family, or a `ProcessRequest` throws an RPC-disconnect HRESULT), tear down (`EndSession` best-effort, `CloseConnection` best-effort, release the COM object), then `OpenConnection2` + `BeginSession` again, and **retry the request once**. If the re-open itself fails, surface the COM error (via `QbErrors`) and report it in `/api/health`. Don't loop — one retry, then fail loudly.

### Open mode (`BeginSession`'s `OpenMode` arg)

- **`DoNotCare` (default, recommended):** "open the file in whatever mode it's already in; if it's not open, open it." With the company file *hosted multi-user*, this lets the SDK attach alongside human users. This is the correct choice for an unattended service that must coexist with people in QuickBooks. Confirmed by the spec.
- **`MultiUser`:** forces multi-user. Only useful if you want the SDK to *be the one* that puts the file into multi-user mode — unnecessary here since hosting handles that.
- **`SingleUser`:** forces single-user — the SDK will fail if anyone else has the file open. **Never** for this project; it would lock humans out (or fail). Listed in config only for completeness.

(`OpenConnection2`'s `connectionType` is a different axis: use `localQBD` — in-process, QuickBooks must be on the same box. There's also `localQBDLaunchUI` for attended apps; don't use it for an unattended service.)

---

## Unattended operation — the mechanics, concretely

This is the part most likely to bite during deploy. Three things must all be true; if any one is missing, the SDK call fails with a recognizable HRESULT.

### 1. Integrated-app authorization with auto-login, stored in the company file

- A QuickBooks **Admin** user, in **single-user mode**, opens *Edit → Preferences → Integrated Applications → Company Preferences*, runs the service once so it presents its certificate / app identity (`Qb:AppId` / `Qb:AppName`), and grants it with **"Allow this application to login automatically"** — binding the grant to a **specific Windows user** (the spec's `svc_qbsdk`).
- This authorization is **written into the `.QBW` file itself** (not the registry, not the app) — so it travels with the company file and is per-Windows-user.
- On QuickBooks versions that introduced the stricter 2016+ integrated-app auth, there's a **"Reauthorize" button** (Admin, single-user mode) that regenerates the unattended-mode config entries for all auto-login apps — `register-integrated-app.md` should mention it as the recovery step if auth gets into a weird state.
- **PII gotcha:** if the company file has personally-identifiable info enabled (SSNs, etc.), QuickBooks may *require an interactive password login before* it will let an SDK app connect — which can defeat unattended mode. Flag this for the deploy checklist; it's environment-specific and may force a config change in QuickBooks.
- Failure signature: `0x80040420` ("waiting for permission" / app not authorized) → README points to `register-integrated-app.md`.

### 2. Company file hosted multi-user

- The `.QBW` must be in **multi-user (hosted) mode** so the SDK can `BeginSession` while humans also have it open. Single-user mode + a human with the file open ⇒ `BeginSession` fails with a session-mode error.
- This is a QuickBooks-side setting (File → Utilities → Host Multi-User Access, or it's already hosted on a server). Spec §11 correctly flags "confirm whether the file is already hosted multi-user" as a deploy-blocker to verify.

### 3. The service process runs as the *same* Windows user the app was bound to

- `install-service.ps1` must register the Windows service to **run as `svc_qbsdk`** (not `LocalSystem`, not `NetworkService`) — the same account named in the auto-login grant. QuickBooks Enterprise must be installed/licensed such that it can launch under that account.
- The SDK, when QuickBooks isn't already running, will launch `qbw32.exe` **headless under that account** — *if* the session-0 caveat below is satisfied.
- Failure signature: `0x80040401`/`0x80040408`/`0x8004040D`/`0x80040414` ("can't start QuickBooks", "unable to auto-login") family → `QbErrors` + README map them.

### The session-0 caveat and the service-vs-task ladder

Windows services run in **session 0** with no interactive desktop. QuickBooks Desktop COM has historically been fragile there (it's a desktop app being driven headless). Mitigation ladder, in priority order — **the service binary is identical in every case; only the launch wrapper differs**:

1. **Run as a Windows service (`install-service.ps1`), as `svc_qbsdk`, with the integrated-app auto-login configured correctly.** On modern QuickBooks SDK (13.0+) and current QuickBooks Enterprise this *usually* works — QuickBooks runs truly headless. Try this first.
2. **If that's unstable: run the same `QbConnectService.exe` via Task Scheduler "at startup" under `svc_qbsdk`** (`run-as-task.ps1`). A scheduled task triggered at startup still doesn't require an interactive logon, but it can run in a context where the desktop-app COM is happier. Documented fallback per spec §3/§7.
3. **If even that's flaky: a session-keeper / autologon-to-a-locked-console approach** — explicitly *out of scope for v1* (spec §10), documented in the README as a known escape hatch, not built.

`/api/health` should always report which launch path is active and the last COM error, so an operator can tell at a glance which rung of the ladder they're on.

---

## Suggested Build Order (with dependency reasoning)

This is the spec's stated order, validated and annotated. Each step is releasable/testable on its own; nothing waits on the QuickBooks host until the very end.

| # | Phase | Builds | Depends on | Why this order |
|---|-------|--------|-----------|----------------|
| **1** | **Seam + fake + pure-core skeleton + tests** | `IRequestProcessor`, `FakeRequestProcessor`, project/solution scaffold, `appsettings.sample.json`, xUnit project, CI that builds + runs tests with **no SDK installed** | nothing | Establishes the "buildable without QuickBooks" property *first* — every later phase inherits it. If the seam is wrong, everything downstream is wrong. Cheap to get right early. |
| **2** | **Session lifecycle (`QbConnectionManager`)** | The state machine, `SemaphoreSlim(1)` gate, STA worker dispatch, reconnect-on-dead-ticket, timeout, `QbErrors` map | #1 (drives it against `FakeRequestProcessor`) | The single most error-prone component (concurrency + lifecycle + COM threading). Build and unit-test it in isolation against the fake — connect→begin→process→end→close, dead-ticket recovery, "two concurrent calls don't interleave", timeout. Everything that follows assumes a working manager. |
| **3** | **qbXML builder + parser for READS** | `QbXmlBuilder` (read ops: `company_info`, `report`, `list_*`, `get_transaction`), `QbXmlParser` (those response shapes, incl. error responses with non-zero `statusCode`, incl. list pagination), golden-file tests, `Ops/OpRegistry` (read entries only) | #1, #2 | Reads are *safe* (no `AllowWrites` gate, no audit, no dry-run) — so they're the cheapest way to prove the whole builder→manager→parser pipe end-to-end. Doing reads before writes also means the first live smoke test (later) is read-only. |
| **4** | **REST API + auth + health** | Kestrel HTTPS bind, bearer-auth middleware, `HealthController`, `QbXmlController` (raw passthrough, size guard), `OpsController` (read ops + their `/dryrun`), in-memory `WebApplicationFactory` integration tests | #2, #3 | Now there's something the Python client and skill can talk to — but only reads, so no danger. Auth + health first so the host is observable from day one. `/api/qbxml` raw passthrough lands here too (it's just "manager + size guard"). |
| **5** | **Write ops + dry-run + the safety gate + audit** | `QbXmlBuilder`/`QbXmlParser` write paths (`create_*`, `mod_*`), `OpRegistry` write entries with `isWrite` + summary formatters, `Safety:AllowWrites` 403 gate in `OpsController` *and* the write-verb scanner in `QbXmlController`, `AuditLog`, integration tests for "403 when AllowWrites=false" + "audit row written on executed write" | #3, #4 | Writes layer *on top of* the proven read pipeline — same builder/parser/manager machinery plus the gate + audit. Keeping writes last means every earlier phase shipped without ever risking the company file. The dry-run endpoints for writes share the builder path from #3/#4 verbatim. |
| **6** | **Python client + skill** | `qb_client.py` (bearer, TLS-verify toggle, retry-on-5xx-only, `dryrun`/`execute`/`qbxml` helpers), `examples/`, `requirements.txt`, `.env.sample`, `SKILL.md` + `references/`, stub-HTTP-server tests for the client | #4 (reads) then #5 (writes) | The consumer side only needs a stable API contract, which #4/#5 provide. Building it after the service means the contract is real, not guessed. The skill's write-safety workflow (dryrun → confirm → execute) depends on #5's dryrun endpoints existing. |
| **7** | **Packaging + deploy + the QuickBooks-host bring-up** | `make-cert.ps1`, `install-service.ps1`/`uninstall-service.ps1`, `run-as-task.ps1` fallback, `README.md` deploy runbook + COM-error troubleshooting + QBWC-fallback note, `register-integrated-app.md`, then the **live smoke sequence** on `10.120.254.13`: `/api/health` → `company_info` → a `report` pull → `create_customer` **dry-run** (eyeball the qbXML) → set `AllowWrites=true` → one throwaway real write → verify in QuickBooks → verify the audit row | everything | This is the only phase that *requires* the QuickBooks host, the COM component, the multi-user file, and the integrated-app authorization. Doing it last means all the logic was already proven against the fake; what's left is the genuinely environment-specific stuff (cert, service account, session-0 ladder, QuickBooks-side auth grant) — exactly the items spec §11 flags as "verify during deploy". |

**Dependency reasoning in one line:** *seam → lifecycle → reads → API → writes → client → deploy* — each layer is testable against fakes until the very last one, and "safe before dangerous" (reads before writes, dry-run before execute, fake before live) is preserved at every step.

---

## Anti-Patterns

### Anti-Pattern 1: Opening a fresh COM connection/session per HTTP request
**What people do:** `using var rp = new RequestProcessor(); rp.OpenConnection2(...); rp.BeginSession(...); ... rp.EndSession(); rp.CloseConnection();` inside the controller, every call.
**Why it's wrong:** QuickBooks may launch `qbw32.exe` on the first session — that's *seconds*. Doing it per request makes every call slow and pounds QuickBooks. It also doesn't buy real isolation (QuickBooks only allows one session per connection anyway).
**Do this instead:** One persistent connection+session in a singleton (`QbConnectionManager`), serialized with a one-slot semaphore, reconnect-on-dead-ticket.

### Anti-Pattern 2: Letting two `ProcessRequest` calls run concurrently
**What people do:** Treat the service as stateless and let ASP.NET's thread pool fire multiple `ProcessRequest`s at once.
**Why it's wrong:** The QuickBooks SDK session is single-threaded; concurrent calls corrupt the session or throw. (And the COM object is STA — it must be touched from the thread that created it.)
**Do this instead:** `SemaphoreSlim(1,1)` around every `ProcessRequest` + lifecycle call; dispatch all COM calls to one dedicated STA worker thread; bound the wait and return `409 Busy` if the queue is backed up.

### Anti-Pattern 3: Swallowing or "fixing up" a non-zero `statusCode`
**What people do:** Treat any 200-from-QuickBooks as success, or auto-retry a stale-`EditSequence` write by re-reading and re-submitting.
**Why it's wrong:** `statusCode != 0` is QuickBooks telling you the operation didn't do what you asked (validation failure, locked record, stale edit sequence). Hiding it produces silent data loss; auto-"fixing" a stale `EditSequence` can clobber a concurrent edit.
**Do this instead:** `QbXmlParser` always surfaces `statusCode`/`statusSeverity`/`statusMessage`; the API returns them verbatim; `qb_client.py` does **not** retry 4xx/business errors; the human/skill decides.

### Anti-Pattern 4: Putting machine-specifics (IP, paths, token, cert password) in code
**What people do:** Hardcode `https://10.120.254.13:8443` or the bearer token in a constant "for now."
**Why it's wrong:** Kills portability (the whole point of the `.sample` pattern) and leaks secrets into git.
**Do this instead:** Everything machine-specific lives in `appsettings.json` (service) / `.env` (client), both gitignored, both with committed `.sample` versions. Code reads config; code has zero literals for IPs/paths/tokens.

### Anti-Pattern 5: Running the service as `LocalSystem` (or any account ≠ the authorized one)
**What people do:** Default the Windows service to `LocalSystem` because it "has more privileges."
**Why it's wrong:** The integrated-app auto-login grant is bound to a *specific* Windows user. Run as anyone else and QuickBooks won't auto-login → `0x8004041D`/`0x80040420`-class failures.
**Do this instead:** `install-service.ps1` registers the service to run as `svc_qbsdk` — the exact account named in the QuickBooks integrated-app grant — and QuickBooks Enterprise must be installable/launchable under it.

### Anti-Pattern 6: Building the host as AnyCPU/x64
**What people do:** Default .NET project settings.
**Why it's wrong:** The QuickBooks SDK COM component is 32-bit; an x64 process can't activate `QBXMLRP2.RequestProcessor` in-process (you'd get a class-not-registered / `0x80040154` even though it *is* registered).
**Do this instead:** Build/publish the host as **x86**. (The pure builder/parser unit tests don't care, but the host that does COM does.)

### Anti-Pattern 7: Treating dry-run as cosmetic
**What people do:** Have `/dryrun` build qbXML one way and the real endpoint build it slightly differently (e.g. dry-run pretty-prints, real one doesn't; or they drift over time).
**Why it's wrong:** The whole value of dry-run is "what you preview is exactly what gets sent." Any drift makes the safety workflow a lie.
**Do this instead:** Both endpoints call the *same* `QbXmlBuilder` method; `/dryrun` just stops after building (plus produces the English summary). Golden-file tests pin the builder output so it can't drift.

---

## Integration Points

### External services / components

| Component | Integration pattern | Notes / gotchas |
|-----------|---------------------|-----------------|
| `QBXMLRP2.RequestProcessor` (COM) | In-process COM (`localQBD`), STA, **x86**, behind `IRequestProcessor` | Must be on the same box as QuickBooks. `qbw32.exe` may be auto-launched on first session. Fragile in session 0 — see the service-vs-task ladder. ProgID: `QBXMLRP2.RequestProcessor` (there's also `RequestProcessor2` exposing `AuthPreferences.PutUnattendedModePref`). |
| QuickBooks Enterprise / the `.QBW` file | Indirect — via the COM component; the file must be **hosted multi-user** and the app **pre-authorized with auto-login** | Authorization lives *in the .QBW*, per-Windows-user. PII-enabled files may demand an interactive password before allowing SDK connect. qbXML spec version pinned in `QbXml:Version` must be ≤ what this QuickBooks build supports. |
| Windows Service Control Manager / Task Scheduler | `install-service.ps1` (`New-Service` as `svc_qbsdk`) or `run-as-task.ps1` (startup task as `svc_qbsdk`) | Identical binary; the launch wrapper is the only difference. Account must match the QuickBooks integrated-app grant. |
| Kestrel HTTPS endpoint | Self-signed cert from `make-cert.ps1`; client controls trust via `QB_VERIFY_TLS` | LAN-internal; bound to the host's LAN IP + a fixed port (e.g. `:8443`). Firewall path between workstation and host must allow that port (spec §11). |
| `qb_client.py` ↔ REST API | HTTPS + `Authorization: Bearer`; retry **5xx/connection only**, never 4xx | The contract is the four endpoints in spec §2. The skill sits on top and enforces dryrun→confirm→execute. |

### Internal boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Controllers ↔ `QbConnectionManager` | Direct method call (`Execute(qbXml) → raw`) | Controllers never touch COM or the gate; the manager is the only door. |
| `QbConnectionManager` ↔ `IRequestProcessor` | Interface call on the STA worker thread | The only seam where COM enters; swap real/fake here. |
| `OpsController`/`QbXmlController` ↔ `QbXmlBuilder`/`QbXmlParser` | Direct calls to pure functions | No I/O on this path — purely string in / DTO out. |
| `OpsController`/manager ↔ `AuditLog` | Direct call on the write success path | Append-only; never read back by the service at runtime. |
| Auth middleware ↔ everything | ASP.NET Core pipeline | Runs before all controllers, including `/api/health`. |
| `OpRegistry` ↔ controllers + builder/parser | Lookup table (`op name → handlers`) | Single source of truth for the v1 catalog; adding an op = a registry entry + builder/parser methods + golden files, no controller changes. |

---

## Sources

- Intuit Developer — *QuickBooks Desktop SDK: Connections, sessions and authorizations* (`developer.intuit.com/app/developer/qbdesktop/docs/develop/connections-sessions-and-authorizations`) — confirms `OpenConnection2`/`BeginSession`/`ProcessRequest`/`EndSession`/`CloseConnection` lifecycle, `localQBD` connection type, file open modes, auto-login authorization stored in the company file. *(HIGH — official; page body did not render via fetch but the API shape is corroborated below.)*
- Intuit blog — *Changes to the Integrated Application Authentication for QuickBooks Desktop users* (June 2016, `blogs.intuit.com`) — the "Reauthorize" button, unattended-mode config regeneration, PII-forces-password behavior, "run as the windows user the app was authorized under". *(MEDIUM — official blog, slightly dated but the mechanism persists.)*
- CLEARIFY support — *Intuit SDK Error 800404(1D/30/35) – Unable to Auto Login* — real-world failure signatures for the auto-login / authorized-Windows-user mismatch. *(LOW — vendor support note; useful for the `QbErrors` map, verify codes against actual behavior.)*
- ConsoliBYTE wiki — `quickbooks_integration_csharp` — C# example of the `QBXMLRP2.RequestProcessor` call sequence in-process. *(LOW — community wiki; pattern-confirmation only.)*
- Bellwether Softworks — *QB Desktop in PowerShell* and invisibleroads `inteum-quickbooks-sync/quickbooks/qbcom.py` — independent implementations showing the same `OpenConnection2 → BeginSession → ProcessRequest → EndSession → CloseConnection` shape and the x86/COM constraints. *(LOW — community; corroborates the lifecycle and the 32-bit gotcha.)*
- Project design spec — `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` — the authoritative target architecture this document validates and sharpens. *(HIGH — the spec of record.)*
- Training knowledge (Claude, cutoff Jan 2026) — COM/STA/x86 interop constraints for the QuickBooks SDK, session-0 fragility of QuickBooks Desktop COM, the service-vs-scheduled-task fallback pattern. *(MEDIUM — well-established but environment-dependent; the live smoke phase on `10.120.254.13` is the real verification.)*

---
*Architecture research for: qbXML / QuickBooks Desktop integration service (ASP.NET Core Windows service wrapping QBXMLRP2)*
*Researched: 2026-05-11*
