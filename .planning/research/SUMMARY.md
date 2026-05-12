# Research Summary — QuickBooks Enterprise Direct-SDK Accounting Integration

**Date:** 2026-05-11
**Inputs:** `STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md` (this folder) + the approved design spec `docs/superpowers/specs/2026-05-11-quickbooks-direct-sdk-accounting-design.md`.
**Bottom line:** the spec's design is sound and current. Research is corroboration + sharpening, not a redesign. Two cheap op additions recommended; the rest is "build it as specified, but defuse these specific landmines."

## Validated stack (one-liner)

.NET 8 LTS (`net8.0-windows`, **x86** — match the 32-bit QB SDK COM), ASP.NET Core on Kestrel (HTTPS-only, file `.pfx` self-signed cert), `Microsoft.Extensions.Hosting.WindowsServices` (`AddWindowsService()` is a no-op when not started by the SCM → one published `.exe` works as console / Windows service / Task-Scheduler fallback). COM kept behind `IRequestProcessor`, with the `tlbimp`-generated `Interop.QBXMLRP2Lib.dll` (pure metadata) referenced only by a separate `Qb.Com` adapter project → solution builds + full test suite runs with **no QuickBooks SDK installed**. qbXML hand-built with `System.Xml.Linq`. Tests: xUnit + `WebApplicationFactory` + NSubstitute (+ optional `Verify.Xunit` golden files); Polly v8 for the one dead-ticket retry; tiny custom bearer-auth middleware (`CryptographicOperations.FixedTimeEquals`), not JwtBearer. Python client: `requests` + `urllib3.Retry` + `python-dotenv`, `pytest` + `responses`, pinned `requirements.txt`. QuickBooks SDK 16.0 is current; qbXML ≤ 16.0 accepted by QB Enterprise 2023/2024 (MEDIUM confidence on exact version numbers — confirm on-box).

## v1 op catalog — verdict: keep as specified

The spec's reads (`company_info`, `report` = P&L/BalanceSheet/AgingAR/AgingAP, `list_customers`/`vendors`/`items`/`accounts`, `list_invoices`/`bills`/`payments`, `get_transaction`) and dry-run-gated writes (`create_customer`/`vendor`/`invoice`/`bill`/`check`, `receive_payment`, `create_journal_entry`, `mod_*`) match what mature qbXML connectors expose. **Two recommended cheap adds (reuse machinery already needed):**
1. **`run_query`** — generic entity query + filters → parsed rows (covers Employee/OtherName/SalesReceipt/Estimate/PO/CreditMemo/Deposit/Class without 15 more wrapped ops or forcing hand-written qbXML).
2. **`get_company_preferences`** — sales-tax on?, decimal places, multi-currency on?, default A/R & A/P accounts — the agent needs these to build *valid* write requests.

**Anti-features confirmed** (spec §10 + two adds): payroll, inventory assemblies, sales-tax filing, multi-currency, bidirectional sync, scheduled jobs — plus batch/mega-request writes (unsafe partial-failure semantics) and first-class Delete/Void ops (destructive → raw-qbXML only).

## Architecture (confirms the spec, one rename)

