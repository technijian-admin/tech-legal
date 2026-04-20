# export-docusign-to-teams.ps1
#
# Archives ALL completed DocuSign envelopes to:
#   MS Teams > Technijian Legal > FileCabinet > {year}/{date}_{subject}_{id}/
# Each envelope folder contains:
#   combined_signed.pdf   — all docs merged
#   certificate_of_completion.pdf
#
# Resumable: progress logged to export-docusign-log.csv.
# Re-run skips already-uploaded envelopes automatically.
#
# Usage:
#   pwsh -File export-docusign-to-teams.ps1 [-DryRun]

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$dsKeysFile      = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$jwtHelperPath   = Join-Path $PSScriptRoot "docusign-jwt-helper.js"
$teamsModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "teams-connector\Teams-Connector.psm1"
$tempDir         = Join-Path $env:TEMP "docusign-export"
$logFile         = Join-Path $PSScriptRoot "export-docusign-log.csv"

$TeamName    = "Technijian Legal"
$ChannelName = "FileCabinet"

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# ─── DocuSign authentication (auto-refresh) ──────────────────────────────────

$script:dsCreds      = $null
$script:dsToken      = $null
$script:dsTokenExp   = [DateTime]::MinValue
$script:dsApiUrl     = $null
$script:dsApiBase    = $null  # https://na1.docusign.net/restapi/v2.1

