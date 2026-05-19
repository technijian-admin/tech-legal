#Requires -RunAsAdministrator
#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [string[]]$CompanyFiles,

    [Parameter(Mandatory)]
    [SecureString]$ServiceAccountPassword,

    [string]$DefaultCompanyKey,
    [string]$BearerToken,
    [SecureString]$CertPassword,
    [string]$AppNamePrefix  = 'TechnijianQbConnect',
    [string]$DnsName        = '10.120.254.13',
    [string[]]$ExtraDnsNames = @('localhost'),
    [int]$Port              = 8443,
    [string]$InstallRoot    = 'D:\QbConnectService',
    [string]$CertOutPath    = 'C:\ProgramData\QbConnectService\qbconnect.pfx',
    [string]$ServiceName    = 'QbConnectService',
    [string]$ServiceAccount = 'svc_qbsdk'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    One-shot installer for the multi-tenant QbConnectService.

.DESCRIPTION
    Installs ONE Windows service that serves N QuickBooks company files. Clients pick which
    company to operate against via the 'company' query param (or X-Qb-Company header) on each
    request.  Without that, the service uses Qb.DefaultCompany.

    Step layout:
        Step 1  Create svc_qbsdk Windows account
        Step 2  Generate the shared HTTPS PFX/CER via make-cert.ps1
        Step 3  Write appsettings.json with Qb.Companies dictionary (one entry per .QBW)
        Step 4  Create the Windows service (Automatic + crash recovery) + SeServiceLogonRight
        Step 5  Save INSTALL-RESULT.txt (bearer token + per-company AppName/AppId + URL + smoke command)

    The service talks to QuickBooks via late-bound COM (Type.GetTypeFromProgID) so it does NOT need a
    tlbimp-generated Interop.QBXMLRP2Lib.dll. Only the QuickBooks SDK COM registration on this host is required.

    Idempotent: re-runs preserve existing accounts, certs, config, service.
    Delete a single artifact to force regenerating just that step.

    NOTE: this installer assumes the deployed exe supports the Qb.Companies dictionary schema
    (multi-tenant). If you deploy an older single-company exe, it will read only Qb.CompanyFilePath
    from the FIRST entry (back-compat key is written to satisfy older builds).

.PARAMETER CompanyFiles
    One or more full paths to .QBW company files. The keys in appsettings.json are derived from
    each filename (sanitized to lowercase alphanumeric + dashes).

.PARAMETER ServiceAccountPassword
    Password for the svc_qbsdk Windows account.

.PARAMETER DefaultCompanyKey
    Which company key to use when a request omits ?company=. Defaults to the first file's key.

.PARAMETER BearerToken
    Single bearer token guarding the whole service. Auto-generated if omitted.

.PARAMETER CertPassword
    PFX password. Auto-generated if omitted.

.PARAMETER AppNamePrefix
    Each company's QuickBooks integrated-app name becomes <Prefix>-<CompanyKey>.
    Default: TechnijianQbConnect.

.PARAMETER Port
    HTTPS port. Default 8443.

.EXAMPLE
    .\install-all.ps1 `
        -CompanyFiles @(
            'D:\Quickbooks\Technijian PVT Ltd..qbw',
            'D:\Quickbooks\Electronic Corporation of America.qbw',
            'D:\Quickbooks\Kutumba Holdings LLC.qbw'
        ) `
        -ServiceAccountPassword (Read-Host -AsSecureString -Prompt 'svc_qbsdk password')
#>

# ============================================================
# Helpers
# ============================================================

function Write-Banner {
    param([string]$Step, [string]$Title)
    $bar = ('=' * 70)
    Write-Host ''
    Write-Host $bar -ForegroundColor Cyan
    Write-Host (" Step {0}  :  {1}" -f $Step, $Title) -ForegroundColor Cyan
    Write-Host $bar -ForegroundColor Cyan
}

function New-RandomHexToken {
    param([int]$Bytes = 32)
    $buf = New-Object byte[] $Bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buf)
    -join ($buf | ForEach-Object { $_.ToString('x2') })
}

