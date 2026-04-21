# export-docusign-enumerate.ps1
# Fetches all completed DocuSign envelopes and writes per-year JSON manifests
# to .\manifests\{year}.json for parallel worker consumption.

$ErrorActionPreference = 'Stop'

$dsKeysFile    = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$jwtHelperPath = Join-Path $PSScriptRoot "docusign-jwt-helper.js"
$manifestDir   = Join-Path $PSScriptRoot "manifests"

New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null

# ─── Auth ────────────────────────────────────────────────────────────────────

function Get-DsToken {
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
    if ($LASTEXITCODE -ne 0) { throw "JWT error: $jwt" }

    $tok = (Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST -Body @{
        grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"; assertion = $jwt
    } -ContentType "application/x-www-form-urlencoded").access_token

    $info    = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers @{ Authorization = "Bearer $tok" }
    $base    = ($info.accounts | Where-Object { $_.account_id -eq $accountId }).base_uri
    $apiBase = "$base/restapi/v2.1"
    $apiUrl  = "$apiBase/accounts/$accountId"

    return @{ Token = $tok; ApiUrl = $apiUrl; ApiBase = $apiBase }
}

# ─── Enumerate ───────────────────────────────────────────────────────────────

Write-Host "Authenticating..." -ForegroundColor Cyan
$ds = Get-DsToken
$hdrs = @{ Authorization = "Bearer $($ds.Token)" }

$all = [System.Collections.Generic.List[object]]::new()
$nextUri = "$($ds.ApiUrl)/envelopes?status=completed&from_date=2000-01-01&count=100&order=asc&order_by=completed"

Write-Host "Fetching envelope list..." -ForegroundColor Cyan
while ($nextUri) {
    $page = Invoke-RestMethod -Uri $nextUri -Headers $hdrs
    foreach ($env in $page.envelopes) {
        $completedAt = if ($env.completedDateTime) { [DateTime]$env.completedDateTime }
                       elseif ($env.lastModifiedDateTime) { [DateTime]$env.lastModifiedDateTime }
                       else { [DateTime]::UtcNow }
        $all.Add(@{
            EnvelopeId   = $env.envelopeId
            CompletedAt  = $completedAt.ToString('s')
            Year         = $completedAt.Year
            DateStr      = $completedAt.ToString('yyyy-MM-dd')
            Subject      = $env.emailSubject
        })
    }
    Write-Host "  Fetched $($all.Count) / $($page.totalSetSize)" -ForegroundColor Gray
    $nextUri = if ($page.nextUri) { "$($ds.ApiBase)$($page.nextUri)" } else { $null }
}

# ─── Write per-year manifests ────────────────────────────────────────────────

$byYear = $all | Group-Object { $_.Year }
foreach ($grp in $byYear) {
    $outFile = Join-Path $manifestDir "$($grp.Name).json"
    $grp.Group | ConvertTo-Json -Depth 5 | Set-Content $outFile -Encoding UTF8
    Write-Host "  Year $($grp.Name): $($grp.Group.Count) envelopes -> $outFile" -ForegroundColor Green
}

Write-Host "`nTotal: $($all.Count) envelopes across $($byYear.Count) years" -ForegroundColor Cyan
Write-Host "Manifests written to: $manifestDir" -ForegroundColor Cyan
