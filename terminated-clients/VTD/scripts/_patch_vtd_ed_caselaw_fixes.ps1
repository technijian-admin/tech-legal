# Fix three citations in the VTD-Ed case law add-on draft after verification.
$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"
$subjectNeedle = "VTD - Add-On: 2020-2026 Case Law Upgrade Research"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null

$drafts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/mailFolders/Drafts/messages?`$top=20&`$orderby=lastModifiedDateTime desc&`$select=id,subject"
$match = $null
foreach ($m in $drafts.value) {
    if ($m.subject -and ($m.subject -match 'Case Law Upgrade')) { $match = $m; break }
}
if (-not $match) { Write-Host "Draft not found" -ForegroundColor Red; exit 1 }
$messageId = $match.id
Write-Host "Found draft: $($match.subject)"

$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" + "?`$select=body"
$html = (Invoke-MgGraphRequest -Method GET -Uri $getUri).body.content

# --- Fix 1: Iyere reframing ---
$oldIyere = '2. <b><i>Iyere v. Wise Auto Group</i></b> (2023) 87 Cal.App.5th 747. Bare "I don''t recall signing" is insufficient to dispute authenticity; authentication may be "carried in any manner." First post-2020 published appellate decision to rebalance the e-sig authentication burden toward the proponent. Belongs in &sect;&nbsp;17 alongside <i>Fabian</i> and <i>Ruiz</i>. Caveat: <i>Iyere</i> concerned a physical signature and the court distinguished electronic ones, so cite for the burden framework, not as direct e-sig authority.'
$newIyere = '2. <b><i>Iyere v. Wise Auto Group</i></b> (2023) 87 Cal.App.5th 747. Most recent California appellate authority rejecting the "I don''t recall signing" defense as insufficient to create a factual dispute on authenticity. IMPORTANT CAVEAT: <i>Iyere</i> concerned a <b>handwritten</b> signature &mdash; the court expressly distinguished electronic signatures and did NOT apply its reasoning to the e-sig context. Recommended use: cite in &sect;&nbsp;17 only by analogy, for the proposition that if even under the stricter handwritten-signature framework a bare failure-to-recall is insufficient, the same principle supports the proponent in the e-sig context governed by <i>Ruiz</i> and <i>Fabian</i>. Do NOT frame <i>Iyere</i> as a direct e-sig authentication holding.'

if ($html.Contains($oldIyere)) {
    $html = $html.Replace($oldIyere, $newIyere)
    Write-Host "  Fix 1 (Iyere reframing): applied" -ForegroundColor Green
} else {
    Write-Host "  Fix 1 (Iyere reframing): anchor not found, skipping" -ForegroundColor Red
}

# --- Fix 2: Hohenshelt citation ---
$oldHohen = '<i>Hohenshelt v. Superior Court</i> (2025) &mdash; CCP &sect;&sect;&nbsp;1281.97/1281.98 fee-payment deadlines;'
$newHohen = '<i>Hohenshelt v. Superior Court</i> (2025) 18 Cal.5th 310 &mdash; CCP &sect;&sect;&nbsp;1281.97/1281.98 fee-payment deadlines;'
if ($html.Contains($oldHohen)) {
    $html = $html.Replace($oldHohen, $newHohen)
    Write-Host "  Fix 2 (Hohenshelt cite): applied" -ForegroundColor Green
} else {
    Write-Host "  Fix 2 (Hohenshelt cite): anchor not found, skipping" -ForegroundColor Red
}

# --- Fix 3: NECF citation ---
$oldNECF = '<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (2025) &mdash; &sect;&nbsp;1668 limits contractual limitations of liability for willful injury;'
$newNECF = '<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (Cal. Apr. 24, 2025, S282968) &mdash; &sect;&nbsp;1668 limits contractual limitations of liability for willful injury;'
if ($html.Contains($oldNECF)) {
    $html = $html.Replace($oldNECF, $newNECF)
    Write-Host "  Fix 3 (NECF cite): applied" -ForegroundColor Green
} else {
    Write-Host "  Fix 3 (NECF cite): anchor not found, skipping" -ForegroundColor Red
}

$patchBody = @{ body = @{ contentType = "HTML"; content = $html } } | ConvertTo-Json -Depth 5
Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" `
    -Body $patchBody `
    -Headers @{ "Content-Type" = "application/json" } | Out-Null
Write-Host "`nDraft patched." -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null
