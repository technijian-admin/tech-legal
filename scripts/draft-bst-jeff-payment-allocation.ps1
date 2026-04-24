# Draft email to Jeff Klein: Payment allocation rule + April 30 math
# Creates draft in Outlook only — NO auto-send.
# Run: .\draft-bst-jeff-payment-allocation.ps1

$ErrorActionPreference = "Stop"

$toEmail    = "jklein@bostongroupwaste.com"
$toName     = "Jeff Klein"
$ccList     = @(
    @{ EmailAddress = @{ Address = "gagan@bostongroupwaste.com"; Name = "Gagan Singh" } },
    @{ EmailAddress = @{ Address = "lcronlaw@gmail.com";          Name = "Mr. Cron" } },
    @{ EmailAddress = @{ Address = "fdunn@callahan-law.com";      Name = "Frank Dunn, Esq." } },
    @{ EmailAddress = @{ Address = "es@callahan-law.com";         Name = "Edward Susolik, Esq." } }
)
$senderUpn  = "RJain@technijian.com"
$subject    = "RE: Boston Group - Payment Allocation and April 30 Confirmation"
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

<p>Following up on my April 20 email. We have not received a substantive response from Boston Group or Mr. Cron on payment or settlement. In the intervening days, Technijian has honored every support request you or your team has made &mdash; disabling tamper protection on our agents, uninstalling Huntress and ManageEngine from your endpoints, and granting you Microsoft 365 global administrator access on your tenant &mdash; all performed in good faith and without prejudice to any claim or the reservation of rights already on the record.</p>

<p>Six days remain until the April 30, 2026 deadline. To avoid any confusion about what a clean resolution looks like, I am confirming in writing how any payment received from Boston Group will be applied and what the `$15,045 settlement requires in practice.</p>

<p><strong>1. Application of payments.</strong> Any payment received from Boston Group will be applied <strong>first</strong> to the four monthly/recurring invoices currently open or about to come due, and <strong>last</strong> to the service cancellation invoice:</p>

<ol>
  <li>Invoice #27890 &mdash; Recurring &mdash; `$552.00 (past due, late fee assessed and will not be waived)</li>
  <li>Invoice #27949 &mdash; March Monthly &mdash; `$5,645.35 (past due, late fee assessed and will not be waived)</li>
  <li>Invoice #28112 &mdash; Recurring &mdash; `$552.00 (due 5/1/2026)</li>
  <li>Invoice #28143 &mdash; April Monthly &mdash; `$5,694.60 (due 5/1/2026)</li>
  <li>Invoice #28064 &mdash; Service Cancellation &mdash; applied <em>last</em></li>
</ol>

<p><strong>2. What the `$15,045 settlement requires in practice.</strong> The `$15,045.00 figure is a good-faith concession on the service cancellation invoice (#28064) only. It is <strong>not</strong> a concession on the monthly/recurring invoices for services already rendered. A clean resolution under the settlement therefore requires the monthly invoices to be paid in full on top of the `$15,045:</p>

<ul>
  <li>Monthly and recurring invoices (#27890 + #27949 + #28112 + #28143): <strong>`$12,443.95</strong></li>
  <li>Settlement of cancellation invoice #28064: <strong>`$15,045.00</strong></li>
  <li><strong>Total required by April 30, 2026 COB: `$27,488.95</strong> (plus the late fees already assessed on #27890 and #27949)</li>
</ul>

<p><strong>3. Consequence if any invoice is left unpaid as of April 30, 2026 COB.</strong> If the total received by April 30 is less than the amounts above, any partial payment will be applied in the order set out in Point 1, and:</p>

<ul>
  <li>The `$15,045 settlement offer expires by its own terms on April 30, 2026 COB.</li>
  <li>Technijian's position on the cancellation invoice reverts in full to the contract-basis figure of <strong>`$126,442.50</strong>.</li>
  <li>The 10% contractual late fee (<strong>`$12,644.25</strong>) will be assessed on invoice #28064 as of May 1, 2026 and will not be waived.</li>
</ul>

<p>In short: <strong>`$27,488.95 received by April 30 COB closes this out on the settlement terms Boston Group expressed a preference for in the April 16 email. Anything less means the full contract-basis figure applies.</strong></p>

<p>Mr. Cron &mdash; Technijian's handling attorney at Callahan &amp; Blaine is <strong>Frank Dunn (fdunn@callahan-law.com)</strong>, with Edward Susolik supervising. Please coordinate directly with Mr. Dunn on how Boston Group intends to proceed. Six days is a short window.</p>

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
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray
Write-Host "Cc      : gagan@bostongroupwaste.com, lcronlaw@gmail.com, es@callahan-law.com" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
Write-Host "`nDRAFT is in Outlook Drafts. Review it, then send from Outlook when ready." -ForegroundColor Yellow
