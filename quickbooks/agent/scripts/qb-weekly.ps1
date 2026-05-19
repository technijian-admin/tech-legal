<#
.SYNOPSIS
    Weekly QB accountant routine. Run by Windows Scheduled Task each Monday morning.

.DESCRIPTION
    Invokes the qb-accountant agent with the weekly task prompt.
    Should run AFTER qb-daily on the same day.

.PARAMETER RepoRoot
    Repo root. Default: c:\vscode\tech-legal\tech-legal

.PARAMETER LogDir
    Transcript directory.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = 'c:\vscode\tech-legal\tech-legal',
    [string]$LogDir   = 'c:\vscode\tech-legal\tech-legal\quickbooks\agent\state\harness-logs'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$transcript = Join-Path $LogDir ("qb-weekly-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null

try {
    Write-Host "=== QB Accountant Weekly — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') ==="
    Set-Location $RepoRoot

    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) { throw "claude CLI not found on PATH." }

    $prompt = @'
You are the qb-accountant agent. Run this week's WEEKLY routine as documented in .claude/agents/qb-accountant.md.

Tasks in order:
1. Full AR collections cycle. Pull all open invoices, bucket by aging (friendly/pastdue/firm/final/escalate). Draft a collection email for every customer in each bucket. Save the batch to state/pending-review/<date>-ar-weekly-batch.json. DO NOT auto-send anything beyond the friendly tier (and only if state/config.json allows it).
2. AP coming due. Pull all open bills due within next 7 days. Build a prioritized payment batch (overdue > due-this-week > discount-window > defer). Surface any early-pay discount opportunities (2/10 net 30). Save to state/pending-review/<date>-ap-batch.json.
3. Class margin trend. Pull this week's P&L by class. Compare to trailing 4 weeks. Flag classes whose margin is declining > 5pt vs the trailing avg. Save to state/snapshots/class-margin-<date>.csv. Highlight declining classes in the weekly summary.
4. 30-day cash forecast. Generate using starting cash + AR (with probability haircuts) + AP + recurring ACH schedule. Save to state/snapshots/forecast-30day-<date>.csv. Flag any day where projected cash drops below $50K (configurable threshold).
5. Weekly summary report to state/reports/weekly-<YYYY-Www>.md. Email to rjain@technijian.com.

Be concise. Surface what needs Ravi's attention at the top. Use the quickbooks-* skills.
'@

    Write-Host "Invoking claude..."
    & claude -p $prompt --output-format text 2>&1 | Tee-Object -FilePath (Join-Path $LogDir ("qb-weekly-output-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log"))

    Write-Host "=== Weekly routine complete at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') ==="
}
catch {
    Write-Host "ERROR in qb-weekly: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}