function ConvertFrom-SecureToPlain {
    param([SecureString]$Secure)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try { [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Get-CompanyKey {
    param([string]$CompanyFilePath)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($CompanyFilePath)
    $name = $name -replace '\.+$', ''
    $name = $name -replace '[^a-zA-Z0-9]+', '-'
    $name = $name -replace '^-+|-+$', ''
    $name = $name.ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($name)) { throw "Cannot derive company key from '$CompanyFilePath'." }
    return $name
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# ============================================================
# Step 0 - Pre-flight
# ============================================================

Write-Banner '0' 'Pre-flight'

$binDir    = Join-Path $InstallRoot 'bin'
$deployDir = Join-Path $InstallRoot 'deploy'
$configDir = Join-Path $InstallRoot 'config'
$exePath   = Join-Path $binDir 'QbConnectService.exe'
$sampleCfg = Join-Path $configDir 'appsettings.sample.json'
$realCfg   = Join-Path $binDir 'appsettings.json'

foreach ($p in @($binDir, $deployDir, $configDir, $exePath, $sampleCfg)) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "Missing artifact: $p (deployment package is incomplete)"
    }
}

# Resolve each company file + derive its key
$companies = @{}
$orderedKeys = New-Object 'System.Collections.Generic.List[string]'
foreach ($cf in $CompanyFiles) {
    if (-not (Test-Path -LiteralPath $cf)) { throw "Company file not found: $cf" }
    $key = Get-CompanyKey -CompanyFilePath $cf
    if ($companies.ContainsKey($key)) { throw "Duplicate company key '$key' (collision between '$($companies[$key].CompanyFilePath)' and '$cf')." }
    $companies[$key] = [pscustomobject]@{
        CompanyKey      = $key
        CompanyFilePath = $cf
        AppId           = ([guid]::NewGuid()).ToString('D').ToUpper()
        AppName         = "$AppNamePrefix-$key"
    }
    $orderedKeys.Add($key)
}

if (-not $DefaultCompanyKey) { $DefaultCompanyKey = $orderedKeys[0] }
if (-not $companies.ContainsKey($DefaultCompanyKey)) {
    throw "DefaultCompanyKey '$DefaultCompanyKey' is not one of: $($orderedKeys -join ', ')"
}

. (Join-Path $deployDir '_common.ps1')
Assert-Elevated

if (-not $BearerToken) { $BearerToken = New-RandomHexToken -Bytes 32 }
if (-not $CertPassword) {
    $rawCert = New-RandomHexToken -Bytes 16
    $CertPassword = ConvertTo-SecureString -String $rawCert -AsPlainText -Force
}

Write-Host ('  Install root      : {0}' -f $InstallRoot)
Write-Host ('  Service           : {0} on port {1}  (account .\{2})' -f $ServiceName, $Port, $ServiceAccount)
Write-Host ('  Cert SAN          : {0}, {1}' -f $DnsName, ($ExtraDnsNames -join ', '))
Write-Host ('  Cert PFX          : {0}' -f $CertOutPath)
Write-Host ('  Default company  : {0}' -f $DefaultCompanyKey)
Write-Host ('  Companies ({0}):' -f $companies.Count)
foreach ($k in $orderedKeys) {
    Write-Host ('    - {0,-30} -> {1}' -f $k, $companies[$k].CompanyFilePath)
}

# ============================================================
# Step 1 - Service account
# ============================================================

Write-Banner '1' ('Service account: {0}' -f $ServiceAccount)

$existingUser = Get-LocalUser -Name $ServiceAccount -ErrorAction SilentlyContinue
if ($existingUser) {
    Write-Host "  '$ServiceAccount' already exists - skipping creation."
} elseif ($PSCmdlet.ShouldProcess($ServiceAccount, 'New-LocalUser')) {
    New-LocalUser -Name $ServiceAccount `
                  -Password $ServiceAccountPassword `
                  -FullName 'QbConnectService service account' `
                  -Description 'QbConnectService service identity' `
                  -PasswordNeverExpires `
                  -AccountNeverExpires | Out-Null
    Write-Host "  Created '$ServiceAccount'."
}

# ============================================================
# Step 2 - HTTPS certificate
# ============================================================

Write-Banner '2' ('HTTPS certificate -> {0}' -f $CertOutPath)

$certDir = Split-Path $CertOutPath -Parent
if (-not (Test-Path -LiteralPath $certDir)) {
    New-Item -ItemType Directory -Path $certDir -Force | Out-Null
}

if (Test-Path -LiteralPath $CertOutPath) {
    Write-Host "  PFX already exists at $CertOutPath - skipping (delete to regenerate)."
} else {
    $makeCertScript = Join-Path $deployDir 'make-cert.ps1'
    $cerOutPath = ($CertOutPath -replace '\.pfx$', '.cer')
    if ($PSCmdlet.ShouldProcess($CertOutPath, 'make-cert.ps1')) {
        & $makeCertScript -DnsName $DnsName -ExtraNames $ExtraDnsNames `
                          -PfxPath $CertOutPath -CerPath $cerOutPath `
                          -PfxPassword $CertPassword -ValidYears 5
        if (-not (Test-Path -LiteralPath $CertOutPath)) {
            throw "make-cert.ps1 did not produce $CertOutPath"
        }
        Write-Host ('  Wrote PFX: {0}' -f $CertOutPath)
        Write-Host ('  Wrote CER: {0}  (distribute to client workstations)' -f $cerOutPath)
    }
}

# ============================================================
# Step 3 - appsettings.json (multi-company)
# ============================================================

Write-Banner '3' 'Write appsettings.json'

if (Test-Path -LiteralPath $realCfg) {
    Write-Host "  appsettings.json already exists at $realCfg - skipping (delete to regenerate)."
} else {
    $cfg = Get-Content -LiteralPath $sampleCfg -Raw | ConvertFrom-Json

    $cfg.Server.BindUrls     = ('https://+:{0}' -f $Port)
    $cfg.Server.CertPath     = $CertOutPath
    $cfg.Server.CertPassword = (ConvertFrom-SecureToPlain -Secure $CertPassword)
    $cfg.Auth.ApiToken       = $BearerToken
    $cfg.Safety.AllowWrites  = $false

    # Multi-tenant Qb schema: Qb.Companies dictionary + Qb.DefaultCompany
    $companiesObj = New-Object PSObject
    foreach ($k in $orderedKeys) {
        $c = $companies[$k]
        $companiesObj | Add-Member -NotePropertyName $k -NotePropertyValue ([pscustomobject]@{
            CompanyFilePath = $c.CompanyFilePath
            AppId           = $c.AppId
            AppName         = $c.AppName
        })
    }

    # Replace Qb section. Keep ConnectionType / OpenMode from the sample.
    $qbConnType = if ($cfg.Qb.PSObject.Properties['ConnectionType']) { $cfg.Qb.ConnectionType } else { 'LocalQBD' }
    $qbOpenMode = if ($cfg.Qb.PSObject.Properties['OpenMode'])       { $cfg.Qb.OpenMode }       else { 'DoNotCare' }
    $cfg.Qb = [pscustomobject]@{
        DefaultCompany  = $DefaultCompanyKey
        Companies       = $companiesObj
        ConnectionType  = $qbConnType
        OpenMode        = $qbOpenMode
        # Back-compat: CompanyFilePath = the default company's file path. Older single-tenant
        # builds of QbConnectService will read this and ignore Companies / DefaultCompany.
        CompanyFilePath = $companies[$DefaultCompanyKey].CompanyFilePath
        AppId           = $companies[$DefaultCompanyKey].AppId
        AppName         = $companies[$DefaultCompanyKey].AppName
    }

    if ($PSCmdlet.ShouldProcess($realCfg, 'Write appsettings.json')) {
        Write-Utf8NoBom -Path $realCfg -Content ($cfg | ConvertTo-Json -Depth 32)
        Write-Host ('  Wrote {0}' -f $realCfg)
    }
}

# ============================================================
# Step 4 - Windows service
# ============================================================

Write-Banner '4' ('Install Windows service: {0}' -f $ServiceName)

$existingSvc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingSvc) {
    Write-Host "  Service '$ServiceName' already exists - skipping."
    Write-Host "  To recreate:   sc.exe delete $ServiceName   then re-run install-all.ps1"
} elseif ($PSCmdlet.ShouldProcess($ServiceName, 'New-Service + sc.exe failure')) {
    $svcCredential = New-Object System.Management.Automation.PSCredential(".\$ServiceAccount", $ServiceAccountPassword)
    $quotedExe = '"' + $exePath + '"'

    New-Service -Name        $ServiceName `
                -BinaryPathName $quotedExe `
                -DisplayName 'QuickBooks Connect Service' `
                -Description 'Multi-tenant Direct-SDK QuickBooks Enterprise REST bridge' `
                -StartupType Automatic `
                -Credential  $svcCredential | Out-Null

    & sc.exe failure     $ServiceName 'reset=' '86400' 'actions=' 'restart/5000/restart/5000/restart/5000' | Out-Null
    & sc.exe failureflag $ServiceName 1 | Out-Null

    Write-Host ("  Created service '{0}' (Automatic, account: .\{1})" -f $ServiceName, $ServiceAccount)
    Write-Host '  Crash recovery: restart 3x at 5s intervals (counter resets daily).'
}

Grant-ServiceLogonRight -Account $ServiceAccount

# ============================================================
# Step 5 - INSTALL-RESULT.txt
# ============================================================

$credFile = Join-Path $InstallRoot 'INSTALL-RESULT.txt'
$primaryUrl = "https://${DnsName}:$Port"
$companyBlock = foreach ($k in $orderedKeys) {
    $c = $companies[$k]
@"

  $k
    Company file : $($c.CompanyFilePath)
    AppName      : $($c.AppName)
    AppId        : $($c.AppId)
    Sample call  : $primaryUrl/api/ops/company_info?company=$k
"@
}

$summary = @"
QbConnectService - Multi-Tenant Installation Result
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')

----- Service -----
  Name             : $ServiceName
  Account          : .\$ServiceAccount  (password supplied at install time; not recorded here)
  Default company  : $DefaultCompanyKey
  URLs             : $primaryUrl/api/health
$($ExtraDnsNames | ForEach-Object { ('                     https://{0}:{1}/api/health' -f $_, $Port) } | Out-String)

----- Bearer token (single, guards all companies) -----
  $BearerToken

----- Cert PFX -----
  File     : $CertOutPath
  Password : $(ConvertFrom-SecureToPlain -Secure $CertPassword)
  Public   : $($CertOutPath -replace '\.pfx$', '.cer')   (distribute to clients)

----- Companies ($($companies.Count)) -----
$($companyBlock -join "`r`n")

==========================================================================
NEXT STEPS - do this for EACH company file ONCE, on this host
==========================================================================

For EACH .QBW above:
  1) Open QuickBooks Desktop, open the specific company file
  2) Log in as the QuickBooks Admin user
  3) File -> Switch to Single-user Mode
  4) Edit -> Preferences -> Integrated Applications -> Company Preferences
  5) Allow the application matching that company's AppName/AppId from the
     '----- Companies -----' block above
  6) Grant data access; 'Allow this application to log in automatically'
     bound to .\$ServiceAccount
  7) File -> Switch to Multi-user Mode

