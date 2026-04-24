# Recreate all Inky-campaign drafts after Python-template edit.
# - Deletes existing drafts whose subjects match campaign patterns (preserves other drafts)
# - Recreates all 55 from staging JSON with the one-pager PDF attached

$ErrorActionPreference = 'Stop'
$senderUpn   = "RJain@technijian.com"
$stagingPath = "c:\tmp\inky-drafts-staging.json"
$pdfPath     = "c:\vscode\tech-branding\tech-branding\Services\My AntiSpam\My AntiSpam One-Pager.pdf"

if (-not (Test-Path $stagingPath)) { throw "Staging file not found: $stagingPath" }
if (-not (Test-Path $pdfPath))     { throw "PDF not found: $pdfPath" }

# Auth
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

# Delete existing campaign drafts (match by subject patterns)
Write-Host "Finding existing campaign drafts to replace..."
$campaignPatterns = @(
    'Important: Your Technijian My AntiSpam Upgrade',
    'Protect .* from Phishing - Technijian My AntiSpam',
    '- Email security under',
    '- Attorney-client privilege and email security',
    '- CMMC email-security controls'
)

$existingDrafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 200 -Property "id,subject"
$deleted = 0
foreach ($d in $existingDrafts) {
    $isCampaign = $false
    foreach ($p in $campaignPatterns) {
        if ($d.Subject -match $p) { $isCampaign = $true; break }
    }
    if ($isCampaign) {
        Remove-MgUserMessage -UserId $senderUpn -MessageId $d.Id
        $deleted++
    }
}
Write-Host "Deleted $deleted prior campaign drafts"
Write-Host ""

# Load PDF
$pdfBytes = [System.IO.File]::ReadAllBytes($pdfPath)
$pdfB64   = [Convert]::ToBase64String($pdfBytes)
$pdfName  = [System.IO.Path]::GetFileName($pdfPath)

# Load messages
$messages = Get-Content $stagingPath -Raw | ConvertFrom-Json
Write-Host "Creating $($messages.Count) drafts..."
Write-Host ""

$created = 0
$errors  = @()
foreach ($m in $messages) {
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

    try {
        $draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
        $null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draft.Id -BodyParameter @{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            Name          = $pdfName
            ContentBytes  = $pdfB64
        }
        $created++
        Write-Host ("[{0,2}/{1}] {2,-7} {3,-10} -> {4}" -f $created, $messages.Count, $m.client_code, $m.template, $m.to[0].email)
    } catch {
        $errors += @{ code = $m.client_code; template = $m.template; error = $_.Exception.Message }
        Write-Host "  ERROR for $($m.client_code): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Deleted: $deleted; Created: $created of $($messages.Count)"
if ($errors.Count -gt 0) {
    Write-Host "Errors: $($errors.Count)" -ForegroundColor Red
    foreach ($e in $errors) { Write-Host "  $($e.code): $($e.error)" -ForegroundColor Red }
}

Disconnect-MgGraph | Out-Null
