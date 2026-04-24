# Create all 55 Inky-campaign drafts in Ravi's Outlook Drafts folder with the one-pager PDF attached.
# Reads rendered bodies from c:\tmp\inky-drafts-staging.json (built by build-inky-drafts-staging.py).

$ErrorActionPreference = 'Stop'
$senderUpn   = "RJain@technijian.com"
$stagingPath = "c:\tmp\inky-drafts-staging.json"
$pdfPath     = "c:\vscode\tech-branding\tech-branding\Services\My AntiSpam\My AntiSpam One-Pager.pdf"

if (-not (Test-Path $stagingPath)) { throw "Staging file not found: $stagingPath" }
if (-not (Test-Path $pdfPath))     { throw "PDF not found: $pdfPath" }

# ---- Auth ----
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

# ---- Delete the 2 old sample drafts (from draft-inky-samples.ps1, no attachment, wrong AFFG template) ----
Write-Host "Cleaning up old sample drafts..."
$oldSubjects = @(
    "Important: Your Technijian My AntiSpam Upgrade - Monday, May 5",
    "Protect American Fundstars Financial Group from Phishing - Technijian My AntiSpam Now Available"
)
$existingDrafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 100 -Property "id,subject,hasAttachments"
$oldDeleted = 0
foreach ($d in $existingDrafts) {
    if ($oldSubjects -contains $d.Subject -and -not $d.HasAttachments) {
        Remove-MgUserMessage -UserId $senderUpn -MessageId $d.Id
        Write-Host "  deleted old sample: $($d.Subject)"
        $oldDeleted++
    }
}
Write-Host "Deleted $oldDeleted old sample drafts"
Write-Host ""

# ---- Load PDF once into memory (same bytes re-used for all drafts) ----
$pdfBytes = [System.IO.File]::ReadAllBytes($pdfPath)
$pdfB64   = [Convert]::ToBase64String($pdfBytes)
$pdfName  = [System.IO.Path]::GetFileName($pdfPath)
Write-Host "Attachment: $pdfName ($([math]::Round($pdfBytes.Length/1KB, 1)) KB)"
Write-Host ""

# ---- Load staged messages ----
$messages = Get-Content $stagingPath -Raw | ConvertFrom-Json
Write-Host "Creating $($messages.Count) drafts..."
Write-Host ""

$created = 0
$errors  = @()

foreach ($m in $messages) {
    $toList = @()
    foreach ($r in $m.to) {
        $toList += @{ EmailAddress = @{ Address = $r.email; Name = $r.name } }
    }
    $ccList = @()
    foreach ($r in $m.cc) {
        $ccList += @{ EmailAddress = @{ Address = $r.email; Name = $r.name } }
    }

    $draftParams = @{
        Subject       = $m.subject
        Body          = @{ ContentType = "HTML"; Content = $m.body_html }
        ToRecipients  = $toList
    }
    if ($ccList.Count -gt 0) { $draftParams['CcRecipients'] = $ccList }

    try {
        $draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
        $null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draft.Id -BodyParameter @{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            Name          = $pdfName
            ContentBytes  = $pdfB64
        }
        $created++
        Write-Host ("[{0,2}/{1}] {2,-7} {3,-10} -> {4,-40} {5}" -f $created, $messages.Count, $m.client_code, $m.template, $m.to[0].email, $m.subject.Substring(0, [Math]::Min(60, $m.subject.Length)))
    } catch {
        $errors += @{ code = $m.client_code; template = $m.template; error = $_.Exception.Message }
        Write-Host "  ERROR for $($m.client_code) [$($m.template)]: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Created: $created of $($messages.Count)"
if ($errors.Count -gt 0) {
    Write-Host "Errors: $($errors.Count)" -ForegroundColor Red
    foreach ($e in $errors) {
        Write-Host "  $($e.code) [$($e.template)]: $($e.error)" -ForegroundColor Red
    }
}

Disconnect-MgGraph | Out-Null
Write-Host ""
Write-Host "All drafts in Outlook > Drafts folder for RJain@technijian.com. Review each and send manually."
