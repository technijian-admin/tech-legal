# Reply to Franklin T. Dunn (Callahan & Blaine) on the Sunrun/Costco matter.
# Frank's 2026-04-24 12:28 PM PT email posed an explicit question on
# monitoring/app access and a factual framing he wanted confirmed before
# drafting the demand letter. This reply answers the question, provides
# focused factual clarifications, and offers call windows for this afternoon.
#
# Default is DRAFT-ONLY (saves to Ravi's Outlook Drafts for review).
# Use -Send to send immediately.

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

# Reply threading to Frank's 2026-04-24 19:28 UTC message
$inReplyTo = "<BN0PR08MB6855383C2D661B65A4E5A166912B2@BN0PR08MB6855.namprd08.prod.outlook.com>"

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

<p>Thank you &mdash; your factual framing is accurate in substance. Answers to your explicit question below, followed by a short list of clarifications to tighten the demand letter, and my availability for a call this afternoon.</p>

<h3 style="color:#b30000;">1. Monitoring / app access &mdash; yes, four channels</h3>

<p>I have (or Sunrun has) real-time and historical production data for both systems through the following:</p>

<ul>
  <li><strong>mySunrun app and web portal</strong> (my.sunrun.com) &mdash; shows daily, monthly, and lifetime production for both systems on the account. During the outage it showed flat-zero production bars for the 2017 Costco system from November 10, 2025 forward. On April 18, 2026 (two days after the April 16 repair) the app flipped to an <em>&ldquo;Outlier detected&rdquo;</em> status and has since displayed <strong>estimated</strong>, not actual, production. Screenshots preserved.</li>
  <li><strong>SolarEdge monitoring portal</strong> &mdash; SolarEdge optimizers on the 2017 Costco system log panel-level production locally and backfill to the cloud once the uplink is restored. Sunrun Installation Services holds admin credentials; I have requested view-only access and the full April 16&ndash;22 panel-level export in my April 22 follow-up to Katherine Wilson. That request is outstanding.</li>
  <li><strong>SDG&amp;E Net Energy Metering interval data</strong> (Account No. 0036-1837-1728-9, NEM Meter No. 06688420) &mdash; utility-side record of net export, independent of Sunrun. The NEM summary on every monthly SDG&amp;E bill from December 2025 through April 2026 shows <strong>zero exported kWh across every Time-of-Use bucket</strong>. This is the strongest piece of third-party corroboration.</li>
  <li><strong>Physical SolarEdge inverter lifetime-kWh counter</strong> &mdash; a reading on the unit itself, read by the Sunrun technician on the April 16 and April 22 site visits. I have asked for both readings in writing; the delta is the on-device answer to any later &ldquo;generating but not uploading&rdquo; argument.</li>
</ul>

<p>The critical point for the claim: <strong>Sunrun&#39;s own proprietary monitoring detected the failure on November 10, 2025</strong> and opened internal Case No. 18181148 that same day with subject designation <em>&ldquo;Metering.&rdquo;</em> Sunrun then did not notify me for 67 days. That asymmetry &mdash; superior monitoring knowledge plus prolonged non-disclosure &mdash; is the core of the concealment / UCL theory.</p>

<h3 style="color:#b30000;">2. Short list of clarifications for the demand letter</h3>

