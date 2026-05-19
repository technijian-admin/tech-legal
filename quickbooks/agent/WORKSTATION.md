# qb-accountant Agent — Workstation Setup Guide

This document is the **complete setup checklist** for any workstation that will run the autonomous `qb-accountant` agent against the Technijian QuickBooks integration.

The agent runs **scheduled accounting work** (bank-feed classification, AR collections, cash snapshots, period-close prep, etc.) by invoking Claude Code with the `qb-accountant` agent definition and the relevant `quickbooks-*` skills. See `quickbooks/agent/README.md` for architecture and `.claude/agents/qb-accountant.md` for the agent persona.

> **Distinct from `docs/WORKSTATION_SETUP.md`** — that doc covers the full tech-legal repo (Foxit, M365 Graph, docx generation, MCP servers). This doc is *focused on what the qb-accountant agent specifically needs*. Some sections overlap; defer to `WORKSTATION_SETUP.md` for the broader integrations.

---

## 0. Choose the right workstation

The agent should run on a workstation that:

- Has reliable **line-of-sight to the QuickBooks server `10.120.254.13`** (HTTPS port 8443). Same domain `technijian.local` is best, but cross-network works if the firewall allows.
- **Stays on a known schedule** — sleep/hibernate kills scheduled tasks. A desktop or always-on laptop is ideal. A dedicated low-power mini PC or always-on virtual machine is the cleanest production setup.
- Has the **OneDrive `Technijian, Inc.` tenant synced** for `rjain` (or whichever user the agent runs as). The vault memory + key files live there.
- Has stable **outbound internet** for Claude API calls + M365 Graph email.

