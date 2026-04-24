# Reply to Franklin T. Dunn with feedback on his 2026-04-24 draft
# demand letter (Settlement Demand Sunrun (Draft v1 4-24-26).docx) and
# the 12-page email exhibits PDF.
#
# Default is DRAFT-ONLY (saves to Ravi's Outlook Drafts for review).
# Use -Send to dispatch immediately.

param([switch]$Send)

$ErrorActionPreference = "Stop"

$toRecipients = @(
    @{ Address = "fdunn@callahan-law.com"; Name = "Franklin T. Dunn" }
)
$ccRecipients = @(
    @{ Address = "ES@callahan-law.com"; Name = "Edward Susolik" }
)

$senderUpn = "RJain@technijian.com"
$subject   = "RE: FORMAL DEMAND - Solar System Disconnected 11/7/25-4/16/26 - 5 Caladium - Acct 0036 1837 1728 9 - Response Due Within 14 Days"
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

<p>Frank,</p>

<p>Thank you &mdash; the strategy of a short cover demand letter with the email thread incorporated by reference makes sense and saves restatement work. Comments below in three buckets: <strong>must-fix before send</strong>, <strong>substantive gaps not covered by the email exhibits</strong>, and <strong>tightening</strong>. Page references are to <em>Settlement Demand Sunrun (Draft v1 4-24-26).docx</em>.</p>

<h3 style="color:#b30000;">1. Must-fix before send</h3>

<ol>
  <li><strong>Typo in client name.</strong> The opening line reads &ldquo;This firm represents Ravi <strong>Jane</strong>.&rdquo; Should be <strong>Ravi Jain</strong>.</li>
  <li><strong>Unresolved Word DATE field.</strong> Top of the letter reads literally <code>DATE \@ &quot;MMMM d, yyyy&quot;</code> immediately before <em>April 24, 2026</em>. Looks like a merge field that didn&#39;t collapse on save. Should render as just <em>April 24, 2026</em>.</li>
  <li><strong>Verify the Sunrun, Inc. service address.</strong> The draft uses <strong>600 California Street, Suite 1800, San Francisco, CA 94108</strong>. My case file has <strong>225 Bush Street, 14th Floor, SF 94104</strong> as the verified current corporate HQ from Sunrun&#39;s investor-relations page, and the 2012 PPA itself designates <strong>45 Fremont Street, 32nd Floor, SF 94105</strong> as the contract notice address (Sunrun&#39;s 2012 HQ). Could you confirm the 600 California address against your CA Secretary of State lookup? For the PPA claims specifically, it may also be worth serving the 45 Fremont Street contract-notice address as a belt-and-suspenders move so Sunrun can&#39;t later argue notice was not perfected to the address designated in the agreement.</li>
</ol>

<h3 style="color:#b30000;">2. Substantive items not covered by the cover letter or the exhibit emails</h3>

<ol>
  <li><strong>Add <code>membercare@sunrun.com</code> to the CC line.</strong> The 2017 Limited Warranty &sect; 4 designates <code>membercare@sunrun.com</code> as the warranty notice channel. The current draft only CCs Katherine Wilson by email. Without <code>membercare@</code>, Sunrun has a small but real argument that 2017 warranty notice was not perfected through the contractually designated channel.</li>

  <li><strong>Express forum reservation paragraph.</strong> The cover letter only says &ldquo;all available legal remedies.&rdquo; The 4/19 email mentions JAMS and small claims, but tucked inside the settlement section. Suggest a one-paragraph reservation in the cover letter so Sunrun can&#39;t argue we waived any forum: <em>&ldquo;Mr. Jain expressly reserves all forums, including (a) JAMS arbitration under Section 16 of the 2012 Prepaid PPA for claims arising out of that agreement, (b) the Superior Court of California, County of Orange, for claims arising out of the 2017 Costco Home Improvement Sales Contract, and (c) individual or class proceedings under the CLRA and UCL.&rdquo;</em></li>

  <li><strong>Song-Beverly Consumer Warranty Act &sect; 1794(d).</strong> Not cited in either document. Residential solar is a &ldquo;consumer good&rdquo; under California precedent and Song-Beverly carries <strong>mandatory</strong> attorney&#39;s fees on a prevailing consumer. This is one of the strongest fee-shifters we have and should be on the leverage list.</li>

  <li><strong>CCP &sect; 1021.5 private-attorney-general fees.</strong> Same &mdash; Katherine&#39;s written &ldquo;`$500 cap + hire counsel for Legal access&rdquo; is the textbook &sect; 1021.5 systemic-barrier fact pattern. Worth invoking as a separate fee theory.</li>

  <li><strong>2012 PPA Section 8 refund as a separate demand item.</strong> The current settlement demand has only (i) `$15,000 and (ii) 2017 restoration. The Section 8 Guaranteed Output refund is a separate, contractual, anniversary-date obligation independent of any lump-sum settlement &mdash; Sunrun has not committed to it. Suggest adding as (iii): <em>&ldquo;Written confirmation of the 2012 Prepaid PPA Section 8 Guaranteed Output refund calculation and payment schedule for the current anniversary year.&rdquo;</em> Otherwise Sunrun pays the `$15K, fixes the 2017 system, and walks away from the PPA refund obligation.</li>

  <li><strong>Confirmation that &sect; 5c (Supplemental Energy) will not be invoked as a defense.</strong> Katherine has been improperly using PPA &sect; 5c (Supplemental Energy) as a liability shield against what is fundamentally a workmanship / monitoring failure. Worth foreclosing in the demand: <em>&ldquo;written confirmation that Sunrun will not assert Section 5c of the Prepaid PPA as a defense to the workmanship claims described in the attached correspondence.&rdquo;</em></li>