<ol>
  <li><strong>Units &mdash; kW vs. kWh.</strong> The 2012 system is <strong>&sim;5.5 kW DC nameplate capacity</strong> (not 10 kWh). The 2017 Costco system is <strong>5.61 kWp DC nameplate</strong>. Combined nameplate on file with SDG&amp;E: <strong>11.16 kW</strong>. On a typical April day in Orange County each system produces on the order of 25&ndash;30 kWh. Household average daytime draw is closer to 17.5 kWh during solar hours, which is why the zero-export reading is material.</li>
  <li><strong>2017 counterparty structure.</strong> Agreed Costco is nominally the principal on the 2017 Home Improvement Sales Contract, but the CSLB license, the 10-year Limited Warranty (performance warranty, not just labor), and the on-contract signature all come from <strong>Sunrun Installation Services, Inc.</strong> (CSLB License No. <strong>750184</strong>; signer: Roland Claudio &ldquo;on behalf of Sunrun&rdquo;). Ed&#39;s April 23 template accordingly addresses the demand to <em>both</em> Sunrun, Inc. and Sunrun Installation Services, Inc. as co-recipients. Costco is preserved as a potential additional defendant if needed.</li>
  <li><strong>Both systems are in play, not just the 2017.</strong> The primary outage is the 2017 Costco system (0 kWh confirmed by the April 22 on-site technician, who replaced the uplink circuit). But the 2012 Prepaid PPA is also on the table because (a) Section 8 Guaranteed Output refund obligations run regardless of which system failed, (b) Sunrun&#39;s written `$500 offer was <strong>computed against the 2012 PPA prepayment</strong> (`$20,000 &divide; 240 months &times; 5 months = `$415, rounded to `$500), which is itself an acknowledgment that the PPA&#39;s production was deficient during the window, and (c) Katherine Wilson has improperly invoked Section 5c (Supplemental Energy) of the PPA as a liability shield against what is fundamentally a workmanship / monitoring failure.</li>
  <li><strong>The 2017 Limited Warranty reads on ongoing performance, not a one-time measurement.</strong> The 85%-of-DC-nameplate test runs for 10 years from permit sign-off &mdash; it is a continuing obligation, not an installation-time snapshot. Five continuous months of zero production is a textbook warranty trigger. I can pull the exact clause text if useful; the PDF is at <em>docs/personal/sunrun/agreement-retail-cust-owned-design-plan.pdf</em>.</li>
  <li><strong>Disclaimer enforceability.</strong> The consequential-damages exclusion and any limitation-of-liability clause in both contracts are subject to <strong>Civ. Code &sect; 1668</strong> as recently construed in <em>New England Country Foods, LLC v. Vanlaw Food Products, Inc.</em>, S282968 (Cal. Apr. 24, 2025). Vanlaw invalidates those provisions for claims sounding in fraud, willful misconduct, or violation of law &mdash; which covers every tort count here. Ed&#39;s April 23 template already cites it; worth keeping front-and-center in the letter.</li>
  <li><strong>Sunrun&#39;s own CLRA posture.</strong> On April 22, 2026 Katherine Wilson stated in writing that <strong>`$500 is the maximum authorization</strong> and that <strong>access to Sunrun&#39;s Legal Department requires retention of counsel</strong>. That is a usable fact both for CLRA &sect; 1770(a)(14) (misrepresenting rights) and for CCP &sect; 1021.5 private-attorney-general fee-shifting.</li>
  <li><strong>Prior agency filings, corrected.</strong> CPUC complaint No. <strong>726931</strong> was closed by the CPUC by letter dated April 21, 2026 (referred to CSLB). The earlier memo referencing &ldquo;#226711&rdquo; was an internal tracking number; the CPUC file number is 726931. A CSLB complaint is teed up but not yet filed (awaiting your guidance on timing).</li>
</ol>

<h3 style="color:#b30000;">3. Demand-letter template</h3>

<p>At Ed&#39;s request I sent him a factually scoped template on Wednesday, April 23, 2026 (8:56 AM PT &mdash; same thread). It incorporates the Vanlaw / &sect; 1668 argument, the CLRA &sect; 1782 30-day cure posture, the document-preservation demand, the forum reservations (JAMS for the 2012 PPA / Superior Court for the 2017 Costco), and a `$15,000 settlement figure (vs. Sunrun&#39;s standing `$500 offer). Ed assigned the matter to you later that afternoon and I have not yet received substantive feedback on the template itself &mdash; please treat it as a starting draft for you to revise as you see fit. Happy to resend it directly to you and to package the supporting exhibits (two contracts, six monthly SDG&amp;E bills, mySunrun screenshots, full Sunrun correspondence thread, CPUC closing letter, April 16 and April 22 technician visit evidence) as a single PDF set &mdash; just say the word.</p>

<h3 style="color:#b30000;">4. Call availability today (Friday, April 24)</h3>

<p>I am free <strong>any time after 2:30 PM PT today</strong>. Cell is 714.402.3164 &mdash; call whenever works for you and I&#39;ll pick up.</p>

<p>On matter sequencing &mdash; per my reply to you earlier today, Sunrun is the highest urgency (May 1 formal-demand response deadline, May 16 CLRA cure ripens, May 4 Sunrun site visit). Vintage is next (settlement posture). BST and the remaining items can slot in behind those.</p>

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

Write-Host "Creating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject          = $subject
    Body             = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients     = @($toGraph)
    CcRecipients     = @($ccGraph)
    Importance       = "Normal"
    InternetMessageHeaders = @(
        @{ Name = "In-Reply-To"; Value = $inReplyTo },
        @{ Name = "References";  Value = $inReplyTo }
    )
}
# InternetMessageHeaders requires an x- prefix per Graph API, so fall back to
# letting Outlook thread by Subject if the custom-header path fails.
try {
    $draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
} catch {
    Write-Host "Custom threading headers rejected (expected); creating without them..." -ForegroundColor DarkYellow
    $draftParams.Remove('InternetMessageHeaders') | Out-Null
    $draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
}
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
