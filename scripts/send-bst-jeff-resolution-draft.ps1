# DRAFT email from Ravi to Jeff Klein per Frank Dunn's 2026-04-27 18:46 instruction:
# "email Jeff and simply state that you want to get this matter behind the company
#  and if he pays the 4 outstanding invoices by Thursday, you will not pursue any
#  further claims."
#
# CC: Lawrence Cron (Jeff's counsel) -- proper protocol when contacting represented party.
# Frank + Ed are NOT cc'd visibly per Frank's "no attorneys officially involved" framing.
# Does NOT send. User reviews in Outlook before clicking Send.

$ErrorActionPreference = "Stop"

$senderUpn = "RJain@technijian.com"
$sigPath   = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$toEmail   = "jklein@bostongroupwaste.com"
$toName    = "Jeff Klein"
$ccEmail   = "lcronlaw@gmail.com"
$ccName    = "Lawrence Cron, Esq."

$subject   = "Resolving the Outstanding Invoices - Path Forward by April 30"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = [System.IO.File]::ReadAllText($sigPath) }

# --- Body (NOTE: backtick-dollar for literal `$ in here-string) ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Jeff,</p>

<p>I want to put this matter behind both of our companies. Here is what I propose, and I think it is the cleanest path for everyone.</p>

<p>Our accounting team has reviewed the cancellation calculation on invoice <strong>#28064</strong> and identified a methodology error. We are voiding that invoice; you will receive a credit memo confirming the void. That removes the cancellation-fee dispute from the table entirely.</p>

<p>That leaves four invoices outstanding for services already rendered:</p>

<table style="border-collapse:collapse;font-family:$fontStack;font-size:11pt">
  <tr style="background:#f4f4f4">
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:left">Invoice</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:left">Type</th>
    <th style="border:1px solid #ccc;padding:6px 10px;text-align:right">Amount</th>
  </tr>
  <tr>
    <td style="border:1px solid #ccc;padding:6px 10px">#27890</td>
    <td style="border:1px solid #ccc;padding:6px 10px">Recurring services</td>
    <td style="border:1px solid #ccc;padding:6px 10px;text-align:right">`$552.00</td>
  </tr>
  <tr>
    <td style="border:1px solid #ccc;padding:6px 10px">#27949</td>
    <td style="border:1px solid #ccc;padding:6px 10px">Monthly Support (March)</td>
    <td style="border:1px solid #ccc;padding:6px 10px;text-align:right">`$5,645.35</td>
  </tr>
  <tr>
    <td style="border:1px solid #ccc;padding:6px 10px">#28112</td>
    <td style="border:1px solid #ccc;padding:6px 10px">Recurring services</td>
    <td style="border:1px solid #ccc;padding:6px 10px;text-align:right">`$552.00</td>
  </tr>
  <tr>
    <td style="border:1px solid #ccc;padding:6px 10px">#28143</td>
    <td style="border:1px solid #ccc;padding:6px 10px">Monthly Support (April)</td>
    <td style="border:1px solid #ccc;padding:6px 10px;text-align:right">`$5,694.60</td>
  </tr>
  <tr style="background:#f4f4f4;font-weight:bold">
    <td style="border:1px solid #ccc;padding:6px 10px" colspan="2">Total</td>
    <td style="border:1px solid #ccc;padding:6px 10px;text-align:right">`$12,443.95</td>
  </tr>
</table>

<p>If BST pays these four invoices in full by <strong>Thursday, April 30, 2026</strong>, Technijian will consider this matter fully resolved and will not pursue any further claims related to the agreement or the termination.</p>

<p>No cancellation fee. No interest. No legal proceedings. Just payment for services rendered, and we both move on.</p>

<p>Please confirm by reply &mdash; or have Mr. Cron confirm &mdash; that BST will pay by Thursday, or let me know if there is anything keeping that from happening so we can talk through it.</p>

<p>Thank you, Jeff.</p>

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

# --- Create draft (NOT a reply -- new thread because this is a different conversation
#     than the Cron/cancellation thread; keeps it clean) ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @( @{ EmailAddress = @{ Address = $toEmail; Name = $toName } } )
    CcRecipients = @( @{ EmailAddress = @{ Address = $ccEmail; Name = $ccName } } )
}

Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "DRAFT READY in Outlook Drafts (NOT sent)." -ForegroundColor Yellow
Write-Host "Open Outlook -> Drafts -> '$subject'" -ForegroundColor Yellow
Write-Host "Review, then click Send." -ForegroundColor Yellow
Write-Host ""
Write-Host "BEFORE SENDING:" -ForegroundColor Yellow
Write-Host "  1. Confirm invoice #28064 cancellation void is processed." -ForegroundColor Gray
Write-Host "  2. Confirm BCC Frank+Ed (or forward separately after send)." -ForegroundColor Gray
Write-Host "Draft Id: $($draft.Id)" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Yellow
