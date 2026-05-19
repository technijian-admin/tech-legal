# QbConnectService Deploy Runbook

`QbConnectService` is the HTTPS-only, direct-SDK QuickBooks Enterprise REST bridge that runs on the QuickBooks host `10.120.254.13`.

## What this is

- Host OS: Windows Server or Windows 10+ on the QuickBooks host.
- Runtime: the normal deploy path is a self-contained x86 single-file publish, so the host does not need .NET 8 preinstalled.
- Alternative only: you can publish framework-dependent and install the ASP.NET Core 8 Hosting Bundle, but that is not the primary path documented here.
- QuickBooks: QuickBooks Desktop Enterprise, a real `.QBW`, and QuickBooks Database Server Manager hosting that file in multi-user mode.
- COM layer: `QBXMLRP2.RequestProcessor` ships with QuickBooks; install the QuickBooks SDK on the host as well for `tlbimp`, the OnScreen Reference, and `qbsdklog.txt`.
- Service account: create a local `svc_qbsdk` account, set its password, grant `Log on as a service`, give it read access to the `.QBW` and the `.pfx`, and log into Windows as that account at least once so its profile and QuickBooks per-user state exist.

`install-service.ps1` grants `Log on as a service` through `secedit`. The manual fallback is `secpol.msc -> Local Policies -> User Rights Assignment -> Log on as a service`.

## Install order

1. Open an elevated PowerShell session on `10.120.254.13`.
2. Change into the deploy folder:

   ```powershell
   Set-Location quickbooks\QbConnectService\deploy
   ```

3. Generate the HTTPS certificate:

   ```powershell
   .\make-cert.ps1 -DnsName 10.120.254.13 -TrustLocally
   ```

4. Copy the sample config and fill in the real host values:

   ```powershell
   Copy-Item ..\src\QbConnectService\appsettings.sample.json .\appsettings.json
   ```

5. Edit `appsettings.json` with the real host values:
   `Auth:ApiToken` should be a long random bearer token.
   `Qb:CompanyFilePath` must be the full path or UNC path of the `.QBW`.
   `Qb:AppId` should be the stable GUID/string described in [docs/register-integrated-app.md](docs/register-integrated-app.md).
   `Server:CertPath` and `Server:CertPassword` must point at the `.pfx` from `make-cert.ps1`.
   `Audit:Path` should be something like `C:\ProgramData\QbConnectService\audit`.
   `QbXml:Version` should be confirmed against `GET /api/health -> qbXmlVersionsSupported`; the sample defaults to `16.0`.
   `Safety:AllowWrites` should stay `false` until the single low-stakes smoke write, then be turned back off.
6. Install the Windows service:

   ```powershell
   .\install-service.ps1
   ```

   This publishes to `C:\Program Files\QbConnectService\`, copies `appsettings.json` and the `.pfx` next to `QbConnectService.exe`, registers the service as `svc_qbsdk`, and configures restart-on-crash.

7. If the normal Windows service path is unstable in session 0, use the documented fallback instead:

   ```powershell
   .\run-as-task.ps1
   ```

   Use that when service startup repeatedly hits `0x80040408`, `0x80040414`, or `0x80040401`, but the same executable works when launched interactively as `svc_qbsdk`.
8. Complete the QuickBooks-side one-time authorization in [docs/register-integrated-app.md](docs/register-integrated-app.md).
9. Start the service or startup task:

   ```powershell
   Start-Service QbConnectService
   ```

10. Run the on-box verification in [docs/SMOKE-CHECKLIST.md](docs/SMOKE-CHECKLIST.md).

Keep `appsettings.json` in the same folder as `QbConnectService.exe`. The self-contained host loads configuration relative to the executable directory. The smoke checklist's `GET /api/health` step is the proof that the deployed config loaded correctly because it echoes `companyFile` from `Qb:CompanyFilePath`.

## Firewall

Open the HTTPS port inbound on the LAN only. The default port comes from `Server:BindUrls` and the sample config uses `8443`.

```powershell
New-NetFirewallRule `
  -DisplayName 'QbConnectService HTTPS' `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 8443 `
  -Action Allow `
  -RemoteAddress LocalSubnet
