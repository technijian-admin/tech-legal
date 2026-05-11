$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$UserMail = "RJain@technijian.com"

$m365Keys = Get-Content $m365KeysFile -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()

$tok = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tid/oauth2/v2.0/token" -Method POST -Body @{
    grant_type="client_credentials"; client_id=$cid; client_secret=$sec; scope="https://graph.microsoft.com/.default"
} -ContentType "application/x-www-form-urlencoded").access_token
$H = @{ "Authorization" = "Bearer $tok"; "ConsistencyLevel" = "eventual" }

# Pull all messages whose subject contains "EOD: Rajat" received since 2026-05-01
$filter = [uri]::EscapeDataString("receivedDateTime ge 2026-05-01T00:00:00Z and startswith(subject,'Admin Reporting: Tech EOD: Rajat')")
$url = "https://graph.microsoft.com/v1.0/users/$UserMail/messages?`$filter=$filter&`$top=60&`$orderby=receivedDateTime%20desc&`$select=id,subject,receivedDateTime,from"
$all = @()
while ($url) {
    $r = Invoke-RestMethod -Uri $url -Headers $H -Method GET
    $all += $r.value
    $url = $r.'@odata.nextLink'
}
Write-Host ("=== {0} EOD-Rajat messages since 2026-05-01 ===" -f $all.Count) -ForegroundColor Cyan

foreach ($m in ($all | Sort-Object receivedDateTime)) {
    $full = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$UserMail/messages/$($m.id)?`$select=subject,receivedDateTime,body" -Headers $H -Method GET
    $txt = $full.body.content -replace '<style[^>]*>.*?</style>','' -replace '(?s)<head.*?</head>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&#39;',"'" -replace '\s+',' '
    Write-Host ""
    Write-Host ("------ {0}  |  {1}" -f $m.receivedDateTime, $full.subject) -ForegroundColor Yellow
    # try to surface clock / shift bits
    $snippet = $txt.Trim()
    if ($snippet.Length -gt 1400) { $snippet = $snippet.Substring(0,1400) + " ...[truncated]" }
    Write-Host $snippet
}