Components: `IRequestProcessor` (mockable COM seam — *the* load-bearing decision), `RealRequestProcessor` (x86/STA adapter) + `FakeRequestProcessor`; **`QbConnectionManager`** (the spec's `QbSession`, renamed — long-lived singleton owning the lifecycle state machine + a `SemaphoreSlim(1,1)` gate on a dedicated STA worker thread); pure `QbXmlBuilder` / `QbXmlParser` (no I/O → unit-testable on a dev box); `QbErrors` (0x8004xxxx → message + remediation); `AuditLog` (append-only, write path only); three controllers (`/health`, `/qbxml`, `/ops/{op}` + `/ops/{op}/dryrun`) behind bearer-auth middleware; `OpRegistry` (single home for the op catalog). Connection lifecycle: persistent connection+session, lazy-opened, reconnect-on-dead-ticket with **exactly one** retry then fail loudly; `OpenMode = DoNotCare`, `connectionType = localQBD`, never `SingleUser`. Invariant: `statusCode != 0` is a QuickBooks *business* outcome → returned as a normal 200 body; HTTP 4xx/5xx reserved for transport/auth/safety-gate/COM-unavailable. Unattended operation = three must-all-be-true: (1) integrated-app auth with "allow to login automatically" granted by an Admin in single-user mode, **stored in the .QBW**, bound to `svc_qbsdk`; (2) company file hosted multi-user; (3) the service runs as `svc_qbsdk` (never LocalSystem) — plus the session-0 fragility caveat and the mitigation ladder (Windows service → `run-as-task.ps1` startup task → session-keeper).

## Top things to defuse (from PITFALLS.md — 20 items, 9 critical)

1. **Session-0 / no interactive desktop** — QB Desktop COM dies when COM-activated inside a Windows service; first deploy smoke test must be run logged-out; `run-as-task.ps1` is the fallback.
2. **Integrated-app authorization dance** — Admin + single-user mode + bound to `svc_qbsdk` + "login automatically"; `AppID`/`AppName` act as a primary key; `0x80040420`/`0x8004041A` are the tells; PII on the file can force interactive password.
3. **Single-user vs multi-user** — file must be hosted multi-user (`.ND` / Database Server Manager) or SDK and humans fight the lock.
4. **The HRESULT family** — `0x80040401/02/08/0A/0D/10/14/16/1A/20/21/22` enumerated with meanings + operator actions; plus "Class not registered" / "Unable to cast … RequestProcessor2" DLL-registration cases.
5. **32-bit DLL + STA threading** — publish x86; all COM on one dedicated STA worker thread (also gives the required serialization); `FinalReleaseComObject` on teardown. (AnyCPU/x64 → confusing `0x80040154`.)
6. **Eternal session / concurrency** — serialized queue, `409 Busy`, watchdog timeout; reconnect must *rebuild* the COM object, not just re-`BeginSession`.
7. **qbXML version PI** — pin in config but the value must be ≤ the installed build's supported spec; verify via `QBXMLVersionsForSession`/`HostQueryRq` at startup; builder always emits the PI, parser hard-fails on a version error.
8. **QuickBooks auto-update** — disable on the host; it silently moves the SDK / resets the auth grant / pops a blocking modal (`0x80040414`).
9. **Empty `Qb:CompanyFilePath`** — "use the open file" breaks the moment QB isn't running (`0x80040416`); set the full UNC path for unattended.

Moderate/minor: iterator/`MaxReturned` truncation (gates every `list_*` op + the size-guard); untyped `ColData`/`RowData` report parsing (read `ColDesc`, never ordinal — needs a *separate* parser from entity parsers); `*Mod` is full-replace not patch + stale `EditSequence` (`0x800404C5`) is the #1 write failure → read→merge→dry-run→confirm→submit; `TxnID` vs `RefNumber` vs `ListID` confusion; `OwnerID="0"` silently gates custom fields (`DataExtRet` omitted by default); polymorphic Item queries (`ItemServiceRet`/`ItemInventoryRet`/…) → parser normalizes; REST security (plaintext token, HTTP/TLS-off, `AllowWrites` default, write-gate must parse qbXML *element names* not substrings, immutable hash-chained audit log, constant-time token compare, UTC audit timestamps); `qbsdklog.txt`; invariant-culture money formatting; gitignore-before-real-config; no lying health checks.

## Recommended build order (7 phases — "seam → lifecycle → reads → API → writes → client → deploy")

1. **Interface + fakes + pure-core + CI** — `IRequestProcessor`, `FakeRequestProcessor`, project layout, x86 config, xUnit, CI green with no QuickBooks. *(Defuses: build-without-SDK; x86 constraint.)*
2. **`QbConnectionManager` lifecycle** — STA worker thread, `SemaphoreSlim(1,1)`, OpenConnection2/BeginSession/ProcessRequest/EndSession/CloseConnection state machine, reconnect-on-dead-ticket (one retry), `QbErrors` map, `RealRequestProcessor` adapter. *(Defuses: STA/threading; eternal-session; HRESULT family; reconnect.)*
3. **Read pipeline** — `QbXmlBuilder` + `QbXmlParser` (entity parsers + the separate report `ColDesc`/`ColData` parser), iterator handling, all read ops + `run_query` + `get_company_preferences` + `company_info` + `report`, response size-guard/spill-to-file. Tested against the fake. *(Defuses: iterator truncation; report parsing; qbXML version PI.)*
4. **REST API + auth + health** — Kestrel HTTPS, bearer-auth middleware (constant-time), `/api/health` (company file, QB version, SDK version, supported qbXML versions, last error, mode, AllowWrites), `/api/qbxml` raw passthrough (with the element-name verb-scan write-gate), `OpRegistry`, `WebApplicationFactory` integration tests. *(Defuses: REST security; lying health checks.)*
5. **Write ops + dry-run + audit** — `create_*`/`receive_payment`/`create_journal_entry`/`mod_*`; `/api/ops/{op}/dryrun` (byte-exact qbXML + resolved-reference echo + plain-English diff + pre-flight validation, zero side effects, NOT write-gated); `Safety:AllowWrites` default-false 403 gate (controllers + raw passthrough + defensively in the manager); immutable hash-chained `AuditLog`. *(Defuses: stale EditSequence; *Mod full-replace; AllowWrites default; audit immutability.)*
6. **Python client + Claude skill + multi-LLM dev tooling** — `qb_client.py` (requests + Retry + dotenv, dry-run helpers) + examples + `requirements.txt`; `quickbooks-accounting` skill (SKILL.md + references: qbXML cheatsheet, setup/troubleshooting); `quickbooks/dev/MULTI-LLM.md` + `run-codex-phase.ps1` (Claude-plans → Codex-executes → Claude-reviews handoff). pytest + `responses` tests.
7. **Packaging + deploy + live smoke** — `make-cert.ps1`, `install-service.ps1`/`uninstall-service.ps1`, `run-as-task.ps1`, `register-integrated-app.md`, service `README.md`; gitignored `appsettings.json` / `.env` + committed `.sample`s; on-box smoke checklist (health → company_info → report → create_customer dry-run → one real low-stakes write → audit row). *(Defuses: session-0; integrated-app auth; multi-user hosting; auto-update; empty CompanyFilePath. This is the only phase that needs the actual host — flag for environment verification: QB Enterprise year/version, multi-user hosting status, `svc_qbsdk` creatability, firewall port.)*

## Open items (environment-specific, deferred to phases 2 & 7)

- Exact QuickBooks Enterprise build on `10.120.254.13` → pins the qbXML spec ceiling + confirms session-0 behavior + build bitness.
- Whether the `.QBW` is already hosted multi-user.
- Whether PII is enabled on the company file (could block pure unattended mode).
- `RequestProcessor` vs `RequestProcessor2` ProgID; whether `AuthPreferences.PutUnattendedModePref` must be set explicitly on this build.
- `QBXMLRP2.dll` path/bitness before generating the interop DLL; latest-SDK confirmation from on-box release notes.
- `svc_qbsdk` account creation + "log on as a service" rights; firewall path for the HTTPS port.
