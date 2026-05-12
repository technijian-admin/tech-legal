# Pitfalls Research

**Domain:** Unattended QuickBooks Desktop (Enterprise) integration via QBXMLRP2 / qbXML COM, fronted by an ASP.NET Core Windows service with a bearer-auth HTTPS REST API
**Researched:** 2026-05-11
**Confidence:** HIGH on the HRESULT family and the integrated-app authorization model (verified against Intuit SDK docs, QODBC error tables, ConsoliBYTE wiki); MEDIUM-HIGH on session-0 service behavior (well-documented community pattern, but exact stability depends on the specific QB Enterprise build on `10.120.254.13`).

> Phase legend used throughout:
> - **P1 — Interface & tests:** `IRequestProcessor`, `QbXmlBuilder`, `QbXmlParser`, `QbErrors`, mock-driven unit/integration tests, controllers, 403-when-writes-off.
> - **P2 — Session lifecycle:** `QbSession` (OpenConnection2 / BeginSession / ProcessRequest / EndSession / CloseConnection), reconnect, serialization, threading/STA, `RealRequestProcessor`.
> - **P3 — Reads:** read ops, report parsing, iterators/pagination, list filters.
> - **P4 — REST & auth:** HTTPS bind, bearer token, error surfacing, `qb_client.py`, health endpoint.
> - **P5 — Writes & audit:** write ops, dry-run gate, `AllowWrites` 403, EditSequence handling, immutable audit log.
> - **P6 — Deploy:** `install-service.ps1` / `run-as-task.ps1`, `make-cert.ps1`, `register-integrated-app.md`, README runbook, smoke tests on the live box.

---

## Critical Pitfalls

### Pitfall 1: Session-0 / "no interactive desktop" — QB Desktop COM dies when launched from a Windows service

**What goes wrong:**
The service installs fine, `GET /api/health` works until the first qbXML call, then `OpenConnection2`/`BeginSession` hangs or returns `0x80040401` ("could not access QuickBooks") / `0x80040408` ("could not start QuickBooks"). QuickBooks Desktop is a heavyweight GUI app; when COM-activated inside session 0 (where Windows services live, with no interactive desktop and a restricted window station), `qbw32.exe` / `QBW.exe` can fail to fully initialize, get stuck behind an invisible modal dialog, or crash. It often *looks* like it worked on the dev box (where someone was logged in) and fails the moment nobody is logged into `10.120.254.13`.

**Why it happens:**
Developers test interactively, ship as a service, and discover session-0 isolation only in prod. Intuit's SDK supports unattended mode but its reliability in session 0 varies by QB year/build and by whether the integrated-app auto-login is configured *exactly* right.

**How to avoid:**
- Build the service binary so it is **launch-wrapper agnostic** from day one (it already is in the spec): the same EXE must run identically (a) as a Windows service and (b) via Task Scheduler "at startup" under `svc_qbsdk`, and (c) interactively. Don't bake `ServiceBase`-only assumptions into startup.
- Default deployment path = **scheduled task at startup under `svc_qbsdk`** with "Run whether user is logged on or not" — this still has session-0 limitations but is the documented, more-stable variant; promote "real Windows service" only if it proves stable on this box. (`run-as-task.ps1` must be a first-class deliverable, not an afterthought.)
- In the smoke-test runbook, the *first* test after deploy is: log out of `10.120.254.13` entirely, then hit `company_info` from the workstation. If it only works while logged in, you have not actually achieved unattended mode.
- Set `Qb:OpenMode = DoNotCare` and pre-launch QuickBooks under `svc_qbsdk` (or let the SDK launch it) — but verify via Task Manager that `QBW.exe` is running in session 0 under `svc_qbsdk`, not session 1 under a human.
- Document the fallback ladder in README: (1) integrated-app + auto-login correctly configured → headless; (2) scheduled task; (3) a session-keeper / autologon-then-lock as last resort.

**Warning signs:**
First qbXML call after a clean reboot (nobody logged in) hangs until `Request:TimeoutSeconds`; `qbsdklog.txt` shows COM activation but no session begin; QB process appears then vanishes; `0x80040401`/`0x80040408` only in prod.

**Phase to address:** P2 (build wrapper-agnostic, threading), P6 (deploy ladder, logged-out smoke test, `run-as-task.ps1`).

---

### Pitfall 2: The integrated-application authorization dance done wrong — wrong Windows user, wrong mode, or never persisted

**What goes wrong:**
qbXML calls return `0x80040420` ("the QuickBooks user has denied access") or `0x8004041A` ("this application does not have permission to access this company data file"), or QuickBooks pops the **certificate / "An application is requesting access..."** dialog *invisibly in session 0* and the call just times out. Most common root cause: the one-time authorization was granted while logged in as a *different* Windows user than the one the service runs as, or it was granted with "prompt each time" instead of "**Allow this application to login automatically**", or it was granted but bound to a *user* when the service runs as `LocalSystem`/`NetworkService`, or someone clicked "Yes, prompt each time" which is fatal for unattended mode (no human to click).

**Why it happens:**
The auth lives *inside the company file*, is keyed to (app certificate/name **+** the Windows user that will run unattended), and the "login automatically" option only appears once you've already created the app entry. It's a fiddly multi-step manual procedure (Edit → Preferences → Integrated Applications → Company Preferences → run the app once → grant cert → set auto-login → pick the Windows user). Skipping or fat-fingering any step silently breaks unattended mode.

**How to avoid:**
- `register-integrated-app.md` is a **mandatory, ordered checklist** with screenshots, executed as **QuickBooks Admin in single-user mode** (the file must be in single-user for the auth grant to stick reliably), running the *actual service binary* (or `SDKTestPlus3.exe` pointed at the same `AppID`/`AppName`) so the cert is issued to the right identity.
- The service must run as the **same Windows account** named in that grant — `svc_qbsdk` — not `LocalSystem`. `install-service.ps1` and `run-as-task.ps1` must take that account as a parameter and refuse to install under `LocalSystem`/`NetworkService`.
- `Qb:AppID` / `Qb:AppName` in config must be **stable and never changed** after authorization; changing either invalidates the grant and re-pops the cert dialog. Treat them like a primary key.
- `GET /api/health` must surface the *last* `0x80040420`/`0x8004041A` and the README must map both to "re-run `register-integrated-app.md`".
- When the QB Admin password changes or the file is restored from backup, the integrated-app grant can be wiped — call this out in README troubleshooting.

