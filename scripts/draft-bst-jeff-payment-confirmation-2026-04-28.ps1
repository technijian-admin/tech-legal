# Settlement payment confirmation email to Jeff Klein
# Confirms 4/27 acceptance, gives wire window through 4/30 COB
# Includes conditional late-fee waiver tied to prompt payment

$ErrorActionPreference = "Stop"

$toEmail    = "jklein@bostongroupwaste.com"
$toName     = "Jeff Klein"
$ccList     = @(
    @{ EmailAddress = @{ Address = "gagan@bostongroupwaste.com"; Name = "Gagan Singh" } },
    @{ EmailAddress = @{ Address = "lcronlaw@gmail.com";          Name = "Lawrence Cron, Esq." } },
    @{ EmailAddress = @{ Address = "fdunn@callahan-law.com";      Name = "Frank Dunn, Esq." } },
    @{ EmailAddress = @{ Address = "es@callahan-law.com";         Name = "Edward Susolik, Esq." } },
    @{ EmailAddress = @{ Address = "billing@technijian.com";      Name = "Technijian Billing" } }
)
$senderUpn  = "RJain@technijian.com"
$subject    = "Boston Group -- Confirming Payment Path to Close Out by April 30"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Credentials ---
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) { Write-Error "Failed to parse M365 credentials"; exit 1 }

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

<p>Following up on our exchange yesterday confirming the path to close out by April 30, 2026. Putting the payment particulars in writing so your Accounts Payable has everything they need to wire the funds this week, and clarifying the conditions that govern the close.</p>

<p><strong>Total amount required by April 30, 2026 COB to consummate the settlement: `$13,063.69</strong></p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Invoice</th><th style="text-align:left">Type</th><th style="text-align:right">Principal</th><th style="text-align:right">10% Late Fee</th><th style="text-align:right">Total</th></tr>
</thead>
<tbody>
<tr><td>#27890</td><td>Recurring (past due 3/31)</td><td style="text-align:right">`$552.00</td><td style="text-align:right">`$55.20</td><td style="text-align:right">`$607.20</td></tr>
<tr><td>#27949</td><td>March Monthly (past due 3/31)</td><td style="text-align:right">`$5,645.35</td><td style="text-align:right">`$564.54</td><td style="text-align:right">`$6,209.89</td></tr>
<tr><td>#28112</td><td>Recurring (due 5/1)</td><td style="text-align:right">`$552.00</td><td style="text-align:right">--</td><td style="text-align:right">`$552.00</td></tr>
<tr><td>#28143</td><td>April Monthly (due 5/1)</td><td style="text-align:right">`$5,694.60</td><td style="text-align:right">--</td><td style="text-align:right">`$5,694.60</td></tr>
<tr style="background-color:#f3f3f3;font-weight:bold"><td colspan="2">TOTAL DUE BY 4/30 COB</td><td style="text-align:right">`$12,443.95</td><td style="text-align:right">`$619.74</td><td style="text-align:right">`$13,063.69</td></tr>
</tbody>
</table>

<p>The 10% contractual late fees on the two overdue March invoices were assessed when those invoices went past due, per Other Terms &para;&nbsp;3 of the Agreement. Per my April 16 email, those late fees are not being waived (Technijian has previously waived late fees for Boston Group as a business courtesy on two prior occasions; those were discretionary, non-precedential accommodations). Full payment of `$13,063.69 is required to consummate the settlement.</p>

<p><strong>Settlement is conditional on full payment received by April 30, 2026 COB.</strong> The agreement reached yesterday is a settlement of the cancellation-fee dispute, contingent upon Boston Group's payment of the full `$13,063.69 by April 30, 2026 close of business. If full payment is not received by that date, the settlement does not consummate, and Technijian's full position is reactivated by its own terms -- including, without limitation:</p>

<ul>
  <li>Reassertion of a cancellation fee under Section 5 of the "Under Contract" provisions (Technijian's textual analysis of Section 5 supports a cancellation fee on Cycle&nbsp;2 unpaid positive excess hours -- the analysis differs from the originally-stated `$126,442.50, but it is non-zero and material; counsel can provide the supporting calculations on request);</li>
  <li>All accrued and continuing 10% contractual late fees on every unpaid invoice;</li>
  <li>Prejudgment interest, contractual attorneys' fees and costs (Section 1717), AAA arbitration costs per Section 6.10, and any other available remedies;</li>
  <li>Withdrawal of any closing accommodations or compromises offered to date.</li>
</ul>

<p><strong>Cancellation invoice #28064 (`$126,442.50)</strong> -- Technijian is holding this invoice open in our system pending receipt of the `$13,063.69 settlement payment. <strong>The voiding of #28064 is conditional on full payment by April 30 COB.</strong> Once payment lands, billing will void #28064 and you will receive written confirmation.</p>

<p><strong>Wire details</strong> (also on each invoice):</p>
<ul>
  <li>Bank: Chase</li>
  <li>Account: 791013375</li>
  <li>Routing: 322271627</li>
  <li>Reference: BST -- Closeout April 2026 -- Invoices #27890, #27949, #28112, #28143</li>
</ul>

<p><strong>Once full `$13,063.69 payment lands by April 30 COB</strong>, Technijian will:</p>
<ol>
  <li>Void invoice #28064 (`$126,442.50) in the billing system and send written confirmation;</li>
  <li>Mark all four monthly invoices and assessed late fees paid in full;</li>
  <li>Coordinate the formal mutual release language through counsel (Frank Dunn at Callahan &amp; Blaine on copy here is handling for Technijian; Mr. Cron coordinating for Boston Group).</li>
</ol>

<p><strong>For clarity on scope of release.</strong> The mutual release will cover the cancellation-fee matter (invoice #28064), the four monthly invoices and the assessed late fees, and any &para;&nbsp;4 credit/reconciliation claim through April 30, 2026. The release does <strong>not</strong> cover any claims Technijian may have against any third party -- including without limitation Tech Heights or Mr. Renwick "Rich" Leggett -- arising from conduct in the BST environment between 3/31 and 4/3, 2026 (including the unauthorized ESXi password change, the CrowdStrike-blocked Domain Admins elevation attempt of 4/2-4/3, and the removal of Technijian monitoring agents). Those claims remain expressly reserved.</p>

<p><strong>Action requested today / tomorrow:</strong> Please have your AP confirm the wire initiation date and reference number to me and Mr. Cron in writing as soon as the wire is in motion. Mr. Cron can coordinate directly with Frank Dunn (fdunn@callahan-law.com) on any release-language particulars.</p>

<p>I would much rather close this matter cleanly with the `$13,063.69 wire by Thursday than reactivate the full position. Let us get this done.</p>

<p>Thank you, Jeff.</p>

</div>
$sig
</body>
</html>
"@

# --- Connect ---
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

# --- Create draft ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body    = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(@{ EmailAddress = @{ Address = $toEmail; Name = $toName } })
    CcRecipients = $ccList
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

Write-Host ""
Write-Host "DRAFT saved to Outlook Drafts." -ForegroundColor Yellow
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray
Write-Host ("Cc      : " + (($ccList | ForEach-Object { $_.EmailAddress.Address }) -join ', ')) -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
