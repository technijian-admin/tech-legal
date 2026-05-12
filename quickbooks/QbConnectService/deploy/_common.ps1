[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Shared helpers for QbConnectService deploy scripts.

.DESCRIPTION
Run this ON THE QuickBooks host (10.120.254.13), not in the dev/CI environment.
This file is dot-sourced by the other deploy scripts and must have no top-level side effects.
#>

function Assert-Elevated {
    [CmdletBinding()]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Administrator rights are required for this operation. Re-run from an elevated PowerShell session.'
    }
}

function Grant-ServiceLogonRight {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string]$Account
    )

    $sid = ([Security.Principal.NTAccount]::new($Account)).Translate([Security.Principal.SecurityIdentifier]).Value
    $principalEntry = "*$sid"

    if (-not $PSCmdlet.ShouldProcess($Account, "Grant 'Log on as a service' (SeServiceLogonRight) via secedit")) {
        return
    }

    $tempDir = Join-Path ([IO.Path]::GetTempPath()) ("qbconnect-secedit-" + [guid]::NewGuid().ToString('N'))
    $cfgPath = Join-Path $tempDir 'user-rights.inf'
    $dbPath = Join-Path $tempDir 'secedit.sdb'

    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        $null = & secedit /export /cfg $cfgPath
        if ($LASTEXITCODE -ne 0) {
            throw "secedit /export failed with exit code $LASTEXITCODE."
        }

        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.AddRange([string[]][IO.File]::ReadAllLines($cfgPath))

        $privilegeSectionIndex = -1
        $serviceRightIndex = -1

        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -match '^\[Privilege Rights\]\s*$') {
                $privilegeSectionIndex = $index
                continue
            }

            if ($lines[$index] -match '^\s*SeServiceLogonRight\s*=') {
                $serviceRightIndex = $index
            }
        }

        if ($serviceRightIndex -ge 0) {
            $existingEntries = @(
                (($lines[$serviceRightIndex] -split '=', 2)[1] -split ',') |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ }
            )

            if ($existingEntries -contains $principalEntry) {
                Write-Verbose "$Account already has SeServiceLogonRight."
                return
            }

            $existingEntries += $principalEntry
            $lines[$serviceRightIndex] = 'SeServiceLogonRight = ' + ($existingEntries -join ',')
        }
        else {
            if ($privilegeSectionIndex -lt 0) {
                $lines.Add('[Privilege Rights]') | Out-Null
                $privilegeSectionIndex = $lines.Count - 1
            }

            $lines.Insert($privilegeSectionIndex + 1, "SeServiceLogonRight = $principalEntry")
        }

        [IO.File]::WriteAllLines($cfgPath, $lines)

        $null = & secedit /configure /db $dbPath /cfg $cfgPath /areas USER_RIGHTS
        if ($LASTEXITCODE -ne 0) {
            throw "secedit /configure failed with exit code $LASTEXITCODE."
        }

        Write-Output "Granted 'Log on as a service' to $Account."
    }
    finally {
        if (Test-Path -LiteralPath $tempDir) {
            Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Manual fallback if the policy edit fails: secpol.msc -> Local Policies -> User Rights Assignment ->
    # Log on as a service.
}

function Get-RepoRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).ProviderPath
}
