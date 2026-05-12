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

### 409 QuickBooks busy

`409 "QuickBooks busy"` means another request is in flight or QuickBooks is
showing a modal dialog on the host. Retry shortly. This is deliberately not
auto-retried by the Python client.

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
