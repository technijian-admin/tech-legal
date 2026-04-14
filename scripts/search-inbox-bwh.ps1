param(
    [string]$Query = "brandywine"
)

$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$UserMail = "RJain@technijian.com"

$m365Keys = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId) { $m365ClientId = [regex]::Match($m365Keys, 'App Client ID = (\S+)').Groups[1].Value }
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365TenantId) { $m365TenantId = [regex]::Match($m365Keys, 'Tenant ID = (\S+)').Groups[1].Value }
$m365Secret = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365Secret) { $m365Secret = [regex]::Match($m365Keys, '(?<=Tenant ID[^\n]+\n)Client Secret = (.+)').Groups[1].Value.Trim() }

$graphTokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token" `
    -Method POST -Body @{
        grant_type    = "client_credentials"
        client_id     = $m365ClientId
        client_secret = $m365Secret
        scope         = "https://graph.microsoft.com/.default"
    } -ContentType "application/x-www-form-urlencoded"
$graphToken = $graphTokenResponse.access_token

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "ConsistencyLevel" = "eventual"
}

# Search recent messages with "brandywine" or "dave" in body/from/subject
$searchQuery = [uri]::EscapeDataString("`"$Query`"")
$url = "https://graph.microsoft.com/v1.0/users/$UserMail/messages?`$search=$searchQuery&`$top=20&`$select=id,subject,from,toRecipients,receivedDateTime,bodyPreview,hasAttachments"

$resp = Invoke-RestMethod -Uri $url -Headers $graphHeaders -Method GET
$msgs = $resp.value

Write-Host ("Found {0} messages matching '{1}'" -f $msgs.Count, $Query) -ForegroundColor Cyan
Write-Host ""

foreach ($m in $msgs) {
    $fromAddr = $m.from.emailAddress.address
    $fromName = $m.from.emailAddress.name
    Write-Host ("---") -ForegroundColor DarkGray
    Write-Host ("Date:    {0}" -f $m.receivedDateTime) -ForegroundColor Yellow
    Write-Host ("From:    {0} <{1}>" -f $fromName, $fromAddr) -ForegroundColor White
    Write-Host ("Subject: {0}" -f $m.subject) -ForegroundColor White
    Write-Host ("Preview: {0}" -f $m.bodyPreview.Substring(0, [Math]::Min(200, $m.bodyPreview.Length))) -ForegroundColor Gray
}
