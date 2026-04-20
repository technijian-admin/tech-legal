# Draft updated BST Jeff Klein pre-expiration follow-up (v2 — post 4/16 exchange)
# Reflects: Mr. Cron identified, Jeff verbally inclined to $15,045, no written acceptance yet
# Saves draft MessageId to bst-jeff-draft-id.txt for scheduled send tomorrow at 8 AM
#
# Usage: .\draft-bst-jeff-followup-v2.ps1

$ErrorActionPreference = "Stop"

$toEmail    = "jklein@bostongroupwaste.com"
$toName     = "Jeff Klein"
$ccList     = @(
    @{ EmailAddress = @{ Address = "gagan@bostongroupwaste.com"; Name = "Gagan Singh" } },
    @{ EmailAddress = @{ Address = "lcronlaw@gmail.com";          Name = "Mr. Cron" } },
    @{ EmailAddress = @{ Address = "es@callahan-law.com";         Name = "Edward Susolik, Esq." } }
)
$senderUpn  = "RJain@technijian.com"
$subject    = "RE: Boston Group - Written Acceptance and Payment Dates Needed Before April 30"
$idFile     = "C:\vscode\tech-legal\tech-legal\scripts\bst-jeff-draft-id.txt"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

# --- HTML body ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Jeff,</p>

<p>Thank you for your April 16 reply. I am following up with specific asks as we approach the April 30, 2026 deadline. Mr. Cron and Edward Susolik are copied.</p>

<p><strong>1. Written settlement acceptance &mdash; needed by April 30, COB.</strong></p>

<p>Your April 16 email stated a preference to resolve the cancellation on the <strong>`$15,045.00</strong> life-of-contract settlement figure. That offer remains open through close of business on April 30, 2026, per my March 23, 2026 email &mdash; but it requires written acceptance. Please reply in writing with acceptance on or before April 30 COB.</p>

<p>If written acceptance is not received by that date:</p>
<ul>
  <li>The offer expires by its own terms.</li>
  <li>Technijian's position reverts to the <strong>`$126,442.50</strong> contract-basis figure on invoice #28064.</li>
  <li>The 10% contractual late fee (<strong>`$12,644.25</strong>) will be assessed on invoice #28064 as of May 1, 2026, and will not be waived.</li>
</ul>

<p><strong>2. Firm remittance dates for all open invoices.</strong></p>

<p>The following five invoices remain open on the Boston Group account:</p>
<ul>
  <li>Invoice #27890 &mdash; Recurring, `$552.00 &mdash; due 3/31/2026 &mdash; <strong>past due, late fee assessed and will not be waived</strong></li>
  <li>Invoice #27949 &mdash; March Monthly, `$5,645.35 &mdash; due 3/31/2026 &mdash; <strong>past due, late fee assessed and will not be waived</strong></li>
  <li>Invoice #28064 &mdash; Service Cancellation, `$126,442.50 &mdash; due 4/30/2026 (or `$15,045.00 if settled in writing)</li>
  <li>Invoice #28112 &mdash; Recurring, `$552.00 &mdash; due 5/1/2026</li>
  <li>Invoice #28143 &mdash; April Monthly, `$5,694.60 &mdash; due 5/1/2026</li>
</ul>

<p>Your April 16 statement that the April charges &ldquo;will be paid as soon as possible&rdquo; is noted, but a firm remittance date is needed to stop the late-fee clock on the overdue invoices. Please reply with a specific payment date or a written payment arrangement from your Accounts Payable for all five invoices.</p>

<p><strong>3. Counsel-to-counsel call.</strong></p>

<p>I have alerted our counsel, Edward Susolik at Callahan &amp; Blaine (es@callahan-law.com), that Mr. Cron is your attorney. With 10 days remaining, a direct call between counsel is the most efficient path to resolving the cancellation reconciliation before April 30. Mr. Cron is welcome to reach out to Ed directly at es@callahan-law.com to propose times.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body    = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $toEmail; Name = $toName } }
    )
    CcRecipients = $ccList
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
$draftId = $draft.Id

# Save MessageId for scheduled send
Set-Content -Path $idFile -Value $draftId -Encoding UTF8
Write-Host "Draft created. MessageId saved to: $idFile" -ForegroundColor Green
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray
Write-Host "Cc      : gagan@bostongroupwaste.com, lcronlaw@gmail.com, es@callahan-law.com" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
Write-Host "`nDRAFT is in Outlook Drafts. Review it, then the scheduled task will send it tomorrow at 8:00 AM." -ForegroundColor Yellow
