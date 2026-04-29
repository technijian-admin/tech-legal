param([Parameter(Mandatory)][string]$EnvelopeId)

$ErrorActionPreference = 'Continue'

$dsKeysFile    = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$jwtHelperPath = Join-Path (Split-Path -Parent $PSScriptRoot) "docusign-jwt-helper.js"

# Get token
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

$info = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers @{ Authorization = "Bearer $tok" }
$base = ($info.accounts | Where-Object { $_.account_id -eq $accountId }).base_uri
$apiUrl = "$base/restapi/v2.1/accounts/$accountId"
$hdrs = @{ Authorization = "Bearer $tok" }

Write-Host "Diagnosing envelope: $EnvelopeId" -ForegroundColor Cyan
Write-Host ""

# Test each call
$tests = @(
    @{ Name = "envelope details";     Path = "envelopes/$EnvelopeId" },
    @{ Name = "recipients";           Path = "envelopes/$EnvelopeId/recipients" },
    @{ Name = "documents list";       Path = "envelopes/$EnvelopeId/documents" },
    @{ Name = "combined no cert";     Path = "envelopes/$EnvelopeId/documents/combined?certificate=false"; Out = $true },
    @{ Name = "combined with cert";   Path = "envelopes/$EnvelopeId/documents/combined";                    Out = $true },
    @{ Name = "certificate";          Path = "envelopes/$EnvelopeId/documents/certificate";                 Out = $true }
)

foreach ($t in $tests) {
    Write-Host "--- $($t.Name) ---" -ForegroundColor Yellow
    Write-Host "GET $apiUrl/$($t.Path)" -ForegroundColor DarkGray
    try {
        if ($t.Out) {
            $tmpOut = [System.IO.Path]::GetTempFileName()
            Invoke-RestMethod -Uri "$apiUrl/$($t.Path)" -Headers $hdrs -OutFile $tmpOut -ErrorAction Stop
            $size = (Get-Item $tmpOut).Length
            Write-Host "  OK - $size bytes" -ForegroundColor Green
            Remove-Item $tmpOut -ErrorAction SilentlyContinue
        } else {
            $r = Invoke-RestMethod -Uri "$apiUrl/$($t.Path)" -Headers $hdrs -ErrorAction Stop
            $jsonShort = ($r | ConvertTo-Json -Depth 1 -Compress)
            if ($jsonShort.Length -gt 200) { $jsonShort = $jsonShort.Substring(0,200) + '...' }
            Write-Host "  OK: $jsonShort" -ForegroundColor Green
        }
    } catch {
        Write-Host "  FAIL: $($_.Exception.Message)" -ForegroundColor Red
        # PS Core 7+ exposes the response body via $_.ErrorDetails.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            Write-Host "  Body: $($_.ErrorDetails.Message)" -ForegroundColor Red
        } elseif ($_.Exception.Response) {
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $sr = New-Object System.IO.StreamReader($stream)
                    $body = $sr.ReadToEnd()
                    if ($body) { Write-Host "  Body: $body" -ForegroundColor Red }
                }
            } catch {}
        }
    }
    Write-Host ""
}
