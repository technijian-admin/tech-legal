$ErrorActionPreference = "Stop"
$foxitKeys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md" -Raw
$clientId     = [regex]::Match($foxitKeys, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$clientSecret = [regex]::Match($foxitKeys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tok = Invoke-RestMethod -Uri "https://na1.foxitesign.foxit.com/api/oauth2/access_token" -Method POST `
    -Body @{ grant_type="client_credentials"; client_id=$clientId; client_secret=$clientSecret; scope="read-write" } `
    -ContentType "application/x-www-form-urlencoded"
$h = @{ "Authorization" = "Bearer $($tok.access_token)"; "Content-Type" = "application/json" }
$body = @{
    folderId = 33313632
    reason_for_cancellation = "Sent via the wrong eSign platform in error. Correct signature request follows via DocuSign."
} | ConvertTo-Json
$resp = Invoke-RestMethod -Uri "https://na1.foxitesign.foxit.com/api/folders/cancelFolder" -Method POST -Headers $h -Body $body
Write-Host "Foxit folder 33313632 cancel response:" -ForegroundColor Green
$resp | ConvertTo-Json -Depth 6 | Write-Host