The agent does NOT need to run on the QB server itself (that's where `QbConnectService` runs). They're separate hosts. The workstation calls the service over HTTPS.

---

## 1. Operating system + shell

| Component | Requirement | Notes |
|---|---|---|
| OS | Windows 10/11, Windows Server 2019+ | macOS / Linux would work in principle but the harness scripts are PowerShell-only |
| PowerShell | **PowerShell 7 (pwsh) is required** (not 5.1) | `winget install Microsoft.PowerShell` |
| Bash (optional) | Git Bash via Git for Windows | Some examples use bash one-liners; pwsh substitutes are always shown |
| User account | Domain-joined preferred, otherwise local with stable credentials | The scheduled tasks need a user whose password they can be registered under |

Verify pwsh:
```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
# Should print 7.x.x or later
```

---

## 2. Software prerequisites

Install in this order:

### 2.1 Git for Windows
- `winget install --id Git.Git` or download from https://git-scm.com/
- Verify: `git --version` (should print 2.40+)

### 2.2 Python 3.10+
- `winget install --id Python.Python.3.12`
- Make sure Python is on PATH
- Verify: `python --version`

### 2.3 GitHub CLI (`gh`) — optional but useful
- `winget install --id GitHub.cli`
- Verify: `gh --version`
- Auth: `gh auth login` (choose HTTPS, browser auth)

### 2.4 Claude Code CLI

The agent is invoked via `claude -p "<prompt>"`. The CLI must be installed and authenticated for the user the scheduled tasks run as.

- Install: follow https://docs.claude.com/en/docs/agents-and-tools/claude-code (currently `npm install -g @anthropic-ai/claude-code` or the official installer).
- Verify: `claude --version`
- **Authenticate**: `claude` (first run prompts for OAuth via claude.ai subscription, OR set `ANTHROPIC_API_KEY` env var for API auth)
- Verify auth: `claude -p "say hi" --output-format text` should return a short greeting.

### 2.5 PowerShell modules

For email-sending via M365 Graph:
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force
```

(If using the `m365` MCP server instead, this module isn't needed — but it's the simpler path.)

### 2.6 (Optional) M365 PowerShell context

The agent's email summary is sent via M365 Graph. If the M365 MCP server is configured globally (in `~/.claude/settings.json`), the agent can use `mcp__m365__send-mail` directly. Otherwise it uses the `send-email` global Claude skill which expects `Microsoft.Graph` PowerShell module + the OneDrive key file. Either path works; one must be set up.

---

## 3. Network + firewall

The workstation must reach the QB server. Verify:

```powershell
Test-NetConnection -ComputerName 10.120.254.13 -Port 8443 -InformationLevel Quiet
# Should return True
```

If False, check:
- Firewall on the workstation (outbound 8443/HTTPS allowed)
- Firewall on `10.120.254.13` (inbound 8443 allowed — handled by the QB host install)
- VPN or office network — the QB server is typically on the corporate LAN

### 3.1 (Optional, recommended) Trust the QB service cert

The service uses a self-signed cert. To avoid `QB_VERIFY_TLS=false` everywhere:

1. Copy `qbconnect.cer` from the QB host (path: `C:\ProgramData\QbConnectService\qbconnect.cer`) to the workstation
2. Import to the workstation's trusted root store (elevated PowerShell):
```powershell
Import-Certificate -FilePath '<path-to>\qbconnect.cer' -CertStoreLocation Cert:\LocalMachine\Root
```
3. Then in `.env`: set `QB_VERIFY_TLS=true`

---

## 4. Clone the repo + Python deps

```powershell
git clone <repo-url> c:\vscode\tech-legal
cd c:\vscode\tech-legal\tech-legal\quickbooks\clients
pip install -r requirements.txt
```

Verify:
```powershell
python -c "from qb_client import QbClient; print('ok')"
```

---

## 5. Credentials + configuration

### 5.1 Configure `quickbooks/clients/.env`

```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\clients
Copy-Item .env.sample .env
notepad .env
```

Fill in:
- `QB_API_BASE_URL=https://10.120.254.13:8443`
- `QB_API_TOKEN=<bearer>` — copy from `D:\QbConnectService\INSTALL-RESULT.txt` on the QB host. (Currently saved at `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\te-hq-app-qb.md` if synced.)
- `QB_VERIFY_TLS=false` (or `true` if you trusted the cert per §3.1)
- `QB_DEFAULT_COMPANY=technijian`

### 5.2 (Optional) DPAPI cred file for remote PSRemoting

The agent does NOT need to remote into the QB server during routine ops — all interaction is via the HTTPS API. But if you want to drive the QB server (start/stop the service, deploy updates, etc.) from this workstation, set up the cred file.

In an elevated pwsh on the workstation:

```powershell
# Trust the QB host for WinRM (NTLM auth):
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '10.120.254.13' -Force -Concatenate

# Save credential (DPAPI-encrypted, bound to your Windows account):
$cred = Get-Credential -UserName 'TECHNIJIAN\Administrator' -Message 'QB server admin'
$cred | Export-CliXml C:\Users\rjain\.qb-server-cred.xml
```

The agent only uses this if you explicitly write workflows that involve `Invoke-Command -ComputerName 10.120.254.13`. The daily/weekly/monthly routines don't need it.

### 5.3 M365 Graph credentials (for outbound email)

If using PowerShell `Send-MgUserMail` path, the credentials live in the OneDrive vault at:
```
C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md
```

Required fields (parsed via regex by scripts):
- `**App Client ID:** <guid>`
- `**Tenant ID:** <guid>`
- `**Client Secret:** <secret>`
- `**Send as:** RJain@technijian.com`

Verify Graph connectivity:
```powershell
$k = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($k,'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($k,'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($k,'Client Secret:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Get-MgUser -UserId 'RJain@technijian.com' | Select-Object DisplayName, Mail
Disconnect-MgGraph
```

Should print Ravi's display name + email. If it fails, the secret may have rotated — see `docs/WORKSTATION_SETUP.md` §5.1 for refresh.

---

## 6. Configure the agent

```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\agent\state
Copy-Item config.json.sample config.json
notepad config.json
```

Key fields to set:
- `summary_email_to` — who gets the daily/weekly/monthly summary (default `rjain@technijian.com`)
- `auto_send_friendly_reminders` — leave **false** initially. Flip to true only after a few weeks of reviewing drafts and trusting the tone.
- `cash_low_water_mark` — dollar threshold below which the forecast flags cash drops (default $50,000)
- `target_margins` — per-class GM% targets. The starter list maps Technijian's main service-line classes.
- `margin_variance_alert_pts` — how many percentage points of decline triggers a flag (default 5)

The agent reads this config on every run.

---

## 7. Smoke test (BEFORE installing scheduled tasks)

Validate every layer works before automating it.

### 7.1 QB service reachable + healthy

```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\clients
python -c "from qb_client import QbClient; c = QbClient.from_env(); import json; print(json.dumps(c.health(), indent=2))"
```

Expected: `"status": "healthy"`, `"connectionState": "SessionOpen"`, `"companyFile": "D:\\Quickbooks\\technijian.qbw"`.

If `"status": "down"` and `lastError.code` shows `0x80040408`, the QB Desktop or scheduled task on the host is not running — see `quickbooks/QbConnectService/docs/register-integrated-app.md`.

### 7.2 Run a read op

```powershell
python -c "from qb_client import QbClient; c = QbClient.from_env(); r = c.op('list_customers'); print(f'{r[\"count\"]} customers')"
```

Expected: `588 customers` (or whatever the current count is).

### 7.3 Run a multi-tenant read op

```powershell
python -c "from qb_client import QbClient; c = QbClient.from_env(); r = c.op('company_info', company='electronic-corporation-of-america'); print(r['companyName'])"
```

Expected: `Electronic Corporation of America`.

### 7.4 Claude Code can invoke the agent

```powershell
cd c:\vscode\tech-legal\tech-legal
claude -p "Acting as the qb-accountant agent: do a health check on QbConnectService for company=technijian. Report the JSON. Don't take any other action." --output-format text
```

Expected: agent prints the parsed health JSON. If Claude says it can't find the agent or skill, your repo root + agent definition path may be wrong — verify `.claude/agents/qb-accountant.md` exists in the cwd.

### 7.5 Smoke-test script (all-in-one)

```powershell
pwsh -NoProfile -File c:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts\smoke-test.ps1
```

(See §10 below for what that script does.)

---

## 8. Install the scheduled tasks

```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts
.\install-tasks.ps1
# Prompts for your Windows password.
```

This registers three tasks:

| Task name | Schedule | Script |
|---|---|---|
| `QbAccountant-Daily` | Mon-Fri 07:00 | `qb-daily.ps1` |
| `QbAccountant-Weekly` | Monday 07:30 | `qb-weekly.ps1` |
| `QbAccountant-Monthly` | 3rd of each month 08:00 | `qb-monthly.ps1` |

Verify:
```powershell
Get-ScheduledTask -TaskName 'QbAccountant-*' | Format-Table TaskName, State, NextRunTime
```

Run one on-demand to validate the full pipeline:
```powershell
Start-ScheduledTask -TaskName QbAccountant-Daily
# Watch:
$last = Get-ChildItem 'c:\vscode\tech-legal\tech-legal\quickbooks\agent\state\harness-logs\' -Filter 'qb-daily-*.log' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content $last.FullName -Tail 80 -Wait
```

You should see (in order):
1. Transcript banner with timestamp
2. Claude CLI invocation
3. Agent doing health check, bank-feed pull, cash snapshot, AR check
4. Files appearing under `state/snapshots/`, `state/pending-review/`, `state/reports/`
5. Summary email sent to `rjain@technijian.com`

---

## 9. Day-1 review

After the first daily run completes, review what the agent produced:

```powershell
$today = Get-Date -Format 'yyyy-MM-dd'
$state = 'c:\vscode\tech-legal\tech-legal\quickbooks\agent\state'

# The daily report:
Get-Content "$state\reports\daily-$today.md"

# Items needing human review:
Get-ChildItem "$state\pending-review\$today-*"

# Audit log of every action:
Get-Content "$state\audit-log.jsonl" -Tail 50
```

For the first 1-2 weeks:
- Verify the bank-feed rules produce sensible classifications. Add new rules to `quickbooks-bank-feed-classifier`'s rule library as you find them.
- Review AR reminder drafts for tone before flipping `auto_send_friendly_reminders` to true.
- Check that the cash snapshot trends look right (compare to QB Desktop balances).

---

## 10. The smoke-test script

(Save this if not already in the repo at `quickbooks/agent/scripts/smoke-test.ps1` — it's also included alongside the harness scripts.)

```powershell
pwsh -NoProfile -File c:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts\smoke-test.ps1
```

It runs 8 checks:
1. PowerShell 7+ available
2. Python 3.10+ available
3. `claude` CLI on PATH
4. `quickbooks/clients/.env` exists and has all keys
5. `quickbooks/agent/state/config.json` exists
6. QB service TCP reachable (port 8443)
7. QB service `/api/health` returns healthy
8. QB service handles multi-tenant `?company=` correctly

Any failure prints a remediation hint. **All 8 must pass before installing scheduled tasks.**

---

## 11. Disabling / removing the agent

Temporarily pause:
```powershell
Get-ScheduledTask -TaskName 'QbAccountant-*' | Disable-ScheduledTask
```

Resume:
```powershell
Get-ScheduledTask -TaskName 'QbAccountant-*' | Enable-ScheduledTask
```

Remove entirely:
```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts
.\install-tasks.ps1 -Remove
```

To stop a currently-running task:
```powershell
Stop-ScheduledTask -TaskName QbAccountant-Daily
```

---

## 12. Troubleshooting

### "claude CLI not found on PATH" in scheduled-task log
- Scheduled tasks run with the registered user's PATH at install time. If `claude` is in a npm global folder, you may need to either:
  - Pin the absolute path in the harness scripts (e.g. `& 'C:\Users\rjain\AppData\Roaming\npm\claude.cmd' -p ...`)
  - Or add the npm bin folder to system PATH

### "Service health check failed"
- The QbConnectService on `10.120.254.13` may have stopped. The service runs as a Scheduled Task in the Administrator session, NOT a Windows service (since session-0 broke QB). If Administrator isn't logged in to the QB host, the service is down.
- Check: RDP to `10.120.254.13` as Administrator, verify `Get-ScheduledTaskInfo -TaskName QbConnectService` shows LastRunResult `267009` (running) and a recent LastRunTime.

### "Daily routine never finishes / runs forever"
- The scheduled task has a 1-hour `ExecutionTimeLimit`. If hit, the task is killed. Check the transcript at `state/harness-logs/`.
- Common cause: a slow report (P&L by class for a year's worth of data) — break into smaller date ranges.

### Emails not arriving
- Verify M365 Graph creds (`§5.3`).
- Verify the recipient (`config.json.summary_email_to`).
- The first email may land in junk; whitelist `RJain@technijian.com` as a sender.

### Agent suggests writes — how do I execute them?
- Review the proposed action JSON under `state/pending-review/<date>-...json`.
- Manually invoke the Python client (or use Claude Code interactively) to dry-run + execute with explicit confirmation. See `.claude/skills/quickbooks-accounting/SKILL.md` for the safe-write workflow.

### "Workstation went to sleep, missed daily run"
- In the scheduled-task settings, set "Wake the computer to run this task" (the install-tasks.ps1 doesn't set this by default — adjust if your workstation sleeps).
- Or run the agent on a dedicated always-on machine.

### Multi-tenant: "Unknown company"
- The agent honors `QB_DEFAULT_COMPANY` from `.env`. To target another company in a query, the agent passes `?company=<key>`.
- Valid keys (as of 2026-05-19): `technijian`, `electronic-corporation-of-america`. The other two (`technijian-pvt-ltd`, `kutumba-holdings-llc`) are configured in the service but not authorized in QuickBooks — calls will fail with `QB_COULD_NOT_START`.

---

## 13. What gets installed where (file map)

```
c:\vscode\tech-legal\tech-legal\
├── .claude\
│   ├── agents\
│   │   └── qb-accountant.md                     ← The agent persona
│   └── skills\
│       ├── quickbooks-accounting\SKILL.md        ← Navigator
│       ├── quickbooks-invoices\SKILL.md
│       ├── quickbooks-bills\SKILL.md
│       ├── quickbooks-checks-and-payments\SKILL.md
│       ├── quickbooks-accounts-items-classes\SKILL.md
│       ├── quickbooks-journal-entries\SKILL.md
│       ├── quickbooks-bank-feeds\SKILL.md
│       ├── quickbooks-bank-feed-classifier\SKILL.md
│       ├── quickbooks-ar-collections\SKILL.md
│       ├── quickbooks-ap-management\SKILL.md
│       ├── quickbooks-period-close\SKILL.md
│       ├── quickbooks-vendor-spend-and-1099\SKILL.md
│       ├── quickbooks-reports\SKILL.md
│       ├── quickbooks-class-margin-analysis\SKILL.md
│       ├── quickbooks-customer-profitability\SKILL.md
│       ├── quickbooks-item-revenue-analysis\SKILL.md
│       ├── quickbooks-cash-flow\SKILL.md
│       ├── quickbooks-forecasting\SKILL.md
│       └── quickbooks-budget-vs-actual\SKILL.md
├── quickbooks\
│   ├── clients\
│   │   ├── qb_client.py                          ← Multi-tenant HTTP client
│   │   ├── .env                                  ← LIVE creds (gitignored)
│   │   ├── .env.sample                           ← template
│   │   ├── requirements.txt
│   │   └── README.md
│   └── agent\
│       ├── README.md                             ← Architecture + safety
│       ├── WORKSTATION.md                        ← THIS file
│       ├── scripts\
│       │   ├── qb-daily.ps1
│       │   ├── qb-weekly.ps1
│       │   ├── qb-monthly.ps1
│       │   ├── install-tasks.ps1
│       │   └── smoke-test.ps1
│       └── state\                                ← gitignored runtime state
│           ├── config.json.sample
│           ├── config.json                       ← LIVE config (gitignored)
│           ├── audit-log.jsonl
│           ├── last-daily-run.json
│           ├── last-weekly-run.json
│           ├── last-monthly-run.json
│           ├── snapshots\
│           ├── pending-review\
│           ├── reports\
│           └── harness-logs\
└── docs\
    └── WORKSTATION_SETUP.md                       ← Broader repo setup (Foxit, MCP, docx, etc.)
```

Workstation-specific (outside the repo):
```
C:\Users\<user>\
├── .qb-server-cred.xml                            ← Optional DPAPI cred for remote PS
└── .claude\
    ├── agents\                                    ← User-level Claude Code agents (global)
    ├── skills\                                    ← User-level skills (global)
    └── settings.json                              ← Claude Code config

C:\Users\<user>\OneDrive - Technijian, Inc\Documents\VSCODE\keys\
├── m365-graph.md                                  ← Tenant App for outbound email
└── te-hq-app-qb.md                                ← QB host credentials + bearer token
```

---

## 14. Periodic maintenance

| Task | Frequency | What |
|---|---|---|
| Review `state/pending-review/` items | Daily | Approve / reject / add new rules to bank-feed-classifier library |
| Review monthly report | Monthly | Catch anomalies, adjust target margins, update budget |
| Update bank-feed-classifier rules | As-needed | New vendors → add a rule so the agent auto-codes them next time |
| Rotate bearer token | Annually | Generate new in `appsettings.json` on the QB host, update workstation `.env` |
| Cert renewal | Every 5 years | `make-cert.ps1` rerun on QB host, re-trust on workstations |
| Claude Code auth refresh | When prompted | `claude auth login` |
| M365 Graph secret refresh | When rotated | Update `m365-graph.md` in OneDrive vault |

---

## 15. Onboarding the next person

If someone else takes over running the agent:

1. Add their AD user to the `Technijian, Inc.` OneDrive tenant so they sync the key vault
2. Help them clone the repo
3. Walk them through §5 (creds) and §7 (smoke test) live
4. Re-run `install-tasks.ps1` registered as their user (the old tasks should be removed first)
5. They'll get the daily summary email from then on

---

## See also

- `quickbooks/agent/README.md` — agent architecture, safety model, cost
- `.claude/agents/qb-accountant.md` — the agent persona itself
- `.claude/skills/quickbooks-accounting/SKILL.md` — top-level skill + safe-write workflow
- `docs/WORKSTATION_SETUP.md` — broader tech-legal repo setup (Foxit, M365, docx gen)
- `C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\te-hq-app-qb.md` — QB host operational doc (credentials, drive mappings, scheduled task setup on the QB server itself)