```

Do not expose this service to the public internet.

## QBWC fallback note

If direct COM remains unstable even under the scheduled-task fallback, especially with persistent `0x80040408` or `0x80040414`, the long-term fallback architecture is the classic QuickBooks Web Connector (`QBWC`) polling design: QuickBooks initiates the connection on a timer and the service exposes a SOAP endpoint for it. That is a different transport and is out of scope for v1. The op layer and qbXML engine stay conceptually similar; only the transport changes.

## HRESULT troubleshooting table

These rows are sourced from `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbErrors.cs`.

| HRESULT | Name | Message | Remediation hint |
| --- | --- | --- | --- |
| `0x80040401` | `QB_ACCESS_FAILED` | Could not access QuickBooks (connection attempt failed; the QuickBooks install may be incomplete or broken). | Check QuickBooks is installed/repaired under the service account; check the session-0 setup; see qbsdklog.txt. |
| `0x80040402` | `QB_UNEXPECTED_ERROR` | Unexpected QuickBooks SDK error - see qbsdklog.txt for details. | Pull qbsdklog.txt from the QuickBooks host. |
| `0x80040408` | `QB_COULD_NOT_START` | Could not start QuickBooks (launch failed; install incomplete or session-0 instability). | Pre-launch QuickBooks under the service account; verify the scheduled-task launch path; see qbsdklog.txt. |
| `0x8004040A` | `QB_DIFFERENT_FILE_OPEN` | A different company file is already open on this machine. | **Auto-recovered since d56ddc1**: the service kills QBW.EXE and retries. See "Self-healing QBW lifecycle" below. |
| `0x8004040D` | `QB_INVALID_TICKET` | Invalid or expired session ticket (the session was dropped, e.g. QuickBooks restarted). | Transient - the service rebuilds the connection and retries once automatically. |
| `0x80040410` | `QB_MODE_MISMATCH` | The company file is open in a mode other than the one specified. | A human has the file open single-user; switch the file to multi-user (hosted) mode. |
| `0x80040414` | `QB_MODAL_DIALOG` | A modal dialog is showing in the QuickBooks UI, blocking the SDK. | **Auto-recovered since d56ddc1** if no interactive session is attached. If a human is at the QB Desktop console, the service refuses to kill and returns 409 with a clean hint. |
| `0x80010105` | `RPC_E_SERVERFAULT` | The QuickBooks COM server faulted - typically QBW.EXE is holding a different `.qbw` and cannot switch in-place. | **Auto-recovered since d56ddc1**: kill QBW.EXE and retry. See "Self-healing QBW lifecycle" below. |
| `0x80040416` | `QB_NO_FILE_SPECIFIED` | QuickBooks is not running and BeginSession did not receive a company-file path. | Set `Qb:CompanyFilePath` to the full path of the `.QBW` (UNC if on a share). |
| `0x8004041A` | `QB_NO_PERMISSION` | This application does not have permission to access this company file. | Re-run `register-integrated-app.md` (Admin, single-user mode). |
| `0x80040420` | `QB_ACCESS_DENIED` | The QuickBooks user has denied access (integrated app not authorized / revoked / waiting for permission). | Re-run `register-integrated-app.md`; check the integrated-apps list in QuickBooks. |
| `0x80040421` | `QB_PASSTHROUGH` | Message passed through from QuickBooks. | Read the message text; usually a QuickBooks-side condition. |
| `0x80040422` | `QB_REQUIRES_SINGLE_USER` | This application requires single-user file access mode. | Another app/user shares the file; coordinate access. |
| `0x80040154` | `REGDB_E_CLASSNOTREG` | `QBXMLRP2.RequestProcessor` is not registered (QuickBooks SDK not installed, or a 32/64-bit interop mismatch). | Install the QuickBooks SDK on the host; confirm the service runs as x86; see Phase 9 deploy notes. |
| `0x80040154` | `QB_RP2_CAST_FAILED` | Unable to cast the COM object to RequestProcessor2 (`{detail}`). The `QBXMLRP2` type library is missing or the wrong bitness. | Install/repair the QuickBooks SDK on the host; confirm x86; regenerate `Interop.QBXMLRP2Lib.dll` on the host (Phase 9). |

A non-zero qbXML `statusCode` such as `3200` for a stale `EditSequence`, or the PII-denied `530` family, is not one of these HRESULTs. It rides inside the HTTP 200 `result.status` payload and is not a COM-layer or HTTP-layer failure.

## Audit log

The audit file is `audit.jsonl` under `Audit:Path`.

- Primary verification path:

  ```powershell
  & 'C:\Program Files\QbConnectService\QbConnectService.exe' --verify-audit
  ```

  `--verify-audit` prints `audit chain OK` on success, or `audit chain BROKEN at seq N` and exits non-zero on failure.

- Manual spot-check:

  ```powershell
  Get-Content 'C:\ProgramData\QbConnectService\audit\audit.jsonl' -Tail 5
  ```

  Confirm that `seq` is monotonic and zero-based, the genesis `prevHash` is 64 zeros, and each row's `prevHash` matches the prior row's `hash`.

## Operator follow-ups not done by the build pipeline

- Regenerate the real QuickBooks interop on the host with `tlbimp` and replace the hand-written `Interop/QBXMLRP2Lib.cs` stub.
- Run [docs/SMOKE-CHECKLIST.md](docs/SMOKE-CHECKLIST.md) on `10.120.254.13`.
- Complete the QuickBooks integrated-app authorization in [docs/register-integrated-app.md](docs/register-integrated-app.md).
- Run the live qbXML re-pin procedure in [docs/QBXML-REPIN.md](docs/QBXML-REPIN.md).

## Connection lifecycle (since 2026-05-19)

The service ships three behaviors that together make multi-company unattended use ergonomic and self-healing. All three are on by default and can be tuned via `appsettings.json` `Qb` section.

### 1. Auto-release after each request (commit `63e390d`)

When `Qb:ReleaseAfterEachRequest` is `true` (default), every successful `ExecuteAsync` / `GetSupportedQbXmlVersionsAsync` ends with `EndSession` + `CloseConnection` inside the same gate as the request. The `.qbw` file is released as soon as the work finishes, so a human at the QB Desktop console can close/switch the file without first stopping the service. The next request pays a ~500ms-1s reconnect cost.

Set `Qb:ReleaseAfterEachRequest = false` only if you have a tight request loop where the persistent-session pattern's reconnect-savings matter more than free file access.

### 2. Self-healing QBW lifecycle (commit `d56ddc1`)

QuickBooks Desktop (QBW.EXE) is single-instance and one-file-at-a-time per the Intuit QB SDK 16.0 Programmer's Guide ("Limitations on Accessing Company Files", page 53). The SDK has no "switch file" API. The only documented escape hatch when QBW.EXE is in a stuck state is to terminate the process and let the next BeginSession cold-launch QB Desktop on the requested file.

When `Qb:AutoRecoverFromQbwStuck` is `true` (default), the service catches the three recoverable HRESULTs and self-heals:

| HRESULT | Meaning |
|---|---|
| `0x8004040A` | A different `.qbw` is already loaded - caller asked for a different company |
| `0x80040414` | Modal dialog blocking the QB UI |
| `0x80010105` | COM server faulted (typically same root cause as different-file) |

The recovery sequence:

1. Refuse if `Qb:AbortRecoveryIfInteractiveQbDesktop` is `true` AND any `QBW.EXE` has a visible window (operator is using QB Desktop interactively on the server console). Returns 409 with a remediation hint.
2. Refuse if `Qb:MaxQbwKillsPerMinute` (default `3`) was already hit in the rolling 1-minute window. Returns 503 with a "circuit-broken" hint. Prevents kill-loops.
3. Release the current SDK session (no dangling COM RCWs).
4. Kill every `QBW.EXE` process and poll for exit (up to `Qb:QbwKillExitTimeoutSeconds`, default `10`).
5. Record the kill in the rolling-window tracker.
6. Retry the original request **ONCE**. The retry cold-starts a fresh QB Desktop on the requested file (~30-40s on first call after a kill).
7. If the retry also fails, surface the error verbatim. No third attempt.

Default behaviour gives you transparent cross-company switching out of the box:

```text
POST /api/ops/list_customers                                   # default company, fast
POST /api/ops/list_customers?company=electronic-corp-...       # 30-40s, auto-switch via kill+retry
POST /api/ops/list_customers?company=electronic-corp-...       # fast, same company still loaded
POST /api/ops/list_customers?company=technijian                # 30-40s, auto-switch back
```

### 3. Explicit connection-management endpoints

For cases where the operator wants explicit control:

| Endpoint | Purpose |
|---|---|
| `POST /api/connection/release` | Drop SDK session ticket only. Idempotent. QBW.EXE stays running. Use to free the file for QB Desktop without killing QB. |
| `POST /api/connection/restart-qb` | Drop SDK ticket AND kill all `QBW.EXE`. Idempotent. Returns pre/post snapshot of process counts. Use to force a clean cold-start on the next call. |

Both require bearer auth. Both acquire the manager's gate so they serialize safely against any in-flight request.

### `/api/health` diagnostic fields

The `/api/health` endpoint exposes all the lifecycle state so operators can verify behavior in production:

| Field | Meaning |
|---|---|
| `status` | `healthy` / `degraded` / `down` - derived from probe outcome |
| `lastProbe` | `ok` / `busy` / `failed` - **load-bearing health signal** (use this, not `connectionState`) |
| `connectionState` | `SessionOpen` / `Disconnected` / `Connecting` / `Poisoned` - typically `Disconnected` immediately after auto-release |
| `releaseAfterEachRequest` | Current value of `Qb:ReleaseAfterEachRequest` |
| `autoRecoverFromQbwStuck` | Current value of `Qb:AutoRecoverFromQbwStuck` |
| `qbwProcesses` | Count of `QBW.EXE` processes seen at this moment |
| `qbwInteractiveSession` | `true` if any `QBW.EXE` has a visible window (human attached) |
| `recentQbwKills` | Auto-recovery kill count in the rolling 1-minute window |
| `maxQbwKillsPerMinute` | Current circuit-breaker ceiling |
| `openMode` / `openModeInt` | `Qb:OpenMode` as enum name + int (verifies the config binding actually worked - useful when MultiUser is expected but didn't take effect) |
| `connectionType` / `connectionTypeInt` | Same for `Qb:ConnectionType` |

### Config flags reference

```json
"Qb": {
  "ReleaseAfterEachRequest": true,        // release SDK ticket after each call
  "AutoRecoverFromQbwStuck": true,        // master switch for kill-and-retry recovery
  "AbortRecoveryIfInteractiveQbDesktop": true,   // refuse to kill if human session attached
  "MaxQbwKillsPerMinute": 3,              // circuit breaker ceiling
  "QbwKillExitTimeoutSeconds": 10         // how long to wait for QBW.EXE to exit after Kill()
}
```

### Authoritative SDK reference

The "must kill QBW.EXE to switch files" design is dictated by Intuit's published constraints, NOT a limitation of this service. See `C:\Program Files\Intuit\IDN\QBSDK16.0\doc\pdf\QBSDK_ProGuide.pdf` page 53 ("Limitations on Accessing Company Files"):

> Only one company file at a time can be accessed by integrated applications on any given machine running QuickBooks.

And page 48 ("Multiple Sessions versus a Single Session"):

> If the user of your application often deals with multiple companies as, for example, a professional accountant who manages finances for multiple organizations, your application will probably open a connection and then begin and end several sessions on different company files before finally closing the connection. **Sessions do not overlap.**

Plus the `qbXMLRP2e.idl` shipped in `C:\Program Files\Intuit\IDN\QBSDK16.0\tools\access\QBXMLRP2e\sources\` which is the source-of-truth enum ordering for `QBFileModeE` and `QBXMLRPConnectionTypeE` (the published C-header order is wrong; the IDL is right - see the b14a487 commit message for the gory details).
