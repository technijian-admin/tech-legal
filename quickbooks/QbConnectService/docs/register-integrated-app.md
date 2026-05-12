# Register the QuickBooks Integrated App

Run this on the QuickBooks host (`10.120.254.13`), once.

MEDIUM confidence: verify the exact QuickBooks dialog wording on the host.

## Prerequisites

- QuickBooks Desktop Enterprise is installed on the host and the target `.QBW` opens there.
- `QBXMLRP2.RequestProcessor` is registered. It normally ships with QuickBooks, but install the QuickBooks SDK on the host as well for `tlbimp`, the OnScreen Reference, and `qbsdklog.txt`.
- The request-processor COM server is 32-bit, which is why `QbConnectService` is published as x86.
- If the COM server is not registered, the service will surface `0x80040154` / `REGDB_E_CLASSNOTREG`. See [quickbooks/QbConnectService/README.md](../README.md).

## Two identities you must not conflate

### `svc_qbsdk` = the Windows account

This is the Windows account the service or scheduled task runs as.

- It must be a real local account on the host.
- It needs the `Log on as a service` right.
- It needs read access to the `.pfx` and to the `.QBW` file or share.
- It must have logged in interactively at least once so its user profile and QuickBooks per-user state exist.
- The integrated-app grant is tied to the Windows user that ran the app, so the grant must be created while logged in as `svc_qbsdk` or while the service/task is running as `svc_qbsdk`.

### The QuickBooks login user = the QuickBooks-internal identity

This is the QuickBooks user whose in-product permissions the SDK will run under.

- It can be `Admin` or a dedicated limited QuickBooks user.
- It is not the same thing as `svc_qbsdk`.
- The authorization dialog may ask you to choose this QuickBooks user and provide that QuickBooks password.

## Procedure

1. Log on to `10.120.254.13` as `svc_qbsdk`.
2. Open the target company file in QuickBooks as `Admin`.
3. Switch QuickBooks into single-user mode.
4. Trigger the first connection as `svc_qbsdk`.
   Start the service with `Start-Service QbConnectService`, or run `QbConnectService.exe` interactively as `svc_qbsdk`, then call `GET /api/health`.
   The health probe triggers `company_info`, which in turn drives the first `OpenConnection2` / `BeginSession`.
5. When QuickBooks prompts to authorize `QbConnectService`, choose the unattended option:
   `Yes, always; allow access even if QuickBooks is not running`.
6. Choose the QuickBooks login user for automatic sign-in.
   Supply that QuickBooks user's password if QuickBooks asks for it.
7. Decide deliberately on personal-data access.
   The same dialog, or a follow-up dialog, may show a checkbox like `Allow this application to access personal data such as Social Security Numbers and customer credit card information`.
   For a back-office accounting integration, you will almost certainly want to enable this. If you do not, calls such as `list_customers`, `list_vendors`, and `get_company_preferences` can return masked or missing PII fields and a qbXML `statusCode` in the `530` family.
   That is not a COM HRESULT. It rides inside the HTTP 200 `result.status` payload and will not appear in the HRESULT troubleshooting table.
8. Switch the company file back to multi-user / hosted mode.
9. Confirm QuickBooks Database Server Manager is hosting the company file again.

## Where QuickBooks stores the grant

The authorization is stored inside QuickBooks's integrated-application settings for that company file:

- `Edit -> Preferences -> Integrated Applications -> Company Preferences`
- It is keyed by the app's `AppID`, the executable path, and the Windows user that ran it.
- It is not a file stored next to the `.QBW`.

## Reauthorize and recovery path

If the grant needs review or repair:

1. Open `Edit -> Preferences -> Integrated Applications -> Company Preferences`.
2. Select `QbConnectService`.
3. Use `Properties` to review or change:
   the `allow access even if QuickBooks is not running` setting, the QuickBooks login user, and the personal-data access setting.
4. If the entry is wrong or broken, remove it and repeat the procedure above in single-user mode as `svc_qbsdk`.

Expect a fresh authorization prompt when any of these change:

- `Qb:AppId` changes
- the executable path changes
- QuickBooks is upgraded to a major new version
- a redeploy causes QuickBooks to treat the app as changed

Deploy to a stable path such as `C:\Program Files\QbConnectService\` and do not move it after granting access.

## `Qb:AppId`

`Qb:AppId` in `appsettings.sample.json` is shown as `REPLACE-WITH-APP-ID`.

- Treat it as an app-declared stable identifier that you choose once and keep stable.
- MEDIUM confidence: verify the exact behavior on the host, but QuickBooks appears to key the grant on this `AppID`.
- The safest pattern is to generate a stable GUID once and place that GUID in the real `appsettings.json`.

## Personal-data checkbox contingency

LOW confidence: it is not yet confirmed whether `RealRequestProcessor` must explicitly declare a personal-data preference such as `pdpRequired` for the PII checkbox to appear at all.

If the host never offers the personal-data checkbox and PII fields still come back masked, that is a small host-side follow-up in the real request-processor/interop layer. It is not part of this documentation task.

## Diagnostics

- `qbsdklog.txt` is the first place to look if the authorization dialog never appears or the SDK connection fails.
- Check the user profile and `%ProgramData%\Intuit\QuickBooks\` locations on the host for QuickBooks SDK logs.
- Intuit's QBSDK Programmer's Guide section on `Connections, sessions and authorizations` is the canonical reference for this flow.
