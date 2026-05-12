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
| `0x8004040A` | `QB_DIFFERENT_FILE_OPEN` | A different company file is already open on this machine. | Close the other company file, or fix `Qb:CompanyFilePath`. |
| `0x8004040D` | `QB_INVALID_TICKET` | Invalid or expired session ticket (the session was dropped, e.g. QuickBooks restarted). | Transient - the service rebuilds the connection and retries once automatically. |
| `0x80040410` | `QB_MODE_MISMATCH` | The company file is open in a mode other than the one specified. | A human has the file open single-user; switch the file to multi-user (hosted) mode. |
| `0x80040414` | `QB_MODAL_DIALOG` | A modal dialog is showing in the QuickBooks UI, blocking the SDK. | Dismiss the dialog on the QuickBooks host and find what is popping it (often an update prompt). |
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
