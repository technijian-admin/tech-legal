param(
    [string]$Query = "Franklin Dunn Sunrun"
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

# Pull the most recent Franklin Dunn message in full
$searchQuery = [uri]::EscapeDataString("`"fdunn@callahan-law.com`"")
$url = "https://graph.microsoft.com/v1.0/users/$UserMail/messages?`$search=$searchQuery&`$top=5&`$select=id,subject,from,toRecipients,ccRecipients,receivedDateTime,body,hasAttachments,internetMessageId"

$resp = Invoke-RestMethod -Uri $url -Headers $graphHeaders -Method GET
$msgs = $resp.value

$outDir = "c:\VSCode\tech-legal\tech-legal\docs\personal\sunrun\emails"
foreach ($m in $msgs) {
    $fromAddr = $m.from.emailAddress.address
    if ($fromAddr -ne 'fdunn@callahan-law.com') { continue }
    $safeDate = $m.receivedDateTime -replace '[:TZ]', '' -replace '-', ''
    $path = Join-Path $outDir ("franklin-dunn-{0}.txt" -f $safeDate)
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("Date:    " + $m.receivedDateTime)
    [void]$sb.AppendLine("From:    " + $m.from.emailAddress.name + " <" + $fromAddr + ">")
    $to = ($m.toRecipients | ForEach-Object { $_.emailAddress.address }) -join '; '
    $cc = ($m.ccRecipients | ForEach-Object { $_.emailAddress.address }) -join '; '
    [void]$sb.AppendLine("To:      " + $to)
    [void]$sb.AppendLine("Cc:      " + $cc)
    [void]$sb.AppendLine("Subject: " + $m.subject)
    [void]$sb.AppendLine("MessageId: " + $m.internetMessageId)
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---- BODY (" + $m.body.contentType + ") ----")
    $bodyText = $m.body.content
    if ($m.body.contentType -eq 'html') {
        $bodyText = [System.Text.RegularExpressions.Regex]::Replace($bodyText, '<style[\s\S]*?</style>', '')
        $bodyText = [System.Text.RegularExpressions.Regex]::Replace($bodyText, '<script[\s\S]*?</script>', '')
        $bodyText = [System.Text.RegularExpressions.Regex]::Replace($bodyText, '<br\s*/?>', "`n")
        $bodyText = [System.Text.RegularExpressions.Regex]::Replace($bodyText, '</p>', "`n`n")
        $bodyText = [System.Text.RegularExpressions.Regex]::Replace($bodyText, '<[^>]+>', '')
        $bodyText = [System.Web.HttpUtility]::HtmlDecode($bodyText)
        $bodyText = [System.Text.RegularExpressions.Regex]::Replace($bodyText, '\n{3,}', "`n`n")
    }
    [void]$sb.AppendLine($bodyText)
    Set-Content -Path $path -Value $sb.ToString() -Encoding UTF8
    Write-Host "Wrote $path" -ForegroundColor Green
}
