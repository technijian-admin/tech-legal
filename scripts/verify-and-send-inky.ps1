# Verify campaign drafts, heal any missing from staging, proofread, then SEND all 55.
# Fixes to prior version:
# - Dedupe by (subject, recipient) pair not just recipient (preserves separate emails to same person for FOR/TOR)
# - Spot-check by recipient email not subject regex (existing-customer subjects are identical across 11 recipients)
# - Heal step: if any staging message has no matching draft, recreate it before the send loop

$ErrorActionPreference = 'Stop'
$senderUpn   = "RJain@technijian.com"
$stagingPath = "c:\tmp\inky-drafts-staging.json"
$pdfPath     = "c:\vscode\tech-branding\tech-branding\Services\My AntiSpam\My AntiSpam One-Pager.pdf"

# Auth
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

# Step 1: find campaign drafts
$allDrafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 200 -Property "id,subject,toRecipients,hasAttachments,createdDateTime"
$campaignDrafts = $allDrafts | Where-Object {
    $_.Subject -match "Technijian My AntiSpam" -or
    $_.Subject -match "Attorney-client privilege" -or
    $_.Subject -match "CMMC email-security"
}
Write-Host "Current campaign drafts: $($campaignDrafts.Count)"

# Step 2: dedupe by (subject + recipient) pair — only true duplicates
$seen = @{}
$dupesDeleted = 0
foreach ($d in ($campaignDrafts | Sort-Object CreatedDateTime -Descending)) {
    if ($null -eq $d.ToRecipients -or $d.ToRecipients.Count -eq 0) { continue }
    $firstRecip = $d.ToRecipients | Select-Object -First 1
    if ($null -eq $firstRecip -or $null -eq $firstRecip.EmailAddress -or $null -eq $firstRecip.EmailAddress.Address) { continue }
    $to = $firstRecip.EmailAddress.Address.ToLower()
    $key = "$($d.Subject)||$to"
    if ($seen.ContainsKey($key)) {
        Remove-MgUserMessage -UserId $senderUpn -MessageId $d.Id
        $dupesDeleted++
        Write-Host "  removed duplicate: $to"
    } else {
        $seen[$key] = $d.Id
    }
}
Write-Host "True duplicates removed: $dupesDeleted"
Write-Host ""

# Step 3: heal — recreate any staging message that lost its draft
$staging = Get-Content $stagingPath -Raw | ConvertFrom-Json
$remainingDrafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 200 -Property "id,subject,toRecipients"
$existingKeys = @{}
foreach ($d in $remainingDrafts) {
    if ($null -eq $d.ToRecipients -or $d.ToRecipients.Count -eq 0) { continue }
    $firstRecip = $d.ToRecipients | Select-Object -First 1
    if ($null -eq $firstRecip -or $null -eq $firstRecip.EmailAddress -or $null -eq $firstRecip.EmailAddress.Address) { continue }
    $to = $firstRecip.EmailAddress.Address.ToLower()
    $key = "$($d.Subject)||$to"
    $existingKeys[$key] = $d.Id
}

$pdfBytes = [System.IO.File]::ReadAllBytes($pdfPath)
$pdfB64   = [Convert]::ToBase64String($pdfBytes)
$pdfName  = [System.IO.Path]::GetFileName($pdfPath)

$missingRecreated = 0
foreach ($m in $staging) {
    $to = $m.to[0].email.ToLower()
    $key = "$($m.subject)||$to"
    if (-not $existingKeys.ContainsKey($key)) {
        $toList = @()
        foreach ($r in $m.to) { $toList += @{ EmailAddress = @{ Address = $r.email; Name = $r.name } } }
        $ccList = @()
        foreach ($r in $m.cc) { $ccList += @{ EmailAddress = @{ Address = $r.email; Name = $r.name } } }
        $draftParams = @{
            Subject      = $m.subject
            Body         = @{ ContentType = "HTML"; Content = $m.body_html }
            ToRecipients = $toList
        }
        if ($ccList.Count -gt 0) { $draftParams['CcRecipients'] = $ccList }
        $draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
        $null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draft.Id -BodyParameter @{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            Name          = $pdfName
            ContentBytes  = $pdfB64
        }
        Write-Host "  recreated: $($m.client_code) -> $to"
        $missingRecreated++
    }
}
Write-Host "Missing drafts recreated: $missingRecreated"
Write-Host ""

