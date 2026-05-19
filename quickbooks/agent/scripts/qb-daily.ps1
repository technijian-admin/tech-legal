<#
.SYNOPSIS
    Daily QB accountant routine. Run by Windows Scheduled Task each morning.

.DESCRIPTION
    Invokes Claude Code in headless mode with the qb-accountant agent and the daily
    task prompt. Output goes to the agent state directory under reports/ and the
    audit log. Operator gets an email summary.

    This script is the HARNESS that triggers the AGENT (defined in
    .claude/agents/qb-accountant.md) on a schedule. The agent itself does the work.

.PARAMETER RepoRoot
    Repo root path. Default: c:\vscode\tech-legal\tech-legal

.PARAMETER LogDir
    Where to write the scheduled-task transcript. Default: <RepoRoot>\quickbooks\agent\state\harness-logs

.EXAMPLE
    pwsh.exe -NoProfile -File C:\vscode\tech-legal\tech-legal\quickbooks\agent\scripts\qb-daily.ps1
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = 'c:\vscode\tech-legal\tech-legal',
    [string]$LogDir   = 'c:\vscode\tech-legal\tech-legal\quickbooks\agent\state\harness-logs'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$transcript = Join-Path $LogDir ("qb-daily-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null

try {
    Write-Host "=== QB Accountant Daily — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') ==="
    Set-Location $RepoRoot

    # Verify Claude Code CLI is available
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) {
        throw "claude CLI not found on PATH. Install Claude Code or update PATH."
    }
    Write-Host "Claude Code: $($claude.Source)"

    $prompt = @'
You are the qb-accountant agent. Run today's DAILY routine as documented in your agent definition (.claude/agents/qb-accountant.md).

Steps in order:
1. Health-check the QbConnectService (Python client `health()`). If unhealthy, email rjain@technijian.com immediately and stop.
2. Pull pending bank-feed downloads for company=technijian. Classify using rules; save unmatched items to state/pending-review/<date>-bank-feed-no-rule.json. Save proposed classifications to state/pending-review/<date>-bank-feed-proposed.json. DO NOT execute writes.
3. Snapshot current cash position (bank accounts + credit cards) to state/snapshots/cash-<date>.csv.
4. Pull open AR; identify newly-overdue invoices (just crossed 30/60/90 thresholds since last run). For the 1-15 day friendly bucket, draft reminder emails (up to 5). Save drafts to state/pending-review/<date>-ar-reminders.json.
5. Check state/config.json for auto-send permissions. If auto_send_friendly_reminders=true, send the friendly drafts via send-email skill. Otherwise leave as drafts.
6. Write a daily summary to state/reports/daily-<date>.md. Email the summary to rjain@technijian.com.
7. Append actions to state/audit-log.jsonl. Update state/last-daily-run.json.

Be concise. Surface anomalies (large variance, service down, cash drop) at the top of the summary. Use existing skills in .claude/skills/quickbooks-*/ - load them on demand.
'@

    Write-Host "Invoking claude in headless mode..."
    # -p / --print runs Claude Code in non-interactive headless mode. Output goes to stdout.
    # --add-dir gives the agent access to additional paths if needed.
    & claude -p $prompt --output-format text 2>&1 | Tee-Object -FilePath (Join-Path $LogDir ("qb-daily-output-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log"))

    Write-Host "=== Daily routine complete at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') ==="
}
catch {
    Write-Host "ERROR in qb-daily: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
    # Try to email the operator about the failure
    try {
        $errBody = "qb-daily.ps1 failed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')`n`n$($_.Exception.Message)`n`n$($_.ScriptStackTrace)"
        # PSCmdlet Send-MailMessage is deprecated but works if SMTP is configured;
        # otherwise the operator should manually check the transcript.
        Write-Host $errBody
    } catch { }
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}
