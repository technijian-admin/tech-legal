# Send BST Jeff Klein Pre-Expiration Follow-up via Microsoft Graph
# DEFAULT: creates draft only (review in Outlook before sending)
# Target send window: week of 2026-04-21 (before 4/30 deadline)
#
# Usage:
#   .\send-bst-jeff-followup.ps1         # draft only (DEFAULT)
#   .\send-bst-jeff-followup.ps1 -Send   # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$recipientEmail = "jklein@bostongroupwaste.com"
$recipientName  = "Jeff Klein"
$ccEmail        = "gagan@bostongroupwaste.com"
$ccName         = "Gagan Singh"
$senderUpn      = "RJain@technijian.com"
$subject        = "RE: Service Cancellation - Status Check Before April 30 Deadline"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

# --- Build HTML body (backtick-escape every literal $) ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Hello Jeff,</p>

<p>I wanted to check in as we approach the April 30, 2026 service end date.</p>

<p>On March 23, I sent you the under-contract termination reconciliation with a contract-basis cancellation fee of <strong>`$126,442.50</strong> (invoice #28064), along with a good-faith settlement alternative of <strong>`$15,045.00</strong> (global life-of-contract reconciliation) for a clean resolution. You responded that your attorney was reviewing the contract. Since then we have not heard further.</p>

<p><strong>Three items I'd like to close out before April 30:</strong></p>

<ol>
<li><strong>Counsel contact.</strong> So that our counsel (Edward Susolik at Callahan &amp; Blaine) can coordinate directly, please send me the name, firm, and contact information for your attorney.</li>
<li><strong>Settlement offer.</strong> The `$15,045.00 alternative remains open through close of business on April 30, 2026 per my March 23 email. If acceptance in writing is not received by that date, the offer will expire by its terms and Technijian's position reverts to the `$126,442.50 contract-basis figure on invoice #28064.</li>
<li><strong>Final invoicing.</strong> The April 2026 monthly invoice (#27949) covers services through the April 30 termination date and remains payable per Section 4.05 of the signed agreement, separate from the cancellation reconciliation.</li>
</ol>

<p>We remain prepared to resolve this cooperatively. If your counsel would prefer to engage with Mr.&nbsp;Susolik directly, please have them reach out to him at es@callahan-law.com; otherwise I am available.</p>

<p>Thank you,</p>

</div>
$sig
</body>
</html>
"@

# --- Connect to Graph ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body = @{
        ContentType = "HTML"
        Content     = $htmlBody
    }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $recipientEmail; Name = $recipientName } }
    )
    CcRecipients = @(
        @{ EmailAddress = @{ Address = $ccEmail; Name = $ccName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "Sending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "`nSENT to $recipientEmail (cc: $ccEmail)." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts folder for RJain@technijian.com." -ForegroundColor Yellow
    Write-Host "Review in Outlook, then either:" -ForegroundColor Yellow
    Write-Host "  - Click Send from Outlook, OR" -ForegroundColor Yellow
    Write-Host "  - Re-run this script with -Send flag to send automatically" -ForegroundColor Yellow
}
Write-Host "Subject: $subject" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