function Read-DsCredentials {
    $c = Get-Content $dsKeysFile -Raw
    $creds = @{
        ClientId  = [regex]::Match($c, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
        UserId    = [regex]::Match($c, 'User ID:\*\*\s*(\S+)').Groups[1].Value
        AccountId = [regex]::Match($c, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
        RsaKey    = [regex]::Match($c, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value
    }
    if (-not $creds.ClientId) { throw "Could not parse DocuSign credentials from $dsKeysFile" }
    $creds
}

function Get-DsToken {
    if ([DateTime]::UtcNow -lt $script:dsTokenExp) { return }

    Write-Host "  [DocuSign] Refreshing token..." -ForegroundColor Cyan
    if (-not $script:dsCreds) { $script:dsCreds = Read-DsCredentials }

    $nodeCmd = (Get-Command node,node.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
    if (-not $nodeCmd -and (Test-Path "C:\Program Files\nodejs\node.exe")) {
        $nodeCmd = "C:\Program Files\nodejs\node.exe"
    }
    if (-not $nodeCmd) { throw "Node.js not found — required for DocuSign JWT signing" }

    $tmp = [System.IO.Path]::GetTempFileName()
    $script:dsCreds.RsaKey | Set-Content $tmp -NoNewline
    try {
        $jwt = & $nodeCmd $jwtHelperPath $script:dsCreds.ClientId $script:dsCreds.UserId $tmp 2>&1
        if ($LASTEXITCODE -ne 0) { throw "JWT error: $jwt" }
    } finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }

    $tokenResp = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST -Body @{
        grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        assertion  = $jwt
    } -ContentType "application/x-www-form-urlencoded"

    $script:dsToken    = $tokenResp.access_token
    $script:dsTokenExp = [DateTime]::UtcNow.AddSeconds(3300)  # refresh 5 min early

    if (-not $script:dsApiUrl) {
        $info  = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" `
                     -Headers @{ Authorization = "Bearer $script:dsToken" }
        $acct  = $info.accounts | Where-Object { $_.account_id -eq $script:dsCreds.AccountId } | Select-Object -First 1
        $base  = if ($acct) { $acct.base_uri } else { "https://na1.docusign.net" }
        $script:dsApiBase = "$base/restapi/v2.1"
        $script:dsApiUrl  = "$script:dsApiBase/accounts/$($script:dsCreds.AccountId)"
    }

    Write-Host "  [DocuSign] Token refreshed, expires ~$($script:dsTokenExp.ToString('HH:mm')) UTC" -ForegroundColor Green
}

function Invoke-Ds {
    param(
        [string]$Path,          # full URL or relative path
        [string]$OutFile = $null
    )
    Get-DsToken
    # nextUri from DocuSign is root-relative like /accounts/{id}/envelopes?...
    # which lives under /restapi/v2.1, not the server root.
    # Account-relative calls (e.g. "envelopes/{id}/...") use dsApiUrl with / separator.
    $uri  = if ($Path -match '^https?://') { $Path }
            elseif ($Path -match '^/') { "$script:dsApiBase$Path" }
            else { "$script:dsApiUrl/$Path" }
    $hdrs = @{ Authorization = "Bearer $script:dsToken" }
    if ($OutFile) {
        Invoke-RestMethod -Uri $uri -Method GET -Headers $hdrs -OutFile $OutFile
    } else {
        Invoke-RestMethod -Uri $uri -Method GET -Headers $hdrs
    }
}


# ─── Progress log ────────────────────────────────────────────────────────────

$done = @{}
if (Test-Path $logFile) {
    Import-Csv $logFile | Where-Object { $_.Status -eq 'done' } | ForEach-Object {
        $done[$_.EnvelopeId] = $true
    }
    Write-Host "Resume mode: $($done.Count) envelopes already uploaded, skipping." -ForegroundColor Yellow
}

function Add-Log {
    param($EnvelopeId, $CompletedDate, $Subject, $TeamsPath, $Status, $Err = '')
    [PSCustomObject]@{
        EnvelopeId    = $EnvelopeId
        CompletedDate = $CompletedDate
        Subject       = $Subject -replace '"',''
        TeamsPath     = $TeamsPath
        Status        = $Status
        Error         = $Err -replace '"',''
        Timestamp     = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    } | Export-Csv -Path $logFile -Append -NoTypeInformation
}

# ─── Teams setup ─────────────────────────────────────────────────────────────

$teamId = $null
if (-not $DryRun) {
    Write-Host "Loading Teams-Connector..." -ForegroundColor Cyan
    if (-not (Test-Path $teamsModulePath)) { throw "Teams-Connector module not found at: $teamsModulePath" }
    Import-Module $teamsModulePath -Force
    Connect-TeamsGraph

    Write-Host "Locating team: $TeamName" -ForegroundColor Cyan
    $team = Get-TeamByName -Name $TeamName | Select-Object -First 1
    if (-not $team) { throw "Team '$TeamName' not found in this tenant." }
    $teamId = $team.id
    Write-Host "Team ID: $teamId" -ForegroundColor Green
}

# ─── Helpers ─────────────────────────────────────────────────────────────────

function Get-SafeName {
    param([string]$s, [int]$max = 80)
    $s = $s -replace '[\\/:*?"<>|#%&{}+`=@!$\x00-\x1F]', '_' -replace '\s+', ' ' -replace '^\s|\s$', ''
    if ($s.Length -gt $max) { $s = $s.Substring(0, $max).TrimEnd() }
    $s
}

# ─── Main loop ───────────────────────────────────────────────────────────────

Write-Host "`nStarting DocuSign export (status=completed, all time)...`n" -ForegroundColor Cyan
Get-DsToken

$nextUri       = "$script:dsApiUrl/envelopes?status=completed&from_date=2000-01-01&count=100&order=asc&order_by=completed"
$nFetched = 0; $nUploaded = 0; $nSkipped = 0; $nErrors = 0

while ($nextUri) {
    $page = Invoke-Ds -Path $nextUri
    if (-not $page.envelopes -or $page.envelopes.Count -eq 0) { break }

    foreach ($env in $page.envelopes) {
        $nFetched++

        $eid = $env.envelopeId
        $completedAt = if ($env.completedDateTime) {
            [DateTime]$env.completedDateTime
        } elseif ($env.lastModifiedDateTime) {
            [DateTime]$env.lastModifiedDateTime
        } else {
            [DateTime]::UtcNow
        }

        $year        = $completedAt.Year.ToString()
        $dateStr     = $completedAt.ToString('yyyy-MM-dd')
        $safeSubject = Get-SafeName -s $env.emailSubject
        $folder      = "$year/${dateStr}_${safeSubject}_${eid}"

        if ($done.ContainsKey($eid)) {
            $nSkipped++
            continue
        }

        $label = "[$nFetched] $dateStr | $($env.emailSubject)"

        if ($DryRun) {
            Write-Host "[DryRun] $label" -ForegroundColor DarkCyan
            Write-Host "         -> $folder/" -ForegroundColor DarkGray
            continue
        }

        Write-Host $label -ForegroundColor White

        $combinedFile = Join-Path $tempDir "${eid}_combined.pdf"
        $certFile     = Join-Path $tempDir "${eid}_certificate.pdf"

        try {
            # Download from DocuSign
            Invoke-Ds -Path "envelopes/$eid/documents/combined?certificate=false" -OutFile $combinedFile
            Invoke-Ds -Path "envelopes/$eid/documents/certificate"               -OutFile $certFile

            # Upload to Teams
            Set-TeamFile -TeamId $teamId -ChannelName $ChannelName `
                         -DestPath "$folder/combined_signed.pdf"            -InFile $combinedFile
            Set-TeamFile -TeamId $teamId -ChannelName $ChannelName `
                         -DestPath "$folder/certificate_of_completion.pdf"  -InFile $certFile

            Remove-Item $combinedFile, $certFile -ErrorAction SilentlyContinue

            Add-Log -EnvelopeId $eid -CompletedDate $completedAt.ToString('s') `
                    -Subject $env.emailSubject -TeamsPath $folder -Status 'done'

            $done[$eid] = $true
            $nUploaded++
            Write-Host "  -> $folder/" -ForegroundColor Green

        } catch {
            $nErrors++
            $msg = $_.Exception.Message
            Write-Host "  ERROR: $msg" -ForegroundColor Red
            Remove-Item $combinedFile, $certFile -ErrorAction SilentlyContinue
            Add-Log -EnvelopeId $eid -CompletedDate $completedAt.ToString('s') `
                    -Subject $env.emailSubject -TeamsPath $folder -Status 'error' -Err $msg
        }
    }

    # Follow DocuSign pagination
    $nextUri = if ($page.PSObject.Properties.Name -contains 'nextUri' -and $page.nextUri) {
        $page.nextUri
    } else { $null }
}

Write-Host "`n=== Export Complete ===" -ForegroundColor Cyan
Write-Host "  Fetched  : $nFetched"
Write-Host "  Uploaded : $nUploaded"
Write-Host "  Skipped  : $nSkipped  (already done)"
Write-Host "  Errors   : $nErrors"
if ($nErrors -gt 0) {
    Write-Host "  Retry errors by re-running — they were not logged as 'done'." -ForegroundColor Yellow
}
Write-Host "  Log: $logFile" -ForegroundColor Gray
