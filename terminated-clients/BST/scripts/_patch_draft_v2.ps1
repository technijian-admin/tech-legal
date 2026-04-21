# Patch v2: add explicit cancellation-invoice late-fee language to §1,
# and add 6 new .eml proof attachments to the draft.

$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"
$messageId = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAEQAACgx7VhNWW1QYCgfGa-8kbOAAXP9qoXAAA="
$pkgDir    = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST\send-packages\2026-04-17"

# --- Graph auth ---
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# ============================================================
# PART A: PATCH body — add cancellation late-fee bullet to §1
# ============================================================
$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" + "?`$select=body"
$full = Invoke-MgGraphRequest -Method GET -Uri $getUri
$html = $full.body.content

# Find the "Any invoice that remains unpaid..." bullet and expand it
$oldBullet = 'Any invoice that remains unpaid after its due date will continue to accrue the contractual 10% late fee per the Agreement until paid.'
$newBullet = 'Any invoice that remains unpaid after its due date will continue to accrue the contractual 10% late fee per the Agreement until paid. In particular, if the cancellation invoice #28064 &mdash; due April&nbsp;30,&nbsp;2026 &mdash; is not paid in full on or before that date, the 10% late fee will be assessed on that invoice as well, and will not be waived.'

if (-not $html.Contains($oldBullet)) {
    Write-Host "Could not find target bullet for expansion; aborting body patch." -ForegroundColor Red
} else {
    $newHtml = $html.Replace($oldBullet, $newBullet)
    $patchBody = @{
        body = @{ contentType = "HTML"; content = $newHtml }
    } | ConvertTo-Json -Depth 5
    Invoke-MgGraphRequest -Method PATCH `
        -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId" `
        -Body $patchBody `
        -Headers @{ "Content-Type" = "application/json" } | Out-Null
    Write-Host "Body patched: cancellation late-fee language added to §1." -ForegroundColor Green
}

# ============================================================
# PART B: Add .eml proof attachments (6 new)
# ============================================================
$newAttachments = @(
    'ProofOfSend_April_Monthly_28143_to_Accounting.eml',
    'ProofOfSend_Weekly_Sample_27753.eml',
    '2026-04-03_Access_Update_Transition.eml',
    '2026-04-09_Account_Closeout_Counsel_Review.eml',
    '2026-04-14_Time-Sensitive_Closeout.eml',
    '2026-04-15_VPN_Support_Access_Limitations.eml'
)

# Check current attachment names to avoid duplicates
$existing = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId/attachments?`$select=name,size"
$existingNames = @()
foreach ($a in $existing.value) { $existingNames += $a.name }
Write-Host ("Current attachment count: {0}" -f $existingNames.Count) -ForegroundColor Cyan

foreach ($name in $newAttachments) {
    if ($existingNames -contains $name) {
        Write-Host "  (skipping, already attached) $name" -ForegroundColor DarkGray
        continue
    }
    $path = Join-Path $pkgDir $name
    if (-not (Test-Path $path)) {
        Write-Host "  MISSING FILE: $path" -ForegroundColor Red
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $b64 = [Convert]::ToBase64String($bytes)

    $attachPayload = @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name          = $name
        contentType   = "message/rfc822"
        contentBytes  = $b64
    } | ConvertTo-Json -Depth 5

    try {
        Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId/attachments" `
            -Body $attachPayload `
            -Headers @{ "Content-Type" = "application/json" } | Out-Null
        Write-Host ("  [+] {0}  ({1:N0} bytes)" -f $name, $bytes.Length) -ForegroundColor Green
    } catch {
        Write-Host ("  [X] FAILED {0}: {1}" -f $name, $_.Exception.Message) -ForegroundColor Red
    }
}

# Final attachment count
$final = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$messageId/attachments?`$select=name,size"
Write-Host ("`nFinal attachment count: {0}" -f $final.value.Count) -ForegroundColor Cyan
$totalSize = 0
foreach ($a in $final.value) { $totalSize += $a.size }
Write-Host ("Total attachment payload: {0:N0} bytes ({1:N2} MB)" -f $totalSize, ($totalSize/1MB)) -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null