Then start the (one) service:
  Start-Service $ServiceName

Smoke (replace COMPANY_KEY with one of: $($orderedKeys -join ', ')):
  `$h = @{ Authorization = 'Bearer $BearerToken' }
  Invoke-RestMethod "$primaryUrl/api/health" -Headers `$h -SkipCertificateCheck
  Invoke-RestMethod "$primaryUrl/api/ops/company_info?company=COMPANY_KEY" -Headers `$h -SkipCertificateCheck

Full ordered smoke checklist: $InstallRoot\docs\SMOKE-CHECKLIST.md
QB integrated-app registration: $InstallRoot\docs\register-integrated-app.md

KEEP THIS FILE SAFE - it contains the bearer token and cert password.
"@

Write-Utf8NoBom -Path $credFile -Content $summary

# ============================================================
# Done
# ============================================================

Write-Banner 'DONE' 'Installation complete'
Write-Host ''
Write-Host ('Credentials summary: {0}' -f $credFile) -ForegroundColor Yellow
Write-Host ''
Write-Host 'REMAINING MANUAL STEPS:' -ForegroundColor Yellow
Write-Host '  1) In QuickBooks, ONCE PER company file: open the file (Admin / single-user)' -ForegroundColor Yellow
Write-Host '     -> Preferences -> Integrated Applications -> allow each TechnijianQbConnect-<key>' -ForegroundColor Yellow
Write-Host ("     -> bind auto-login to .\{0}, switch back to multi-user" -f $ServiceAccount) -ForegroundColor Yellow
Write-Host ("  2) Start-Service {0}" -f $ServiceName) -ForegroundColor Yellow
Write-Host ("  3) Smoke checklist: {0}\docs\SMOKE-CHECKLIST.md" -f $InstallRoot) -ForegroundColor Yellow
Write-Host ''
