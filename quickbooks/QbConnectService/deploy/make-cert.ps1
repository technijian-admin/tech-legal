[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$DnsName = '10.120.254.13',
    [string[]]$ExtraNames = @('localhost'),
    [string]$PfxPath = '.\qbconnect.pfx',
    [string]$CerPath = '.\qbconnect.cer',
    [int]$ValidYears = 5,
    [switch]$TrustLocally,
    [securestring]$PfxPassword
)

$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Generate the HTTPS certificate for QbConnectService.

.DESCRIPTION
Run this ON THE QuickBooks host (10.120.254.13), not in the dev/CI environment.
Creates a self-signed HTTPS certificate, exports a PFX for the service, and exports a public CER for clients.
#>

$subject = "CN=$DnsName"
$allNames = @($DnsName) + $ExtraNames

if (-not $PSBoundParameters.ContainsKey('PfxPassword') -and -not $WhatIfPreference) {
    $PfxPassword = Read-Host -AsSecureString -Prompt 'PFX password'
}

$existing = Get-ChildItem -Path Cert:\LocalMachine\My |
    Where-Object { $_.Subject -eq $subject }

if ($existing) {
    Write-Warning "A certificate with subject '$subject' already exists in Cert:\LocalMachine\My. This script will create a new one."
}

$cert = $null

if ($PSCmdlet.ShouldProcess('Cert:\LocalMachine\My', "Create self-signed HTTPS certificate for $DnsName")) {
    $cert = New-SelfSignedCertificate `
        -Subject $subject `
        -DnsName $allNames `
        -CertStoreLocation 'Cert:\LocalMachine\My' `
        -KeyExportPolicy Exportable `
        -KeyUsage DigitalSignature, KeyEncipherment `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -Type SSLServerAuthentication `
        -NotAfter (Get-Date).AddYears($ValidYears)
}

if ($PSCmdlet.ShouldProcess($PfxPath, 'Export service PFX')) {
    if ($null -eq $cert) {
        throw 'PFX export requested before the certificate was created.'
    }

    Export-PfxCertificate -Cert $cert -FilePath $PfxPath -Password $PfxPassword | Out-Null
}

if ($PSCmdlet.ShouldProcess($CerPath, 'Export public CER')) {
    if ($null -eq $cert) {
        throw 'CER export requested before the certificate was created.'
    }

    Export-Certificate -Cert $cert -FilePath $CerPath | Out-Null
}

if ($TrustLocally -and $PSCmdlet.ShouldProcess('Cert:\LocalMachine\Root', "Trust $CerPath locally")) {
    Import-Certificate -FilePath $CerPath -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
}

Write-Output "Next: set Server:CertPath and Server:CertPassword in appsettings.json, then distribute $CerPath to clients (or set QB_VERIFY_TLS accordingly)."

# If a strict client rejects the IP-as-DNS-name SAN, rebuild the certificate with
# [System.Security.Cryptography.X509Certificates.X509SubjectAlternativeNameBuilder]
# and an explicit IPAddress SAN entry.
