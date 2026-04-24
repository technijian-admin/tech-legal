param(
    [Parameter(Mandatory=$true)][string]$MessageId
)
$ErrorActionPreference = "Stop"
$UserMail = "RJain@technijian.com"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$tok = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tid/oauth2/v2.0/token" -Method POST -Body @{
    grant_type="client_credentials"; client_id=$cid; client_secret=$sec; scope="https://graph.microsoft.com/.default"
} -ContentType "application/x-www-form-urlencoded").access_token

$encoded = [uri]::EscapeDataString($MessageId)
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$UserMail/messages/$encoded" -Method DELETE -Headers @{ Authorization = "Bearer $tok" } | Out-Null
Write-Host "Deleted draft $MessageId" -ForegroundColor Green
