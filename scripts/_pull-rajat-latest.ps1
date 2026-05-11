$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$UserMail = "RJain@technijian.com"

$m365Keys = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()

$tok = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token" `
    -Method POST -Body @{ grant_type="client_credentials"; client_id=$m365ClientId; client_secret=$m365Secret; scope="https://graph.microsoft.com/.default" } `
    -ContentType "application/x-www-form-urlencoded").access_token
$H = @{ "Authorization" = "Bearer $tok"; "ConsistencyLevel" = "eventual" }

# All recent messages mentioning rajat (search across from/to/subject/body)
$q = [uri]::EscapeDataString('"rajat"')
$url = "https://graph.microsoft.com/v1.0/users/$UserMail/messages?`$search=$q&`$top=15&`$select=id,subject,from,toRecipients,ccRecipients,receivedDateTime,bodyPreview,hasAttachments,conversationId"
$resp = Invoke-RestMethod -Uri $url -Headers $H -Method GET
$msgs = $resp.value | Sort-Object receivedDateTime -Descending

Write-Host ("=== {0} messages matching 'rajat' (newest first) ===" -f $msgs.Count) -ForegroundColor Cyan
$i = 0
foreach ($m in $msgs) {
    $i++
    $from = "{0} <{1}>" -f $m.from.emailAddress.name, $m.from.emailAddress.address
    Write-Host ""
    Write-Host ("[{0}] {1}" -f $i, $m.receivedDateTime) -ForegroundColor Yellow
    Write-Host ("    From:    {0}" -f $from)
    Write-Host ("    To:      {0}" -f (($m.toRecipients | ForEach-Object { $_.emailAddress.address }) -join ", "))
    if ($m.ccRecipients) { Write-Host ("    Cc:      {0}" -f (($m.ccRecipients | ForEach-Object { $_.emailAddress.address }) -join ", ")) }
    Write-Host ("    Subject: {0}" -f $m.subject)
    Write-Host ("    Attach:  {0}" -f $m.hasAttachments)
    Write-Host ("    Id:      {0}" -f $m.id)
    Write-Host ("    Preview: {0}" -f $m.bodyPreview)
}

# Now pull the FULL body of the single newest message FROM rajat's gmail
$fromRajat = $msgs | Where-Object { $_.from.emailAddress.address -eq "rajatkumar07860@gmail.com" } | Select-Object -First 1
if ($fromRajat) {
    Write-Host ""
    Write-Host "================ FULL BODY OF NEWEST MESSAGE FROM RAJAT ================" -ForegroundColor Green
    $full = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$UserMail/messages/$($fromRajat.id)?`$select=subject,from,toRecipients,ccRecipients,receivedDateTime,body" -Headers $H -Method GET
    Write-Host ("Date:    {0}" -f $full.receivedDateTime)
    Write-Host ("From:    {0} <{1}>" -f $full.from.emailAddress.name, $full.from.emailAddress.address)
    Write-Host ("Subject: {0}" -f $full.subject)
    Write-Host "---"
    # strip HTML to text-ish
    $txt = $full.body.content -replace '<style[^>]*>.*?</style>','' -replace '<[^>]+>',' ' -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&rsquo;',"'" -replace '&ldquo;','"' -replace '&rdquo;','"' -replace '&mdash;','-' -replace '&#8594;','->' -replace '\s+',' '
    Write-Host $txt
} else {
    Write-Host ""
    Write-Host "No message found directly FROM rajatkumar07860@gmail.com in the search results." -ForegroundColor Red
}