**Warning signs:**
`0x80040420` / `0x8004041A` on first real call; an "Application Certificate" or access-request dialog visible if you RDP into the box; the integrated-apps list in QuickBooks shows the app with access = "Prompt each time" or missing entirely; the app entry exists but `svc_qbsdk` ≠ the user it's bound to.

**Phase to address:** P6 (`register-integrated-app.md`, install scripts enforce the service account), P4/P1 (health endpoint + `QbErrors` surface `0x80040420`/`0x8004041A` cleanly).

---

### Pitfall 3: Single-user vs multi-user mode conflicts — SDK can't open the file while a human has it open

**What goes wrong:**
`BeginSession` fails with `0x80040410` ("company data file is currently open in a mode other than the one specified") or `0x80040422` ("requires single-user file access mode") or `0x8004040A` ("a different company file is already open"). Happens whenever a bookkeeper has the `.QBW` open on their machine in single-user mode and the service tries to open it, or vice versa, or the file simply isn't *hosted* (Database Server Manager not configured) so only one process can ever touch it.

**Why it happens:**
QuickBooks allows exactly one company file open per machine, and concurrent access requires the file to be **hosted in multi-user mode** via QuickBooks Database Server Manager. If hosting isn't on, the SDK and humans fight over an exclusive lock. Teams often discover the file was running single-user the whole time only when the integration starts conflicting with staff.

**How to avoid:**
- **Open item to verify before any code:** confirm the company file on `10.120.254.13` is hosted multi-user (Database Server Manager running, "Host Multi-User Access" enabled, `.ND` file present). This is already flagged in the design's §11 — don't let it slide; it's a hard prerequisite.
- Set `Qb:OpenMode = DoNotCare` so the SDK joins whatever mode the file is hosted in rather than demanding single-user.
- `GET /api/health` must report the current company-file open mode so operators can see at a glance whether a human grabbed it single-user.
- README: explicit "never open the company file in single-user mode while the service is running" instruction for staff; and the *one* legitimate exception — the integrated-app authorization step in Pitfall 2 — must be done during a maintenance window with the service stopped.
- Map `0x80040410` / `0x80040422` / `0x8004040A` in `QbErrors` to actionable text ("a user has the file open in single-user mode; switch to multi-user").

**Warning signs:**
Integration works fine until 9am when staff log in; `0x80040410`/`0x80040422` correlated with business hours; no `.ND` file next to the `.QBW`; Database Server Manager not in the services list.

**Phase to address:** P6 (verify hosting prerequisite, README), P2/P1 (`QbErrors` mapping, health reports mode).

---

### Pitfall 4: The COM HRESULT family treated as opaque blobs — operators can't self-diagnose

**What goes wrong:**
A qbXML call fails, the API returns `COMException 0x80040408` with no human text, and nobody on either side knows whether QuickBooks is down, the file is locked, the app isn't authorized, or a modal dialog is stuck on screen. Time-to-recovery balloons because every incident requires a developer to look up the code.

**Why it happens:**
`QBXMLRP2.RequestProcessor` throws raw `COMException`s with `0x8004xxxx` HRESULTs; the SDK does not give friendly messages. Without a lookup table, the codes are meaningless.

**How to avoid:**
Ship `QbErrors.cs` as a **complete, unit-tested** map (one xUnit case per code) covering at minimum:

| HRESULT | Meaning | Operator action |
|---|---|---|
| `0x80040401` | Could not access QuickBooks (connection attempt failed; QB install may be incomplete/broken) | Check QB is installed/repaired under `svc_qbsdk`; check session-0 setup |
| `0x80040402` | Unexpected error — see `qbsdklog.txt` | Pull the SDK log |
| `0x80040408` | Could not start QuickBooks (launch failed; install incomplete or session-0 instability) | Pre-launch QB; verify scheduled-task launch path |
| `0x8004040A` | A *different* company file is already open on this machine | Close the other file or fix `Qb:CompanyFilePath` |
| `0x8004040D` | Invalid session ticket (stale/expired) | Session torn down — reconnect (the service should auto-retry once) |
| `0x80040410` | Company file open in a mode other than the one specified | A human has it single-user; switch file to multi-user |
| `0x80040414` | A modal dialog is showing in the QuickBooks UI | Dismiss the dialog on the QB box (and find what's popping it) |
| `0x80040416` | QB not running and `BeginSession` didn't get a company-file path | Set `Qb:CompanyFilePath` (don't rely on "use the open file" when QB may be closed) |
| `0x8004041A` | This application does not have permission to access this company file | Re-run `register-integrated-app.md` |
| `0x80040420` | The QuickBooks user has denied access (integrated app not authorized / auth revoked / "waiting for permission") | Re-run `register-integrated-app.md`; check integrated-apps list |
| `0x80040421` | Text passed straight through from QuickBooks | Read the message text; usually a QB-side condition |
| `0x80040422` | This application requires single-user file access mode | Another app/user shares the file; coordinate access |

Plus the COM-creation failures that aren't `0x8004xxxx`: "Cannot create QBXMLRP2 component" / `Class not registered` / `Unable to cast COM object ... RequestProcessor2` = SDK not installed or `QBXMLRP2.dll` not registered on the host, or a 32/64-bit interop mismatch.

`GET /api/health.lastError` must include both the HRESULT *and* the mapped message. README repeats the table.

**Warning signs:**
Logs full of bare hex codes; support tickets that say "QuickBooks broke" with no diagnosis; same incident re-investigated repeatedly.

**Phase to address:** P1 (`QbErrors` + tests), P4 (health surfaces mapped text), P6 (README table).

---

### Pitfall 5: 32/64-bit and STA threading — calling QBXMLRP2 COM from an ASP.NET Core thread-pool thread

**What goes wrong:**
Intermittent `0x80010105` (RPC_E_SERVERFAULT) / `InvalidComObjectException` / random hangs under load, or "Cannot create QBXMLRP2 component" even though the DLL is registered. `QBXMLRP2.RequestProcessor` is an **STA (single-threaded apartment)** COM object; ASP.NET Core request handlers run on **MTA thread-pool threads**, and the apartment mismatch corrupts the COM proxy. Separately, `QBXMLRP2.dll` is **32-bit**; a default `dotnet publish` (AnyCPU → 64-bit on a 64-bit box) can't load it, giving `BadImageFormatException` / `Class not registered`.

