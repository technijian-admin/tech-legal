# Draft email to Ed Susolik: BST counsel now identified — Mr. Cron (lcronlaw@gmail.com)
# Creates a draft in Outlook Drafts only — no attachments, no send flag.
# Run, then review in Outlook and send manually.

param([switch]$Send)

$ErrorActionPreference = "Stop"

$recipientEmail = "es@callahan-law.com"
$recipientName  = "Edward Susolik, Esq."
$senderUpn      = "RJain@technijian.com"
$subject        = "BST (Boston Group) — BST Counsel Now Identified; Counsel-to-Counsel Call Before 4/30"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys    = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
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

<p>Ed,</p>

<p>Quick update on BST (Boston Group) ahead of the April 30 deadline &mdash; two things happened on April 16 that change the picture.</p>

<p><strong>1. BST's counsel is now identified.</strong></p>

<p>Jeff Klein replied to my April 14 closeout email and copied his attorney for the first time:
<strong>Mr. Cron &mdash; lcronlaw@gmail.com.</strong>
He did not provide Mr. Cron's first name or firm in the email, but the cc is clear. That resolves the open question from our March 19 call about whether and when BST counsel would surface.</p>

<p><strong>2. Jeff's position in that email (April 16, 9:35 PM).</strong></p>
<ul>
  <li>Acknowledged the April monthly invoices (#28112, `$552.00; #28143, `$5,694.60) will be paid &ldquo;as soon as possible&rdquo; &mdash; no firm date given.</li>
  <li>Expressed a preference to pay the `$15,045 life-of-contract settlement figure rather than the `$126,442.50 contract-basis cancellation invoice, but stated he &ldquo;cannot find any reference to unbilled hours in the invoices sent to us monthly&rdquo; and was &ldquo;not told about&rdquo; work performed but not billed.</li>
  <li>Asked for Microsoft 365 global admin credentials (redirected to Tech Heights in my reply).</li>
</ul>

<p><strong>3. My reply (April 16, 11:50 PM) &mdash; you were copied.</strong></p>
<p>I addressed all five points in writing. Key items for your file:</p>
<ul>
  <li>Rebutted the &ldquo;no notice of unbilled hours&rdquo; claim: every weekly and monthly invoice for 36 months carried a separate time-entries spreadsheet disclosing offshore/onshore allocation per ticket. Invoice #28143 (April 1, 2026) expressly showed 286.39 unpaid India Normal hours and 35.29 India After-Hours hours, with the footnote language from the MSA. No timely objection was filed by BST across the full contract term.</li>
  <li>Confirmed the `$15,045 settlement offer remains open through April 30, 2026, COB, conditioned on written acceptance. No extension was offered.</li>
  <li>Confirmed that if invoice #28064 (`$126,442.50) is not paid or settled in writing by April 30, the 10% contractual late fee (`$12,644.25) will be assessed and will not be waived.</li>
  <li>Invited a counsel-to-counsel call before April 30 and directed Mr. Cron to your contact at es@callahan-law.com.</li>
</ul>

<p><strong>Where things stand today (April 20).</strong></p>
<p>We have 10 days. Jeff is verbally inclined toward `$15,045 but has not put anything in writing. Mr. Cron has not yet reached out. The full termination reconciliation package (damages analysis, settlement memo, case law memo, signed MSA, invoices, exhibits) is ready for you and I will send it under separate cover this week &mdash; it is large and I wanted to flag the counsel development first.</p>

<p>A few things I would value your guidance on before the deadline:</p>
<ol>
  <li><strong>Should you reach out to Mr. Cron proactively</strong> to schedule the call, or let him come to you? We have 10 days and I would rather not lose a week waiting.</li>
  <li><strong>If Jeff sends written acceptance of `$15,045 before 4/30</strong> but the March and April monthly invoices (#27890, #27949, #28112, #28143, totaling `$12,443.95) are still unpaid, do we require those to be paid concurrently as a condition of the settlement, or handle them separately?</li>
  <li><strong>Tech Heights / Leggett.</strong> Still inclined to preserve only &mdash; reservation-of-rights in any BST settlement &mdash; unless you think a parallel letter to Leggett now creates useful pressure. Your call.</li>
</ol>

<p>Happy to get on a call this week. Please use the booking link in my email signature to find a time, or reach me on my cell.</p>

<p>Thanks, Ed.</p>

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
    Body = @{
        ContentType = "HTML"
        Content     = $htmlBody
    }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $recipientEmail; Name = $recipientName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT to $recipientEmail." -ForegroundColor Green
} else {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "DRAFT saved to Outlook Drafts for RJain@technijian.com." -ForegroundColor Yellow
    Write-Host "Subject: $subject" -ForegroundColor Gray
    Write-Host "To: $recipientEmail" -ForegroundColor Gray
}

Disconnect-MgGraph | Out-Null
