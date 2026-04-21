$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
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

$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" + "?`$select=body"
$html = (Invoke-MgGraphRequest -Method GET -Uri $getUri).body.content

# Actual characters from fetched HTML: em-dash is U+2014, quotes are &quot;, section is literal §
$mdash = [char]0x2014

# ---- Fix 1: Iyere reframing ----
# Simpler approach: replace the specific sentence fragment that overstates the holding
$oldIyere1 = 'First post-2020 published appellate decision to rebalance the e-sig authentication burden toward the proponent.'
$newIyere1 = 'IMPORTANT CAVEAT: <i>Iyere</i> concerned a <b>handwritten</b> signature, not an e-signature, and the court expressly distinguished electronic ones.'
if ($html.Contains($oldIyere1)) {
    $html = $html.Replace($oldIyere1, $newIyere1)
    Write-Host "  Fix 1a (Iyere overstatement): applied" -ForegroundColor Green
} else { Write-Host "  Fix 1a: anchor not found" -ForegroundColor Red }

# Reframe the recommended use to analogy-only
$oldIyere2 = 'Belongs in §&nbsp;17 alongside <i>Fabian</i> and <i>Ruiz</i>. Caveat: <i>Iyere</i> concerned a physical signature and the court distinguished electronic ones, so cite for the burden framework, not as direct e-sig authority.'
$newIyere2 = 'Recommended use: cite in §&nbsp;17 only by ANALOGY, for the proposition that if even under the stricter handwritten-signature framework a bare failure-to-recall is insufficient, the same principle supports the proponent in the e-sig context governed by <i>Ruiz</i> and <i>Fabian</i>. Do NOT frame <i>Iyere</i> as a direct e-sig authentication holding.'
if ($html.Contains($oldIyere2)) {
    $html = $html.Replace($oldIyere2, $newIyere2)
    Write-Host "  Fix 1b (Iyere recommended use): applied" -ForegroundColor Green
} else { Write-Host "  Fix 1b: anchor not found" -ForegroundColor Red }

# ---- Fix 2: Hohenshelt cite ----
$oldHohen = "<i>Hohenshelt v. Superior Court</i> (2025) $mdash CCP §§&nbsp;1281.97/1281.98 fee-payment deadlines;"
$newHohen = "<i>Hohenshelt v. Superior Court</i> (2025) 18 Cal.5th 310 $mdash CCP §§&nbsp;1281.97/1281.98 fee-payment deadlines;"
if ($html.Contains($oldHohen)) {
    $html = $html.Replace($oldHohen, $newHohen)
    Write-Host "  Fix 2 (Hohenshelt cite): applied" -ForegroundColor Green
} else { Write-Host "  Fix 2: anchor not found" -ForegroundColor Red }

# ---- Fix 3: NECF cite ----
$oldNECF = "<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (2025) $mdash §&nbsp;1668 limits contractual limitations of liability for willful injury;"
$newNECF = "<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (Cal. Apr. 24, 2025, S282968) $mdash §&nbsp;1668 limits contractual limitations of liability for willful injury;"
if ($html.Contains($oldNECF)) {
    $html = $html.Replace($oldNECF, $newNECF)
    Write-Host "  Fix 3 (NECF cite): applied" -ForegroundColor Green
} else { Write-Host "  Fix 3: anchor not found" -ForegroundColor Red }

$patchBody = @{ body = @{ contentType = "HTML"; content = $html } } | ConvertTo-Json -Depth 5
Invoke-MgGraphRequest -Method PATCH `
    -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" `
    -Body $patchBody `
    -Headers @{ "Content-Type" = "application/json" } | Out-Null
Write-Host "Draft patched." -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null
