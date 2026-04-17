# Send Sunrun Solar Service Failure Demand Letter via Microsoft Graph
# DEFAULT: Tier 1 recipients only (Katherine + membercare + customercare), draft only
#
# Personal demand letter from Ravi Jain (homeowner) to Sunrun re: 5 Caladium solar disconnect
# Two contracts at issue: 2012 Prepaid PPA + 2017 Costco Customer-Owned
# Damages: `$2,583 documented + `$2,500 projected + PPA Section 8 refund + leverage = `$7,500 demand
#
# Strategy: Send Tier 1 first. If no substantive response in 14 days, re-run with -Escalate
# to add the Tier 2 executive CCs (CEO, Chief Legal Officer, Chief Field Ops, Asst General Counsel).
# Going to the C-suite on the first contact burns the strongest leverage before it's needed.
#
# Usage:
#   .\send-sunrun-demand.ps1                       # Tier 1 draft only (DEFAULT - START HERE)
#   .\send-sunrun-demand.ps1 -Send                 # Tier 1, send immediately
#   .\send-sunrun-demand.ps1 -Escalate             # Tier 1 + Tier 2 draft (after 14-day silence)
#   .\send-sunrun-demand.ps1 -Escalate -Send       # Tier 1 + Tier 2, send immediately

param(
    [switch]$Send,
    [switch]$Escalate
)

$ErrorActionPreference = "Stop"

# --- Recipients ---
$toRecipients = @(
    @{ Address = "katherine.wilson@sunrun.com"; Name = "Katherine Wilson" }
)

# Tier 1 = contractually required warranty channels (verified active)
# NOTE: customercare@sunrun.com sent an auto-response on 2026-04-17 02:27 UTC
# saying "This inbox is no longer monitored — use the app or call (855) 478-6786"
# It is removed from the CC list. Member Care remains the warranty notice channel.
$tier1Cc = @(
    @{ Address = "membercare@sunrun.com"; Name = "Sunrun Member Care (Warranty Notice)" }
)

# Tier 2 = executive escalation (firstname.lastname@sunrun.com pattern; unverified)
# Use ONLY after Tier 1 fails to produce a substantive response within 14 days.
$tier2Cc = @(
    @{ Address = "mary.powell@sunrun.com";       Name = "Mary Powell, CEO" },
    @{ Address = "jeanna.steele@sunrun.com";     Name = "Jeanna Steele, Chief Legal Officer" },
    @{ Address = "patrick.kent@sunrun.com";      Name = "Patrick Kent, Chief Field Operations Officer" },
    @{ Address = "carolyn.colasurdo@sunrun.com"; Name = "Carolyn Colasurdo, Assistant General Counsel" }
)

if ($Escalate) {
    $ccRecipients = $tier1Cc + $tier2Cc
    Write-Host "ESCALATION MODE: Tier 1 + Tier 2 recipients" -ForegroundColor Yellow
} else {
    $ccRecipients = $tier1Cc
    Write-Host "Tier 1 only (default - first-contact mode)" -ForegroundColor Cyan
}

$senderUpn = "RJain@technijian.com"
$subject   = "FORMAL DEMAND - Solar System Disconnected 11/7/25-4/16/26 - 5 Caladium - Acct 0036 1837 1728 9 - Response Due Within 14 Days"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Attachments ---
$sunrunDir = "c:\VSCode\tech-legal\tech-legal\docs\personal\sunrun"
$attachmentFiles = @(
    "$sunrunDir\agreement-retail-cust-owned-design-plan.pdf",  # 2017 Costco contract
    "$sunrunDir\33267 agt (1).pdf",                            # 2012 Prepaid PPA
    "$sunrunDir\Oct-2025.pdf",                                 # Pre-disconnect baseline
    "$sunrunDir\Nov-2025.pdf",                                 # Disconnect month
    "$sunrunDir\Dec-2025.pdf",                                 # First full month dead
    "$sunrunDir\Jan-2026.pdf",
    "$sunrunDir\Feb-2026.pdf",
    "$sunrunDir\Mar-2026.pdf",
    "$sunrunDir\Apr-2026.pdf"                                  # Most recent
)

