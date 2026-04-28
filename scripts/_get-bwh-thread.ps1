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

# Search for Brandywine messages, then filter client-side
$searchQuery = [uri]::EscapeDataString("`"from:dave@brandywine-homes.com`"")
$url = "https://graph.microsoft.com/v1.0/users/$UserMail/messages?`$search=$searchQuery&`$top=15&`$select=id,subject,from,receivedDateTime,body"

$resp = Invoke-RestMethod -Uri $url -Headers $graphHeaders -Method GET
$msgs = $resp.value | Sort-Object receivedDateTime -Descending | Select-Object -First 10

foreach ($m in $msgs) {
    Write-Host ("========================================") -ForegroundColor Cyan
    Write-Host ("Date:    {0}" -f $m.receivedDateTime) -ForegroundColor Yellow
    Write-Host ("Subject: {0}" -f $m.subject) -ForegroundColor White
    Write-Host ("----------------------------------------") -ForegroundColor DarkGray

    # Strip HTML for plain text
    $content = $m.body.content
    if ($m.body.contentType -eq "html") {
        $content = $content -replace '<style[^>]*>[\s\S]*?</style>', ''
        $content = $content -replace '<script[^>]*>[\s\S]*?</script>', ''
        $content = $content -replace '<br\s*/?>', "`n"
        $content = $content -replace '</p>', "`n"
        $content = $content -replace '</div>', "`n"
        $content = $content -replace '<[^>]+>', ''
        $content = [System.Web.HttpUtility]::HtmlDecode($content)
        $content = $content -replace '(\r?\n\s*){3,}', "`n`n"
    }
    Write-Host $content
    Write-Host ""
}