**Why it happens:**
ASP.NET Core has no STA concept; developers `new`-up the COM object inside a controller action and it works on the first call, then degrades. The bitness issue is invisible until the COM `CoCreateInstance`.

**How to avoid:**
- Run all COM interaction on a **dedicated single STA thread** owned by `QbSession` — a long-lived worker thread created with `Thread { ApartmentState = STA }`, with controller actions marshaling work to it via a queue (this also gives you the required serialization for free; see Pitfall 6). Never touch the COM object from a request thread.
- The COM object must be **created and used on the same thread** for its whole lifetime; don't pass the RCW across threads.
- Build/publish the service as **x86** (or run inside a 32-bit host) so it can load `QBXMLRP2.dll`. Document this in README and the `.csproj` (`<PlatformTarget>x86</PlatformTarget>`).
- `IRequestProcessor` abstraction is right; just make sure `RealRequestProcessor` is only ever instantiated on the STA worker.
- Call `Marshal.ReleaseComObject` (or `FinalReleaseComObject`) on the RCW when tearing down a session; leaked RCWs keep `QBW.exe` alive forever (see Pitfall 12).

**Warning signs:**
Works for a few calls then `RPC_E_*` / `InvalidComObjectException`; `BadImageFormatException` at startup; `QBW.exe` count climbing; flaky behavior only under concurrent requests.

**Phase to address:** P2 (STA worker thread, x86 target, RCW lifetime).

---

### Pitfall 6: Trying to keep a session open forever, or firing concurrent qbXML requests

**What goes wrong:**
The service holds one `BeginSession`/`EndSession` open across many minutes; QuickBooks restarts, gets updated, or a human switches the file, and the held ticket goes stale → `0x8004040D` ("invalid ticket") on the next call, sometimes with the whole COM proxy now dead. Or: two REST calls arrive together, both hit the (non-thread-safe, single-session) RequestProcessor, and you get interleaved/garbled qbXML, `0x80040414` storms, or a hard crash.

**Why it happens:**
"Connection pooling" instinct from databases doesn't apply — the QB SDK session is a single, fragile, single-threaded resource. And QuickBooks itself does *not* like long-held sessions or concurrency.

**How to avoid:**
- **Serialize everything** through the STA worker queue (Pitfall 5). One qbXML round-trip in flight, period. Second concurrent caller waits up to a short bound, then gets `409 Busy` with a hint (already in the design — keep it).
- Prefer a **short-lived session per request** (or per small batch): `OpenConnection2` once at startup is fine, but `BeginSession`→`ProcessRequest`→`EndSession` per request is the safer pattern than one eternal session. If keeping a session open, treat *any* COM error as "tear down and reconnect on next request" (one retry) — which the design already specifies; make sure the retry actually re-creates the COM object, not just re-`BeginSession`s on a dead one.
- Add a `Request:TimeoutSeconds` watchdog (already in config) so a stuck call (e.g. behind a modal dialog) doesn't wedge the queue forever — on timeout, tear the session down.
- Never expose a "keep-alive" or "open session" endpoint.

**Warning signs:**
`0x8004040D` after periods of inactivity; garbled responses or `0x80040414` when traffic spikes; the queue depth growing; a single slow report blocking health checks.

**Phase to address:** P2 (serialized worker, per-request session, watchdog, reconnect-rebuilds-COM).

---

### Pitfall 7: qbXML version processing instruction missing, wrong, or newer than the installed QB supports

**What goes wrong:**
Every request comes back as a parse error / "unsupported version" / empty response, or — subtler — requests *work* but newer elements you used silently get dropped, or `*Mod` requests behave differently than expected. The `<?qbxml version="16.0"?>` processing instruction (and the matching `requestXML version` attribute on `ProcessRequest`) must name a spec version the **installed QuickBooks build supports** — QB 2016-era understands ~12.0/13.0; only recent Enterprise builds understand 16.0. Sending a version higher than the host supports = failure; omitting it = QuickBooks guesses (often wrongly) or rejects.

**Why it happens:**
Devs copy a version number from a tutorial or use the SDK's latest, never checking the *target* QuickBooks Enterprise year on `10.120.254.13`. The design pins it in config (`QbXml:Version`) — good — but the *value* still has to be right for that box.

**How to avoid:**
- **Open item (already in design §11): confirm the exact QB Enterprise year/build on `10.120.254.13` first**, then set `QbXml:Version` to the highest version that build supports (use `QBXMLRP2.QBXMLVersionsForSession` at startup to enumerate what the live session actually accepts, and log it / expose it in `/api/health`).
- `QbXmlBuilder` must emit the processing instruction from config on *every* request, and `QbXmlParser` must hard-fail (not silently continue) on a version/parse error.
- Add a startup self-check: open a session, call `QBXMLVersionsForSession`, assert `QbXml:Version` is in the list, refuse to serve (or log a loud warning) if not.
- README: "if you upgrade QuickBooks, re-check the supported version list and bump `QbXml:Version`."

**Warning signs:**
All requests fail with version/parse errors after a fresh deploy or a QB upgrade; `QBXMLVersionsForSession` doesn't contain your configured version; `*Mod` requests using fields that "should" exist get ignored.

**Phase to address:** P1 (`QbXmlBuilder` always emits PI; parser hard-fails), P2 (startup version self-check via `QBXMLVersionsForSession`), P6 (verify QB year, README).

---

### Pitfall 8: QuickBooks auto-update silently breaks the integration (version mismatch / re-prompt / different binary)

**What goes wrong:**
Everything works for weeks, then one morning every call fails. QuickBooks auto-installed an update overnight: the SDK runtime moved, `QBXMLRP2.dll` got re-registered (or de-registered), the supported qbXML version changed, the integrated-app authorization got reset, or the "company file must be updated" modal is now blocking the UI (`0x80040414`) and won't clear without a human.

**Why it happens:**
QuickBooks Desktop ships automatic updates by default; an unattended box that nobody watches will take them blind. The SDK is tightly coupled to the QB build.

