# Phase 9: Packaging, Deploy & On-Box Smoke — Research

**Researched:** 2026-05-12
**Domain:** Windows service packaging / PowerShell deploy scripts, self-signed TLS, QuickBooks Desktop SDK (`QBXMLRP2`) integrated-app authorization, operator runbooks
**Confidence:** HIGH for the .NET/PowerShell/Kestrel mechanics (verified against this repo + Microsoft docs); MEDIUM for QuickBooks-side authorization specifics and exact HRESULT semantics (Intuit docs are sparse/old; the operator must verify on `10.120.254.13`).

## Summary

Phase 9 is **almost entirely documentation + PowerShell scripts**, not application code. The service binary (`QbConnectService.exe`, x86 self-contained single-file) is already tri-mode (console / Windows service / scheduled task) from Phase 1 via `AddWindowsService()`, already binds HTTPS-only Kestrel with a file-cert from `Server:CertPath`/`Server:CertPassword` or a dev-cert fallback (Phase 5), already has the full config-section surface (`Server`/`Auth`/`Qb`/`Safety`/`QbXml`/`Audit`/`Request`), already has the `QbErrors` HRESULT map, and already has `AuditLog.VerifyChainAsync()` (but **no endpoint or CLI switch exposes it** — see Open Questions). The deliverables are: (a) 4 PowerShell scripts (`make-cert.ps1`, `install-service.ps1`, `uninstall-service.ps1`, `run-as-task.ps1`) that are *authored + self-checking + `-WhatIf`-capable* but **not executed against a live service** in the dev environment; (b) the gitignored `appsettings.json` + `clients/.env` real configs plus a `.gitignore` audit confirming nothing machine-specific leaks; (c) `register-integrated-app.md` + a full `QbConnectService/README.md` deploy runbook + an HRESULT troubleshooting table built from `QbErrors.cs`; (d) an ordered on-box `SMOKE-CHECKLIST.md` the operator literally checks off; (e) a "re-pin constructed qbXML on the live host" documented procedure + a known-constructed inventory; (f) optionally a CI job that PSScriptAnalyzer-lints the new `.ps1` files and verifies the `.sample` configs parse + carry every key the code reads.

The hard scope boundary: **Codex runs in the dev environment which has NO QuickBooks SDK and is NOT `10.120.254.13`.** So `tlbimp` regen of the real interop, the actual on-box smoke RUN, and the live qbXML re-pin are *operator tasks documented now, executed later on the host*. The plan MUST make this explicit and MUST NOT ask Codex to do them.

**Primary recommendation:** Treat Phase 9 as 1 plan, ~6–8 tasks: (1) `make-cert.ps1`; (2) `install-service.ps1` + `uninstall-service.ps1` (+ a small shared `_common.ps1` for the "Log on as a service" right and admin-elevation check); (3) `run-as-task.ps1`; (4) real `appsettings.json` + `clients/.env` + `.gitignore` audit + sample-parity test; (5) `register-integrated-app.md`; (6) `QbConnectService/README.md` deploy runbook + HRESULT table; (7) `docs/SMOKE-CHECKLIST.md` + `docs/QBXML-REPIN.md` (the re-pin procedure + inventory); (8) optional CI lint job + the final `docs(09-01)` SUMMARY/ROADMAP/REQUIREMENTS/STATE commit. Have `install-service.ps1` *invoke `dotnet publish`* (or accept a pre-published path) so the operator does one thing.

---

## Standard Stack

### Core (all already in the repo / .NET 8)
| Tool | Version | Purpose | Why standard |
|------|---------|---------|--------------|
| `Microsoft.Extensions.Hosting.WindowsServices` (`AddWindowsService()`) | 8.0.* (already referenced) | Lets the *same exe* run as console or Windows service with no code change | The MS-blessed way since .NET Core 3; already wired in `Program.cs` |
| Kestrel `listenOptions.UseHttps(certPath, password)` | .NET 8 | HTTPS bind from a PFX file | Already wired in `Program.cs` `ConfigureKestrel`; reads `Server:CertPath`/`Server:CertPassword` |
| `dotnet publish -r win-x86 -c Release --self-contained true -p:PublishSingleFile=true` | .NET 8 SDK | Produces the single x86 exe | Exactly what `quickbooks-ci.yml` already does in its "Publish smoke" step and what the csproj defaults to in Release |

### Supporting (PowerShell, all built into Windows / PS 5.1+)
| Tool | Purpose | Notes |
|------|---------|-------|
| `New-Service` | Register the Windows service | `-BinaryPathName`, `-Credential`, `-StartupType Automatic`, `-DisplayName`, `-Description`. Quoting: pass `-BinaryPathName '"C:\path with spaces\QbConnectService.exe"'` (inner double-quotes literally in the string). |
| `sc.exe` | The bits `New-Service` can't do: **failure recovery** (`sc.exe failure QbConnectService reset= 86400 actions= restart/5000/restart/5000/restart/5000` and `sc.exe failureflag QbConnectService 1`), and re-pointing the binary path / account on an *existing* service (`sc.exe config QbConnectService binPath= "..."` / `obj= ".\svc_qbsdk" password= "..."`). Note the `key= value` syntax requires the space *after* the `=`. |
| `New-SelfSignedCertificate` + `Export-PfxCertificate` + `Export-Certificate` | Generate the HTTPS cert, export `.pfx` (with `-Password`) for the service and the public `.cer` for clients | PS 5.1+; `-CertStoreLocation Cert:\LocalMachine\My`. |
| `Import-Certificate -CertStoreLocation Cert:\LocalMachine\Root` | (Optional) Trust the self-signed cert machine-wide so a local client doesn't need `QB_VERIFY_TLS=false` | Recommended for an internal box — simplest path. |
| `Register-ScheduledTask` / `schtasks.exe` | The session-0 fallback in `run-as-task.ps1` | `Register-ScheduledTask` with `New-ScheduledTaskTrigger -AtStartup`, `New-ScheduledTaskPrincipal -UserId .\svc_qbsdk -LogonType Password -RunLevel Highest` (or `-LogonType S4U` if no password is stored — but S4U has no network token, which can matter if the `.QBW` is on a share; recommend `Password` for that reason), `New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit 0`. |
| `secedit.exe` (export/import INF) | Grant `SeServiceLogonRight` ("Log on as a service") to `svc_qbsdk` | The no-extra-dependency way: `secedit /export /cfg <tmp.inf>`, append the SID to the `SeServiceLogonRight` line, `secedit /configure /db secedit.sdb /cfg <tmp.inf> /areas USER_RIGHTS`. (Avoid the `Carbon` module / `ntrights.exe` — extra dependency / not on modern Windows.) MEDIUM confidence on the exact INF surgery; widely used pattern but easy to get wrong — script it carefully, and the runbook should still tell the operator how to do it by hand via `secpol.msc` as a fallback. |
| `Invoke-ScriptAnalyzer` (PSScriptAnalyzer module) | Optional CI lint of the new `.ps1` files | Not installed by default on `windows-latest`? It actually *is* preinstalled on GitHub `windows-latest` runners. A `pwsh -c 'Invoke-ScriptAnalyzer -Path quickbooks -Recurse -EnableExit'` step is cheap and worth adding. |

