# Short status reply to Katherine Wilson - a Sunrun tech has arrived unscheduled
# and is currently on-site at 5 Caladium looking at the 2017 Costco system.
#
# Purpose: get the on-site visit on the record, request written documentation
# of scope + findings + tech name + work order #, preserve all prior legal
# positions (May 1 demand deadline, May 4 appointment, preservation notice).
#
# Usage:
#   .\send-sunrun-tech-onsite-notice.ps1         # draft only (DEFAULT)
#   .\send-sunrun-tech-onsite-notice.ps1 -Send   # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$toRecipients = @(
    @{ Address = "katherine.wilson@sunrun.com"; Name = "Katherine Wilson" }
)
$ccRecipients = @(
    @{ Address = "membercare@sunrun.com"; Name = "Sunrun Member Care (Warranty Notice)" }
)

$senderUpn = "RJain@technijian.com"
$subject   = "Re: FORMAL DEMAND - Solar System Disconnected 11/7/25-4/16/26 - 5 Caladium - Acct 0036 1837 1728 9 - Response Due Within 14 Days"
$sigPath   = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:11pt;color:rgb(0,0,0)">

<p>Katherine,</p>

<p><strong>Status update for the record:</strong> a Sunrun technician arrived at 5 Caladium unscheduled a short time ago and is currently on-site inspecting the 2017 Costco system. I have not sent an acceptance of your 12:59 PM PT dispatch offer; the technician arrived independently. I am cooperating with the visit and letting the work proceed.</p>

<p>Please confirm in writing, today:</p>

<ol>
  <li>The technician&#39;s name and Sunrun employee / contractor ID.</li>
  <li>The work order number for this April 22, 2026 on-site visit.</li>
  <li>The scope of work authorized for today&#39;s visit.</li>
  <li>That a written summary of findings, root cause, parts replaced, and final production status will be provided to me after the technician leaves the site.</li>
</ol>

<p>For the avoidance of doubt:</p>

<ul>
  <li>This unscheduled visit does <strong>not</strong> replace or supersede the <strong>May 4, 2026 (12:00 PM &ndash; 5:00 PM)</strong> appointment unless the 2017 Costco system is verified by Sunrun&#39;s own monitoring as producing normally for a full 48 hours after today&#39;s visit. If it is not, the May 4 appointment must proceed.</li>
  <li>All deadlines stated in my prior correspondence remain in effect, including the <strong>May 1, 2026</strong> response deadline on the April 17 formal demand, the <strong>CLRA &sect; 1782</strong> 30-day notice clock (ripens May 16, 2026), and the existing document-preservation scope.</li>
  <li>The document-preservation scope in Section 10 of my April 19 email is hereby expanded to include today&#39;s April 22, 2026 work order, technician field notes, photographs, GPS records, and any monitoring telemetry captured before, during, and after the visit.</li>
  <li>Nothing about today&#39;s visit constitutes a waiver, release, or settlement of any claim. Compensation and legal correspondence remain on their separate track.</li>
</ul>

<p>I will follow up separately once the technician has completed the visit with what I observed on site.</p>

</div>
$sig
</body>
</html>
"@

# --- Proofread: stripped-dollar-sign + placeholder check (FAIL FAST) ---
if ($htmlBody -match '[\s>](\,\d{3})') {
    Write-Error "BLOCKED: Stripped dollar sign detected near '$($matches[1])'. Backtick-escape every literal `$<digit> in the body."
    exit 1
}
if ($htmlBody -match '\[Your Name\]|TODO|TBD|\[INSERT|\[CLIENT') {
    Write-Error "BLOCKED: Placeholder text found in email body."
    exit 1
}
Write-Host "Proofread checks passed." -ForegroundColor Green

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

$toGraph = $toRecipients | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } }
$ccGraph = $ccRecipients | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } }

Write-Host "Creating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($toGraph)
    CcRecipients = @($ccGraph)
    Importance   = "High"
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "`nSENDING NOW..." -ForegroundColor Yellow
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT." -ForegroundColor Green
} else {
    Write-Host "`n=== DRAFT SAVED to Outlook Drafts folder for $senderUpn ===" -ForegroundColor Yellow
    Write-Host "Subject: $subject" -ForegroundColor Gray
    Write-Host "TO:" -ForegroundColor Gray
    $toRecipients | ForEach-Object { Write-Host "  $($_.Name) <$($_.Address)>" -ForegroundColor Gray }
    Write-Host "CC:" -ForegroundColor Gray
    $ccRecipients | ForEach-Object { Write-Host "  $($_.Name) <$($_.Address)>" -ForegroundColor Gray }
    Write-Host "`nReview in Outlook (Drafts folder), edit if needed, then click Send." -ForegroundColor Yellow
    Write-Host "Re-run with -Send to send immediately." -ForegroundColor Cyan
}

Disconnect-MgGraph | Out-Null