**How to avoid:**
- **Disable automatic updates** on `10.120.254.13` (Help → Update QuickBooks → Options → Automatic Update = No), or at minimum schedule them for known maintenance windows. Document this in the deploy runbook as a required configuration.
- After *any* QB update or QB upgrade, run the post-deploy smoke checklist: health → `QBXMLVersionsForSession` → `company_info` → confirm integrated-app grant still present.
- Watch for the "update company file?" modal — after a QB update the file format may bump and the first open needs a human to click through once; `0x80040414` is the tell.
- `GET /api/health` should report the QuickBooks version it sees; alert/log when it changes unexpectedly.
- Same applies to the **QuickBooks SDK** itself and to Windows updates that re-isolate session 0.

**Warning signs:**
Sudden total failure with no code change on your side; QB version in `/api/health` changed; `0x80040414` after an overnight update; integrated-app list now empty.

**Phase to address:** P6 (disable auto-update in runbook, post-update smoke checklist), P4 (health reports QB version).

---

### Pitfall 9: `Qb:CompanyFilePath` empty ("use the open file") when QuickBooks isn't running

**What goes wrong:**
Config has `Qb:CompanyFilePath = ""` (rely on whatever's open). Works while a human has the file open. Then nobody's logged in, QuickBooks isn't running, the SDK launches it — but with no file path it doesn't know *which* `.QBW` to open → `0x80040416` ("BeginSession must include the company file name when QuickBooks is not running"). Or worse: a *different* company file gets opened than intended.

**Why it happens:**
"Use the open file" is the convenient dev-time setting; it's a footgun in unattended mode where there is no "open file."

**How to avoid:**
- For the unattended deployment, **set `Qb:CompanyFilePath` to the full UNC/local path of the `.QBW`** — don't leave it empty. The design lists `""` as an option; the README must say "for unattended mode this MUST be set."
- Validate at startup that the path exists and is readable by `svc_qbsdk`; refuse to start (or loudly warn) otherwise.
- Map `0x80040416` in `QbErrors` to "set `Qb:CompanyFilePath`."
- If the file is on a network share, ensure `svc_qbsdk` has share + NTFS permissions and that the path is consistent (drive letters mapped per-user won't exist in session 0 — use UNC).

**Warning signs:**
`0x80040416` only when QB wasn't already running; integration works during business hours, fails after-hours; a surprise company file opens.

**Phase to address:** P6 (config + README + startup validation), P1 (`QbErrors` mapping).

---

## Moderate Pitfalls

### Pitfall 10: Iterator / `MaxReturned` mishandling → silently truncated lists and reports

**What goes wrong:**
A `list_invoices` / `list_customers` call returns the first ~30 rows and the code treats that as the complete set, because QuickBooks capped the response or the request used `MaxReturned` without looping the iterator. Downstream analysis is wrong and nobody notices — the response *looked* successful (`statusCode=0`).

**Why it happens:**
qbXML query responses are paginated via `iteratorID` / `iteratorRemainingCount`; large responses can also be rejected outright for size. Naive code sends one query and stops.

**How to avoid:**
- Every list/query op in `QbXmlBuilder` must use the iterator pattern: first request `iterator="Start"` with a sane `MaxReturned`; loop on `iteratorRemainingCount > 0` re-issuing with `iterator="Continue"` and the returned `iteratorID`; stop at zero. `QbXmlParser` must expose `iteratorRemainingCount` so the op layer knows it's incomplete.
- Never return a partial list to the caller without an explicit `truncated: true` / `total` indicator. Default behavior = fully drain the iterator.
- Re-issuing against an *expired* iterator errors — handle that as "restart the query," not "fail."
- Unit-test the parser against a multi-page sample (`iteratorRemainingCount` > 0 then = 0).

**Prevention phase:** P3 (reads — iterator loop in builder, parser exposes remaining count, op layer drains or flags).

---

### Pitfall 11: Report queries return untyped `ColData` / `RowData` — fragile positional parsing

**What goes wrong:**
`ProfitAndLoss` / `BalanceSheet` / `AgingAR` / `AgingAP` responses come back as `<ReportData>` with `<DataRow>`/`<TextRow>`/`<SubtotalRow>`/`<TotalRow>` containing `<ColData colID="N" value="..."/>` — *positional*, weakly-typed, with column meaning defined by a separate `<ColDesc>` block, and layout that shifts with date range, account count, and report options. Code that assumes "column 1 is the label, column 2 is the amount" breaks the moment the report shape changes (comparison columns, % columns, multi-period).

**Why it happens:**
Report responses are fundamentally different from list responses — they're rendered tabular output, not entities. Devs parse them like lists.

**How to avoid:**
- `QbXmlParser` for reports must read `<ColDesc>` first to learn what each `colID` means, then map `<ColData>` by `colID`, never by ordinal position.
- Pin report *options* in the request (no comparison columns, single period, specific summarize-by) so the column set is deterministic for v1; expand later if needed.
- Return both the parsed JSON *and* the raw qbXML (the design already does this) so the caller can fall back to raw when the parse is uncertain.
- Distinguish `DataRow` vs `SubtotalRow` vs `TotalRow` vs `TextRow` in the JSON — collapsing them loses the hierarchy.
- Golden-file tests with real sample report XML, including one with subtotals and one with an unusual date macro.

**Prevention phase:** P3 (reads — ColDesc-driven report parser, pinned report options, golden-file tests).

---

### Pitfall 12: `QBW.exe` process leaks / QuickBooks left running forever

**What goes wrong:**
The service launched QuickBooks (or the SDK did) but never properly `EndSession`/`CloseConnection`/`ReleaseComObject`, so `QBW.exe` lingers in session 0, eats RAM, holds a lock on the company file, and eventually a *new* launch attempt conflicts with the zombie → `0x8004040A` / `0x80040401`. Over days the box accumulates dead QB processes.

**Why it happens:**
COM cleanup is easy to skip on the error path; an exception between `BeginSession` and `EndSession` leaves the session dangling, and a leaked RCW prevents the QB process from exiting.

**How to avoid:**
- Strict `try/finally`: `EndSession` then `CloseConnection` then `Marshal.FinalReleaseComObject` on every path, including exceptions and timeouts.
- On service shutdown, tear the session down cleanly; on service start, detect a pre-existing `QBW.exe` and decide policy (reuse vs. kill — usually reuse if it's `svc_qbsdk`'s and the right file).
- Health endpoint can report whether a QB process is running and how long the current session has been open.

**Prevention phase:** P2 (session lifecycle — finally-cleanup, RCW release, shutdown teardown).

---

### Pitfall 13: Stale `EditSequence` on `*Mod`, and `TxnID`/`ListID` vs `RefNumber` confusion

**What goes wrong:**
A `mod_invoice` fails with `3200` ("the provided edit sequence is out-of-date") because the object was changed in QuickBooks between the read and the write. Or a write targets the wrong record because the caller passed a human-facing `RefNumber` (which is *not* unique and *not* the SDK's key) where a `TxnID` was needed — or passed a `TxnID` where a `ListID` was needed. Worst case: a `mod_*` silently overwrites fields the caller didn't intend because they sent a partial object.

**Why it happens:**
qbXML's optimistic-concurrency model requires you to re-fetch the object, take its *current* `EditSequence`, and submit the `Mod` immediately. `RefNumber` is a user-editable label; `TxnID` (transactions) and `ListID` (list entities) are the immutable keys. Devs conflate them.

**How to avoid:**
- `mod_*` ops must **always do a fresh query** (by `TxnID`/`ListID`) immediately before the `Mod`, lift the live `EditSequence`, and include it in the `Mod` request — never cache an `EditSequence` from an earlier call.
- API contract: `mod_*` takes `TxnID` (or `ListID`), *not* `RefNumber`. `get_transaction` may accept `RefNumber` for convenience but must resolve it to a `TxnID` (and error if `RefNumber` is ambiguous).
- On `3200` (stale edit sequence), return it verbatim (the design says: never auto-retry/fix-up — honor that) and let the skill re-dry-run.
- The dry-run output must show exactly which fields the `Mod` will set, so a partial-object overwrite is visible before it happens.
- Document `TxnID` vs `RefNumber` vs `ListID` in the qbXML cheatsheet.

**Prevention phase:** P5 (writes — fresh-fetch-then-Mod, key discipline, dry-run shows fields), P3 (`get_transaction` resolves RefNumber→TxnID).

---

### Pitfall 14: REST-layer security shortcuts — plaintext bearer token, HTTP, no audit, writes-on-by-default

**What goes wrong:**
The bearer token sits in `appsettings.json` in plaintext readable by anyone on the box; or the bind is HTTP (or HTTPS with TLS verification disabled on the client and the cert never rotated) so the token crosses the LAN sniffable; or `Safety:AllowWrites` ships `true`; or there's no audit trail so a bad write can't be traced. This is an accounting system — a leaked token = someone can read the books and (if writes are on) create checks/journal entries.

**Why it happens:**
LAN-only deployments breed "it's internal, it's fine" thinking. The design already mitigates most of this — the risk is regression during implementation.

**How to avoid (mostly enforcing the existing design):**
- `Safety:AllowWrites` **defaults to `false`**; the 403 path (for `create_*`, `mod_*`, *and* raw qbXML containing `Add`/`Mod`/`Del`/`Void`) must be unit-tested so a refactor can't quietly flip it. Detecting write-intent in raw qbXML needs real parsing, not a substring check (a `Mod` could be nested; `<Add...Rq>` element-name match, not `"Add"` text match).
- Token: long random value, in the gitignored `appsettings.json` only; `appsettings.sample.json` has a placeholder; `.env` for the client is gitignored too. Consider DPAPI/`dotnet user-secrets`/env-var injection rather than plaintext if the box's threat model warrants it — at minimum NTFS-restrict the file to `svc_qbsdk` + admins.
- HTTPS only; `make-cert.ps1` produces the cert; document cert expiry/rotation. `QB_VERIFY_TLS=false` on the client is acceptable for the self-signed case but the README should explain the trade-off and offer pinning the cert instead.
- Constant-time token comparison (avoid timing oracle); reject missing/empty `Authorization` with 401 (don't treat empty == empty as a match).
- **Immutable audit log** for every executed write: timestamp, op, args, qbXML sent, response `statusCode`/`statusSeverity`/`statusMessage`, token id. Append-only file with restrictive ACLs; rotate without rewriting; ideally hash-chain entries so tampering is detectable. Also log *attempted-but-403'd* writes.
- Size-guard `POST /api/qbxml` and the report responses (already in design) so a giant payload can't OOM the service.
- Rate-limit / at least log auth failures.

**Prevention phase:** P4 (HTTPS, token handling, 401, size guards), P5 (audit log immutability + hash chain, 403 write-gate with real qbXML parsing, log 403'd attempts), P6 (cert rotation in README, NTFS ACLs on config + audit log).

---

## Minor Pitfalls

### Pitfall 15: `qbsdklog.txt` ignored / not located
The SDK writes a diagnostic log (`qbsdklog.txt`, typically under the QuickBooks `Intuit` ProgramData/AppData path of the running user) that explains most failures `0x80040402` won't. **Prevention:** README documents where it lives for `svc_qbsdk`, and `/api/health` or a log statement points to it on error. **Phase:** P6 (README), P2 (point to it on COM error).

### Pitfall 16: Date macros and date ranges in reports interpreted differently than expected
`ThisFiscalYear`, `LastMonth`, etc. resolve relative to the company file's fiscal-year setting and QuickBooks' clock — not the caller's. An explicit `FromReportDate`/`ToReportDate` is more predictable. **Prevention:** support both, default ops to explicit dates, document the macro semantics in the cheatsheet. **Phase:** P3.

### Pitfall 17: Amount/quantity formatting and rounding in qbXML
qbXML wants amounts as plain decimal strings with a specific precision; locale-formatted numbers (commas, currency symbols) get rejected or misread, and naive `double` math introduces rounding errors that QuickBooks then rejects on a journal entry that doesn't balance. **Prevention:** `QbXmlBuilder` formats all monetary values with `decimal` + invariant culture + fixed precision; never `double`; assert debits == credits before sending a journal entry. **Phase:** P5 (and P1 builder tests).

### Pitfall 18: `appsettings.json` / `.env` accidentally committed
Real config holds the bearer token and the company-file path. **Prevention:** `.gitignore` entries committed *before* the real files exist; only `*.sample` versions tracked; a pre-commit check or CI guard. **Phase:** P1 (repo hygiene from the start), P6 (verify on deploy).

### Pitfall 19: Health check that lies — returns 200 without actually touching QuickBooks
A `GET /api/health` that only checks "is the web host up" reports green while QuickBooks is dead. **Prevention:** health does a lightweight real SDK call (e.g. cached `company_info` or `QBXMLVersionsForSession`) or at least reports the last successful-call timestamp and last error; degrade to `503` when the session is known-bad. **Phase:** P4.

### Pitfall 20: Time zone / clock skew between workstation and QB host in the audit log
Audit timestamps in local time of one box vs the other make forensic reconstruction painful. **Prevention:** log UTC (ISO-8601 with offset) everywhere. **Phase:** P5.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Run the service as `LocalSystem` instead of `svc_qbsdk` | Skip creating/licensing a service account | Integrated-app auth (bound to a user) won't apply → `0x80040420` forever; session-0 COM even more fragile | **Never** for this design |
| Leave `Qb:CompanyFilePath` empty ("use open file") | Less config | Breaks the moment QB isn't already running (`0x80040416`); risk of wrong file | Only on a dev box where a human always has the file open |
| Single eternal SDK session, no per-request teardown | Marginally less overhead | Stale-ticket failures (`0x8004040D`) after any QB restart/update; harder reconnect logic | Acceptable *if* "any COM error ⇒ rebuild COM + reconnect, one retry" is rock-solid |
| Substring-match raw qbXML for "Add/Mod/Del" to enforce the write-gate | Quick to write | False negatives (nested `Mod`) and false positives ("Address" contains "Add") → either unsafe or annoying | Never — parse the qbXML element names |
| Parse report `ColData` by ordinal position | Works for the one report you tested | Breaks on any report-option/date-range change | Never — read `ColDesc` |
| Plaintext bearer token in `appsettings.json` with default ACLs | Simplest config | Anyone on the box (or with the backup) reads the token; accounting data exposure | Acceptable *only* with NTFS ACLs restricting the file to `svc_qbsdk` + admins; prefer secret-store/env-var |
| `QB_VERIFY_TLS=false` on the client | No CA setup | MITM on the LAN can steal the token | OK short-term with self-signed cert; pin the cert ASAP |
| Skip the audit log for `mod_*` because "it's like create" | Less code | No trail for the highest-risk operation | Never |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `QBXMLRP2.RequestProcessor` COM | Created/used on ASP.NET thread-pool (MTA) threads | Dedicated long-lived **STA** worker thread; all COM on it; `FinalReleaseComObject` on teardown |
| `QBXMLRP2.dll` (32-bit) | AnyCPU/x64 publish → `BadImageFormatException` / `Class not registered` | Publish/run the service as **x86** |
| Company file access | Assuming single-user is fine | File must be **hosted multi-user** (Database Server Manager); set `OpenMode=DoNotCare` |
| Integrated-app authorization | Granted as the wrong Windows user, or "prompt each time", or `AppID`/`AppName` later changed | Grant as **QB Admin in single-user mode**, bound to `svc_qbsdk`, with **"login automatically"**; never change `AppID`/`AppName` |
| qbXML version | Hardcoded/copied version higher than the installed QB supports | Pin in config; verify against `QBXMLVersionsForSession` at startup |
| QuickBooks auto-update | Left on; updates break the SDK overnight | Disable auto-update on the host; smoke-test after any QB change |
| List/report queries | One request, treat as complete | Drive the **iterator** to exhaustion; flag/expose truncation |
| `*Mod` requests | Cached `EditSequence` | Fresh query → live `EditSequence` → immediate `Mod` |
| Transaction identity | Passing `RefNumber` as the key | Use `TxnID` (txns) / `ListID` (lists); resolve `RefNumber` only as a lookup |
| Windows session 0 | Test interactively, deploy as service, assume parity | Test **logged-out**; ship `run-as-task.ps1`; wrapper-agnostic binary |
| Modal dialogs in QB UI (`0x80040414`) | Nobody watches the box; a dialog wedges everything | Disable popups/update prompts; watchdog timeout tears the session down; alert on `0x80040414` |
| Network paths in session 0 | Mapped drive letters in config | Use UNC paths; `svc_qbsdk` needs share+NTFS rights |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Pulling a huge `list_invoices` / report without iterators | Time-outs, data-overflow errors, or silent truncation at ~30 rows | Iterator loop with bounded `MaxReturned`; size-guard responses | As soon as the company file has more than a trivial number of records |
| Serialized queue + one slow report blocking health/everything | `409 Busy`, health flapping, skill timeouts | Watchdog timeout per call; consider a separate fast path for `/api/health` that doesn't queue behind a big report | Whenever a long report and another call overlap |
| Re-opening a full `BeginSession`/launch per tiny request | Each call adds QB launch/session overhead if QB keeps exiting | Keep `OpenConnection2` open at startup; keep QB process warm; per-*request* `BeginSession` is fine, per-request *process launch* is not | Under any sustained call rate if QB isn't kept running |
| Leaked RCWs keeping `QBW.exe` alive across many requests | RAM creep, eventual file-lock conflicts (`0x8004040A`) | `FinalReleaseComObject` in `finally`; monitor `QBW.exe` count | Over days/weeks of uptime |
| Returning megabyte raw-qbXML report bodies over the REST API | Slow responses, client memory spikes | Size threshold → write raw to a file beside the audit log, return a reference + parsed summary (already in design) | Large P&L/Balance Sheet with many accounts |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Bearer token in plaintext `appsettings.json` with default ACLs | Anyone on the box or with a file backup gets full API access (reads + writes if enabled) | NTFS-restrict to `svc_qbsdk`+admins; prefer DPAPI/secret-store/env-var; long random token |
| HTTP bind, or HTTPS with the cert never rotated and client `VERIFY_TLS=false` permanently | Token sniffable / MITM on the LAN | HTTPS only; rotate cert; pin the cert on the client instead of disabling verification |
| `Safety:AllowWrites=true` shipped, or write-gate that misses nested `Mod`/`Add` in raw qbXML | Unauthorized creation/modification of checks, invoices, journal entries | Default `false`; element-name-aware qbXML parsing for the gate; unit-test the 403 path |
| No audit log, or audit log mutable / no ACLs / no integrity | Can't trace a bad or fraudulent write; insider can erase their tracks | Append-only, restrictive ACLs, hash-chained entries, UTC timestamps, log token id; log 403'd attempts too |
| Timing-unsafe token comparison; empty `Authorization` treated as a match | Token brute-force / auth bypass | Constant-time compare; reject empty/missing with 401 |
| Verbose error responses leaking the company-file path / internal details to any caller | Recon for an attacker on the LAN | Surface the mapped HRESULT message and `status*` from QB; don't echo full file paths/stack traces to unauthenticated-ish callers |
| No size guard on `POST /api/qbxml` | DoS / OOM the service with a giant payload | Reject over a configured size before processing |

## "Looks Done But Isn't" Checklist

- [ ] **Unattended mode:** Verified by **logging out of `10.120.254.13` entirely and reproducing a `company_info` call from the workstation** — not just "works on the box while I'm RDP'd in."
- [ ] **Integrated-app auth:** The integrated-apps list in QuickBooks shows the app with access = "login automatically", bound to `svc_qbsdk`, and the service runs as that exact account.
- [ ] **Multi-user hosting:** `.ND` file exists beside the `.QBW`; Database Server Manager is running; a human can have the file open while the service works.
- [ ] **qbXML version:** `QbXml:Version` is confirmed present in `QBXMLVersionsForSession` on the live box; startup self-check logs it.
- [ ] **Bitness:** Service publishes/runs as x86 and successfully `CoCreateInstance`s `QBXMLRP2.RequestProcessor` on the host.
- [ ] **Threading:** All COM calls demonstrably run on one STA thread; concurrent REST calls serialize (test with two simultaneous requests).
- [ ] **Reconnect:** Kill `QBW.exe` mid-life; next request rebuilds the COM object + re-`BeginSession`s and succeeds (one retry), not just errors.
- [ ] **Iterators:** A list op against a company file with > `MaxReturned` records returns the *full* set (or an explicit `truncated` flag), not the first page.
- [ ] **Report parser:** Parses by `ColDesc`/`colID`, verified against a report XML with subtotals and a comparison-period variant.
- [ ] **Write-gate:** With `AllowWrites=false`, `create_*`, `mod_*`, *and* a raw qbXML body containing an `Add`/`Mod`/`Del`/`Void` request all return 403; unit-tested.
- [ ] **Dry-run:** `POST /api/ops/{op}/dryrun` returns the exact qbXML + plain-English summary and does **not** touch QuickBooks (verified by checking nothing changed / no audit row).
- [ ] **EditSequence:** A `mod_*` re-fetches and uses the live `EditSequence`; a deliberately stale one yields `3200` returned verbatim, not a silent retry.
- [ ] **Audit log:** Every executed write produces a row with qbXML sent + `status*` + token id; the file is append-only with restricted ACLs; 403'd attempts are also logged.
- [ ] **Error mapping:** Every HRESULT in the Pitfall 4 table maps to a friendly message + operator action; `QbErrors` has a unit test per code; `/api/health.lastError` shows the mapped text.
- [ ] **Config hygiene:** Only `*.sample` config is committed; real `appsettings.json` / `.env` are gitignored; no IP/path/token literals in source.
- [ ] **Auto-update:** QuickBooks automatic update is disabled (or windowed) on the host; documented in the runbook.
- [ ] **README runbook:** Covers the HRESULT table, the `register-integrated-app.md` pointer, multi-user hosting requirement, qbXML-version-after-upgrade note, `qbsdklog.txt` location, cert rotation, and the QBWC fallback note.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Session-0 instability discovered post-deploy | MEDIUM | Switch launch from Windows service to `run-as-task.ps1` (startup scheduled task under `svc_qbsdk`); if still flaky, autologon-then-lock or a session-keeper; binary unchanged |
| Integrated-app auth wrong/revoked (`0x80040420`/`0x8004041A`) | LOW | Stop service → QB Admin, single-user mode → re-run `register-integrated-app.md` (run the binary, grant cert, set "login automatically", bind `svc_qbsdk`) → restart |
| File stuck single-user / hosting off (`0x80040410`/`0x80040422`) | LOW–MEDIUM | Enable Database Server Manager hosting + "Host Multi-User Access"; ensure no human has it single-user; restart service |
| qbXML version wrong after QB upgrade | LOW | Re-run `QBXMLVersionsForSession`; set `QbXml:Version` to a supported value; restart |
| QuickBooks auto-updated and broke things | MEDIUM | Run post-update smoke checklist; re-register integrated app if the list was wiped; clear any "update company file?" modal; disable auto-update going forward |
| `QBW.exe` zombie holding the file (`0x8004040A`/`0x80040401`) | LOW | Confirm it's `svc_qbsdk`'s zombie, kill it, restart the service (which re-launches QB cleanly) |
| Stale `EditSequence` (`3200`) on a write | LOW | Re-run the dry-run (fresh fetch picks up the new `EditSequence`), re-confirm, resubmit |
| Truncated list/report shipped to callers before iterator fix | LOW–MEDIUM (code) / variable (data) | Add the iterator loop; re-pull anything that mattered; add the `truncated` flag so it can't recur silently |
| Token leaked (committed config, sniffed over HTTP, etc.) | MEDIUM | Rotate `Auth:ApiToken` + every client `.env`; review audit log for unexpected writes; switch to HTTPS / restrict file ACLs; if writes were on, reconcile the books |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Session-0 / unattended service | P2 (wrapper-agnostic, threading) + P6 (deploy ladder, `run-as-task.ps1`) | Logged-out smoke test reproduces `company_info` from the workstation |
| 2. Integrated-app authorization dance | P6 (`register-integrated-app.md`, install scripts enforce `svc_qbsdk`) + P1/P4 (`QbErrors`/health surface `0x80040420`/`0x8004041A`) | QB integrated-apps list shows "login automatically" bound to `svc_qbsdk`; service runs as that account |
| 3. Single-user vs multi-user conflict | P6 (verify multi-user hosting prerequisite, README) + P1/P2 (`QbErrors` mapping, health reports mode) | `.ND` file present; human + service both access the file concurrently |
| 4. Opaque HRESULT family | P1 (`QbErrors` + per-code tests) + P4 (health shows mapped text) + P6 (README table) | `QbErrors` test suite covers every code in the table |
| 5. 32/64-bit + STA threading | P2 (STA worker thread, x86 target, RCW release) | x86 publish `CoCreateInstance`s on the host; two concurrent requests serialize |
| 6. Eternal session / concurrency | P2 (serialized worker, per-request session, watchdog, reconnect rebuilds COM) | Kill `QBW.exe`; next request recovers; concurrent caller gets `409 Busy` |
| 7. qbXML version PI wrong/missing | P1 (builder always emits PI; parser hard-fails) + P2 (startup `QBXMLVersionsForSession` check) + P6 (verify QB year) | Startup log shows configured version ∈ supported list |
| 8. QB auto-update breakage | P6 (disable auto-update in runbook, post-update smoke checklist) + P4 (health reports QB version) | Auto-update confirmed off; smoke checklist exists |
| 9. Empty `Qb:CompanyFilePath` unattended | P6 (config + README + startup validation) + P1 (`QbErrors` for `0x80040416`) | Service refuses to start with empty path when intended for unattended; UNC path used |
| 10. Iterator/`MaxReturned` truncation | P3 (iterator loop, parser exposes remaining count, op drains/flags) | List op on a large file returns the full set or `truncated:true` |
| 11. Untyped `ColData` report parsing | P3 (ColDesc-driven parser, pinned report options, golden-file tests) | Parser handles a report XML with subtotals + comparison columns |
| 12. `QBW.exe` / RCW leaks | P2 (finally-cleanup, `FinalReleaseComObject`, shutdown teardown) | `QBW.exe` count stable over a long-running test |
| 13. Stale `EditSequence` / `TxnID` vs `RefNumber` | P5 (fresh-fetch-then-Mod, key discipline, dry-run shows fields) + P3 (`get_transaction` resolves RefNumber→TxnID) | Stale `EditSequence` yields `3200` returned verbatim; `mod_*` rejects `RefNumber` as key |
| 14. REST-layer security shortcuts | P4 (HTTPS, token handling, 401, size guards) + P5 (audit immutability + hash chain, 403 write-gate with real parsing) + P6 (cert rotation, ACLs) | 403-path unit-tested incl. nested `Mod` in raw qbXML; audit rows present + tamper-evident |
| 15. `qbsdklog.txt` ignored | P6 (README) + P2 (point to it on COM error) | README documents the path for `svc_qbsdk` |
| 16. Date macro semantics | P3 (support explicit dates, default to them, document macros) | Report ops default to explicit `From/ToReportDate` |
| 17. Amount/quantity formatting | P5 + P1 (builder uses `decimal`/invariant culture/fixed precision; assert JE balances) | Builder golden-file tests include money values; JE balance assertion |
| 18. Config accidentally committed | P1 (gitignore before real files; CI guard) + P6 (verify on deploy) | `git status` clean of `appsettings.json`/`.env`; only `*.sample` tracked |
| 19. Lying health check | P4 (health does a real lightweight SDK call / reports last-success + last-error, degrades to 503) | Health goes red when the session is known-bad |
| 20. Audit timestamp time zone | P5 (UTC ISO-8601 everywhere) | Audit rows use UTC with offset |

## Sources

- Intuit QuickBooks Desktop SDK — "Connections, sessions and authorizations" (https://developer.intuit.com/app/developer/qbdesktop/docs/develop/connections-sessions-and-authorizations) — integrated-app authorization model, auto-login / batch mode (HIGH; page rendered thin via WebFetch but corroborated by the error tables below)
- Intuit QuickBooks SDK "Tips and techniques" (https://developer.intuit.com/app/developer/qbdesktop/docs/develop/tutorials/tips-and-techniques) — iterators, `QBXMLVersionsForSession`, modal-dialog gotcha (MEDIUM-HIGH)
- QODBC QBXML / SDK error-code tables (https://qodbc.com/qbxml-error-codes/ and https://qodbc.com/qbxmlerrorcodes/) — meanings of `0x80040401`, `0x80040402`, `0x80040408`, `0x8004040A`, `0x8004040D`, `0x80040410`, `0x80040414`, `0x80040416`, `0x8004041A`, `0x80040420`, `0x80040421`, `0x80040422` (HIGH — cross-checked against the Intuit-derived "Status codes in response messages" PDF and ConsoliBYTE wiki)
- ConsoliBYTE wiki — QuickBooks error codes & qbXML iterator/customer-query examples (http://wiki.consolibyte.com/wiki/doku.php/quickbooks_error_codes ; http://www.consolibyte.com/wiki/doku.php/quickbooks_qbxml_customerquery_with_iterators) — iterator pattern, `MaxReturned`, `iteratorRemainingCount`, error-code corroboration (MEDIUM-HIGH, long-standing community reference)
- ConneXEcommerce / ConsoliBYTE forums — "Unable to cast COM object ... RequestProcessor2", "Cannot create QBXMLRP2 COM component" (https://help.connexecommerce.com/hc/unable-to-cast-com-object-of-type-system.__comobject-to-interface-type-interop.qbxmlrp2.requestprocessor2 ; http://consolibyte.com/forum/viewtopic.php?id=8107) — DLL-registration / bitness / interop failures (MEDIUM)
- Intuit Developer community — "Is there a way to achieve unattended/automated login to QuickBooks Desktop" (https://help.developer.intuit.com/s/question/0D54R00009O1Id3SAF/) — unattended-mode constraints (MEDIUM)
- Intuit QuickBooks SDK Release Notes (14.0, 13.0) (https://static.developer.intuit.com/resources/ReleaseNotes_QBXMLSDK_14_0.pdf) — qbXML version history, headless/auto-login support evolution (MEDIUM-HIGH)
- Project design spec: `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md` (the system under analysis)
- Practitioner knowledge of Windows session-0 isolation, STA/MTA COM apartment rules, and ASP.NET Core hosting (HIGH on the general mechanics; the *specific* QB-in-session-0 behavior is build-dependent — flagged MEDIUM-HIGH)

---
*Pitfalls research for: unattended QuickBooks Desktop / QBXMLRP2 / qbXML COM integration behind a bearer-auth HTTPS REST service*
*Researched: 2026-05-11*