### Alternatives considered
| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| `New-Service` + `sc.exe failure` | `sc.exe create` for everything | `New-Service -Credential` handles the account+password prompt cleanly and grants nothing extra; `sc.exe create obj=` needs the password on the command line. Use `New-Service` for create, `sc.exe` only for failure-recovery and existing-service reconfig. |
| `secedit` INF surgery | `Carbon` PowerShell module / `ntrights.exe` | Both are extra dependencies; `ntrights.exe` ships with old resource kits, not modern Windows. `secedit` is built in. |
| Self-contained single-file publish | Framework-dependent + install the ASP.NET Core 8 Hosting Bundle on the host | Self-contained is what the csproj/CI already do and removes a host prerequisite — keep it. Mention the hosting-bundle alternative in the README only as a note. |
| Self-signed cert + import to LocalMachine\Root | Internal CA-issued cert | Out of scope for one internal box; self-signed + Root-import is the documented path. |

---

## Architecture / Deliverable Layout

```
quickbooks/QbConnectService/
├── README.md                       # REWRITE: full 10.120.254.13 deploy runbook + HRESULT table + QBWC-fallback note
├── deploy/                          # NEW folder for the scripts (keeps repo root clean)
│   ├── make-cert.ps1
│   ├── install-service.ps1
│   ├── uninstall-service.ps1
│   ├── run-as-task.ps1
│   └── _common.ps1                  # shared: Assert-Elevated, Grant-ServiceLogonRight, Get-PublishPath helpers
├── docs/
│   ├── register-integrated-app.md   # NEW: one-time QB-side authorization flow
│   ├── SMOKE-CHECKLIST.md           # NEW: ordered on-box smoke, operator checks off
│   └── QBXML-REPIN.md               # NEW: live-host re-pin procedure + known-constructed inventory
└── src/QbConnectService/
    └── appsettings.json             # NEW (gitignored): the real config — but see note below; appsettings.sample.json already exists
quickbooks/clients/
├── .env                             # NEW (gitignored): the real client config; .env.sample already exists
.github/workflows/quickbooks-ci.yml  # OPTIONAL: add a PSScriptAnalyzer lint step + a sample-parity test invocation
quickbooks/QbConnectService/src/QbConnectService.Tests/
└── SampleConfigParityTests.cs       # OPTIONAL: assert appsettings.sample.json + .env.sample parse and have every key the code reads
```

Note on the exact script-folder name: `setup-and-troubleshooting.md` and `ServerOptions.cs` forward-reference the scripts by *bare filename* (`make-cert.ps1` etc.), not by path, so `quickbooks/QbConnectService/deploy/` is fine; the planner should pick one path and update the forward-references in the skill + `ServerOptions.cs` XML comment to point at it. The README and `register-integrated-app.md` *are* referenced by path (`quickbooks/QbConnectService/README.md`, `register-integrated-app.md` is referenced bare) — keep `README.md` where it is; put `register-integrated-app.md` under `quickbooks/QbConnectService/docs/`.

### Pattern: `appsettings.json` — should the *real* one be committed?

**No.** It's gitignored (`.gitignore` line `quickbooks/QbConnectService/src/QbConnectService/appsettings.json`). DEPLOY-02 says "machine-specifics live only in gitignored `appsettings.json` and `clients/.env`, each with a committed `.sample`". So Phase 9 does **not** add a committed `appsettings.json`; it (a) confirms `appsettings.sample.json` is complete and accurate (it currently is — `Server`/`Auth`/`Qb`/`Safety`/`QbXml`/`Audit`/`Request`), (b) confirms `.env.sample` is complete, (c) confirms `.gitignore` covers both real files, (d) the README tells the operator to `cp appsettings.sample.json appsettings.json` on the host and fill it in. **Codex must NOT create a real `appsettings.json` in the repo.** The "deliverable" here is really the *audit + the sample-parity test*, not a new file.

Also worth fixing in Phase 9: the csproj `<None Update="appsettings.sample.json" CopyToOutputDirectory="PreserveNewest" />` copies the *sample* to the publish output but not a real `appsettings.json` (which won't exist at build time anyway). The ASP.NET Core host loads `appsettings.json` **relative to `ContentRootPath`**, which for a published app is the directory of the exe — *unless the working directory differs*. For a Windows service, the process working directory is `C:\Windows\System32` by default, NOT the exe directory; but `WebApplication.CreateBuilder` sets `ContentRootPath` to `AppContext.BaseDirectory` (the exe folder) for self-contained single-file apps, so `appsettings.json` next to the exe IS found. **The plan should still have `install-service.ps1` explicitly NOT rely on working directory** (don't pass a `-WorkingDirectory`; `New-Service` has no such parameter anyway — the service always starts in System32; rely on `ContentRootPath = exe dir`). The README should say "put `appsettings.json` in the same folder as `QbConnectService.exe`". MEDIUM confidence that single-file `ContentRootPath` resolves to the exe dir — the planner should add a one-line note telling the operator to verify `GET /api/health` reflects the configured `companyFile` value (it echoes `qb.Value.CompanyFilePath`) as the smoke-test proof the config was loaded.

### Pattern: `install-service.ps1` should publish

Recommend: `install-service.ps1 -PublishFirst` (default `$true`) runs:
```powershell
dotnet publish "$RepoRoot\quickbooks\QbConnectService\src\QbConnectService" `
  -c Release -r win-x86 --self-contained true -p:PublishSingleFile=true `
  -o "$PublishDir"
```
then copies `appsettings.json` from a `-ConfigPath` param (default: alongside the script) into `$PublishDir`, then `New-Service -Name QbConnectService -BinaryPathName "`"$PublishDir\QbConnectService.exe`"" -DisplayName "QuickBooks Connect Service" -Description "..." -StartupType Automatic -Credential (Get-Credential -Message 'svc_qbsdk password')`, then the `sc.exe failure` calls, then `Grant-ServiceLogonRight`. Provide `-SkipPublish` for the "I already published" case. Idempotency: `if (Get-Service QbConnectService -ErrorAction SilentlyContinue) { Stop-Service; sc.exe config ... ; sc.exe failure ... } else { New-Service ... ; sc.exe failure ... }` — i.e. reconfigure-in-place rather than delete+recreate (avoids the "marked for deletion" race when an MMC snap-in has the SCM open).

### Pattern: `run-as-task.ps1` — when and why

