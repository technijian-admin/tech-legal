$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null

$drafts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/mailFolders/Drafts/messages?`$top=5&`$orderby=lastModifiedDateTime desc&`$select=id,subject"
$match = $null; foreach ($m in $drafts.value) { if ($m.subject -match "Case Law Upgrade") { $match = $m; break } }
if (-not $match) { Write-Host "Draft not found" -ForegroundColor Red; exit 1 }
$messageId = $match.id
Write-Host "Draft: $($match.subject)"

$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" + "?`$select=body"
$html = (Invoke-MgGraphRequest -Method GET -Uri $getUri).body.content

# Actual HTML-encoded anchors (quotes stored as &quot;, section sign stored as literal §)
$oldIyere = 'Bare &quot;I don''t recall signing&quot; is insufficient to dispute authenticity; authentication may be &quot;carried in any manner.&quot; First post-2020 published appellate decision to rebalance the e-sig authentication burden toward the proponent. Belongs in §&nbsp;17 alongside <i>Fabian</i> and <i>Ruiz</i>. Caveat: <i>Iyere</i> concerned a physical signature and the court distinguished electronic ones, so cite for the burden framework, not as direct e-sig authority.'
$newIyere = 'Most recent California appellate authority rejecting the &quot;I don''t recall signing&quot; defense as insufficient to create a factual dispute on authenticity. IMPORTANT CAVEAT: <i>Iyere</i> concerned a <b>handwritten</b> signature &mdash; the court expressly distinguished electronic signatures and did NOT apply its reasoning to the e-sig context. Recommended use: cite in §&nbsp;17 only by analogy, for the proposition that if even under the stricter handwritten-signature framework a bare failure-to-recall is insufficient, the same principle supports the proponent in the e-sig context governed by <i>Ruiz</i> and <i>Fabian</i>. Do NOT frame <i>Iyere</i> as a direct e-sig authentication holding.'

if ($html.Contains($oldIyere)) {
    $html = $html.Replace($oldIyere, $newIyere)
    Write-Host "  Fix 1 (Iyere reframing): applied" -ForegroundColor Green
} else {
    Write-Host "  Fix 1 (Iyere reframing): anchor not found" -ForegroundColor Red
}

$oldHohen = '<i>Hohenshelt v. Superior Court</i> (2025) &mdash; CCP §§&nbsp;1281.97/1281.98 fee-payment deadlines;'
$newHohen = '<i>Hohenshelt v. Superior Court</i> (2025) 18 Cal.5th 310 &mdash; CCP §§&nbsp;1281.97/1281.98 fee-payment deadlines;'
if ($html.Contains($oldHohen)) {
    $html = $html.Replace($oldHohen, $newHohen)
    Write-Host "  Fix 2 (Hohenshelt cite): applied" -ForegroundColor Green
} else {
    Write-Host "  Fix 2 (Hohenshelt cite): anchor not found" -ForegroundColor Red
}

$oldNECF = '<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (2025) &mdash; §&nbsp;1668 limits contractual limitations of liability for willful injury;'
$newNECF = '<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (Cal. Apr. 24, 2025, S282968) &mdash; §&nbsp;1668 limits contractual limitations of liability for willful injury;'
if ($html.Contains($oldNECF)) {
    $html = $html.Replace($oldNECF, $newNECF)
    Write-Host "  Fix 3 (NECF cite): applied" -ForegroundColor Green
} else {
    Write-Host "  Fix 3 (NECF cite): anchor not found" -ForegroundColor Red
}

$patchBody = @{ body = @{ contentType = "HTML"; content = $html } } | ConvertTo-Json -Depth 5
Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" `
    -Body $patchBody `
    -Headers @{ "Content-Type" = "application/json" } | Out-Null
Write-Host "Draft patched." -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null
