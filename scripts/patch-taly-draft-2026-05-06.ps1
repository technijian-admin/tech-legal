# Surgical PATCH of TALY/Rob draft body — applies prose tightening
# Edit 1: tighten GLBA compliance bullet (long parenthetical -> trailing aside)
# Edit 2: reduce "May 1" repetition in the final next-steps paragraph

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
Write-Host "Patching draft: $msgId" -ForegroundColor Cyan

# ── Fetch current body ──
$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$msgId" + "?`$select=body"
$full = Invoke-MgGraphRequest -Method GET -Uri $getUri
$html = $full.body.content

# ── Edit 1: GLBA bullet (anchor on the unique opening "<strong>Client and regulatory") ──
$oldBlock1 = '<li><strong>Client and regulatory requirements.</strong> If any of your own clients send you vendor security questionnaires, or if your firm is subject to GLBA''s Safeguards Rule (the FTC''s 2023 update covers a broad range of financial services and includes periodic vulnerability assessments and pen testing), or if you''re working toward or maintaining SOC 2, these line items often map directly to required controls.</li>'
$newBlock1 = '<li><strong>Client and regulatory requirements.</strong> If your own clients send you vendor security questionnaires, or if Talley is subject to GLBA''s Safeguards Rule, or if you''re working toward SOC 2, RTPT and SA often map directly to required controls. (The FTC''s 2023 update to the Safeguards Rule defines &ldquo;financial institution&rdquo; broadly and requires periodic vulnerability assessments and penetration testing.)</li>'

if ($html -notmatch [regex]::Escape($oldBlock1)) {
    Write-Error "Edit 1: anchor block not found verbatim in draft body. Aborting."
    Disconnect-MgGraph | Out-Null
    exit 1
}
$html2 = $html.Replace($oldBlock1, $newBlock1)
Write-Host "Edit 1: GLBA bullet replaced" -ForegroundColor Green

# ── Edit 2: final paragraph (anchor on unique "void and reissue the current pending May 1") ──
$oldBlock2 = "we'll void and reissue the current pending May 1 invoice (#28363, for the June service period)"
$newBlock2 = "we'll void and reissue the currently pending invoice #28363 (covering the June service period)"

if ($html2 -notmatch [regex]::Escape($oldBlock2)) {
    Write-Error "Edit 2: anchor block not found verbatim. Aborting."
    Disconnect-MgGraph | Out-Null
    exit 1
}
$html3 = $html2.Replace($oldBlock2, $newBlock2)
Write-Host "Edit 2: final paragraph tightened" -ForegroundColor Green

# ── Sanity: ensure no stripped currency or empty hrefs introduced ──
if ($html3 -match '[\s>](\,\d{3})') { Write-Error "BLOCKED: stripped currency"; exit 1 }
if ($html3 -match 'href=""') { Write-Error "BLOCKED: empty href"; exit 1 }
$expectedAmounts = @('$724.75','$468.00','$256.75','$172.50','$92','$135','$603','$240.45')
foreach ($v in $expectedAmounts) {
    if ($html3 -notmatch [regex]::Escape($v)) {
        Write-Error "BLOCKED: expected amount missing after patch: $v"; exit 1
    }
}

# ── Save patched preview to disk ──
$previewPath = "c:\tmp\taly-rob-msa-preview-patched-$(Get-Date -Format yyyyMMdd-HHmmss).html"
$html3 | Out-File -FilePath $previewPath -Encoding UTF8
Write-Host "Patched preview saved: $previewPath" -ForegroundColor Cyan

# ── PATCH the draft body ──
$patchBody = @{
    body = @{ contentType = "HTML"; content = $html3 }
} | ConvertTo-Json -Depth 5

$patchUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$msgId"
Invoke-MgGraphRequest -Method PATCH -Uri $patchUri -Body $patchBody -Headers @{ "Content-Type" = "application/json" }
Write-Host "Draft body PATCHed successfully." -ForegroundColor Green

Disconnect-MgGraph | Out-Null
