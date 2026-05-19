# qb-accountant — Autonomous QuickBooks Agent

An autonomous accounting agent for Technijian that runs on a schedule and uses the `quickbooks-*` skills to:

- Classify bank-feed downloads
- Track AR and draft collection reminders
- Snapshot cash position daily
- Generate weekly cash-flow forecasts
- Produce monthly close-prep reports + P&L by class + customer/vendor analysis
- Surface anomalies for human review

The agent is **read-first and draft-only** — it never writes to QuickBooks without explicit human confirmation. Routine drafts (the friendly-tier AR reminder bucket) can optionally be auto-sent if configured.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Windows Scheduled Tasks                                          │
│    QbAccountant-Daily    (Mon-Fri 07:00)                          │
│    QbAccountant-Weekly   (Mon       07:30)                        │
│    QbAccountant-Monthly  (3rd of month 08:00)                     │
└────────────┬─────────────────────────────────────────────────────┘
             │ invokes
             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Harness scripts (this folder)                                    │
│    qb-daily.ps1                                                   │
│    qb-weekly.ps1                                                  │
│    qb-monthly.ps1                                                 │
│                                                                    │
│  Each does:  claude -p "<routine prompt>"                          │
└────────────┬─────────────────────────────────────────────────────┘
             │ spawns
             ▼
┌──────────────────────────────────────────────────────────────────┐
│  qb-accountant agent  (.claude/agents/qb-accountant.md)           │
│    + quickbooks-* skills in .claude/skills/                       │
│    + QB Python client (quickbooks/clients/qb_client.py)           │
└────────────┬─────────────────────────────────────────────────────┘
             │ writes
             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Agent state                                                       │
