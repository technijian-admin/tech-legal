# QuickBooks Enterprise — Direct-SDK Accounting Service & Claude Skill

**Date:** 2026-05-11
**Status:** Design approved (pending written-spec review)
**Repo location:** `tech-legal/quickbooks/` (service + clients) and `tech-legal/.claude/skills/quickbooks-accounting/` (skill)
**QuickBooks host:** `10.120.254.13` (QuickBooks Enterprise, company file hosted multi-user)

## 1. Goal

Give Claude real-time, programmatic access to QuickBooks Enterprise — read reports/lists and create/update transactions — via a small service that talks to QuickBooks Desktop directly through the QuickBooks SDK COM interface (`QBXMLRP2.RequestProcessor`). No QuickBooks Web Connector, no SOAP, no polling, no job queue: requests are synchronous round-trips.

This supersedes an earlier QBWC-polled design (which is retained only as a documented fallback in the service README, not built).

## 2. Architecture

```
┌─────────────────────────────┐         ┌──────────────────────────────────────┐
│  Workstation (repo home,    │  HTTPS  │  10.120.254.13  (QuickBooks server)    │
│  where Claude runs)         │  +Bearer│                                        │
│                             │ ───────▶│  QbConnectService (Windows service)    │
│  .claude/skills/            │         │    ├─ REST API  /api/...               │
│    quickbooks-accounting/   │ ◀─────── │    └─ QbSession ──COM──▶ QBXMLRP2 ──▶  │
│  quickbooks/clients/        │  JSON +  │                          QuickBooks   │
│    qb_client.py             │  raw qbXML│                         Enterprise   │
└─────────────────────────────┘         └──────────────────────────────────────┘
```

- **`QbConnectService`** — ASP.NET Core app, installed as a Windows service on `10.120.254.13`. It:
  - Loads the QuickBooks SDK COM component `QBXMLRP2.RequestProcessor`, opens a connection + session to the company file, and forwards qbXML to QuickBooks in-process.
  - Exposes a **LAN HTTPS REST API with bearer-token auth**.
  - **Serializes** request execution — QuickBooks' SDK session is single-threaded; one qbXML round-trip in flight at a time, with a configurable timeout.
  - Auto-reconnects if QuickBooks restarts or the session drops.
  - Logs every request; every **write** op additionally appends to an immutable audit log.
- **Client side** (travels with the repo): `quickbooks/clients/qb_client.py` (HTTPS client, bearer token, retries) and the `quickbooks-accounting` skill that drives it.

### REST API

| Method & path | Purpose |
|---|---|
| `GET  /api/health` | Liveness + company-file name, QuickBooks version, SDK version, last error, current mode, `AllowWrites` flag. |
| `POST /api/qbxml` | Raw qbXML passthrough → returns raw qbXML response. Size-guarded. Used for anything not yet wrapped as an op. |
| `POST /api/ops/{op}` | High-level operation (see §4). Service validates args, builds qbXML, executes, returns parsed JSON **and** the raw qbXML response. |
| `POST /api/ops/{op}/dryrun` | Same as above but builds and returns the qbXML + a plain-English summary **without executing**. Used by the skill's write-safety workflow. |

Auth: `Authorization: Bearer <token>` on every call; token in service config. No token / wrong token → 401.

## 3. Mode — Unattended (chosen)

The service runs **with nobody logged in** to the QuickBooks server. Requirements:

1. **Integrated-app pre-authorization (one-time, manual, QuickBooks-side):** a QuickBooks **Admin**, in **single-user mode**, opens *Edit → Preferences → Integrated Applications → Company Preferences*, runs the service once so it requests a certificate, and grants it with **"Allow this application to login automatically"** bound to a specific Windows user (call it `svc_qbsdk`). This writes the authorization into the company file.
2. **Company file in multi-user (hosted) mode** so the SDK can open it while humans also have it open. (Single-user mode + a human with the file open → SDK calls fail.)
3. **Service runs as `svc_qbsdk`** — the same Windows user the integrated app was bound to — and QuickBooks Enterprise is installed/licensed for that user.
4. **Open mode `DoNotCare`** in config; when QuickBooks isn't already running, the SDK launches it headless under `svc_qbsdk`.

**Known risk — Windows session 0:** Windows services run in session 0 with no interactive desktop, and QuickBooks Desktop COM has historically been fragile there. The service README documents two mitigations in priority order: (a) configure the integrated app + auto-login correctly so QuickBooks runs truly headless (works on modern QuickBooks SDK 13.0+ in most setups); (b) if that proves unstable, run the same executable via Task Scheduler "at startup" under `svc_qbsdk` (still no interactive logon required for a scheduled task), or under a session-keeper. The service binary is identical in all cases — only the launch wrapper differs.

## 4. Operation catalog (v1)

