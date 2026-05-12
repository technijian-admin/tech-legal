[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ServiceName = 'QbConnectService',
    [string]$InstallDir = "$env:ProgramFiles\QbConnectService",
    [string]$Account = '.\svc_qbsdk',
    [switch]$SkipPublish,
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'appsettings.json'),
    [string]$PfxPath = (Join-Path $PSScriptRoot 'qbconnect.pfx')
)

$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Publish and install the QbConnectService Windows service.

.DESCRIPTION
Run this ON THE QuickBooks host (10.120.254.13), not in the dev/CI environment.
Requires administrator rights for real installs. Use -WhatIf for a dry-run that performs no changes.
#>

. (Join-Path $PSScriptRoot '_common.ps1')

function Invoke-ScCommand {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $output = & sc.exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "sc.exe $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }

    return $output
}

if (-not $WhatIfPreference) {
    Assert-Elevated
}

$dotnetVersionText = (& dotnet --version).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'dotnet --version failed. Install the .NET 8 SDK on the host before running this script.'
}

$dotnetVersion = [Version]::Parse($dotnetVersionText)
if ($dotnetVersion.Major -lt 8) {
    throw ".NET SDK 8 or newer is required. Found '$dotnetVersionText'."
}

$repoRoot = Get-RepoRoot
$projectPath = Join-Path $repoRoot 'quickbooks\QbConnectService\src\QbConnectService'
$exePath = Join-Path $InstallDir 'QbConnectService.exe'
$quotedExePath = '"' + $exePath + '"'

if (-not $SkipPublish) {
    if ($PSCmdlet.ShouldProcess($InstallDir, 'Publish self-contained win-x86 QbConnectService build')) {
        & dotnet publish $projectPath -c Release -r win-x86 --self-contained true -p:PublishSingleFile=true -o $InstallDir
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet publish failed with exit code $LASTEXITCODE."
        }
    }
}

if (-not $WhatIfPreference -and -not (Test-Path -LiteralPath $exePath)) {
    throw "Expected published executable at '$exePath'."
}

if (Test-Path -LiteralPath $ConfigPath) {
    if ($PSCmdlet.ShouldProcess((Join-Path $InstallDir 'appsettings.json'), "Copy $ConfigPath")) {
        Copy-Item -LiteralPath $ConfigPath -Destination (Join-Path $InstallDir 'appsettings.json') -Force
    }
}
else {
    Write-Warning "No appsettings.json found at '$ConfigPath'. Supply the host-specific config before starting the service."
}

if (Test-Path -LiteralPath $PfxPath) {
    if ($PSCmdlet.ShouldProcess((Join-Path $InstallDir (Split-Path -Leaf $PfxPath)), "Copy $PfxPath")) {
        Copy-Item -LiteralPath $PfxPath -Destination (Join-Path $InstallDir (Split-Path -Leaf $PfxPath)) -Force
    }
}
else {
    Write-Warning "No PFX found at '$PfxPath'. Supply the host certificate before starting the service."
}

$credential = $null
$serviceUser = $Account
$servicePassword = ''

if (-not $WhatIfPreference) {
    $credential = Get-Credential -UserName $Account -Message "Password for $Account"
    $serviceUser = $credential.UserName
    $servicePassword = $credential.GetNetworkCredential().Password
}
else {
    Write-Output "WhatIf: skipping credential prompt for $Account."
}

$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    if ($existingService.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess($ServiceName, 'Stop existing service before reconfiguration')) {
        Stop-Service -Name $ServiceName -Force
    }

    if ($PSCmdlet.ShouldProcess($ServiceName, "Reconfigure service in place to run '$quotedExePath' as $serviceUser")) {
        Invoke-ScCommand -Arguments @(
            'config',
            $ServiceName,
            "binPath= $quotedExePath",
            'start= auto',
            "obj= $serviceUser",
            "password= $servicePassword"
        ) | Out-Null
    }
}
else {
    if ($PSCmdlet.ShouldProcess($ServiceName, "Create Windows service for '$quotedExePath' as $serviceUser")) {
        if ($null -eq $credential) {
            throw 'A credential is required to create the service.'
        }

        New-Service `
            -Name $ServiceName `
            -BinaryPathName $quotedExePath `
            -DisplayName 'QuickBooks Connect Service' `
            -Description 'Direct-SDK QuickBooks Enterprise REST bridge' `
            -StartupType Automatic `
            -Credential $credential | Out-Null
    }
}

if ($PSCmdlet.ShouldProcess($ServiceName, 'Enable restart-on-crash recovery')) {
    Invoke-ScCommand -Arguments @(
        'failure',
        $ServiceName,
        'reset= 86400',
        'actions= restart/5000/restart/5000/restart/5000'
    ) | Out-Null
}

if ($PSCmdlet.ShouldProcess($ServiceName, 'Set failureflag=1')) {
    Invoke-ScCommand -Arguments @('failureflag', $ServiceName, '1') | Out-Null
}

Grant-ServiceLogonRight -Account $serviceUser

if (-not $WhatIfPreference) {
    $qcOutput = Invoke-ScCommand -Arguments @('qc', $ServiceName)
    $binaryPathLine = $qcOutput | Select-String -Pattern 'BINARY_PATH_NAME'
    if ($binaryPathLine -and $binaryPathLine.Line -notmatch 'BINARY_PATH_NAME\s+:\s+"') {
        Write-Warning "sc.exe qc shows an unquoted BINARY_PATH_NAME. Review the service configuration before starting it."
    }
}

Write-Output 'Next: run quickbooks/QbConnectService/docs/register-integrated-app.md, then Start-Service QbConnectService, then quickbooks/QbConnectService/docs/SMOKE-CHECKLIST.md.'