│    state/audit-log.jsonl      — every action, append-only         │
│    state/last-*-run.json      — most recent run metadata          │
│    state/snapshots/*.csv      — periodic data snapshots           │
│    state/reports/*.md         — generated reports                 │
│    state/pending-review/*.json — items flagged for human          │
└──────────────────────────────────────────────────────────────────┘
```

## Setup

### Prerequisites

1. **QbConnectService running** on `10.120.254.13`. Verify with `Get-Service QbConnectService` or the scheduled task `QbConnectService` (the multi-tenant variant we installed in May 2026).
2. **`claude` CLI** on PATH for the user that will run the scheduled tasks (`rjain` on `TE-HQ-LPTRJ4`).
3. **Python 3.10+** with `quickbooks/clients/requirements.txt` installed: `pip install -r quickbooks/clients/requirements.txt`.
4. **`.env` configured** at `quickbooks/clients/.env` — copy from `.env.sample` and fill:
   ```
   QB_API_BASE_URL=https://10.120.254.13:8443
   QB_API_TOKEN=<bearer token from D:\QbConnectService\INSTALL-RESULT.txt>
   QB_VERIFY_TLS=false
   QB_DEFAULT_COMPANY=technijian
   ```

### Install the scheduled tasks

```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts
.\install-tasks.ps1
# Prompts for your Windows password — needed so tasks can run when you're not logged on.
```

Verify:
```powershell
Get-ScheduledTask -TaskName 'QbAccountant-*'
```

### Configure the agent

Copy the sample config:
```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\agent\state
Copy-Item config.json.sample config.json
notepad config.json
```

Edit:
- `summary_email_to` — who gets the daily summary
- `auto_send_friendly_reminders` — default `false`. Set `true` only after you've reviewed a few weeks of drafts and trust the tone.
- `target_margins` — per-class gross margin targets (used to flag underperforming classes)
- `cash_low_water_mark` — the threshold below which the forecast flags low-cash days

`config.json` is `.gitignore`'d so credentials/preferences don't leak.

### Run one task on-demand to validate

```powershell
Start-ScheduledTask -TaskName QbAccountant-Daily
# Watch the transcript:
Get-Content (Get-ChildItem 'c:\vscode\tech-legal\tech-legal\quickbooks\agent\state\harness-logs\qb-daily-*' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName -Tail 50 -Wait
```

You should see (in order):
1. Claude Code authenticating
2. Health-check call returning healthy
3. Bank-feed pull
4. Cash snapshot
5. AR aging
6. Daily summary written + emailed

Output files appear under `state/reports/` and `state/pending-review/`.

## Daily output to expect

After a daily run you should have, in `state/`:

```
reports/daily-2026-05-19.md           — markdown summary, also emailed
snapshots/cash-2026-05-19.csv          — bank/cc snapshot for trending
pending-review/2026-05-19-bank-feed-no-rule.json     — items the classifier couldn't auto-code
pending-review/2026-05-19-bank-feed-proposed.json    — auto-classified items waiting for execute approval
pending-review/2026-05-19-ar-reminders.json          — friendly-tier AR reminder drafts
audit-log.jsonl                        — appended with each action
last-daily-run.json                    — overwritten with this run's metadata
```

Review the `pending-review/` items each morning. When you approve a batch, run the appropriate execute command (which the daily report tells you).

## Weekly output

After Monday's weekly run:

```
reports/weekly-2026-W21.md             — emailed
snapshots/forecast-30day-2026-05-19.csv — rolling cash forecast
snapshots/class-margin-2026-05-19.csv   — class margin trend
pending-review/2026-05-19-ar-weekly-batch.json  — full AR collection cycle (drafts)
pending-review/2026-05-19-ap-batch.json         — proposed bill payment batch
```

## Monthly output

After the 3rd-of-month run for prior month:

```
reports/monthly-2026-04.md             — emailed
snapshots/pl-by-class-2026-04.csv      — full P&L by class for the period
snapshots/customer-profitability-2026-04.csv
snapshots/vendor-spend-2026-04.csv
snapshots/budget-variance-2026-04.csv   — if budget exists in QB
pending-review/2026-04-close-prep.json  — period-close checklist results
pending-review/2026-04-monthly-jes.json — recurring JE drafts (depreciation, accruals, etc.)
```

## Safety / trust model

The agent operates with strict authority limits:

| Action | Authority |
|---|---|
| Reading QB data | Allowed — no approval needed |
| Writing files under `quickbooks/agent/state/` | Allowed |
| Sending the daily summary email to operator | Allowed |
| Auto-sending friendly-tier AR reminders | **Only if `auto_send_friendly_reminders: true` in config** |
| Any QB write (create/mod) | **NEVER without human "yes execute" per write** |
| Anything destructive (Void, Delete, force-close period) | Forbidden |

The agent definition is at `.claude/agents/qb-accountant.md` — review it to understand exactly what authority it has and what it does.

Every action is logged to `state/audit-log.jsonl` — append-only, never overwritten. The hash-chained QB audit log on the QB server is the immutable record of any actual QB write.

## Troubleshooting

### "Task ran but did nothing"

Check `state/harness-logs/qb-*-<timestamp>.log` for the harness transcript. Common causes:
- `claude` CLI not on PATH
- Claude not authenticated (`claude auth login`)
- Python client `.env` missing or wrong

### "Service health check failed"

The QbConnectService scheduled task on `10.120.254.13` may have stopped. Check:
```powershell
$cred = Import-CliXml C:\Users\rjain\.qb-server-cred.xml
Invoke-Command -ComputerName 10.120.254.13 -Credential $cred -ScriptBlock {
    Get-ScheduledTask -TaskName QbConnectService | Get-ScheduledTaskInfo
    Get-Process QbConnectService -ErrorAction SilentlyContinue
}
```

### "Daily routine takes too long"

The agent invokes Claude Code which calls the model + QB service in series. Typical daily run is 1-3 minutes. Set the scheduled task `ExecutionTimeLimit` to an hour just in case.

### Disabling the agent temporarily

```powershell
Get-ScheduledTask -TaskName 'QbAccountant-*' | Disable-ScheduledTask
# Re-enable:
Get-ScheduledTask -TaskName 'QbAccountant-*' | Enable-ScheduledTask
```

### Removing the agent

```powershell
cd c:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts
.\install-tasks.ps1 -Remove
```

## Cost

Each routine invokes Claude Code which spends tokens. Rough estimates:
- Daily routine: ~50-150K tokens (sonnet-4-6 typical)
- Weekly: ~150-400K tokens (more analysis)
- Monthly: ~400K-1M tokens (full period close + multi-section report)

At sonnet-4-6 pricing (~$3/M input, $15/M output), a daily run costs $0.10-$0.30. Monthly cycle ~$15-30 total. Adjustable via Claude Code's model selection (use sonnet for routine, opus for monthly judgment-heavy work).

## Files

- `.claude/agents/qb-accountant.md` — the agent persona
- `.claude/skills/quickbooks-*/SKILL.md` — the 14 skill files the agent loads on demand
- `quickbooks/agent/scripts/qb-daily.ps1` — daily harness
- `quickbooks/agent/scripts/qb-weekly.ps1` — weekly harness
- `quickbooks/agent/scripts/qb-monthly.ps1` — monthly harness
- `quickbooks/agent/scripts/install-tasks.ps1` — registers scheduled tasks
- `quickbooks/agent/state/` — agent state (gitignored)
- `quickbooks/agent/state/config.json.sample` — config template
- `quickbooks/clients/qb_client.py` — Python client used by the agent