The session-0 problem: a Windows *service* runs in session 0 with no interactive desktop. QuickBooks Desktop historically does NOT love running headless in session 0 — `QBW32.exe` can pop modal dialogs (update prompts, "company file in use" warnings, the QBXMLRP2 authorization dialog the *first* time) that nothing can dismiss in session 0, manifesting as HRESULTs `0x80040414` (modal dialog blocking the SDK) or `0x80040408` (could-not-start). The fallback: run `QbConnectService.exe` as a **scheduled task** that starts at boot under `svc_qbsdk` with `-RunLevel Highest`. A task started by the *task scheduler service* still runs in a non-interactive session, but: (1) it inherits the `svc_qbsdk` profile properly (the integrated-app grant + QuickBooks's per-user state live in that profile), (2) `-RunLevel Highest` gives it the elevated token QuickBooks sometimes wants, (3) it's easier to attach a debugger / RDP in as `svc_qbsdk` and see what QuickBooks is doing. **The operator switches from service → task when:** the service install produces `0x80040408`/`0x80040414`/`0x80040401` at startup that don't reproduce when you log in interactively as `svc_qbsdk` and run the exe from a console — i.e. the failure is session-0-specific. The README should say exactly that. The two are mutually exclusive — run ONE; `uninstall-service.ps1` removes the service, `run-as-task.ps1 -Remove` removes the task. (MEDIUM confidence on whether a scheduled task actually fixes session-0 QuickBooks issues vs just relocating them — this is folklore from the QBSDK era; the runbook should present it as "the documented fallback to try", not a guaranteed fix, and note that the *true* last resort is the QBWC-polled design.)

### Pattern: `make-cert.ps1`

```powershell
param([string]$DnsName = '10.120.254.13', [string[]]$ExtraNames = @('localhost'),
      [string]$PfxPath = '.\qbconnect.pfx', [string]$CerPath = '.\qbconnect.cer',
      [int]$ValidYears = 5, [switch]$TrustLocally)
$pwd = Read-Host -AsSecureString -Prompt 'PFX password'   # or accept -PfxPassword (SecureString)
$cert = New-SelfSignedCertificate `
  -Subject "CN=$DnsName" `
  -DnsName (@($DnsName) + $ExtraNames) `   # IP literal as a DnsName entry is accepted and lands in the SAN
  -CertStoreLocation 'Cert:\LocalMachine\My' `
  -KeyExportPolicy Exportable `
  -KeyUsage DigitalSignature,KeyEncipherment `
  -KeyAlgorithm RSA -KeyLength 2048 `
  -Type SSLServerAuthentication `
  -NotAfter (Get-Date).AddYears($ValidYears)
Export-PfxCertificate -Cert $cert -FilePath $PfxPath -Password $pwd | Out-Null
Export-Certificate -Cert $cert -FilePath $CerPath | Out-Null
if ($TrustLocally) { Import-Certificate -FilePath $CerPath -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null }
# Then: instruct the operator to set Server:CertPath = $PfxPath and Server:CertPassword in appsettings.json,
# put the .pfx somewhere svc_qbsdk can read (e.g. C:\ProgramData\QbConnectService\), and set the client's
# QB_VERIFY_TLS to the .cer path (or 'false', or import the .cer into the client box's trust store).
```
Notes: an IP-literal SAN — `New-SelfSignedCertificate -DnsName '10.120.254.13'` puts `10.120.254.13` in the DNS-name SAN, not an IP-address SAN; most TLS clients (including .NET `HttpClient` and Python `requests`/`urllib3` with a CA bundle) match it fine for `https://10.120.254.13`. If a stricter client complains, the operator can build the cert with an explicit `IPAddress` SAN via a `[Security.Cryptography.X509Certificates.X509SubjectAlternativeNameBuilder]` (mention as a "if needed" appendix; don't over-engineer the default). Rotation: re-running `make-cert.ps1` makes a *new* cert; the operator updates `appsettings.json` and restarts the service, and re-distributes the `.cer`. The script should warn if a cert with the same subject already exists in `LocalMachine\My`.

---

## QuickBooks-side: `register-integrated-app.md` (MEDIUM confidence — operator verifies on host)

The canonical QBXMLRP2 unattended/integrated-app authorization flow (from the Intuit QBSDK Programmer's Guide, "Connections, sessions and authorizations" — <https://developer.intuit.com/app/developer/qbdesktop/docs/develop/connections-sessions-and-authorizations>):

1. **Prereqs on the host:** QuickBooks Desktop **Enterprise** installed; the QuickBooks SDK / `QBXMLRP2.RequestProcessor` COM server registered. *Clarify:* `QBXMLRP2.dll` (the request processor COM server) ships **with QuickBooks itself** in modern versions (under `%CommonProgramFiles%\Intuit\QuickBooks\`), so a *separate* QuickBooks SDK install is **not strictly required** to *run* the service — but the SDK download (`QBXMLRP2Lib` type library, OnScreen Reference, `qbsdklog.txt` tooling) **is** required for the `tlbimp` interop regen and is the canonical doc source, so the README should say "install the QuickBooks SDK on the host" anyway. If `QBXMLRP2.RequestProcessor` is *not* registered you get `0x80040154` REGDB_E_CLASSNOTREG — see HRESULT table. Confirm the COM server is **32-bit** (it is — hence x86 service); confirm `RegSvr32` registration if a repair install didn't do it.
2. **Two distinct identities — make this crisp in the doc:**
   - `svc_qbsdk` = the **Windows** account the service/task runs *as*. It needs: a real local-user account on the host, "Log on as a service" right, read access to the `.pfx` and the `.QBW` (or its share), and — critically — it must have *logged in interactively at least once* so QuickBooks builds its per-user profile/state. The integrated-app grant is stored per-Windows-user, so it must be granted *while logged in as `svc_qbsdk`* (or while the service is running *as* `svc_qbsdk`).
   - The **QuickBooks login user** (e.g. the `Admin` user, or a dedicated limited QB user) = the QuickBooks-internal user whose permissions the SDK requests run under. The authorization dialog asks you to pick this when you choose "and login automatically". `svc_qbsdk` ≠ this QB user; the doc must say so explicitly.
3. **The procedure:**
   a. Log in to the host **as `svc_qbsdk`** (or arrange the service to run as it).
   b. Open the company file in **QuickBooks as `Admin`** in **single-user mode** ("File → Switch to Single-user Mode").
   c. Trigger a connection from the integrated app: start `QbConnectService` (or run the exe in a console as `svc_qbsdk`), then hit `GET /api/health` — that does a `company_info` probe → `OpenConnection2`/`BeginSession`, which on first contact makes QuickBooks pop the **"Application Certificate" / "Authorize new app"** dialog naming `QbConnectService` (the `AppName`/`AppId` from `Qb` config).
   d. In the dialog choose **"Yes, always; allow access even if QuickBooks is not running."** — this is the "allow to login automatically" / batch-mode grant that lets the service run when QB isn't open.
   e. When prompted, select the **login user** for the auto-login (Admin or a dedicated QB user) and supply that QB user's password if QB asks.
   f. **PII gotcha:** the same dialog (or a follow-up) has a checkbox along the lines of *"Allow this application to access personal data such as Social Security Numbers and customer credit card information."** If you do NOT check it, the request processor returns the moral equivalent of `personalDataNotAllowed` (qbXML `statusCode` ~`530`/`531`-family on requests touching SSNs/credit-card fields) — `list_customers`/`list_vendors`/`get_company_preferences` may come back with masked or missing fields. The doc must say: decide deliberately; for a back-office accounting integration that pulls vendor/customer detail, you almost certainly want to **check it**. (The QBXMLRP2 side of this is the `qbXMLPersonalDataPref` the *app* declares — our `RealRequestProcessor` currently doesn't set it explicitly; flag as a possible small Phase-9 code touch or a documented limitation: if PII access is needed AND the SDK requires the app to declare `pdpRequired`, that's a `RealRequestProcessor.OpenConnection2`-adjacent change. LOW confidence on whether the current code path even reaches the PII dialog without that declaration — operator must verify; if not, that's a defect to fix in this phase.)
   g. After the grant: switch the company file **back to multi-user / hosted mode** ("File → Switch to Multi-user Mode", and confirm Database Server Manager is hosting it) so other users / the service's `OpenMode = DoNotCare` work without a "different file open"/"requires single-user" HRESULT.
4. **Where the grant is stored:** in QuickBooks's own integrated-application list for that company file (visible at **Edit → Preferences → Integrated Applications → Company Preferences tab → the app's row**), keyed by AppID + the app's executable path/signature, under the Windows user that ran the app. (It's *not* a file next to the `.QBW`; it's in QB's company-file/preferences store.) MEDIUM confidence on the exact storage location — don't over-specify; what matters is the operator knows it's per-(company-file × Windows-user × AppID × exe-path).
5. **"Reauthorize" recovery path:** Edit → Preferences → Integrated Applications → Company Preferences → select `QbConnectService` → **Properties** (review/adjust the "allow access even if QB not running" + login user + personal-data settings), or **remove it** and re-run step 3 to re-grant from scratch. **What triggers a fresh authorization prompt:** the `AppID` changed; the executable's path changed (so don't move the exe after granting — or expect a re-prompt; this is *why* `install-service.ps1` should publish to a stable path like `C:\Program Files\QbConnectService\` or `C:\ProgramData\QbConnectService\bin\`); the exe's signature changed (we don't code-sign — every rebuild is a new "signature" in QB's eyes only if QB keys on a hash, which is version-dependent; MEDIUM confidence, so the doc should warn "a redeploy may re-trigger the auth dialog — be ready to re-grant in single-user mode"); a major QuickBooks version upgrade. The doc should make "deploy a new build → may need to re-grant" a known step.
6. **Cite:** Intuit QBSDK Programmer's Guide / "Connections, sessions and authorizations" page; the `qbsdklog.txt` (in the user's profile / `%ProgramData%\Intuit\QuickBooks\`) is the diagnostic when the dialog never appears or auth fails.

---

## `QbConnectService/README.md` deploy runbook structure (for `10.120.254.13`)

1. **What this is / prerequisites:**
   - Windows Server / Windows 10+ on the QuickBooks host; .NET 8 **not required to be installed** (self-contained single-file publish bundles the runtime) — mention the framework-dependent + ASP.NET Core 8 Hosting Bundle alternative only as a note.
   - **QuickBooks Desktop Enterprise** installed and a company file (`.QBW`) present; **QuickBooks Database Server Manager** installed and *hosting* the `.QBW` (multi-user). The `QBXMLRP2.RequestProcessor` COM server (ships with QuickBooks; the standalone QuickBooks SDK install is recommended for `tlbimp`, OnScreen Reference, and `qbsdklog.txt`).
   - A `svc_qbsdk` local Windows account: created, password set, **"Log on as a service"** granted (`install-service.ps1` does this via `secedit`; manual path = `secpol.msc → Local Policies → User Rights Assignment → Log on as a service`), has read access to the `.QBW`/share and the `.pfx`, and **has logged in interactively at least once** (so its profile + QuickBooks per-user state exist).
2. **Install order (the happy path):**
   1. `cd quickbooks\QbConnectService\deploy`
   2. `.\make-cert.ps1 -DnsName 10.120.254.13 -TrustLocally` → note the `.pfx`/`.cer` paths + the PFX password.
   3. `copy ..\src\QbConnectService\appsettings.sample.json .\appsettings.json` and edit: `Auth:ApiToken` (a long random token), `Qb:CompanyFilePath` (full path / UNC of the `.QBW`), `Qb:AppId` (the registered app id — leave blank/auto on first run if you're letting QB assign it, then pin it; **MEDIUM** — clarify on host), `Server:CertPath`/`Server:CertPassword` (the `.pfx`), `Audit:Path` (`C:\ProgramData\QbConnectService\audit`), `QbXml:Version` (confirm against `GET /api/health → qbXmlVersionsSupported` — the sample says `16.0`), `Safety:AllowWrites` = **false** (flip to true only for the smoke write, then back).
   4. `.\install-service.ps1` (publishes to `C:\Program Files\QbConnectService\`, copies `appsettings.json` + the `.pfx` next to the exe, registers the service as `svc_qbsdk`, sets restart-on-crash, grants the logon right). *OR* — if you hit session-0 problems — `.\run-as-task.ps1` instead (registers the boot-time scheduled task as `svc_qbsdk`, RunLevel Highest).
   5. Follow `docs\register-integrated-app.md` (single-user mode, Admin, "allow even if QB not running", pick the login user, PII checkbox, back to multi-user).
   6. `Start-Service QbConnectService` (or `Start-ScheduledTask`), then run `docs\SMOKE-CHECKLIST.md`.
3. **Firewall:** open the HTTPS port (default **8443** from `Server:BindUrls`) **inbound, scoped to the LAN** — `New-NetFirewallRule -DisplayName 'QbConnectService HTTPS' -Direction Inbound -Protocol TCP -LocalPort 8443 -Action Allow -RemoteAddress LocalSubnet` (or the specific workstation IPs). Do NOT expose it to the internet.
4. **QBWC-fallback note (one paragraph):** "If direct COM proves unstable in session 0 even as a scheduled task (persistent `0x80040408`/`0x80040414`), the fallback architecture is the classic QuickBooks Web Connector–polled design — QB initiates the connection on a timer, the service is a SOAP endpoint it calls. That's a different design, out of scope for v1, noted here for completeness; nothing in the op layer or qbXML engine changes, only the transport."
5. **HRESULT troubleshooting table** — built directly from `QbConnectService.Qb.Com/QbErrors.cs` (note the file is at `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbErrors.cs`, *not* the `Qb/` subpath the additional-context guessed):

   | HRESULT | Name | Symptom | Likely cause | Fix |
   |---|---|---|---|---|
   | `0x80040154` | REGDB_E_CLASSNOTREG / QB_RP2_CAST_FAILED | "Class not registered" on startup; health `down` | `QBXMLRP2.RequestProcessor` not registered, or 32/64-bit interop mismatch | Install/repair QuickBooks SDK on the host; confirm the service runs **x86**; regenerate `Interop.QBXMLRP2Lib.dll` via `tlbimp` on the host (this phase's interop-regen step) |
   | `0x80040401` | QB_ACCESS_FAILED | Connection attempt fails | QuickBooks install incomplete/broken under the service account; session-0 instability | Repair QuickBooks under `svc_qbsdk`; try the scheduled-task fallback; check `qbsdklog.txt` |
   | `0x80040402` | QB_UNEXPECTED_ERROR | Generic SDK error | Various | Pull `qbsdklog.txt` from the host |
   | `0x80040408` | QB_COULD_NOT_START | "Could not start QuickBooks" at first request | Launch failed; install incomplete; **session-0 instability** | Pre-launch QuickBooks under `svc_qbsdk`; switch service→scheduled task; check `qbsdklog.txt` |
   | `0x8004040A` | QB_DIFFERENT_FILE_OPEN | "A different company file is already open" | Wrong `Qb:CompanyFilePath`, or a human has another file open | Close the other file or fix `Qb:CompanyFilePath` |
   | `0x8004040D` | QB_INVALID_TICKET | Transient session drop (QB restarted) | Dead ticket | The service auto-rebuilds + retries once — no action |
   | `0x80040410` | QB_MODE_MISMATCH | "File open in a different mode" | A human has it open **single-user** | Switch the `.QBW` to multi-user / hosted |
   | `0x80040414` | QB_MODAL_DIALOG | SDK blocked | A modal dialog is up in the QB UI (often an update prompt) on the host | Dismiss it on the host; find what's popping it; consider the scheduled-task fallback |
   | `0x80040416` | QB_NO_FILE_SPECIFIED | "QB not running and no company file given" | `Qb:CompanyFilePath` empty/wrong | Set it to the full `.QBW` path (UNC if on a share) |
   | `0x8004041A` | QB_NO_PERMISSION | "App doesn't have permission to this company file" | Integrated-app grant missing/revoked | Re-run `register-integrated-app.md` (Admin, single-user) |
   | `0x80040420` | QB_ACCESS_DENIED | "QB user denied access" | App not authorized / revoked / waiting | Re-run `register-integrated-app.md`; check the integrated-apps list |
   | `0x80040421` | QB_PASSTHROUGH | Message passed from QB | A QB-side condition | Read the message text |
   | `0x80040422` | QB_REQUIRES_SINGLE_USER | "App requires single-user mode" | Another app/user shares the file | Coordinate access |

   The README should add a note: a non-zero qbXML `statusCode` (e.g. `3200` stale `EditSequence`, the PII `530`-family) is **not** one of these HRESULTs — it rides inside the HTTP-200 `result.status` body and is *not* an error at the COM/HTTP layer.
6. **Audit log:** `audit.jsonl` lives under `Audit:Path` (sample: `C:\ProgramData\QbConnectService\audit\audit.jsonl`). To verify the hash chain: **there is currently no endpoint or CLI switch** — `AuditLog.VerifyChainAsync()` exists but isn't exposed. The README should (a) tell the operator to tail the file (`Get-Content audit.jsonl -Tail 5`) and eyeball the `seq` (monotonic, 0-based) + `prevHash`/`hash` chaining, and (b) note "a built-in `--verify-audit` switch / `GET /api/audit/verify` endpoint is a v2 gap" — OR the planner may decide to add a tiny `args` switch in `Program.cs` (`if (args.Contains("--verify-audit")) { ... resolve AuditLog, call VerifyChainAsync, print, exit; }`) since it's a small, well-bounded, testable addition that genuinely helps the operator. **Recommend adding the `--verify-audit` switch** — it's ~15 lines, fully unit-testable, and closes a real operator gap. (See Open Questions.)

---

## `docs/SMOKE-CHECKLIST.md` — ordered on-box smoke (operator checks off)

Make it literal checkboxes. Use PowerShell `Invoke-RestMethod` (the host has PS; `curl.exe` works too). With a Root-imported cert, no `-SkipCertificateCheck` needed; otherwise `-SkipCertificateCheck` (PS 7) or use `curl.exe --cacert qbconnect.cer`.

```
$base  = 'https://10.120.254.13:8443'
$token = '<Auth:ApiToken from appsettings.json>'
$h     = @{ Authorization = "Bearer $token" }
```

- [ ] **0. Environment facts captured** (fill the table below before starting).
- [ ] **1. Health** — `Invoke-RestMethod "$base/api/health" -Headers $h`. GOOD = `status: "healthy"`, `connectionState: "SessionOpen"`, `companyFile` matches your `appsettings.json`, `quickBooksVersion` populated (e.g. `Enterprise 34.0`), `qbXmlVersionsSupported` non-empty, `lastError: null`. (If `status` is `down`/`degraded`, stop and use the HRESULT table — `lastError.code` is the HRESULT.)
- [ ] **2. company_info** — `Invoke-RestMethod -Method Post "$base/api/ops/company_info" -Headers $h -ContentType application/json -Body '{}'`. GOOD = `result.status.statusCode == 0`, company name / fiscal year / `edition` look right. Record the exact `edition` / `ProductName` string — that's the first re-pin data point (CompanyInfoOp's `ProductName` format).
- [ ] **3. report** — `Invoke-RestMethod -Method Post "$base/api/ops/report" -Headers $h -ContentType application/json -Body '{ "report": "ProfitAndLoss", "dateMacro": "ThisFiscalYearToDate" }'`. GOOD = `status.statusCode == 0`, `rows` populated, column headers present. Eyeball the `ColDesc`/`ColTitle`/`ColType` casing vs `QbReportParser` expectations — second re-pin data point.
- [ ] **4. create_customer DRY-RUN** — `Invoke-RestMethod -Method Post "$base/api/ops/create_customer/dryrun" -Headers $h -ContentType application/json -Body '{ "name": "ZZ_SMOKE_TEST_2026-05-12" }'`. GOOD = response `{ qbXml, summary, preFlight: [...all ok...], allowWrites: false }`; the `qbXml` is a well-formed `CustomerAddRq`; **no side effect** (re-run `company_info` / look in QB — no new customer). Inspect element/enum names in `qbXml` vs the OSR — re-pin data point.
- [ ] **5. flip AllowWrites** — edit `appsettings.json` `Safety:AllowWrites = true`, restart the service/task, confirm `GET /api/health → allowWrites: true`.
- [ ] **6. one real low-stakes write** — `Invoke-RestMethod -Method Post "$base/api/ops/create_customer" -Headers $h -ContentType application/json -Body '{ "name": "ZZ_SMOKE_TEST_2026-05-12" }'`. GOOD = HTTP 200, `result.status.statusCode == 0`, a `ListID` / `EditSequence` returned. (Why a customer: most reversible — no GL impact, easy to make inactive; safer than a journal entry. If a customer with that name already exists from a prior smoke run, append a timestamp/GUID.)
- [ ] **7. confirm in QuickBooks** — open QB on the host, Customers list, find `ZZ_SMOKE_TEST_2026-05-12`. Then **make it inactive** to clean up: there is no `delete` op, so use the raw qbXML passthrough — `POST /api/qbxml` with a `CustomerModRq` setting `IsActive` false (needs the `ListID` + `EditSequence` from step 6), or just toggle "Make Inactive" in the QB UI. Document the `CustomerModRq` snippet in the checklist.
- [ ] **8. confirm the audit row** — `Get-Content "$($auditPath)\audit.jsonl" -Tail 3`. GOOD = the last line is the `create_customer` write: `seq` = previous+1 (or 0 if first ever), `op: "create_customer"`, `args` has the name, `responseStatusCode: "0"`, `prevHash` = the prior row's `hash` (or 64 zeros if first), `hash` present. (If you added `--verify-audit`: `QbConnectService.exe --verify-audit` and confirm `OK`.)
- [ ] **9. flip AllowWrites back to false**, restart, confirm `health → allowWrites: false`.

**Environment facts to record (fill in on the host):**

| Fact | Where to read it | Value |
|---|---|---|
| QuickBooks Enterprise year / version (build) | `GET /api/health → quickBooksVersion`; QB: Help → About | |
| Multi-user hosting status of the `.QBW` | QB: File menu (says "Switch to Single-user") + Database Server Manager shows it hosted | |
| `svc_qbsdk` account + "Log on as a service" right | `secpol.msc → User Rights Assignment → Log on as a service` lists `svc_qbsdk` | |
| Firewall rule for the HTTPS port | `Get-NetFirewallRule -DisplayName 'QbConnectService HTTPS'` exists, scoped to LAN | |
| `RequestProcessor` vs `RequestProcessor2` ProgID, registered & 32-bit | `reg query HKCR\QBXMLRP2.RequestProcessor` / `tlbimp` succeeds | |
| PII (personal-data) access granted to the integrated app | QB: Edit → Preferences → Integrated Applications → app Properties → personal-data checkbox | |
| `qbXmlVersionsSupported` (drives `QbXml:Version`) | `GET /api/health → qbXmlVersionsSupported` | |

---

## `docs/QBXML-REPIN.md` — known-constructed inventory + re-pin procedure

**Inventory (every MEDIUM-confidence / "Phase 9 re-pin" marker found in the codebase — grep `"Phase 9"` / `"re-pin"` / `"CONSTRUCTED"`):**

| Item | Where | What to verify on the host |
|---|---|---|
| `HostRet.ProductName` / `edition` string format | `Qb/Ops/CompanyInfoOp.cs` | Exact `ProductName` text from a real `company_info` (smoke step 2) |
| Preference field names (`IsMultiCurrencyOn`, `IsUsingClassTracking`, `DefaultItemSalesTaxRef`, `decimalPlaces` source) | `Qb/Ops/CompanyPreferencesOp.cs`; skill `SKILL.md` `get_company_preferences` row | Real `PreferencesQueryRq` response element names/casing |
| `get_transaction` query element names | `Qb/Ops/GetTransactionOp.cs` | Real `TransactionQueryRq` (or `*QueryRq`) child names |
| `ListInvoicesOp` query element name (`IncludeLineItems`?) | `Qb/Ops/ListInvoicesOp.cs`; skill `SKILL.md` `list_invoices` row; cheatsheet "Phase-9 re-pin candidates" | `InvoiceQueryRq` — is it `IncludeLineItems`, and what's the exact casing |
| Item subtype discriminator names | `Qb/Ops/ListItemsOp.cs` | `ItemQueryRq` polymorphic response — `ItemServiceRet`/`ItemInventoryRet`/... names |
| Report enum values + aging-date shape + `ColDesc`/`ColTitle`/`ColType` casing | `Qb/Ops/ReportOp.cs`; `QbReportParser.cs`; the constructed P&L golden fixture in `QbConnectService.Tests` | Real `GeneralSummaryReportQueryRq` / `AgingReportQueryRq` responses (smoke step 3) |
| Name-query filter wrappers (`FullNameList` vs `NameFilter` vs `NameRangeFilter`; `ListIDList`/`FullNameList`/`TxnIDList` wrappers per entity) | `Qb/Ops/WriteOpBase.cs` (`FetchByNameAsync`/`FetchCurrentAsync`) | Per-entity `*QueryRq` filter element names from the OSR |
| Write-verb enumeration (`*AddRq`/`*ModRq`/`*DelRq`/`*VoidRq` + `ListDelRq`/`TxnDelRq`/`TxnVoidRq`) | `QbWriteDetector.cs` | The OSR's full request-type enumeration — is anything write-ish missing |
| `mod` stale-`EditSequence` `statusCode=3200` | `Qb/Ops/ModOp.cs` + tests | Force a stale `mod`, confirm the real code/severity |
| All Phase-7 `*Add` qbXML fixtures | `QbConnectService.Tests/CreateEntityOpsTests.cs`, `CreateTransactionOpsTests.cs`, `CreateJournalEntryOpTests.cs`, `ReceivePaymentOpTests.cs`, `ModOpTests.cs` | Run each op's `/dryrun` on the host, diff the `qbXml` element/enum names vs the fixture |
| Phase-4 `*Rs` fixtures (`CompanyPreferencesOpTests` `AccountQuery` casing, etc.) | `QbConnectService.Tests/*OpTests.cs` | As above — diff against real responses |

**Procedure (operator, on the host):** for each item: (1) call the op (or `/dryrun`, or raw `/api/qbxml`) against the live company file; (2) capture the real qbXML request *and* response (the service spills oversized responses to `QbXml:SpillPath`; small ones come back inline); (3) compare against the OnScreen Reference (OSR — shipped with the QuickBooks SDK) for the host's qbXML version and against the relevant `*OpTests.cs` golden fixture / parser expectation; (4) if a name/enum/casing differs, fix the **fixture** *and* the **builder/parser** in `QbConnectService.Qb.Com` to match reality, (5) re-run `dotnet test` (must stay green), (6) remove the "Phase 9 re-pin" comment from that file, (7) update the skill's `qbxml-cheatsheet.md` "Phase-9 re-pin candidates" section as items are resolved. This is the *only* part of Phase 9 that edits production code, and it happens **on the host**, not in the dev/Codex environment.

---

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Run the same exe as console + service + task | A `Topshelf`-style harness or manual `ServiceBase` | `AddWindowsService()` (already in `Program.cs`) | Built-in, MS-supported, already done |
| Generate the HTTPS cert | OpenSSL scripting / `makecert.exe` | `New-SelfSignedCertificate` + `Export-PfxCertificate` + `Export-Certificate` | Built into PS 5.1+, no external tooling |
| Service failure recovery | A watchdog wrapper process | `sc.exe failure ... actions= restart/5000/...` + `sc.exe failureflag ... 1` | The SCM does it natively |
| Grant "Log on as a service" | A custom LSA-policy P/Invoke | `secedit /export` → edit INF → `secedit /configure` (scripted in `_common.ps1`); manual fallback `secpol.msc` | No extra module; widely-used pattern |
| Boot-time non-service launch | A bootstrap `.bat` in `Startup` | `Register-ScheduledTask -AtStartup -RunLevel Highest -UserId .\svc_qbsdk` | Proper credentials, restart settings, runs before login |
| Lint PowerShell in CI | A custom syntax check | `Invoke-ScriptAnalyzer` (preinstalled on `windows-latest`) | Catches real issues, zero install |
| Verify the audit hash chain | A new bespoke verifier | `AuditLog.VerifyChainAsync()` (exists) — just wire a `--verify-audit` arg or a guarded `GET /api/audit/verify` | Logic is already written + tested |

---

## Common Pitfalls

### 1. `New-Service` quoting for a path with spaces
`-BinaryPathName "C:\Program Files\QbConnectService\QbConnectService.exe"` — the SCM stores the binPath verbatim; if it contains spaces and any arguments, the *whole exe path* must be wrapped in inner double-quotes inside the string: `-BinaryPathName '"C:\Program Files\QbConnectService\QbConnectService.exe"'`. Same for `sc.exe config ... binPath= "\"C:\Program Files\...\""`. If you skip this, the service may try to start `C:\Program.exe`. **Verification:** `sc.exe qc QbConnectService` shows the stored `BINARY_PATH_NAME` — confirm the quotes are there.

### 2. Service marked for deletion / can't recreate
If MMC (`services.msc`) or another tool has the SCM open, `New-Service` after a `Remove-Service`/`sc delete` can fail with "marked for deletion". **Avoid by reconfiguring in place** (`sc.exe config` on the existing service) instead of delete+recreate; `uninstall-service.ps1` should `Stop-Service` then `Remove-Service` (PS 6+) / `sc.exe delete` and warn the operator to close `services.msc` first.

### 3. `appsettings.json` not found because of working directory
A Windows service starts with CWD = `C:\Windows\System32`. The ASP.NET Core host loads `appsettings.json` relative to `ContentRootPath`. For a self-contained single-file publish, `ContentRootPath` = the exe's directory (`AppContext.BaseDirectory`), so `appsettings.json` *next to the exe* is found — but DON'T rely on CWD, and DON'T put `appsettings.json` somewhere else expecting it to be picked up. **Verification:** `GET /api/health` echoes `companyFile` from `Qb:CompanyFilePath` — if it's empty/wrong, the config didn't load. (MEDIUM confidence on single-file `ContentRootPath` behaviour — the smoke checklist's health step is the proof.)

### 4. session-0 + QuickBooks = modal-dialog deadlock
The biggest deploy risk. A first-ever connection pops the integrated-app authorization dialog *in QB's UI* — if the service is running in session 0 and nobody's logged in interactively as `svc_qbsdk`, that dialog has no desktop. **Avoid:** do the `register-integrated-app.md` grant *first*, interactively, as `svc_qbsdk`, in single-user mode, *before* relying on the service. Subsequent updates/upgrades can re-trigger it — the runbook must say "after a redeploy, watch for the auth dialog". The scheduled-task fallback (`run-as-task.ps1`) is the documented escape hatch; the QBWC-polled redesign is the true last resort.

### 5. PII / personal-data not granted → masked fields, not an error
If the integrated app wasn't granted personal-data access, `list_customers`/`list_vendors`/`get_company_preferences` come back with SSNs/credit-card fields missing or masked and a qbXML `statusCode` in the `530`-ish family — **not** a COM HRESULT, so it won't show in the HRESULT table or as an HTTP error; it's silently inside `result.status`. The doc must call this out so the operator doesn't think the data "just isn't there". (And: confirm whether `RealRequestProcessor` needs to declare `pdpRequired` for the dialog to even *offer* the PII checkbox — if so, that's a small code fix in this phase.)

### 6. IP-literal cert SAN mismatch
`New-SelfSignedCertificate -DnsName '10.120.254.13'` puts the IP in the *DNS-name* SAN, not the *IP-address* SAN. .NET `HttpClient` and Python `requests`/`urllib3` match `https://10.120.254.13` against it fine; some stricter clients won't. **Avoid** by also accepting a hostname (add the host's name to `-DnsName`), or — if a client complains — rebuild with an explicit `IPAddress` SAN via `X509SubjectAlternativeNameBuilder`. Don't make that the default; document it as an appendix.

### 7. Asking Codex to do host-only work
`tlbimp` regen, running the smoke RUN, the live re-pin edits — all require `10.120.254.13` + the QuickBooks SDK. `run-codex-phase.ps1`'s HARD RULES already forbid `tlbimp` in the dev env. The PLAN must explicitly scope these as *operator follow-ups documented now, not executed by Codex*, and each Phase-9 task that produces a script must say "authored + self-checked + `-WhatIf` where possible; NOT executed against a live service here".

### 8. `.gitignore` is append-only; don't commit the real configs
`run-codex-phase.ps1` HARD RULES: `.gitignore` append-only. The real `appsettings.json` / `clients/.env` are already gitignored — Codex must NOT create them in the repo (it would be ignored anyway, but don't try). The deliverable is the *audit* + the sample-parity test. Also: scoped `git add` only — never `git add -A`/`git add .` (there's unrelated India HR WIP in the tree).

---

## Code Examples (verified patterns)

### Idempotent service install (sketch — `install-service.ps1`)
```powershell
#requires -RunAsAdministrator
param(
  [string]$ServiceName = 'QbConnectService',
  [string]$InstallDir  = "$env:ProgramFiles\QbConnectService",
  [string]$Account     = '.\svc_qbsdk',
  [switch]$SkipPublish,
  [string]$ConfigPath  = (Join-Path $PSScriptRoot 'appsettings.json'),
  [string]$PfxPath     = (Join-Path $PSScriptRoot 'qbconnect.pfx')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')   # Assert-Elevated; Grant-ServiceLogonRight
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')   # adjust depth to repo root
if (-not $SkipPublish) {
  dotnet publish "$repoRoot\quickbooks\QbConnectService\src\QbConnectService" `
    -c Release -r win-x86 --self-contained true -p:PublishSingleFile=true -o $InstallDir
}
Copy-Item $ConfigPath (Join-Path $InstallDir 'appsettings.json') -Force
if (Test-Path $PfxPath) { Copy-Item $PfxPath $InstallDir -Force }
$exe = Join-Path $InstallDir 'QbConnectService.exe'
$cred = Get-Credential -UserName $Account -Message "Password for $Account"
$svc = Get-Service $ServiceName -ErrorAction SilentlyContinue
if ($svc) {
  Stop-Service $ServiceName -ErrorAction SilentlyContinue
  & sc.exe config $ServiceName binPath= "`"$exe`"" start= auto obj= $Account password= $cred.GetNetworkCredential().Password | Out-Null
} else {
  New-Service -Name $ServiceName -BinaryPathName "`"$exe`"" -DisplayName 'QuickBooks Connect Service' `
    -Description 'Direct-SDK QuickBooks Enterprise REST bridge' -StartupType Automatic -Credential $cred | Out-Null
}
& sc.exe failure     $ServiceName reset= 86400 actions= restart/5000/restart/5000/restart/5000 | Out-Null
& sc.exe failureflag $ServiceName 1 | Out-Null
Grant-ServiceLogonRight -Account ($cred.UserName)
Write-Host "Installed. Next: run docs\register-integrated-app.md, then Start-Service $ServiceName, then docs\SMOKE-CHECKLIST.md"
```
(Self-check ideas the planner should require: assert `dotnet --version` ≥ 8; assert the exe exists post-publish; `sc.exe qc` after install and assert `BINARY_PATH_NAME` is quoted; `-WhatIf`/`-DryRun` switch that prints every `sc.exe`/`New-Service` it *would* run without doing it.)

### Sample-parity test (sketch — `SampleConfigParityTests.cs`)
```csharp
// Parse appsettings.sample.json, assert it has every section/key the Options classes bind:
// Server:BindUrls, Server:CertPath, Server:CertPassword, Server:MaxRequestBodyBytes,
// Auth:ApiToken, Qb:CompanyFilePath, Qb:AppId, Qb:AppName, Qb:ConnectionType, Qb:OpenMode,
// Safety:AllowWrites, QbXml:Version, QbXml:OwnerIdZero, QbXml:MaxReturned, QbXml:MaxResponseBytes,
// QbXml:SpillPath, Audit:Path, Request:TimeoutSeconds, Request:BusyWaitSeconds.
// And: parse quickbooks/clients/.env.sample, assert keys QB_API_BASE_URL, QB_API_TOKEN,
// QB_VERIFY_TLS, QB_TIMEOUT, QB_RETRIES. Fail if a key the code reads is missing from the sample.
```
This runs in the existing `QbConnectService.Tests` project on `windows-latest` with no QuickBooks needed — worth adding; it's the automated enforcement of DEPLOY-02.

---

## State of the Art / notes

- `AddWindowsService()` is the current MS way; `Topshelf` is legacy. Already done — no change.
- Self-contained single-file publish (`-p:PublishSingleFile=true --self-contained`) for win-x86 is what the csproj + CI already do; keep it (removes the .NET-on-host prerequisite).
- QuickBooks Web Connector (QBWC) is the *other* integration model (QB-initiated polling); intentionally **not** used here (the whole point of this project is direct COM) — the README mentions it only as the fallback if session-0 COM proves unworkable.
- The QuickBooks Desktop SDK / qbXML is essentially frozen tech (last meaningful SDK release ~14.0, 2020); the OnScreen Reference and `qbsdklog.txt` are the canonical references and they're stable. The re-pin work is about matching *this host's QuickBooks Enterprise version's* qbXML dialect, not about SDK churn.

---

## Open Questions

1. **Expose `VerifyChainAsync`?** `AuditLog.VerifyChainAsync()` exists but nothing calls it outside tests. **Recommendation:** add a `--verify-audit` arg to `Program.cs` (resolve `AuditLog` from a minimal host, call it, print `OK`/`broken at seq N`, `Environment.Exit`). ~15 lines, fully unit-testable, closes a real operator gap, doesn't touch QuickBooks. Planner should decide; if not, the README must explicitly call it a v2 gap and give the manual tail-and-eyeball procedure.

2. **Does `RealRequestProcessor` need to declare personal-data access (`pdpRequired`)?** The current COM forwarder calls `AuthPreferences().PutUnattendedModePref(...)` but (from the Phase-1 stub interop) there's no obvious `qbXMLPersonalDataPref` declaration. If the host smoke shows customer/vendor PII fields are masked and the auth dialog never offered a personal-data checkbox, that's a small `RealRequestProcessor`/interop change to make in this phase. **LOW confidence** — operator must verify on the host; the plan should flag it as a contingency, not a guaranteed task.

3. **`Qb:AppId` lifecycle.** Does QuickBooks assign the AppID on first authorization (and you then pin it in `appsettings.json`), or does the app declare it up front? The sample has `"AppId": "REPLACE-WITH-APP-ID"`. `register-integrated-app.md` needs to say which; **MEDIUM confidence** it's app-declared (a GUID/string you choose), with QB keying the grant on it — but the operator should confirm. If it's app-declared, generate a stable GUID once and bake it into the sample's guidance.

4. **Script folder path & forward-reference fixups.** The skill (`setup-and-troubleshooting.md`), `ServerOptions.cs`'s XML comment, and `MULTI-LLM.md` forward-reference `make-cert.ps1` etc. by bare name; `README.md` is referenced by full path. The planner must pick the script folder (recommend `quickbooks/QbConnectService/deploy/`) and have a task update the bare-name references to include the path so they resolve. The skill also forward-references `README.md` (path is fine) and "the on-box smoke checklist" (pick `quickbooks/QbConnectService/docs/SMOKE-CHECKLIST.md` and update the reference).

5. **Does the scheduled-task fallback actually fix session-0 QuickBooks issues?** Folklore says "run it as a task, not a service" helps; the mechanism (proper user profile, elevated token, easier to debug) is plausible but not guaranteed. Present `run-as-task.ps1` as "the documented thing to try if the service install hits `0x80040408`/`0x80040414`", with QBWC-redesign as the true last resort. **MEDIUM/LOW confidence** — don't oversell it.

---

## Sources

### Primary (HIGH confidence)
- This repo: `quickbooks/QbConnectService/src/QbConnectService/Program.cs`, `Worker.cs`, `appsettings.sample.json`, `QbConnectService.csproj`, `Options/ServerOptions.cs`, `Api/HealthEndpoints.cs`, `Api/OpsEndpoints.cs` — confirmed the tri-mode host, HTTPS-file-cert wiring, config sections, health response fields, op routes.
- This repo: `quickbooks/QbConnectService/src/QbConnectService.Qb.Com/QbErrors.cs` — the authoritative HRESULT map for the troubleshooting table; `Audit/AuditLog.cs` — `VerifyChainAsync` exists, no caller outside tests; `Interop/QBXMLRP2Lib.cs` — the `tlbimp`-on-host regen note; the various `Qb/Ops/*.cs` "Phase 9 re-pin" comments — the re-pin inventory.
- This repo: `.gitignore`, `.github/workflows/quickbooks-ci.yml`, `quickbooks/dev/MULTI-LLM.md`, `quickbooks/dev/run-codex-phase.ps1` constraints, `.claude/skills/quickbooks-accounting/references/setup-and-troubleshooting.md` + `qbxml-cheatsheet.md` (the Phase-9 forward-references), `.planning/{ROADMAP,STATE}.md`.
- Microsoft Learn — `New-Service`, `Set-Service`, `New-SelfSignedCertificate`, `Export-PfxCertificate`, `Register-ScheduledTask`, `secedit`, ASP.NET Core Windows services hosting (`AddWindowsService` / `ContentRootPath` for published apps), `sc.exe failure`/`failureflag` syntax. (General-knowledge-level, consistent with current docs.)

### Secondary (MEDIUM confidence)
- Intuit Developer — "Connections, sessions and authorizations" (<https://developer.intuit.com/app/developer/qbdesktop/docs/develop/connections-sessions-and-authorizations>): QBXMLRP2 `AuthPreferences`/`PutUnattendedModePref`, automatic-login ("batch") mode (SDK 3.0+), personal-data preference (`pdpNotNeeded`/`pdpOptional`/`pdpRequired`). The integrated-app authorization dialog flow, the "allow even if QB not running" option, the personal-data checkbox, the Edit→Preferences→Integrated Applications recovery path — these are from the QBSDK Programmer's Guide era and are MEDIUM confidence; the operator must verify the exact wording/behaviour on `10.120.254.13`.
- `theitbros.com`, `morgantechspace.com`, `jdhitsolutions.com`, `w3tutorials.net` — the `secedit`-INF / "Log on as a service" scripting pattern (multiple credible sources agree → MEDIUM).

### Tertiary (LOW confidence — flag for host verification)
- The session-0 → scheduled-task workaround for QuickBooks COM instability (QBSDK-era folklore; plausible mechanism, not authoritatively documented).
- Whether `RealRequestProcessor` must declare `pdpRequired` for the PII dialog to appear.
- `Qb:AppId` assignment lifecycle (app-declared vs QB-assigned).
- Exact qbXML `statusCode` family for personal-data-denied (≈ `530`/`531`).

## Metadata

**Confidence breakdown:**
- PowerShell / Windows service / cert mechanics: HIGH — built-in cmdlets, well-documented, plus the repo already wires the .NET side.
- Deliverable layout & scope boundary: HIGH — derived from the repo's existing forward-references, `.gitignore`, CI, and the Codex guardrails.
- QuickBooks integrated-app authorization specifics: MEDIUM — Intuit docs are sparse/old; operator must confirm on the host.
- Exact HRESULT semantics: MEDIUM — the *names/remediation* come straight from `QbErrors.cs` (HIGH), but the real-world symptom→cause mapping (esp. session-0 cases) is partly inference.
- The "constructed qbXML re-pin" inventory: HIGH (it's a grep of the codebase); the *procedure* outcome: MEDIUM (depends on the host's qbXML dialect).

**Research date:** 2026-05-12
**Valid until:** ~2026-08-12 (stable domain — .NET 8 LTS, QBSDK is frozen; revisit only if the host turns out to be a very different QuickBooks edition/version than assumed).
