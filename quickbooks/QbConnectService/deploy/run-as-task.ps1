[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TaskName = 'QbConnectService',
    [string]$InstallDir = "$env:ProgramFiles\QbConnectService",
    [string]$Account = '.\svc_qbsdk',
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Register or remove the QbConnectService scheduled-task fallback.

.DESCRIPTION
Run this ON THE QuickBooks host (10.120.254.13), not in the dev/CI environment.
This is the documented fallback for the session-0 problem. Use it when the service install hits
0x80040408 / 0x80040414 / 0x80040401 at startup, but the same executable works when run interactively as
svc_qbsdk. The Windows service and this scheduled task are mutually exclusive; run ONE. This is not a
guaranteed fix. If direct COM remains unstable, the QBWC-polled redesign noted in quickbooks/QbConnectService/README.md
is the last resort.
#>

. (Join-Path $PSScriptRoot '_common.ps1')

if (-not $WhatIfPreference) {
    Assert-Elevated
}

if ($Remove) {
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $existingTask) {
        Write-Output "$TaskName is not registered."
        return
    }

    if ($PSCmdlet.ShouldProcess($TaskName, 'Unregister scheduled task')) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    return
}

$exePath = Join-Path $InstallDir 'QbConnectService.exe'
$action = New-ScheduledTaskAction -Execute $exePath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId $Account -LogonType Password -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings

if (-not $WhatIfPreference) {
    $credential = Get-Credential -UserName $Account -Message "Password for $Account"
    $password = $credential.GetNetworkCredential().Password

    if ($PSCmdlet.ShouldProcess($TaskName, "Register scheduled task for $Account at startup")) {
        Register-ScheduledTask -TaskName $TaskName -InputObject $task -User $credential.UserName -Password $password | Out-Null
    }
}
else {
    Write-Output "WhatIf: skipping credential prompt for $Account."
    if ($PSCmdlet.ShouldProcess($TaskName, "Register scheduled task for $Account at startup")) {
        return
    }
}
