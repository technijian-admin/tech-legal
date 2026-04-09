# Test DocuSign JWT Authentication
$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$keysContent = Get-Content $keysFile -Raw

$ClientId = [regex]::Match($keysContent, 'Client ID:\*\*\s*(\S+)').Groups[1].Value
$UserId = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

Write-Host "Client ID: $ClientId" -ForegroundColor Cyan
Write-Host "User ID: $UserId" -ForegroundColor Cyan
Write-Host "Account ID: $AccountId" -ForegroundColor Cyan
Write-Host "RSA Key loaded: $($rsaKey.Length) chars" -ForegroundColor Cyan

$OAuthUrl = "https://account.docusign.com/oauth/token"

# JWT Header
$header = @{ alg = "RS256"; typ = "JWT" } | ConvertTo-Json -Compress
$headerB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($header)).TrimEnd('=').Replace('+','-').Replace('/','_')

# JWT Payload
$now = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
$payload = @{
    iss   = $ClientId
    sub   = $UserId
    aud   = "account.docusign.com"
    iat   = $now
    exp   = $now + 3600
    scope = "signature impersonation"
} | ConvertTo-Json -Compress
$payloadB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payload)).TrimEnd('=').Replace('+','-').Replace('/','_')

# Sign with RSA
$dataToSign = "$headerB64.$payloadB64"
$pemLines = $rsaKey -split "`n" | Where-Object { $_ -notmatch "-----" -and $_.Trim() -ne "" }
$keyBase64 = ($pemLines -join "").Trim()
$keyBytes = [Convert]::FromBase64String($keyBase64)

# Try modern .NET method first, fall back to RSACryptoServiceProvider
try {
    $rsa = [System.Security.Cryptography.RSA]::Create()
    $rsa.ImportRSAPrivateKey($keyBytes, [ref]$null)
} catch {
    # Fallback: use RSACng or manual import
    Write-Host "Using fallback RSA import..." -ForegroundColor Yellow
    $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    # Import via PKCS8
    $rsa = [System.Security.Cryptography.RSA]::Create()
    # Try ImportPkcs8PrivateKey
    try {
        $rsa.ImportPkcs8PrivateKey($keyBytes, [ref]$null)
    } catch {
        # Last resort: use BouncyCastle-style manual parse
        Write-Host "Trying pwsh 7+ method..." -ForegroundColor Yellow
        $rsa = [System.Security.Cryptography.RSA]::Create()
        $pem = $rsaKey
        $rsa.ImportFromPem($pem)
    }
}
$sigBytes = $rsa.SignData(
    [System.Text.Encoding]::UTF8.GetBytes($dataToSign),
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
)
$sigB64 = [Convert]::ToBase64String($sigBytes).TrimEnd('=').Replace('+','-').Replace('/','_')
$jwt = "$dataToSign.$sigB64"

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