**Reads:**
- `company_info` — company name, address, fiscal year, QuickBooks edition.
- `report` — `ProfitAndLoss`, `BalanceSheet`, `AgingAR`, `AgingAP`; args: report type, date range (or date macro).
- `list_customers`, `list_vendors`, `list_items`, `list_accounts` — optional active-only / name filter.
- `list_invoices`, `list_bills`, `list_payments` — filter by date range and/or entity (customer/vendor).
- `get_transaction` — by `RefNumber` or `TxnID`.

**Writes (all dry-run-gated, see §5):**
- `create_customer`, `create_vendor`
- `create_invoice`, `create_bill`, `create_check`
- `receive_payment`
- `create_journal_entry`
- `mod_*` — update an existing object via its `TxnID`/`ListID` + `EditSequence`.

**Anything else** → `POST /api/qbxml` with hand-written qbXML.

qbXML spec version is pinned in config (e.g. `16.0`) and sent in the `<?qbxml version="…"?>` processing instruction; `QbXmlBuilder` targets that version.

## 5. Write-safety model

- `Safety:AllowWrites` in service config defaults to **`false`**. While false, the service returns **403** to any write op (`create_*`, `mod_*`, and any `raw` qbXML containing an `Add`/`Mod`/`Del`/`Void` request). It must be deliberately set to `true` to enable writes.
- Even with writes enabled, the **skill's workflow always dry-runs first**: it calls `POST /api/ops/{op}/dryrun`, shows the user the exact qbXML and a plain-English summary, and submits the real `POST /api/ops/{op}` **only after the user explicitly confirms**. No silent auto-apply, ever.
- Every executed write is appended to an **immutable audit log** on the QuickBooks server: timestamp, op, args, qbXML sent, response statusCode/statusSeverity/statusMessage, and the calling token's id.
- QuickBooks errors (stale `EditSequence`, validation failures, locked records, etc.) are returned verbatim to the caller — never silently retried or "fixed up."

## 6. Components & layout

```
tech-legal/
  quickbooks/
    QbConnectService/                 # .NET solution
      QbConnectService.sln
      src/
        QbConnectService/             # ASP.NET Core host
          Program.cs
          Controllers/
            HealthController.cs
            QbXmlController.cs         # POST /api/qbxml
            OpsController.cs           # POST /api/ops/{op}, /api/ops/{op}/dryrun
          Qb/
            QbSession.cs               # wraps RequestProcessor: OpenConnection2 / BeginSession / ProcessRequest / EndSession / CloseConnection; reconnect; serialized
            IRequestProcessor.cs       # thin interface over the COM type, so it can be mocked
            RealRequestProcessor.cs    # adapter over QBXMLRP2.RequestProcessor
            QbXmlBuilder.cs            # one method per op -> qbXML request
            QbXmlParser.cs             # qbXML response -> clean JSON; surfaces status*
            QbErrors.cs                # maps known 0x8004xxxx codes to messages
          Audit/AuditLog.cs            # append-only writer
          appsettings.sample.json      # committed; real appsettings.json gitignored
        QbConnectService.Tests/        # xUnit
      scripts/
        make-cert.ps1                  # self-signed cert for the HTTPS bind
        install-service.ps1            # register Windows service (runs as svc_qbsdk)
        uninstall-service.ps1
        run-as-task.ps1                # fallback: register a startup scheduled task instead
      README.md                        # deploy runbook for the QB server + troubleshooting + QBWC-fallback note
      register-integrated-app.md       # the manual QuickBooks-side authorization steps

    clients/
      qb_client.py                     # HTTPS client, bearer token, retries, dry-run helpers
      examples/                        # small runnable snippets (pull P&L, list invoices, create-customer dry-run)
      .env.sample                      # committed; real .env gitignored
      requirements.txt

  .claude/skills/quickbooks-accounting/
    SKILL.md
    references/
      qbxml-cheatsheet.md              # common qbXML request/response shapes, query filters, pagination
      setup-and-troubleshooting.md     # pointers into quickbooks/QbConnectService/README.md + common failures

  docs/superpowers/specs/
    2026-05-11-quickbooks-direct-sdk-accounting-design.md   # this file
```

### Configuration (all machine-specifics here; both files gitignored, `.sample` versions committed)

`QbConnectService/src/QbConnectService/appsettings.json`:
- `Server:BindUrls` — e.g. `https://10.120.254.13:8443` (HTTPS, LAN IP)
- `Server:CertPath`, `Server:CertPassword` — the self-signed cert from `make-cert.ps1`
- `Auth:ApiToken` — bearer token (random, long)
- `Qb:CompanyFilePath` — full path to the `.QBW`, or `""` to use whatever file is open
- `Qb:OpenMode` — `DoNotCare` | `SingleUser` | `MultiUser` (default `DoNotCare`)
- `Qb:AppId`, `Qb:AppName` — identity shown in QuickBooks' integrated-apps list
- `Safety:AllowWrites` — `false` by default
- `QbXml:Version` — e.g. `16.0`
- `Audit:Path` — path to the append-only audit log
- `Request:TimeoutSeconds` — per-call timeout (default e.g. 120)

