# Test DocuSign JWT Authentication
$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jwtHelperPath = Join-Path $scriptDir "docusign-jwt-helper.js"
$nodeCommand = (Get-Command node,node.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
if (-not $nodeCommand -and (Test-Path "C:\Program Files\nodejs\node.exe")) {
    $nodeCommand = "C:\Program Files\nodejs\node.exe"
}
$keysContent = Get-Content $keysFile -Raw

$ClientId = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

Write-Host "Client ID: $ClientId" -ForegroundColor Cyan
Write-Host "User ID: $UserId" -ForegroundColor Cyan
Write-Host "Account ID: $AccountId" -ForegroundColor Cyan
Write-Host "RSA Key loaded: $($rsaKey.Length) chars" -ForegroundColor Cyan

$OAuthUrl = "https://account.docusign.com/oauth/token"
if (-not $nodeCommand) {
    Write-Host "`nNODE COMMAND NOT FOUND. Install Node.js or add node.exe to PATH." -ForegroundColor Red
    exit 1
}

$tempKeyPath = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKeyPath -NoNewline
$jwt = & $nodeCommand $jwtHelperPath $ClientId $UserId $tempKeyPath 2>&1
Remove-Item $tempKeyPath -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nJWT GENERATION FAILED: $jwt" -ForegroundColor Red
    exit 1
}

try {
    $tokenResponse = Invoke-RestMethod -Uri $OAuthUrl -Method POST -Body @{
        grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        assertion  = $jwt
    } -ContentType "application/x-www-form-urlencoded"

    Write-Host "`nAUTH SUCCESS" -ForegroundColor Green
    $token = $tokenResponse.access_token

    # Get user info to find correct base_uri
    $headers = @{ "Authorization" = "Bearer $token" }
    $userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers $headers

    Write-Host "User: $($userInfo.name)" -ForegroundColor Yellow
    Write-Host "Email: $($userInfo.email)" -ForegroundColor Yellow

    foreach ($acct in $userInfo.accounts) {
        Write-Host "`nAccount: $($acct.account_name)" -ForegroundColor Cyan
        Write-Host "  ID: $($acct.account_id)"
        Write-Host "  Base URI: $($acct.base_uri)"
        Write-Host "  Default: $($acct.is_default)"
    }
}
catch {
    Write-Host "`nAUTH FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
}
