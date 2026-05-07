# Second PATCH of TALY/Rob draft body
# Reason: web check confirmed Talley & Associates is a governmental-relations /
# association-management firm (MHP conversions). GLBA Safeguards Rule does NOT
# apply. Replace the GLBA bullet with industry-appropriate framing.

# ── Auth ──
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$senderUpn = "RJain@technijian.com"
$msgId = (Get-Content "c:\vscode\tech-legal\tech-legal\scripts\taly-rob-msa-draft-id.txt" -Raw).Trim()
Write-Host "Patching draft (v2 - industry alignment): $msgId" -ForegroundColor Cyan

# ── Fetch current body ──
$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$msgId" + "?`$select=body"
$full = Invoke-MgGraphRequest -Method GET -Uri $getUri
$html = $full.body.content

# ── Replace GLBA bullet with industry-appropriate framing ──
$oldBlock = '<li><strong>Client and regulatory requirements.</strong> If your own clients send you vendor security questionnaires, or if Talley is subject to GLBA''s Safeguards Rule, or if you''re working toward SOC 2, RTPT and SA often map directly to required controls. (The FTC''s 2023 update to the Safeguards Rule defines &ldquo;financial institution&rdquo; broadly and requires periodic vulnerability assessments and penetration testing.)</li>'
$newBlock = '<li><strong>Client and contract requirements.</strong> If your association clients, government counterparties, or any of your engagements impose specific cybersecurity controls (vendor security questionnaires, SOC 2 expectations, contractual security minimums, or state cybersecurity statutes), RTPT and SA often map directly to required controls. Worth a quick scan of your top engagement letters before we pull either line.</li>'

if ($html -notmatch [regex]::Escape($oldBlock)) {
    Write-Error "Anchor block not found verbatim. Aborting (no changes made)."
    Disconnect-MgGraph | Out-Null
    exit 1
}
$html2 = $html.Replace($oldBlock, $newBlock)
Write-Host "GLBA reference removed and bullet re-targeted to association/government engagements" -ForegroundColor Green

# ── Sanity ──
if ($html2 -match '[\s>](\,\d{3})') { Write-Error "BLOCKED: stripped currency"; exit 1 }
if ($html2 -match 'href=""') { Write-Error "BLOCKED: empty href"; exit 1 }
if ($html2 -match 'GLBA') { Write-Error "BLOCKED: GLBA still present after patch"; exit 1 }
$expectedAmounts = @('$724.75','$468.00','$256.75','$172.50','$92','$135','$603','$240.45')
foreach ($v in $expectedAmounts) {
    if ($html2 -notmatch [regex]::Escape($v)) {
        Write-Error "BLOCKED: expected amount missing after patch: $v"; exit 1
    }
}

# ── Save patched preview ──
$previewPath = "c:\tmp\taly-rob-msa-preview-v2-$(Get-Date -Format yyyyMMdd-HHmmss).html"
$html2 | Out-File -FilePath $previewPath -Encoding UTF8
Write-Host "Patched preview saved: $previewPath" -ForegroundColor Cyan

# ── PATCH the draft body ──
$patchBody = @{
    body = @{ contentType = "HTML"; content = $html2 }
} | ConvertTo-Json -Depth 5

$patchUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$msgId"
Invoke-MgGraphRequest -Method PATCH -Uri $patchUri -Body $patchBody -Headers @{ "Content-Type" = "application/json" }
Write-Host "Draft body PATCHed (v2) successfully." -ForegroundColor Green

Disconnect-MgGraph | Out-Null
