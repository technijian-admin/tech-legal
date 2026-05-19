<#
.SYNOPSIS
    Register the qb-accountant scheduled tasks on this workstation.

.DESCRIPTION
    Creates three Windows Scheduled Tasks:
      QbAccountant-Daily   - daily at 07:00 (Monday-Friday)
      QbAccountant-Weekly  - Monday at 07:30 (after daily)
      QbAccountant-Monthly - 3rd of each month at 08:00

    All run as the current user, interactive (so they have access to the user's
    cred file + claude CLI auth).

.PARAMETER RepoRoot
    Repo root. Default: c:\vscode\tech-legal\tech-legal

.PARAMETER User
    User to run the tasks as. Default: current Windows user.

.PARAMETER Remove
    Remove the tasks instead of installing.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$RepoRoot = 'c:\vscode\tech-legal\tech-legal',
    [string]$User = $env:USERDOMAIN + '\' + $env:USERNAME,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$scriptDir = Join-Path $RepoRoot 'quickbooks\agent\scripts'
$stateDir  = Join-Path $RepoRoot 'quickbooks\agent\state'

# Pre-flight: state directory structure + config
if (-not $Remove) {
    $subdirs = 'harness-logs', 'snapshots', 'reports', 'pending-review'
    foreach ($sd in $subdirs) {
        $p = Join-Path $stateDir $sd
        if (-not (Test-Path $p)) {
            New-Item -ItemType Directory -Path $p -Force | Out-Null
            Write-Host "Created: $p"
        }
    }

    $configPath = Join-Path $stateDir 'config.json'
    $samplePath = Join-Path $stateDir 'config.json.sample'
    if (-not (Test-Path $configPath)) {
        if (Test-Path $samplePath) {
            Write-Host "WARNING: $configPath not found. Copying from sample." -ForegroundColor Yellow
            Copy-Item $samplePath $configPath
            Write-Host "       Please review and edit $configPath before the first scheduled run." -ForegroundColor Yellow
        } else {
            throw "Missing $configPath and no sample to copy from. Aborting."
        }
    }

    # Verify .env exists
    $envPath = Join-Path $RepoRoot 'quickbooks\clients\.env'
    if (-not (Test-Path $envPath)) {
        throw "Missing $envPath. Copy from .env.sample and fill in credentials before installing tasks."
    }

    # Verify claude CLI is on PATH
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) {
        Write-Host "WARNING: claude CLI not found on PATH. Tasks will fail at runtime." -ForegroundColor Yellow
        Write-Host "         Install Claude Code and ensure it's on PATH before running any task." -ForegroundColor Yellow
    } else {
        Write-Host "claude CLI: $($claude.Source)"
    }
}

$tasks = @(
    @{
        Name        = 'QbAccountant-Daily'
        Script      = Join-Path $scriptDir 'qb-daily.ps1'
        Trigger     = New-ScheduledTaskTrigger -Daily -At 07:00 -DaysOfWeek Monday, Tuesday, Wednesday, Thursday, Friday -ErrorAction SilentlyContinue
        Description = 'qb-accountant daily routine: bank-feed classify, AR aging, cash snapshot, daily email summary.'
    },
    @{
        Name        = 'QbAccountant-Weekly'
        Script      = Join-Path $scriptDir 'qb-weekly.ps1'
        Trigger     = New-ScheduledTaskTrigger -Weekly -At 07:30 -DaysOfWeek Monday
        Description = 'qb-accountant weekly routine: full AR cycle, AP coming-due batch, class margin trend, 30-day cash forecast.'
    },
    @{
        Name        = 'QbAccountant-Monthly'
        Script      = Join-Path $scriptDir 'qb-monthly.ps1'
        Trigger     = $null  # Monthly triggers need extra config (see below)
        Description = 'qb-accountant monthly routine: period-close prep, P&L by class, customer/vendor analysis, budget variance, recurring JE drafts.'
    }
)

# Monthly trigger: use the "DaysOfMonth" trigger
$monthlyTrigger = New-ScheduledTaskTrigger -Weekly -At 08:00 -DaysOfWeek Sunday -WeeksInterval 4
# Windows doesn't have a clean "day 3 of every month" via PowerShell cmdlets without using
# the COM API. Workaround: use a daily trigger that the script itself filters on day-of-month.
# OR use schtasks.exe directly (which DOES support "3rd of every month"):
# We'll do the latter for QbAccountant-Monthly below, bypassing Register-ScheduledTask for it.

if ($Remove) {
    foreach ($t in $tasks) {
        if (Get-ScheduledTask -TaskName $t.Name -ErrorAction SilentlyContinue) {
            if ($PSCmdlet.ShouldProcess($t.Name, 'Unregister scheduled task')) {
                Unregister-ScheduledTask -TaskName $t.Name -Confirm:$false
                Write-Host "Removed: $($t.Name)"
            }
        } else {
            Write-Host "Not registered: $($t.Name)"
        }
    }
    return
}

# Verify each script file exists
foreach ($t in $tasks) {
    if (-not (Test-Path $t.Script)) { throw "Missing script: $($t.Script)" }
}

$cred = Get-Credential -UserName $User -Message "Password for $User (needed so tasks can run when you're not logged on)"
$pwd = $cred.GetNetworkCredential().Password

foreach ($t in $tasks) {
    Write-Host "Registering $($t.Name) ..."
    $action = New-ScheduledTaskAction `
        -Execute 'pwsh.exe' `
        -Argument ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $t.Script) `
        -WorkingDirectory $scriptDir

    $settings = New-ScheduledTaskSettingsSet `
        -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
        -RestartCount 2 -RestartInterval (New-TimeSpan -Minutes 10) `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    if ($t.Name -eq 'QbAccountant-Monthly') {
        # Monthly: use schtasks.exe for "3rd of every month at 08:00"
        & schtasks.exe /Create /TN $t.Name `
            /TR ('pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $t.Script) `
            /SC MONTHLY /D 3 /ST 08:00 `
            /RU $User /RP $pwd /F | Out-Null
        & schtasks.exe /Change /TN $t.Name /RU $User /RP $pwd | Out-Null
        Write-Host "  Registered via schtasks.exe (3rd of each month, 08:00)"
    } else {
        Register-ScheduledTask `
            -TaskName $t.Name `
            -Action $action `
            -Trigger $t.Trigger `
            -Settings $settings `
            -Description $t.Description `
            -User $User -Password $pwd `
            -Force | Out-Null
        Write-Host "  Registered (trigger: $($t.Trigger.GetType().Name))"
    }
}

Write-Host ''
Write-Host '=== Registered tasks ==='
Get-ScheduledTask -TaskName 'QbAccountant-*' | Format-Table TaskName, State, Author, Description -AutoSize

Write-Host ''
Write-Host 'NEXT STEPS:'
Write-Host '  1. Verify pwsh.exe is on PATH for the scheduled-task context.'
Write-Host '  2. Verify the `claude` CLI is on PATH for the user.'
Write-Host '  3. Verify quickbooks/clients/.env has the right token + QB_DEFAULT_COMPANY.'
Write-Host '  4. Run one task on-demand to validate:  Start-ScheduledTask -TaskName QbAccountant-Daily'
Write-Host '  5. Watch the transcript in: quickbooks\agent\state\harness-logs\'
