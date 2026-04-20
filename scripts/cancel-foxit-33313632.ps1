# One-off: cancel AFFG SOW-004 Rev 1 Foxit folder that was sent by mistake
# Tries multiple known Foxit cancel endpoints until one works

$ErrorActionPreference = "Stop"
$folderId = 33313632
$reason = "Switching to DocuSign per client request"
$foxitKeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md"
$baseUrl = "https://na1.foxitesign.foxit.com/api"

$foxitKeys = Get-Content $foxitKeysFile -Raw
$clientId = [regex]::Match($foxitKeys, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$clientSecret = [regex]::Match($foxitKeys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$tokenResponse = Invoke-RestMethod -Uri "$baseUrl/oauth2/access_token" -Method POST -Body @{
    grant_type=  "client_credentials"; client_id= $clientId; client_secret=$clientSecret; scope= "read-write"
} -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token
$headers = @{ "Authorization" = "Bearer $accessToken" }
$jsonHeaders = @{ "Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" }

$attempts = @(
    @{ Method = "POST";   Uri = "$baseUrl/folders/$folderId/cancel";       Body = (@{ reason = $reason } | ConvertTo-Json) },
    @{ Method = "POST";   Uri = "$baseUrl/folders/cancelfolder";           Body = (@{ folderId = $folderId; reason = $reason } | ConvertTo-Json) },
    @{ Method = "PUT";    Uri = "$baseUrl/folders/$folderId/status";       Body = (@{ status = "CANCELLED"; reason = $reason } | ConvertTo-Json) },
    @{ Method = "POST";   Uri = "$baseUrl/folders/$folderId/void";         Body = (@{ reason = $reason } | ConvertTo-Json) },
    @{ Method = "DELETE"; Uri = "$baseUrl/folders/$folderId";              Body = $null },
    @{ Method = "POST";   Uri = "$baseUrl/folders/$folderId/actions/cancel"; Body = (@{ reason = $reason } | ConvertTo-Json) }
)

foreach ($a in $attempts) {
    try {
        Write-Host "`nTrying $($a.Method) $($a.Uri)" -ForegroundColor Cyan
        if ($a.Body) {
            $resp = Invoke-RestMethod -Uri $a.Uri -Method $a.Method -Headers $jsonHeaders -Body $a.Body -ErrorAction Stop
        } else {
            $resp = Invoke-RestMethod -Uri $a.Uri -Method $a.Method -Headers $headers -ErrorAction Stop
        }
        Write-Host "SUCCESS. Response:" -ForegroundColor Green
        Write-Host ($resp | ConvertTo-Json -Depth 6) -ForegroundColor Gray
        Write-Host "`nEnvelope $folderId cancelled via: $($a.Method) $($a.Uri)" -ForegroundColor Green
        exit 0
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "  $statusCode $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

Write-Error "All known cancel endpoints failed. Log in to https://na1.foxitesign.foxit.com and cancel folder $folderId manually."
exit 1
