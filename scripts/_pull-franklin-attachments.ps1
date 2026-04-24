$ErrorActionPreference = "Stop"
$UserMail = "RJain@technijian.com"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$tok = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tid/oauth2/v2.0/token" -Method POST -Body @{
    grant_type="client_credentials"; client_id=$cid; client_secret=$sec; scope="https://graph.microsoft.com/.default"
} -ContentType "application/x-www-form-urlencoded").access_token
$h = @{ Authorization = "Bearer $tok"; ConsistencyLevel = "eventual" }

$searchQuery = [uri]::EscapeDataString("`"fdunn@callahan-law.com`"")
$url = "https://graph.microsoft.com/v1.0/users/$UserMail/messages?`$search=$searchQuery&`$top=10&`$select=id,subject,receivedDateTime,hasAttachments,from"
$resp = Invoke-RestMethod -Uri $url -Headers $h -Method GET

$outDir = "c:\VSCode\tech-legal\tech-legal\docs\personal\sunrun\attachments"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

foreach ($m in $resp.value) {
    if ($m.from.emailAddress.address -ne 'fdunn@callahan-law.com') { continue }
    if (-not $m.hasAttachments) { continue }
    Write-Host ("Message {0} ({1})" -f $m.receivedDateTime, $m.subject) -ForegroundColor Cyan
    $attUrl = "https://graph.microsoft.com/v1.0/users/$UserMail/messages/$($m.id)/attachments"
    $atts = (Invoke-RestMethod -Uri $attUrl -Headers $h -Method GET).value
    foreach ($a in $atts) {
        $datePart = ($m.receivedDateTime -replace '[:TZ]', '' -replace '-', '').Substring(0, 14)
        $safeName = "$datePart-$($a.name)"
        $path = Join-Path $outDir $safeName
        $bytes = [Convert]::FromBase64String($a.contentBytes)
        [IO.File]::WriteAllBytes($path, $bytes)
        Write-Host ("  Wrote {0} ({1} bytes, {2})" -f $path, $bytes.Length, $a.contentType) -ForegroundColor Green
    }
}
