[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ServiceName = 'QbConnectService'
)

$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Stop and remove the QbConnectService Windows service.

.DESCRIPTION
Run this ON THE QuickBooks host (10.120.254.13), not in the dev/CI environment.
Requires administrator rights for real removals. Use -WhatIf for a dry-run that performs no changes.
#>

. (Join-Path $PSScriptRoot '_common.ps1')

if (-not $WhatIfPreference) {
    Assert-Elevated
}

Write-Warning 'Close services.msc before uninstalling, or the service may remain marked for deletion until the MMC snap-in releases it.'

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Output "$ServiceName is not installed."
    return
}

if ($service.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess($ServiceName, 'Stop service')) {
    Stop-Service -Name $ServiceName -Force
}

if ($PSCmdlet.ShouldProcess($ServiceName, 'Remove Windows service')) {
    if (Get-Command -Name Remove-Service -ErrorAction SilentlyContinue) {
        Remove-Service -Name $ServiceName
    }
    else {
        $null = & sc.exe delete $ServiceName
        if ($LASTEXITCODE -ne 0) {
            throw "sc.exe delete $ServiceName failed with exit code $LASTEXITCODE."
        }
    }
}