# Step 4: spot-check by recipient (existing-customer template has identical subjects, so match by to-addr)
$samples = @(
    @{ email = "ckramer@acuityadvisors.com";     template = "existing" }
    @{ email = "dave@andersenmp.com";            template = "base" }
    @{ email = "iris.liu@americanfundstars.com"; template = "financial" }
    @{ email = "lbjendo@mac.com";                template = "healthcare" }
    @{ email = "chris@chrisblanklaw.com";        template = "legal" }
    @{ email = "bgoldcole@gmail.com";            template = "defense" }
    @{ email = "rami.hammouri@aleragroup.com";   template = "insurance" }
)
Write-Host "=== Proofread spot-check ==="
$allCurrent = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 200 -Property "id,subject,toRecipients,hasAttachments"
$allOk = $true
foreach ($s in $samples) {
    $match = $allCurrent | Where-Object {
        ($_.ToRecipients | Select-Object -First 1).EmailAddress.Address.ToLower() -eq $s.email.ToLower()
    } | Select-Object -First 1
    if ($null -eq $match) {
        Write-Host "  MISSING: $($s.template) / $($s.email)" -ForegroundColor Red
        $allOk = $false
        continue
    }
    $full = Get-MgUserMessage -UserId $senderUpn -MessageId $match.Id -Property "id,subject,body,toRecipients,hasAttachments"
    $body = $full.Body.Content
    $hasDupe = ($body -match 'Thanks,<br\s*/?>\s*Ravi' -or $body -match 'Thanks, and stay safe')
    $hasAttach = $full.HasAttachments
    $unmerged = [regex]::Matches($body, '\[[A-Z][A-Za-z ]+\]') | Where-Object { $_.Value -ne '[object Object]' }
    $status = "OK"
    if ($hasDupe)            { $status = "FAIL: Thanks-Ravi dupe"; $allOk = $false }
    if (-not $hasAttach)     { $status = "FAIL: no attachment";    $allOk = $false }
    if ($unmerged.Count -gt 0){ $status = "FAIL: unmerged tokens";  $allOk = $false }
    Write-Host ("  {0,-11} -> {1,-42} {2}" -f $s.template, $s.email, $status)
}
Write-Host ""

$finalCampaign = $allCurrent | Where-Object {
    $_.Subject -match "Technijian My AntiSpam" -or
    $_.Subject -match "Attorney-client privilege" -or
    $_.Subject -match "CMMC email-security"
}

if (-not $allOk) {
    Write-Host "PROOFREAD FAILED - ABORTING SEND" -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}
if ($finalCampaign.Count -ne 55) {
    Write-Host "COUNT MISMATCH - expected 55, found $($finalCampaign.Count). ABORTING SEND" -ForegroundColor Red
    Disconnect-MgGraph | Out-Null
    exit 1
}

Write-Host "All 55 drafts verified clean. Sending..." -ForegroundColor Green
Write-Host ""

# Step 5: send
$sent = 0
$sendErrors = @()
foreach ($d in $finalCampaign) {
    $to = ($d.ToRecipients | Select-Object -First 1).EmailAddress.Address
    try {
        Send-MgUserMessage -UserId $senderUpn -MessageId $d.Id
        $sent++
        Write-Host ("[{0,2}/{1}] sent -> {2}" -f $sent, $finalCampaign.Count, $to)
    } catch {
        $sendErrors += @{ to = $to; subject = $d.Subject; error = $_.Exception.Message }
        Write-Host "  ERROR sending to $to : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Send Summary ==="
Write-Host "Sent: $sent of $($finalCampaign.Count)"
if ($sendErrors.Count -gt 0) {
    Write-Host "Errors: $($sendErrors.Count)" -ForegroundColor Red
    foreach ($e in $sendErrors) { Write-Host "  $($e.to): $($e.error)" -ForegroundColor Red }
}

Disconnect-MgGraph | Out-Null
