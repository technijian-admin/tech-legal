# export-by-client-worker.ps1
#
# Re-archives one year's DocuSign envelopes organized BY CLIENT (not by date).
# For each envelope:
#   1. Fetch recipient emails + document names from DocuSign
#   2. Classify the envelope to a client code via domain map (fallback: subject scan)
#   3. Download combined signed PDF + certificate of completion
#   4. Save as: FileCabinet-new/<CLIENT>/<YYYY-MM-DD>_<doc-name>_<envid8>.pdf
#                                     and  ..._<envid8>_certificate.pdf
#
# Run one instance per year in parallel.
#
# Usage:
#   pwsh -File export-by-client-worker.ps1 -Year 2025
#   pwsh -File export-by-client-worker.ps1 -Year 2025 -DestRoot "C:\path\to\FileCabinet-new"

param(
    [Parameter(Mandatory)][int]$Year,
    [string]$DestRoot = "C:\Users\rjain\OneDrive - Technijian, Inc\Technijian Legal - Documents\FileCabinet"
)

$ErrorActionPreference = 'Stop'

# ─── Paths ───────────────────────────────────────────────────────────────────

$dsKeysFile    = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$jwtHelperPath = Join-Path (Split-Path -Parent $PSScriptRoot) "docusign-jwt-helper.js"
$manifestFile  = Join-Path (Split-Path -Parent $PSScriptRoot) "manifests\$Year.json"
$mapFile       = Join-Path $PSScriptRoot "client-domain-map.json"
$logFile       = Join-Path $PSScriptRoot "export-byclient-log-$Year.csv"
$tempDir       = Join-Path $env:TEMP "docusign-byclient-$Year"

New-Item -ItemType Directory -Path $tempDir  -Force | Out-Null
New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null

if (-not (Test-Path $manifestFile)) { throw "Manifest not found: $manifestFile" }
if (-not (Test-Path $mapFile))      { throw "Domain map not found: $mapFile" }

$envelopes = Get-Content $manifestFile -Raw | ConvertFrom-Json
$map       = Get-Content $mapFile      -Raw | ConvertFrom-Json

# Build hashtables for fast lookup
$domainMap = @{}
foreach ($p in $map.domains.PSObject.Properties) { $domainMap[$p.Name.ToLower()] = $p.Value }

$subjectCodes = @($map.subject_codes)

$keywordOverrides = @{}
foreach ($p in $map.subject_keyword_overrides.PSObject.Properties) { $keywordOverrides[$p.Name.ToLower()] = $p.Value }

$internalKeywords = @($map.internal_keywords | ForEach-Object { $_.ToLower() })

# Personal email providers — when recipient is on these, doc is almost always
# an HR letter to a candidate/employee, not a client agreement
$personalProviders = @(
    'gmail.com','yahoo.com','hotmail.com','outlook.com','icloud.com',
    'aol.com','live.com','msn.com','protonmail.com','proton.me','me.com',
    'rediffmail.com','ymail.com','rocketmail.com','hotmail.co.in','yahoo.co.in',
    'yahoo.co.uk','outlook.in','live.in'
)

# ─── DocuSign auth (per-process token, refresh as needed) ────────────────────

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
    try {
        $jwt = & $nodeCmd $jwtHelperPath $clientId $userId $tmp 2>&1
        if ($LASTEXITCODE -ne 0) { throw "JWT error: $jwt" }
    } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }

    $tok = (Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST -Body @{
        grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"; assertion = $jwt
    } -ContentType "application/x-www-form-urlencoded").access_token

    if (-not $script:dsApiUrl) {
        $info = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers @{ Authorization = "Bearer $tok" }
        $base = ($info.accounts | Where-Object { $_.account_id -eq $accountId }).base_uri
        $script:dsApiBase = "$base/restapi/v2.1"
        $script:dsApiUrl  = "$script:dsApiBase/accounts/$accountId"
    }

    $script:dsToken    = $tok
    $script:dsTokenExp = [DateTime]::UtcNow.AddSeconds(3300)
    Write-Host "[$Year] Token refreshed" -ForegroundColor DarkGray
}

