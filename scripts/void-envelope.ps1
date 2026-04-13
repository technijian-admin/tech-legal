param(
    [Parameter(Mandatory=$true)]
    [string]$EnvelopeId,
    [string]$Reason = "Superseded"
)

$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$keysContent = Get-Content $keysFile -Raw
$ClientId = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

$tempKeyPath = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKeyPath -NoNewline
$jwtHelperPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "docusign-jwt-helper.js"
$jwt = & node $jwtHelperPath $ClientId $UserId $tempKeyPath 2>&1
Remove-Item $tempKeyPath -ErrorAction SilentlyContinue

$tokenResponse = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST -Body @{
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    assertion  = $jwt
} -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token

$headers = @{ "Authorization" = "Bearer $accessToken" }
$userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers $headers
$baseUri = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
$apiUrl = "$baseUri/restapi/v2.1/accounts/$AccountId"

$voidBody = @{ status = "voided"; voidedReason = $Reason } | ConvertTo-Json
$sendHeaders = @{ "Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" }
Invoke-RestMethod -Uri "$apiUrl/envelopes/$EnvelopeId" -Method PUT -Headers $sendHeaders -Body $voidBody | Out-Null
Write-Host "Envelope $EnvelopeId voided: $Reason" -ForegroundColor Green
