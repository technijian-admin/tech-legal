# export-docusign-worker.ps1
# Processes one year's DocuSign envelopes: downloads and saves to OneDrive.
# Run one instance per year in parallel.
#
# Usage: pwsh -File export-docusign-worker.ps1 -Year 2022

param(
    [Parameter(Mandatory)][int]$Year
)

$ErrorActionPreference = 'Stop'

$dsKeysFile    = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$jwtHelperPath = Join-Path $PSScriptRoot "docusign-jwt-helper.js"
$manifestFile  = Join-Path $PSScriptRoot "manifests\$Year.json"
$logFile       = Join-Path $PSScriptRoot "export-log-$Year.csv"
$destBase      = "C:\Users\rjain\OneDrive - Technijian, Inc\Technijian Legal - Documents\FileCabinet"
$tempDir       = Join-Path $env:TEMP "docusign-worker-$Year"

New-Item -ItemType Directory -Path $tempDir  -Force | Out-Null
New-Item -ItemType Directory -Path $destBase -Force | Out-Null

if (-not (Test-Path $manifestFile)) { throw "Manifest not found: $manifestFile" }
$envelopes = Get-Content $manifestFile -Raw | ConvertFrom-Json

# ─── Token management ────────────────────────────────────────────────────────

$script:dsToken    = $null
$script:dsTokenExp = [DateTime]::MinValue
$script:dsApiUrl   = $null
$script:dsApiBase  = $null

function Refresh-DsToken {
    if ([DateTime]::UtcNow -lt $script:dsTokenExp) { return }

    $c = Get-Content $dsKeysFile -Raw
    $clientId  = [regex]::Match($c, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
    $userId    = [regex]::Match($c, 'User ID:\*\*\s*(\S+)').Groups[1].Value
    $accountId = [regex]::Match($c, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
    $rsaKey    = [regex]::Match($c, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

    $nodeCmd = (Get-Command node,node.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
    if (-not $nodeCmd -and (Test-Path "C:\Program Files\nodejs\node.exe")) { $nodeCmd = "C:\Program Files\nodejs\node.exe" }

    $tmp = [System.IO.Path]::GetTempFileName()
    $rsaKey | Set-Content $tmp -NoNewline
    $jwt = & $nodeCmd $jwtHelperPath $clientId $userId $tmp 2>&1
    Remove-Item $tmp -ErrorAction SilentlyContinue

    $tok = (Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST -Body @{
        grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"; assertion = $jwt
    } -ContentType "application/x-www-form-urlencoded").access_token

    if (-not $script:dsApiUrl) {
        $info    = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers @{ Authorization = "Bearer $tok" }
        $base    = ($info.accounts | Where-Object { $_.account_id -eq $accountId }).base_uri
        $script:dsApiBase = "$base/restapi/v2.1"
        $script:dsApiUrl  = "$script:dsApiBase/accounts/$accountId"
    }

    $script:dsToken    = $tok
    $script:dsTokenExp = [DateTime]::UtcNow.AddSeconds(3300)
    Write-Host "[$Year] Token refreshed" -ForegroundColor DarkGray
}

function Download-Ds {
    param([string]$Path, [string]$OutFile)
    Refresh-DsToken
    $uri = "$script:dsApiUrl/$Path"
    Invoke-RestMethod -Uri $uri -Method GET -Headers @{ Authorization = "Bearer $script:dsToken" } -OutFile $OutFile
}

# ─── Progress tracking ───────────────────────────────────────────────────────

$done = @{}
if (Test-Path $logFile) {
    Import-Csv $logFile | Where-Object { $_.Status -eq 'done' } | ForEach-Object { $done[$_.EnvelopeId] = $true }
    Write-Host "[$Year] Resuming: $($done.Count) already done" -ForegroundColor Yellow
}

function Add-Log {
    param($EnvelopeId, $Subject, $DestPath, $Status, $Err = '')
    [PSCustomObject]@{
        EnvelopeId = $EnvelopeId
        Subject    = ($Subject -replace '"','')
        DestPath   = $DestPath
        Status     = $Status
        Error      = ($Err -replace '"','')
        Timestamp  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    } | Export-Csv -Path $logFile -Append -NoTypeInformation
}

function Get-SafeName {
    param([string]$s, [int]$max = 80)
    $s = $s -replace '[\\/:*?"<>|#%&{}+`=@!$\x00-\x1F]', '_' -replace '\s+', ' ' -replace '^\s|\s$', ''
    if ($s.Length -gt $max) { $s = $s.Substring(0, $max).TrimEnd() }
    $s
}

# ─── Main ────────────────────────────────────────────────────────────────────

$nDone = 0; $nSkip = 0; $nErr = 0
$total = $envelopes.Count
Write-Host "[$Year] Processing $total envelopes..." -ForegroundColor Cyan

Refresh-DsToken

foreach ($env in $envelopes) {
    $eid         = $env.EnvelopeId
    $safeSubject = Get-SafeName -s $env.Subject
    $folderName  = "$($env.DateStr)_${safeSubject}_${eid}"
    $destFolder  = Join-Path $destBase "$Year\$folderName"

    if ($done.ContainsKey($eid)) { $nSkip++; continue }

    $combinedFile = Join-Path $tempDir "${eid}_combined.pdf"
    $certFile     = Join-Path $tempDir "${eid}_certificate.pdf"

    try {
        Download-Ds -Path "envelopes/$eid/documents/combined?certificate=false" -OutFile $combinedFile
        Download-Ds -Path "envelopes/$eid/documents/certificate"                -OutFile $certFile

        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
        Move-Item $combinedFile (Join-Path $destFolder "combined_signed.pdf")        -Force
        Move-Item $certFile     (Join-Path $destFolder "certificate_of_completion.pdf") -Force

        Add-Log -EnvelopeId $eid -Subject $env.Subject -DestPath $destFolder -Status 'done'
        $done[$eid] = $true
        $nDone++

        $pct = [int](($nDone + $nSkip) / $total * 100)
        Write-Host "[$Year] $pct% ($($nDone+$nSkip)/$total) $($env.DateStr) | $($env.Subject.Substring(0,[Math]::Min(45,$env.Subject.Length)))" -ForegroundColor Green

    } catch {
        $nErr++
        $msg = $_.Exception.Message
        Write-Host "[$Year] ERROR $eid : $msg" -ForegroundColor Red
        Remove-Item $combinedFile, $certFile -ErrorAction SilentlyContinue
        Add-Log -EnvelopeId $eid -Subject $env.Subject -DestPath $destFolder -Status 'error' -Err $msg
    }
}

Remove-Item $tempDir -Recurse -ErrorAction SilentlyContinue

Write-Host "[$Year] DONE — Saved: $nDone | Skipped: $nSkip | Errors: $nErr" -ForegroundColor Cyan