function Invoke-Ds {
    param([string]$Path, [string]$OutFile = $null)
    Refresh-DsToken
    $uri  = "$script:dsApiUrl/$Path"
    $hdrs = @{ Authorization = "Bearer $script:dsToken" }
    if ($OutFile) {
        Invoke-RestMethod -Uri $uri -Method GET -Headers $hdrs -OutFile $OutFile
    } else {
        Invoke-RestMethod -Uri $uri -Method GET -Headers $hdrs
    }
}

# ─── Helpers ─────────────────────────────────────────────────────────────────

function Get-SafeName {
    param([string]$s, [int]$max = 90)
    if (-not $s) { return 'untitled' }
    $s = $s -replace '[\\/:*?"<>|#%&{}+`=@!$\x00-\x1F]', '_' -replace '\s+', ' ' -replace '^\s|\s$', ''
    $s = $s -replace '^\.+',''
    if ($s.Length -gt $max) { $s = $s.Substring(0, $max).TrimEnd() }
    if (-not $s) { return 'untitled' }
    $s
}

function Get-DocBaseName {
    param([string]$DocName, [string]$Subject)
    # Prefer the document name (stripped of extension) over the subject
    $candidate = if ($DocName) { $DocName } else { $Subject }
    # Strip "Complete with Docusign: " prefix that DocuSign auto-adds
    $candidate = $candidate -replace '^Complete with Docusign:\s*',''
    $candidate = $candidate -replace '^Please sign this\s+',''
    # Strip common file extensions
    $candidate = $candidate -replace '\.(pdf|docx?|xlsx?|pptx?|txt|rtf)$',''
    Get-SafeName -s $candidate -max 90
}

function Classify-Envelope {
    param($Recipients, $Subject, $DocNames)

    $allText = (@($Subject) + @($DocNames)) -join ' '
    $allTextLower = $allText.ToLower()

    # 1. Internal keyword check (offer letters, NDAs to staff, etc.)
    foreach ($kw in $internalKeywords) {
        if ($allTextLower -match [regex]::Escape($kw)) { return 'TECHNIJIAN' }
    }

    # 2. Subject keyword overrides (e.g., "Tartan" → TOR vs "Falconer" → FOR)
    foreach ($k in $keywordOverrides.Keys) {
        if ($allTextLower -match [regex]::Escape($k)) { return $keywordOverrides[$k] }
    }

    # 3. Subject scan for explicit client codes (e.g., "SOW-AFFG-001")
    foreach ($code in $subjectCodes) {
        if ($allText -match "(?<![A-Z])$code(?![A-Z])") { return $code }
    }

    # 4. Recipient domain match (skip @technijian.com — that's the sender)
    $externalDomains = @()
    foreach ($r in $Recipients) {
        if (-not $r) { continue }
        $email = "$r".ToLower()
        if ($email -notmatch '@') { continue }
        $dom = ($email -split '@')[-1].Trim()
        if ($dom -match '^technijian\.') { continue }
        if ($domainMap.ContainsKey($dom)) { return $domainMap[$dom] }
        $externalDomains += $dom
    }

    # 5. If only Technijian recipients (or none external) → internal
    if (-not $externalDomains -or $externalDomains.Count -eq 0) {
        return 'TECHNIJIAN'
    }

    # 6. If all external recipients are personal email providers (gmail, yahoo, etc.)
    #    this is almost certainly an internal HR doc (offer letter to candidate, etc.)
    $allPersonal = $true
    foreach ($d in $externalDomains) {
        if ($personalProviders -notcontains $d) { $allPersonal = $false; break }
    }
    if ($allPersonal) { return 'TECHNIJIAN' }

    # 7. Fall back: UNCLASSIFIED bucket for human triage
    return 'UNCLASSIFIED'
}

# ─── Progress tracking ───────────────────────────────────────────────────────

$done = @{}
if (Test-Path $logFile) {
    Import-Csv $logFile | Where-Object { $_.Status -eq 'done' } | ForEach-Object { $done[$_.EnvelopeId] = $true }
    Write-Host "[$Year] Resuming: $($done.Count) already done" -ForegroundColor Yellow
}

function Add-Log {
    param($EnvelopeId, $ClientCode, $DestFile, $Subject, $DocName, $Status, $Err = '')
    [PSCustomObject]@{
        EnvelopeId = $EnvelopeId
        ClientCode = $ClientCode
        DestFile   = $DestFile
        Subject    = ($Subject -replace '"','')
        DocName    = ($DocName -replace '"','')
        Status     = $Status
        Error      = ($Err -replace '"','')
        Timestamp  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    } | Export-Csv -Path $logFile -Append -NoTypeInformation
}

