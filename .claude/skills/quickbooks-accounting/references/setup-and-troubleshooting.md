# QuickBooks Client Setup and Troubleshooting

## Common failure modes

### Health is not healthy

If `GET /api/health` returns `status != "healthy"` or `connectionState` is not
connected, the service cannot activate or maintain the QuickBooks COM session.
Check the QuickBooks SDK install and the integrated-app authorization on the
host. The QuickBooks-side authorization must be granted in single-user mode,
"allow to login automatically" must be enabled, and it must be bound to the
service account. See
`quickbooks/QbConnectService/src/QbConnectService/Api/HealthEndpoints.cs` for
the response fields; `lastError` carries the detail.

### 401 Unauthorized

`401 Unauthorized` with `WWW-Authenticate: Bearer` means `QB_API_TOKEN` is
missing or wrong. It must match `Auth:ApiToken` from the service's
`appsettings.json`.

### 403 Writes disabled

`403 "Writes disabled"` means `Safety:AllowWrites=false` on the service. The
operator must deliberately flip `AllowWrites` to `true` before any write can
execute, and even then the 5-step safe-write workflow still applies.

### 503 QuickBooks unavailable

`503 "QuickBooks unavailable"` with a `qbErrorCode` means the service hit a
QuickBooks COM/HRESULT error. Use the surfaced code and the service's `QbErrors`
map to find the human message and remediation.

**Auto-recovered HRESULTs (since 2026-05-19, commit `d56ddc1`)** — the service
self-heals from these by killing QBW.EXE and retrying once. You should rarely
see them surface to API callers unless an interactive QB Desktop session is
attached (which the safety guard refuses to disturb), or the kill-rate ceiling
(default `3/min`) was hit:

- `0x8004040A QB_DIFFERENT_FILE_OPEN` - caller asked for a different `.qbw`
  than QBW.EXE has open. Cross-company switches via `?company=` produce this
  in the SDK layer; the service handles the kill+retry transparently.
- `0x80040414 QB_MODAL_DIALOG` - a popup is blocking the QB UI thread.
  Auto-recover kills the QBW.EXE that's showing the modal (if no human is
  attached) and retries on a fresh QB launch.
- `0x80010105 RPC_E_SERVERFAULT` - COM server faulted. Usually the same root
  cause as `0x8004040A` surfaced differently by the SDK.

When auto-recovery refuses (interactive session detected, or ceiling hit), the
service returns a clean 409 with a remediation hint pointing at
`POST /api/connection/restart-qb` as the manual override.

### 409 QuickBooks busy / 409 auto-recovery refused

`409 "QuickBooks busy"` with the `qbErrorCode` field is the standard "another
request is in flight or QuickBooks is showing a modal dialog on the host" -
retry shortly. Deliberately not auto-retried by the Python client.

`409 "auto-recovery refused: QBW.EXE has an interactive session on the server
console"` means the service detected a visible QB Desktop window (a human is
RDP'd into `10.120.254.13` using QB Desktop interactively) and refused to kill
QBW automatically. Resolution:

1. The operator dismisses any QB Desktop popup on the server console and
   closes QB Desktop.
2. Or: call `POST /api/connection/restart-qb` to force the kill manually (this
   bypasses the safety guard).
3. Or (last resort): SSH/WinRM into the host and `Stop-Process -Name QBW
   -Force` directly.

### 504 QuickBooks timeout

`504 "QuickBooks timeout"` means the request exceeded the configured watchdog
timeout on the service.

### TLS verification failures

If TLS fails, the dev cert is usually self-signed. Set `QB_VERIFY_TLS=false` or
point `QB_VERIFY_TLS` at the correct `.cer` / CA bundle path.

## Deploy and host docs

These live under the service folder:

- `quickbooks/QbConnectService/README.md` for the `10.120.254.13` deploy
  runbook and HRESULT troubleshooting table
- `quickbooks/QbConnectService/docs/register-integrated-app.md` for the
  one-time QuickBooks-side authorization flow, the PII gotcha, and the
  Reauthorize recovery path
- `quickbooks/QbConnectService/deploy/make-cert.ps1`,
  `quickbooks/QbConnectService/deploy/install-service.ps1`,
  `quickbooks/QbConnectService/deploy/uninstall-service.ps1`, and
  `quickbooks/QbConnectService/deploy/run-as-task.ps1` for cert creation and
  service/task installation
- `quickbooks/QbConnectService/docs/SMOKE-CHECKLIST.md` for the ordered
  live-host validation flow
- `quickbooks/QbConnectService/docs/QBXML-REPIN.md` for the live-host qbXML
  re-pin procedure and inventory

## Build pipeline pointer

For the documented multi-LLM build/review loop around this subsystem, see
`quickbooks/dev/MULTI-LLM.md`.