</ol>

<h3 style="color:#b30000;">3. Tightening</h3>

<ol>
  <li><strong>Cure deadline alignment.</strong> Draft says restoration &ldquo;no later than May 22, 2026.&rdquo; The CLRA &sect; 1782 30-day cure ripens on <strong>May 17, 2026</strong> (30 days from the April 17 formal demand). Suggest pulling the outside restoration date back to May 17 so both clocks ripen on the same day &mdash; otherwise Sunrun has a 5-day window to cure after the CLRA cause of action vests, which is awkward.</li>

  <li><strong>Damages figure.</strong> Draft says &ldquo;at least `$3,600.&rdquo; The 4/19 email had documented excess at `$2,583 plus an additional ~`$2,500 projected through the November 6, 2026 NEM true-up. If you have a more recent SDG&amp;E run that brings the documented number to `$3,600, that&#39;s fine; otherwise consider &ldquo;in excess of `$3,000 documented and additional projected charges accruing through restoration.&rdquo;</li>

  <li><strong>Signature block.</strong> Draft signs <em>Edward Susolik</em> with reference initials <em>ES:jn</em>. Two questions: (a) is Ed signing or are you? Either works &mdash; Ed signing carries senior-partner weight, you signing reflects current matter ownership. (b) The &ldquo;jn&rdquo; reference initials look like a Jenna Griffin artifact &mdash; my notes have her as no longer at the firm. Worth verifying the typist credit.</li>

  <li><strong>Enclosure description.</strong> Draft simply says &ldquo;Enclosures.&rdquo; Stronger record: <em>&ldquo;Enclosure: Email correspondence and supporting materials (12 pages).&rdquo;</em> That makes the served record unambiguous if Sunrun later disputes what was attached.</li>

  <li><strong>Mr. Jain&#39;s 2012 prepayment.</strong> Draft says &ldquo;over `$20,000.&rdquo; The actual figure is <strong>exactly `$20,000</strong> per the PPA, which is what Katherine&#39;s `$500 math was computed against (`$20,000 &divide; 240 months &times; 5 months = `$415, rounded up). Precise number reads tighter and ties to the offer-calculation argument.</li>
</ol>

<h3 style="color:#b30000;">4. What works well &mdash; endorse</h3>

<ul>
  <li>Two-recipient address structure (Sunrun, Inc. and Sunrun Installation Services, Inc.) is correct.</li>
  <li>14-day payment + 30-day CLRA cure structure is clean.</li>
  <li>Calling out CSLB License No. 750184 by name pins Sunrun Installer to its license obligations.</li>
  <li>Document preservation paragraph is appropriately broad.</li>
  <li>The incorporation-by-reference of the email exhibits package is efficient and avoids restatement; the 4/19 email already pleads CLRA &sect; 1770(a)(14), &sect;&sect; 1572 / 1710 fraudulent concealment, &sect; 17200, &sect; 3294 punitives, and Vanlaw / Civ. Code &sect; 1668 &mdash; so the cover letter doesn&#39;t need to re-plead.</li>
</ul>

<p>If it&#39;s helpful, I&#39;m happy to mark up a tracked-changes version of the .docx and send it back for your review. Otherwise the above items can be incorporated directly. Talk at 4 PM as agreed.</p>

<p>Thank you,</p>

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

$draftParams = @{
    Subject      = $subject
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($toGraph)
    CcRecipients = @($ccGraph)
    Importance   = "Normal"
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
