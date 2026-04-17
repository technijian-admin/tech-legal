# Patch v3: promote cancellation-invoice late-fee consequence into §3
# so it's adjacent to the settlement offer (maximum visibility).

$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"
$messageId = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAEQAACgx7VhNWW1QYCgfGa-8kbOAAXP9qoXAAA="

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome

$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" + "?`$select=body"
$html = (Invoke-MgGraphRequest -Method GET -Uri $getUri).body.content

# Build the new standalone paragraph in the draft's plain style
$font = 'Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif'
$pStyle  = 'direction:ltr; margin-top:1em; margin-bottom:1em'
$spStyle = "font-family:$font; font-size:12pt; color:rgb(0,0,0)"

$newText = 'And please note: because invoice&nbsp;#28064 (the cancellation-fee invoice) is itself due April&nbsp;30,&nbsp;2026, the same Net-30 / 10% late-fee terms apply to that invoice. If invoice&nbsp;#28064 is not paid in full on or before April&nbsp;30,&nbsp;2026, the 10% late fee will be assessed on it as well &mdash; adding &#36;12,644.25 to the balance on that single invoice &mdash; and will not be waived.'
$newPara = "<p class=`"elementToProof`" style=`"$pStyle`"><span style=`"$spStyle`">$newText</span></p>"

# Find the end of §3 — the closing </p> of the settlement-offer paragraph,
# immediately before the §4 ("Microsoft 365 global admin") paragraph starts.
$needle = 'This is separate from the April monthly invoices referenced in Point&nbsp;1 above.</span></p>'
if (-not $html.Contains($needle)) {
    # Fallback: try without &nbsp;
    $needle = 'This is separate from the April monthly invoices referenced in Point 1 above.</span></p>'
}
if (-not $html.Contains($needle)) {
    Write-Host "Could not locate §3 end anchor. Aborting." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}

# Guard against double-insertion
if ($html.Contains('adding &#36;12,644.25') -or $html.Contains('adding $12,644.25')) {
    Write-Host "New paragraph already present; nothing to do." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    exit 0
}

$newHtml = $html.Replace($needle, $needle + $newPara)

$patchBody = @{
    body = @{ contentType = "HTML"; content = $newHtml }
} | ConvertTo-Json -Depth 5
Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" `
    -Body $patchBody `
    -Headers @{ "Content-Type" = "application/json" } | Out-Null

Write-Host "Section 3 extended with cancellation late-fee consequence." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
