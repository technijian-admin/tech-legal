<#
.SYNOPSIS
    Monthly QB accountant routine. Run by Windows Scheduled Task on the 3rd of each month
    for the prior month's data (gives 2-3 days for late items to land).

.DESCRIPTION
    Invokes the qb-accountant agent with the monthly task prompt.
    Generates period-close prep, full P&L by class, customer/vendor analysis,
    budget-vs-actual, and recurring JE drafts.

.PARAMETER RepoRoot
    Repo root. Default: c:\vscode\tech-legal\tech-legal

.PARAMETER LogDir
    Transcript directory.

.PARAMETER PriorMonthOverride
    Optional YYYY-MM override. Default: previous month from today.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = 'c:\vscode\tech-legal\tech-legal',
    [string]$LogDir   = 'c:\vscode\tech-legal\tech-legal\quickbooks\agent\state\harness-logs',
    [string]$PriorMonthOverride
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$transcript = Join-Path $LogDir ("qb-monthly-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null

try {
    # Derive prior month (or use override)
    if ($PriorMonthOverride) {
        $priorMonth = $PriorMonthOverride
        $parts = $priorMonth.Split('-')
        $year = [int]$parts[0] ; $month = [int]$parts[1]
    } else {
        $today = Get-Date
        $priorMonthDate = $today.AddMonths(-1)
        $year = $priorMonthDate.Year
        $month = $priorMonthDate.Month
        $priorMonth = "{0:0000}-{1:00}" -f $year, $month
    }
    $monthStart = "{0:0000}-{1:00}-01" -f $year, $month
    $monthEnd = (Get-Date $monthStart).AddMonths(1).AddDays(-1).ToString('yyyy-MM-dd')

    Write-Host "=== QB Accountant Monthly for $priorMonth ($monthStart -> $monthEnd) — running at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') ==="
    Set-Location $RepoRoot

    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) { throw "claude CLI not found on PATH." }

    $prompt = @"
You are the qb-accountant agent. Run the MONTHLY routine for the period ${monthStart} through ${monthEnd}, as documented in .claude/agents/qb-accountant.md.

Tasks in order:
1. Period-close checklist for ${priorMonth}. Walk the 10 stages in .claude/skills/quickbooks-period-close/SKILL.md. For each stage, report pass/fail/needs-review. Save unfinished items to state/pending-review/${priorMonth}-close-prep.json.
2. Full P&L by class for ${priorMonth}. Use raw qbXML GeneralSummaryReportQueryRq with SummarizeColumnsBy=Class. Parse and produce a class x category (Income/COGS/Expense/Net) summary table. Save to state/snapshots/pl-by-class-${priorMonth}.csv. Compare to prior month - highlight classes that moved materially.
3. Customer profitability YTD. Top 10 by net contribution + bottom 10 by net (i.e., the worst customers). Save to state/snapshots/customer-profitability-${priorMonth}.csv. See .claude/skills/quickbooks-customer-profitability/SKILL.md.
4. Vendor spend YTD. Top 20 by total spend + concentration analysis. Flag 1099-eligible vendors approaching/exceeding the \$600 threshold. Save to state/snapshots/vendor-spend-${priorMonth}.csv.
5. Budget vs actual for ${priorMonth} (if budget exists). Flag accounts with >20% variance. Save to state/snapshots/budget-variance-${priorMonth}.csv.
6. Cash flow snapshot + YTD trend. Use snapshots/cash-*.csv history. Plot starting/ending cash by month.
7. Recurring JE drafts for the period:
   - Depreciation (if fixed assets in service)
   - Prepaid insurance roll-forward (if 1300 - Prepaid Insurance has balance)
   - Any other monthly accruals from your library
   Save the proposed JEs to state/pending-review/${priorMonth}-monthly-jes.json. DO NOT execute.
8. Write a monthly summary to state/reports/monthly-${priorMonth}.md. Email to rjain@technijian.com.

Be concise. Use markdown tables. Surface what needs review at the top.
"@

    Write-Host "Invoking claude..."
    & claude -p $prompt --output-format text 2>&1 | Tee-Object -FilePath (Join-Path $LogDir ("qb-monthly-output-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log"))

    Write-Host "=== Monthly routine complete at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz') ==="
}
catch {
    Write-Host "ERROR in qb-monthly: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}