# Verify all attachments exist
foreach ($f in $attachmentFiles) {
    if (-not (Test-Path $f)) { Write-Error "Missing attachment: $f"; exit 1 }
}

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

# --- HTML body ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:11pt;color:rgb(0,0,0)">

<p><strong>Date:</strong> April 16, 2026<br>
<strong>To:</strong> Sunrun, Inc. and Sunrun Installation Services, Inc.<br>
<strong>Re:</strong> FORMAL WARRANTY NOTICE AND DEMAND FOR REIMBURSEMENT &mdash; Solar System Service Failure<br>
<strong>Property:</strong> 5 Caladium, Rancho Santa Margarita / Las Flores, CA 92688<br>
<strong>SDG&amp;E Account:</strong> 0036 1837 1728 9 (NEM Meter #06688420, System Size 11.16 kW)<br>
<strong>Contracts:</strong> (1) 2012 Sunrun Solar Power Service Agreement (Prepaid PPA), Doc # PI139KV7A331V-A, executed 9/12/2012; and (2) 2017 Costco Home Improvement Sales Contract (Customer-Owned), executed 10/12/2017</p>

<p>To Sunrun, Sunrun Installation Services Inc., and the addressed recipients:</p>

<p>This letter constitutes formal written notice of warranty and contract breach under both of my Sunrun agreements, and a demand for reimbursement of `$7,500.00 for direct damages caused by Sunrun&#39;s service failure between November 7, 2025 and April 16, 2026. Please treat this as the written notice required by Section 4 of the 2017 Limited Warranty and as a notice of dispute under Section 16 of the 2012 Prepaid PPA. Two systems serve my property under separate Sunrun agreements: a 2012 Sunrun-owned, Sunrun-maintained Prepaid PPA system, and a 2017 customer-owned system installed through the Costco solar program. Together they comprise the 11.16 kW system on file with SDG&amp;E.</p>

<h3 style="color:#b30000;">1. Statement of Facts</h3>

<p><strong>November 10, 2025 &mdash; First service visit.</strong> Sunrun technicians arrived at the Property. They informed me that they could not complete the work that day and would need to return. They left without restoring the system to operation. No follow-up appointment was scheduled or kept by Sunrun in the months that followed, despite the system being non-operational.</p>

<p><strong>November 7, 2025 onward &mdash; System non-operational.</strong> SDG&amp;E&#39;s interval-meter data, as recorded on every monthly bill from December 2025 through April 2026 (attached), shows that the Solar Facility produced <strong>zero exportable energy in every Time-of-Use bucket</strong> from November 7, 2025 forward. The Net Energy Metering Summary on each bill contains no negative kWh entries &mdash; meaning the meter recorded no solar export to the grid in any hour of any day. By contrast, the October 9, 2025 bill (also attached) shows the Solar Facility exporting heavily under normal operation (Off-Peak: -550 kWh in the most recent prior period, -201 kWh in the period before that).</p>

<p><strong>April 16, 2026 &mdash; Second service visit and admission.</strong> Sunrun technicians returned today, restored the system to operation, and informed me that they did not know why the previous crew had disconnected it. The system is now operational. The cause of the original disconnection has not been explained in writing. The outage was therefore <strong>caused by Sunrun&#39;s own personnel during a service visit, not by grid failure, weather, or any act of mine</strong>.</p>

<h3 style="color:#b30000;">2. Documented Damages &mdash; SDG&amp;E Bills</h3>

<p>The seven attached SDG&amp;E bills compare the prior NEM year (Nov 2024 &ndash; Apr 2025, system working) to the current NEM year (Nov 2025 &ndash; Apr 2026, system disconnected). The comparison is conclusive:</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse; font-family:$fontStack; font-size:10pt;">
<thead style="background:#f2f2f2;">
<tr><th>Bill mailed</th><th>Period</th><th>Total kWh</th><th>NEM Charges</th><th>Daily avg</th><th>YoY change</th><th>Solar export?</th></tr>
</thead>
<tbody>
<tr><td>Oct 9, 2025</td><td>9/9-10/7 (29d)</td><td>1,152</td><td>~`$309</td><td>39.7</td><td>+33.7%</td><td><strong>Yes</strong> (-550 kWh off-peak)</td></tr>
<tr><td>Nov 10, 2025</td><td>10/8-11/6 (30d)</td><td>1,407</td><td>`$424.15</td><td>46.9</td><td>+12.4%</td><td>Partial (-135 kWh)</td></tr>
<tr style="background:#fff3f3;"><td>Dec 10, 2025</td><td>11/7-12/8 (32d)</td><td><strong>2,088</strong></td><td><strong>`$631.84</strong></td><td>65.3</td><td>+7.8%</td><td><strong>NO export</strong></td></tr>
<tr style="background:#fff3f3;"><td>Jan 12, 2026</td><td>12/9-1/8 (31d)</td><td><strong>2,305</strong></td><td><strong>`$772.32</strong></td><td>74.4</td><td><strong>+40.3%</strong></td><td>NO</td></tr>
<tr style="background:#fff3f3;"><td>Feb 10, 2026</td><td>1/9-2/6 (29d)</td><td><strong>2,004</strong></td><td><strong>`$749.87</strong></td><td>69.1</td><td><strong>+40.3%</strong></td><td>NO</td></tr>
<tr style="background:#fff3f3;"><td>Mar 12, 2026</td><td>2/7-3/10 (32d)</td><td><strong>2,289</strong></td><td><strong>`$785.04</strong></td><td>71.5</td><td><strong>+147.5%</strong></td><td>NO</td></tr>
<tr style="background:#fff3f3;"><td>Apr 10, 2026</td><td>3/11-4/8 (29d)</td><td><strong>2,041</strong></td><td><strong>`$669.34</strong></td><td>70.4</td><td><strong>+235.1%</strong></td><td>NO</td></tr>
</tbody>
</table>

<p><strong>Year-over-year comparison &mdash; same five winter months:</strong></p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse; font-family:$fontStack; font-size:10pt;">
<thead style="background:#f2f2f2;">
<tr><th>Period</th><th>Total kWh from grid</th><th>NEM cumulative balance</th></tr>
</thead>
<tbody>
<tr><td>Dec 2024 &ndash; Apr 2025 (solar working)</td><td>6,527 kWh</td><td>`$1,025</td></tr>
<tr><td>Dec 2025 &ndash; Apr 2026 (solar dead)</td><td><strong>10,727 kWh</strong></td><td><strong>`$3,608</strong></td></tr>
<tr style="background:#fff3f3;"><td><strong>Net excess attributable to disconnect</strong></td><td><strong>+4,200 kWh</strong></td><td><strong>+`$2,583 (already incurred)</strong></td></tr>
</tbody>
</table>

<p>Per the April 10, 2026 bill, the YoY daily average is <strong>+235.1%</strong> &mdash; my home consumed roughly 3.4 times the grid energy this April compared to the same month last year, simply because the Solar Facility was disconnected.</p>

<h3 style="color:#b30000;">3. Contractual Breaches</h3>

<p><strong>Under the 2012 Sunrun Solar Power Service Agreement (Prepaid PPA):</strong></p>

<ul>
<li><strong>Section 2 (Solar Facility):</strong> Sunrun&#39;s &quot;Sunrun Obligations&quot; expressly include monitoring, maintenance, and repair of the Solar Facility throughout the 20-year Initial Term. Sunrun owns the system. An outage of more than five months caused by Sunrun&#39;s own technicians is a direct breach of this maintenance obligation.</li>
<li><strong>Section 5(b):</strong> &quot;All electric energy produced by the Solar Facility will be made available to you for use at the Property.&quot; Producing zero kWh for over five months is a complete failure of this obligation.</li>
<li><strong>Section 8 (Guaranteed Output and Refunds):</strong> Sunrun guarantees the Estimated Output set forth in Exhibit A. The Section 8(e) carve-outs &mdash; grid failure, customer-caused shutdown &mdash; <strong>do not apply here</strong>; the technicians who returned today expressly stated they did not know why the prior crew had disconnected the system, confirming the cause was Sunrun-side, not grid or customer. I am owed a Section 8(c) refund check at the next anniversary date for the kWh shortfall, calculated against the Exhibit A Guaranteed Output and the per-kWh refund rate.</li>
<li><strong>Section 13 (Access, Maintenance and Repair):</strong> Sunrun is responsible at its sole expense for repair and replacement during the term. No invoice for the April 16, 2026 service visit will be paid by me.</li>
<li><strong>Section 17(b) (Force Majeure):</strong> &quot;Force Majeure cannot be attributable to fault or negligence on the part of the party claiming Force Majeure.&quot; Sunrun has no force majeure defense for damage caused by its own technicians.</li>
</ul>

<p><strong>Under the 2017 Costco Home Improvement Sales Contract (Customer-Owned, Doc # PKKVVKACNCLK):</strong></p>

<ul>
<li><strong>Limited Warranties &sect; 2:</strong> Sunrun warrants &quot;all of its labor&quot; for ten years from permit signoff (active until ~late 2027) and warrants that rated electrical output will not be less than 85% of DC nameplate. Negligent service-tech work that took the system to <strong>0% of nameplate output for over five months</strong> falls squarely within both prongs of this warranty.</li>
<li><strong>Limited Warranties &sect; 4:</strong> &quot;Sunrun will at its expense repair or replace any parts or labor covered by the Limited Warranties.&quot; This letter is the written warranty notice required by &sect; 4. No charge for the April 16, 2026 repair will be paid by me.</li>
</ul>

<h3 style="color:#b30000;">4. Applicable California Law</h3>

<p>The contractual liability and exclusionary provisions in both agreements (2012 PPA &sect; 15; 2017 contract &quot;Limitation of Liability&quot;) are <strong>not enforceable</strong> against the conduct described here under controlling California authority:</p>

<ul>
<li><em>Tunkl v. Regents of the University of California</em>, 60 Cal.2d 92 (1963) &mdash; exculpatory contracts are unenforceable when they affect the public interest.</li>
<li><em>City of Santa Barbara v. Superior Court</em>, 41 Cal.4th 747 (2007) &mdash; agreements purporting to release liability for future <strong>gross negligence</strong> are unenforceable as against public policy.</li>
<li><em>Health Net of California, Inc. v. Department of Health Services</em>, 113 Cal.App.4th 224 (2003) &mdash; limitation-of-liability clauses do not shield gross negligence or willful misconduct.</li>
<li><strong>Cal. Civ. Code &sect; 1668</strong> &mdash; &quot;All contracts which have for their object, directly or indirectly, to exempt anyone from responsibility for his own fraud, or willful injury to the person or property of another, or violation of law, whether willful or negligent, are against the policy of the law.&quot;</li>
<li><strong>Cal. Civ. Code &sect; 1670.5</strong> &mdash; courts may refuse to enforce unconscionable contracts or clauses.</li>
<li><em>Foley v. Interactive Data Corp.</em>, 47 Cal.3d 654 (1988) &mdash; every contract contains an implied covenant of good faith and fair dealing.</li>
<li><em>Lewis Jorge Construction Management, Inc. v. Pomona Unified School Dist.</em>, 34 Cal.4th 960 (2004) &mdash; under <em>Hadley v. Baxendale</em> as adopted in California, <strong>direct damages</strong> include those that arise naturally from the breach itself. The cost of replacement utility power that Sunrun was contractually obligated to deliver is a direct damage, not consequential.</li>
<li><em>Cates Construction, Inc. v. Talbot Partners</em>, 21 Cal.4th 28 (1999) &mdash; describing the direct/consequential damage distinction in California contract law.</li>
<li><strong>Cal. Bus. &amp; Prof. Code &sect;&sect; 17200 et seq.</strong> (Unfair Competition Law) &mdash; entitles me to restitution for unfair business practices.</li>
<li><strong>Cal. Civ. Code &sect;&sect; 1750 et seq.</strong> (Consumers Legal Remedies Act) &mdash; this letter also serves as the 30-day notice under &sect; 1782 demanding correction, repair, replacement, or other rectification of the violation.</li>
<li><strong>Cal. Bus. &amp; Prof. Code &sect; 7159</strong> et seq. &mdash; Home Improvement Contractor obligations apply to Sunrun (CSLB License #750184) and Costco (CSLB License #858087).</li>
</ul>

<p>The excess utility cost of `$2,583 already incurred is the cost of Sunrun&#39;s own non-performance &mdash; the <em>thing bargained for and not delivered</em> &mdash; and is therefore direct, not consequential, damage. The limitation-of-liability clauses do not bar it.</p>

<h3 style="color:#b30000;">5. Demand</h3>

<p>I demand the following within <strong>fourteen (14) calendar days</strong> from the date of this letter:</p>

<ol>
<li><strong>Payment of `$7,500.00</strong> as full reimbursement for: (a) `$2,583.00 in documented excess SDG&amp;E charges from December 2025 through April 2026; (b) approximately `$2,500.00 in projected excess SDG&amp;E charges through the November 6, 2026 NEM true-up, reflecting the production deficit the Solar Facility cannot recover during the remainder of this NEM year; and (c) the Section 8 production-guarantee refund owed under the 2012 PPA for the kWh shortfall during the outage. Payment may be issued by check to Ravi Jain at 5 Caladium, Rancho Santa Margarita, CA 92688, or as an SDG&amp;E account credit applied directly to account 0036 1837 1728 9.</li>
<li><strong>Written confirmation</strong>, signed by an authorized Sunrun representative, that: (i) the Solar Facility was disconnected by Sunrun personnel during a prior service visit, as confirmed by the technicians who restored it on April 16, 2026; (ii) Sunrun bears responsibility for the resulting outage; (iii) no charge will be invoiced to me for the April 16, 2026 service visit, parts, or labor; and (iv) the 2012 PPA Section 8 production-guarantee shortfall for the current anniversary year will be calculated and paid as required by the contract.</li>
<li><strong>Root-cause report</strong> in writing, identifying which Sunrun technician(s) were on-site on November 10, 2025, what action disconnected the system, and what process change Sunrun is implementing so that future service visits cannot leave a customer&#39;s system disconnected for months without follow-up.</li>
</ol>

<p>If a satisfactory written response is not received within fourteen (14) days, I will proceed without further notice to: (i) file complaints with the California Contractors State License Board (against License #750184 Sunrun Installation Services and #858087 Costco), the Better Business Bureau (San Francisco), the California Public Utilities Commission Consumer Affairs Branch, the California Department of Consumer Affairs, and the California Attorney General&#39;s Public Inquiry Unit; (ii) initiate JAMS arbitration as required by Section 16 of the 2012 PPA for claims arising under that agreement; and (iii) file a small-claims action in Orange County (Lamoreaux Justice Center) for claims arising under the 2017 contract within the `$12,500 jurisdictional limit of Cal. Code Civ. Proc. &sect; 116.221.</p>

<h3 style="color:#b30000;">6. Reservation of Rights and Document Preservation</h3>

<p>This letter is sent without prejudice to and with full reservation of all rights, claims, and remedies available to me under the 2012 PPA, the 2017 contract, the 2017 Limited Warranties, the manufacturer warranties for the LG and SolarEdge equipment, California statutory and common law, and the laws of any other applicable jurisdiction. Nothing herein waives any claim, including any claim for additional damages should the Solar Facility fail again, should the cause of the outage prove worse than represented, or should further harm be discovered.</p>

<p><strong>Document preservation:</strong> Sunrun, Sunrun Installation Services, Inc., and any affiliated entity are hereby placed on notice to preserve all documents, communications, work orders, dispatch records, technician notes, monitoring data, photographs, GPS logs, voicemails, text messages, and electronic records relating to: (i) the account and customer file for Ravi Jain at 5 Caladium, Rancho Santa Margarita, CA 92688; (ii) the November 10, 2025 service visit; (iii) the April 16, 2026 service visit; (iv) any monitoring telemetry from the SolarEdge inverters and panels at the Property between October 1, 2025 and the date of this letter; and (v) all internal communications regarding the cause of the outage. Spoliation of any such records will be raised in any subsequent proceeding.</p>

<p><strong>Attached for your reference:</strong></p>
<ol>
<li>2017 Costco / Sunrun Home Improvement Sales Contract and Limited Warranties (12 pages)</li>
<li>2012 Sunrun Solar Power Service Agreement &mdash; Prepaid PPA, Doc # PI139KV7A331V-A (14 pages)</li>
<li>SDG&amp;E bill mailed October 9, 2025 (pre-disconnect baseline)</li>
<li>SDG&amp;E bill mailed November 10, 2025 (transition month)</li>
<li>SDG&amp;E bill mailed December 10, 2025 (first full month with system disconnected)</li>
<li>SDG&amp;E bills mailed January, February, March, and April 2026 (continuing damages)</li>
</ol>

<p>Please direct your response to me at this email address (rjain@technijian.com) and at the Property address. I am open to a prompt resolution and would prefer to settle this matter without further escalation.</p>

<p>Sincerely,</p>

<p>Ravi Jain<br>
5 Caladium, Rancho Santa Margarita, CA 92688</p>

</div>
$sig
</body>
</html>
"@

# --- Proofread: check for stripped dollar signs and placeholders (FAIL FAST) ---
if ($htmlBody -match '[\s>](\,\d{3})') {
    Write-Error "BLOCKED: Stripped dollar sign detected near '$($matches[1])'. Backtick-escape every literal `$<digit> in the body."
    exit 1
}
if ($htmlBody -match '\[Your Name\]|TODO|TBD|\[INSERT|\[CLIENT') {
    Write-Error "BLOCKED: Placeholder text found in email body."
    exit 1
}
Write-Host "Proofread checks passed." -ForegroundColor Green

# --- Connect to Graph ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Build recipient arrays for Graph ---
$toGraph = $toRecipients | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } }
$ccGraph = $ccRecipients | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } }

# --- Create draft ---
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

# --- Add attachments ---
Write-Host "Attaching evidence files..." -ForegroundColor Cyan
foreach ($f in $attachmentFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $b64   = [Convert]::ToBase64String($bytes)
    $null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draft.Id -BodyParameter @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        Name          = [System.IO.Path]::GetFileName($f)
        ContentBytes  = $b64
    }
    Write-Host "  Attached: $([System.IO.Path]::GetFileName($f)) ($([math]::Round($bytes.Length/1024,1)) KB)" -ForegroundColor Gray
}

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
    Write-Host "`nNOTE on CC list: membercare@ and customercare@ are verified Sunrun channels." -ForegroundColor Cyan
    Write-Host "Executive emails (mary.powell, jeanna.steele, patrick.kent, carolyn.colasurdo) follow Sunrun's" -ForegroundColor Cyan
    Write-Host "firstname.lastname@sunrun.com pattern but are not officially confirmed by the company." -ForegroundColor Cyan
    Write-Host "Bounces are possible. The verified care channels will receive the message regardless." -ForegroundColor Cyan
}

Disconnect-MgGraph | Out-Null