# ─── Main ────────────────────────────────────────────────────────────────────

Refresh-DsToken

$nDone = 0; $nSkip = 0; $nErr = 0
$total = $envelopes.Count
Write-Host "[$Year] Processing $total envelopes -> $DestRoot" -ForegroundColor Cyan

foreach ($env in $envelopes) {
    $eid = $env.EnvelopeId
    if ($done.ContainsKey($eid)) { $nSkip++; continue }

    $combinedTmp = Join-Path $tempDir "${eid}.pdf"
    $certTmp     = Join-Path $tempDir "${eid}_cert.pdf"

    try {
        # Fetch recipients + documents in two separate calls (some envelopes 400 on combined include)
        $recResp = Invoke-Ds -Path "envelopes/$eid/recipients"
        $recipients = @()
        foreach ($cat in @('signers','carbonCopies','agents','editors','intermediaries','certifiedDeliveries')) {
            if ($recResp.$cat) { $recipients += $recResp.$cat | ForEach-Object { $_.email } }
        }
        $recipients = $recipients | Where-Object { $_ } | Select-Object -Unique

        $docsResp = Invoke-Ds -Path "envelopes/$eid/documents"
        $docs = @()
        if ($docsResp.envelopeDocuments) { $docs = @($docsResp.envelopeDocuments) }
        $signedDocs = @($docs | Where-Object {
            $_.documentId -notmatch '^certificate' -and
            $_.type -ne 'summary' -and
            $_.documentId -notmatch '^summary'
        })
        # Force array context to avoid PowerShell single-element unwrapping (string -> char)
        $docNames = @($signedDocs | ForEach-Object { [string]$_.name })
        $primaryName = if ($docNames.Count -gt 0) { [string]$docNames[0] } else { [string]$env.Subject }

        $clientCode = Classify-Envelope -Recipients $recipients -Subject $env.Subject -DocNames $docNames
        $docBase    = Get-DocBaseName -DocName $primaryName -Subject $env.Subject
        $envIdShort = $eid.Substring(0, 8)
        $dateStr    = $env.DateStr
        $baseFile   = "${dateStr}_${docBase}_${envIdShort}"

        $clientDir = Join-Path $DestRoot $clientCode
        New-Item -ItemType Directory -Path $clientDir -Force | Out-Null

        $combinedDest = Join-Path $clientDir "$baseFile.pdf"
        $certDest     = Join-Path $clientDir "${baseFile}_certificate.pdf"

        Invoke-Ds -Path "envelopes/$eid/documents/combined?certificate=false" -OutFile $combinedTmp
        Invoke-Ds -Path "envelopes/$eid/documents/certificate"                -OutFile $certTmp

        Move-Item $combinedTmp $combinedDest -Force
        Move-Item $certTmp     $certDest     -Force

        Add-Log -EnvelopeId $eid -ClientCode $clientCode -DestFile $combinedDest `
                -Subject $env.Subject -DocName $primaryName -Status 'done'
        $done[$eid] = $true
        $nDone++

        $pct = [int](($nDone + $nSkip) / $total * 100)
        $shortName = if ($docBase.Length -gt 50) { $docBase.Substring(0,50) } else { $docBase }
        Write-Host "[$Year] $pct% ($($nDone+$nSkip)/$total) $clientCode | $dateStr | $shortName" -ForegroundColor Green

    } catch {
        $nErr++
        $msg = $_.Exception.Message
        Write-Host "[$Year] ERROR $eid : $msg" -ForegroundColor Red
        if ($combinedTmp -and (Test-Path $combinedTmp)) { Remove-Item $combinedTmp -ErrorAction SilentlyContinue }
        if ($certTmp     -and (Test-Path $certTmp))     { Remove-Item $certTmp     -ErrorAction SilentlyContinue }
        Add-Log -EnvelopeId $eid -ClientCode '' -DestFile '' `
                -Subject $env.Subject -DocName '' -Status 'error' -Err $msg
    }
}

Remove-Item $tempDir -Recurse -ErrorAction SilentlyContinue

Write-Host "[$Year] DONE - Saved: $nDone | Skipped: $nSkip | Errors: $nErr" -ForegroundColor Cyan