`clients/.env`:
- `QB_API_BASE_URL` — e.g. `https://10.120.254.13:8443`
- `QB_API_TOKEN` — matches `Auth:ApiToken`
- `QB_VERIFY_TLS` — `false` if using the self-signed cert without trusting it (else path to the CA/cert)

## 7. Error handling & edge cases

| Situation | Behaviour |
|---|---|
| QuickBooks not running / can't launch | SDK error surfaced (`0x80040401` etc.); `GET /api/health` reports it; README maps common codes. |
| Wrong company file open / file mismatch | `BeginSession` fails; error returned; README covers fixing `Qb:CompanyFilePath`. |
| Integrated app not authorized / auth revoked | `0x80040420` ("waiting for permission") surfaced; README points to `register-integrated-app.md`. |
| File in single-user mode while a human has it open | `BeginSession` fails with a session-mode error; documented fix = host the file multi-user. |
| Concurrent requests | Serialized; later request waits up to a short bound, else returns `409 Busy` with a hint. |
| Very large report response | Size guard; above threshold the raw qbXML is written to a file beside the audit log and the API returns a reference + the parsed summary. |
| QuickBooks restarted mid-session | `QbSession` detects the dead ticket, tears down, re-opens on the next request (one retry). |
| Workstation can't reach the server | Client-side network error surfaced by `qb_client.py`; nothing for the service to do. |
| Session 0 / service-context COM instability | See §3 mitigation ladder; `run-as-task.ps1` is the documented fallback. |

## 8. Testing strategy

- **Unit (xUnit, in `QbConnectService.Tests`):**
  - `QbXmlBuilder` — golden-file tests: `(op, args)` → expected qbXML string, one case per op.
  - `QbXmlParser` — sample qbXML response files → expected JSON; includes error responses (non-zero statusCode).
  - `QbSession` — drive its state machine against a **mock `IRequestProcessor`**: connect → begin → process → end → close; reconnect-on-dead-ticket; serialization (two concurrent calls don't interleave).
  - `QbErrors` — known codes → expected messages.
- **Integration:** boot the ASP.NET Core host with the mock `IRequestProcessor` registered, hit `/api/health`, `/api/qbxml`, `/api/ops/{op}`, `/api/ops/{op}/dryrun` over HTTP; assert responses, the 403 when `AllowWrites=false`, and audit-log rows for executed writes.
- **Python:** `qb_client.py` tested against a stub HTTP server (responses, retries, dry-run helper, bearer-token header).
- **Smoke (manual, against the live QuickBooks server, in this order):** `GET /api/health` → `company_info` → a `report` pull → `create_customer` **dry-run** (inspect the qbXML) → with `AllowWrites=true`, one real low-stakes write (e.g., create a throwaway customer) → verify it in QuickBooks → verify the audit-log row.

## 9. Portability

- The **service** is pinned to wherever QuickBooks Enterprise runs (today `10.120.254.13`); the **client + skill** travel with the `tech-legal` repo and run wherever Claude runs.
- All machine-specifics live only in `appsettings.json` (service) and `clients/.env` (client); both gitignored, both with committed `.sample` versions. No hardcoded IPs/paths/tokens in code.
- **Moving the service to a new QuickBooks server:** copy `tech-legal/quickbooks/QbConnectService/` there → edit `appsettings.json` → `make-cert.ps1` → `install-service.ps1` (or `run-as-task.ps1`) → re-run the `register-integrated-app.md` steps in QuickBooks.
- **Moving the repo / client to a new workstation:** clone the repo → `pip install -r quickbooks/clients/requirements.txt` → copy `.env.sample` → `.env`, set `QB_API_BASE_URL` + `QB_API_TOKEN`. Done.

## 10. Out of scope (v1)

- The QBWC-polled SOAP design (kept only as a README fallback note).
- Payroll, inventory assemblies, sales-tax filing, multi-currency specifics — addable later as new ops.
- A UI. The interfaces are the REST API and the Claude skill; no web front-end.
- Bidirectional sync / scheduled jobs. Every call is initiated by the skill/operator on demand.
- Unattended-mode "session keeper" tooling beyond documenting `run-as-task.ps1`.

## 11. Open items to verify during implementation/deploy

- Exact QuickBooks Enterprise year/version on `10.120.254.13` → confirms the right qbXML spec version and SDK build.
- Whether the company file is already hosted multi-user (required for unattended access alongside human users).
- Confirm a dedicated Windows service account (`svc_qbsdk` or similar) can be created on the QuickBooks server and QuickBooks licensed/launchable under it.
- Confirm the workstation ↔ `10.120.254.13` path allows the chosen HTTPS port through any firewall.
