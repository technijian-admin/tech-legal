# Creates an Outlook DRAFT (does NOT send) to Ed Susolik + Frank Dunn
# RE: FW: Complaint received for Ravi Jain
# Full client analysis + copy-paste response for Frank to send to Gabby

$ErrorActionPreference = "Stop"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$sig = Get-Content "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw

$htmlBody = @'
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:#000000; max-width:780px;">

<p>Ed and Frank,</p>

<p>Thank you for forwarding Sunrun's response from Gabby Thompson (Senior Expert, Customer Solutions). I have reviewed it carefully against both contracts and our SDG&E billing records. <strong>I do not believe $2,000 is an acceptable resolution</strong>, and I would like to walk you through the specific problems with Sunrun's analysis before you respond.</p>

<p>For Frank's convenience, I have included a <strong>copy-paste ready draft response to Gabby</strong> at the bottom of this email. Please feel free to edit and send it directly on my behalf if the analysis below supports it.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<!-- ======================================================= -->
<h3 style="color:#1a1a2e; font-size:13pt; margin-bottom:4px;">BACKGROUND — TWO SYSTEMS AT ISSUE</h3>
<table style="border-collapse:collapse; width:100%; font-size:11pt;" cellpadding="8">
  <thead>
    <tr style="background-color:#006DB6; color:#ffffff;">
      <th style="text-align:left; padding:8px;">System</th>
      <th style="text-align:left; padding:8px;">Contract</th>
      <th style="text-align:left; padding:8px;">Outage Period</th>
      <th style="text-align:left; padding:8px;">Sunrun's Offer</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background-color:#f8f9fa;">
      <td style="padding:8px;"><strong>#1622893336</strong></td>
      <td style="padding:8px;">2012 Prepaid PPA (Sunrun-owned system; Ravi prepaid ~$20,000 for 20-year term)</td>
      <td style="padding:8px;">November 7, 2025 &ndash; April 16, 2026 (~160 days)</td>
      <td style="padding:8px; color:#c0392b;"><strong>$0</strong> (claims 105.4% lifetime performance)</td>
    </tr>
    <tr>
      <td style="padding:8px;"><strong>#1772672455</strong></td>
      <td style="padding:8px;">2017 Costco Home Improvement Contract (customer-owned; Ravi paid $22,474.07)</td>
      <td style="padding:8px;">November 7, 2025 &ndash; April 22, 2026 (~165 days; uplink replaced Apr 22 &mdash; restoration unconfirmed; May 4 site visit pending)</td>
      <td style="padding:8px; color:#c0392b;"><strong>$2,000</strong> (based on 6,149 kWh &times; $0.11/kWh = $676.39, rounded up)</td>
    </tr>
  </tbody>
</table>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<!-- ======================================================= -->
<h3 style="color:#1a1a2e; font-size:13pt; margin-bottom:4px;">ISSUE 1 &mdash; 2012 PPA: THE 105.4% LIFETIME AVERAGE DOES NOT EXTINGUISH SECTION 8</h3>

<p>Gabby's response states: <em>"Our records indicate that system performance is currently at 105.4% of the contract amount. As the production exceeds 100%, no performance guarantee credit is due."</em></p>

<p><strong>This is legally and contractually wrong.</strong> The 2012 Prepaid PPA Section 8 (&ldquo;Guaranteed Output and Refunds&rdquo;) is a <em>per-period</em> refund mechanism. It is not a lifetime averaging formula. The fact that the 2012 system may have over-performed in 2013&ndash;2024 does not permit Sunrun to bank those excess kWh as an offset against a 2025&ndash;2026 outage period. Each contract year stands on its own for Section 8 purposes.</p>

<p><strong>Key point:</strong> Sunrun's own Service Pipeline Specialist (Katherine Wilson) calculated this correctly just eight days ago &mdash; her April 22, 2026 email used the formula: <em>$20,000 prepayment &divide; 240 months &times; 5 months = $415</em>. That calculation treats the outage as a per-period credit obligation, which is the correct reading of Section 8. Gabby's April 30 response abandons Katherine's own formula with no explanation and no contract citation.</p>

<p><strong>What we need from Frank:</strong> Please request (a) the Section 8 calculation worksheet and supporting production-monitoring data for the 2025&ndash;2026 contract year, and (b) the contractual provision that authorizes lifetime-averaging in lieu of per-period refunds. If Sunrun cannot produce that provision, Katherine&rsquo;s $415 figure (or a corrected per-year calculation) should govern &mdash; and their offer on the 2012 system should not be zero.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<!-- ======================================================= -->
<h3 style="color:#1a1a2e; font-size:13pt; margin-bottom:4px;">ISSUE 2 &mdash; 2017 COSTCO SYSTEM: $0.11/kWh HAS NO BASIS IN THE CONTRACT OR IN SDGE BILLING REALITY</h3>

<p>Gabby's offer uses $0.11/kWh as the compensation rate for 6,149 lost kWh. This figure has no contractual basis and dramatically understates actual harm.</p>

<p><strong>What the Costco Work Order actually says:</strong> The Work Order (incorporated into the 2017 Costco Home Improvement Sales Contract) states the system was sized for a <strong>95% energy offset</strong> against an annual usage of <strong>7,864 kWh</strong>. The value the system was sold to deliver was measured in retail electricity cost savings &mdash; not at a wholesale or avoided-cost floor rate.</p>

<p><strong>Actual SDG&amp;E rates from my billing records (EVTOU5-Residential rate schedule, same period):</strong></p>

<table style="border-collapse:collapse; width:80%; font-size:11pt;" cellpadding="6">
  <thead>
    <tr style="background-color:#006DB6; color:#ffffff;">
      <th style="text-align:left; padding:6px;">Season</th>
      <th style="text-align:left; padding:6px;">TOU Period</th>
      <th style="text-align:right; padding:6px;">Delivery Rate</th>
      <th style="text-align:right; padding:6px;">Generation Rate</th>
      <th style="text-align:right; padding:6px;">Effective Total</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background-color:#f8f9fa;">
      <td style="padding:6px;">Summer</td>
      <td style="padding:6px;">On-Peak</td>
      <td style="text-align:right; padding:6px;">$0.29426</td>
      <td style="text-align:right; padding:6px;">$0.40592</td>
      <td style="text-align:right; padding:6px;"><strong>~$0.70/kWh</strong></td>
    </tr>
    <tr>
      <td style="padding:6px;">Winter</td>
      <td style="padding:6px;">On-Peak</td>
      <td style="text-align:right; padding:6px;">$0.29426</td>
      <td style="text-align:right; padding:6px;">$0.17258</td>
      <td style="text-align:right; padding:6px;"><strong>~$0.47/kWh</strong></td>
    </tr>
  </tbody>
</table>

<p style="margin-top:10px;">The outage period ran November 2025 through April 2026 &mdash; predominantly winter/spring billing months. Using a blended conservative rate of <strong>$0.45/kWh</strong> (significantly below summer peak):</p>

<table style="border-collapse:collapse; font-size:11pt;" cellpadding="6">
  <tr style="background-color:#f8f9fa;">
    <td style="padding:6px;">Sunrun&rsquo;s calculation:</td>
    <td style="padding:6px;">6,149 kWh &times; $0.11 =</td>
    <td style="padding:6px; color:#c0392b;"><strong>$676.39</strong></td>
  </tr>
  <tr>
    <td style="padding:6px;">Conservative retail rate ($0.45):</td>
    <td style="padding:6px;">6,149 kWh &times; $0.45 =</td>
    <td style="padding:6px; color:#27ae60;"><strong>$2,767.05</strong></td>
  </tr>
  <tr>
    <td style="padding:6px;">Actual blended seasonal rate (~$0.55):</td>
    <td style="padding:6px;">6,149 kWh &times; $0.55 =</td>
    <td style="padding:6px; color:#27ae60;"><strong>$3,381.95</strong></td>
  </tr>
</table>

<p style="margin-top:10px;">Note that the 2017 True-Up bill (issued November 10, 2025) shows a <strong>$2,712.00 balance due</strong> with a cumulative NEM deficit of $2,098.55 &mdash; this is direct, documented evidence of what the lost solar production cost on the SDG&amp;E account in real dollars.</p>

<p><strong>What we need from Frank:</strong> Please ask Gabby to identify the provision in the 2017 Costco contract that authorizes $0.11/kWh as the compensation rate for lost production. I do not believe any such provision exists. If she cannot cite one, the applicable rate should be the actual retail rate under my SDG&amp;E tariff (EVTOU5), which averages well above $0.40/kWh for the outage period.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<!-- ======================================================= -->
<h3 style="color:#1a1a2e; font-size:13pt; margin-bottom:4px;">ISSUE 3 &mdash; 2017 COSTCO: THE LIMITED WARRANTY IS ACTIVE AND WAS BREACHED</h3>

<p>Gabby states: <em>"This system does not have any production guarantees."</em> This conflates two distinct concepts and is misleading.</p>

<p>The 2017 Costco Home Improvement Sales Contract includes a <strong>10-year Limited Warranty</strong> running from the date the permit was signed by the building inspector. PTO (Permission to Operate) was granted <strong>March 14, 2018</strong>, placing the Limited Warranty expiration at <strong>March 14, 2028 &mdash; the warranty is still fully in force</strong>.</p>

<p><strong>What the Limited Warranty (Section 2) guarantees:</strong></p>
<blockquote style="border-left:4px solid #006DB6; margin:10px 0; padding:8px 16px; background-color:#f0f7ff; font-style:italic;">
&ldquo;Sunrun warrants (i) all of its labor, and (ii) the rated electrical output of the System will not be less than 85% of the DC nameplate rating (measured in kW) measured upon completion of the installation as a <strong>result of defects in parts Sunrun supplied or labor Sunrun performed</strong> to install the System.&rdquo;
</blockquote>

<p>A complete system failure lasting 165 days &mdash; caused by a faulty uplink circuit that Sunrun&rsquo;s own technician identified and replaced on April 22, 2026 &mdash; is precisely the type of <strong>defect in Sunrun-supplied parts</strong> that the Limited Warranty covers. Sunrun acknowledged the defect by replacing the failed component; the warranty obligation follows directly.</p>

<p>The warranty also requires repair &ldquo;within a reasonable time&rdquo; (Section 4). <strong>165 days is not a reasonable time.</strong> By analogy, California Civil Code &sect; 1793.2(b) establishes a 30-day benchmark for consumer-good warranty repairs; five months is more than five times that benchmark.</p>

<p>Gabby&rsquo;s claim that there are &ldquo;no production guarantees&rdquo; may be technically correct in the narrow sense that there is no minimum annual kWh output guarantee &mdash; but it does not address the Limited Warranty obligation, which is a separate and distinct remedy that is squarely applicable here.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<!-- ======================================================= -->
<h3 style="color:#1a1a2e; font-size:13pt; margin-bottom:4px;">ISSUE 4 &mdash; NEITHER SYSTEM&rsquo;S OUTAGE DATES ARE ACKNOWLEDGED IN WRITING</h3>

<p>Gabby&rsquo;s response acknowledges kWh lost &ldquo;over the life of the system&rdquo; but <strong>never states the specific outage dates</strong>: November 7, 2025 through April 16, 2026 (System 1), and November 7, 2025 through at least April 22, 2026 (System 2, with May 4 site visit still pending).</p>

<p>Getting Sunrun to confirm the outage dates in writing is important for the record. Our April 22 on-site technician verbally acknowledged the November&ndash;April outage as a genuine production failure; Gabby&rsquo;s written response should be asked to confirm the same.</p>

<p>Also notable: the 2017 Costco system (System 2) is <strong>not yet confirmed restored</strong>. The April 22 repair (uplink circuit replacement) was described by the technician as restoring the monitoring uplink only. A Sunrun-scheduled site visit is still set for <strong>Monday, May 4, 2026 (12:00 PM &ndash; 5:00 PM)</strong>. Any settlement discussion should account for the fact that the system may not be fully operational, and settlement conditioned on confirmed written restoration.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<!-- ======================================================= -->
<h3 style="color:#1a1a2e; font-size:13pt; margin-bottom:4px;">TIMING &mdash; KEY DEADLINES</h3>

<table style="border-collapse:collapse; width:80%; font-size:11pt;" cellpadding="6">
  <thead>
    <tr style="background-color:#006DB6; color:#ffffff;">
      <th style="text-align:left; padding:6px;">Date</th>
      <th style="text-align:left; padding:6px;">Event</th>
    </tr>
  </thead>
  <tbody>
    <tr style="background-color:#fff3cd;">
      <td style="padding:6px;"><strong>May 1, 2026 (tomorrow)</strong></td>
      <td style="padding:6px;">14-day formal demand response deadline expires (demand sent April 17)</td>
    </tr>
    <tr style="background-color:#f8f9fa;">
      <td style="padding:6px;">May 4, 2026</td>
      <td style="padding:6px;">Sunrun-scheduled site visit, System 2 (2017 Costco)</td>
    </tr>
    <tr style="background-color:#f8d7da;">
      <td style="padding:6px;"><strong>May 16, 2026</strong></td>
      <td style="padding:6px;">CLRA &sect; 1782 30-day notice ripens &mdash; lawsuit cause of action fully available; mandatory attorney&rsquo;s fees attach on prevail (&sect; 1780(e))</td>
    </tr>
  </tbody>
</table>

<p style="margin-top:10px;">Sunrun moved from $500 to $2,000 in a single attorney letter. That is a strong signal they understand their exposure. My standing demand of <strong>$7,500</strong> includes (a) a check or NEM credit, (b) confirmed restoration of System 2 within 7 days of settlement, (c) Section 8 refund for the outage period on System 1, and (d) written root-cause summary. All attorney&rsquo;s fees and costs incurred from this point forward will be added to the settlement figure.</p>

<hr style="border:1px solid #e0e0e0; margin:20px 0;" />

<!-- ======================================================= -->
<h3 style="color:#1a1a2e; font-size:13pt; margin-bottom:4px; background-color:#f0f7ff; padding:10px; border-left:4px solid #006DB6;">DRAFT RESPONSE FOR FRANK &mdash; COPY-PASTE READY TO SEND TO GABBY</h3>
<p style="font-size:10pt; color:#888;">[Frank: please review, edit as needed, and send from your firm email. The bracketed items may need verification or adjustment based on your review of the full contract text.]</p>

<div style="background-color:#f8f9fa; border:1px solid #dee2e6; border-radius:4px; padding:16px; margin-top:8px; font-size:11pt;">

<p><strong>To:</strong> Gabby Thompson &lt;gabby.thompson@sunrun.com&gt;<br>
<strong>Re:</strong> Complaint for Ravi Jain &mdash; Case #18181148<br>
<strong>From:</strong> Franklin T. Dunn, Callahan &amp; Blaine, PC</p>

<p>Dear Gabby,</p>

<p>Thank you for your prompt response dated April 30, 2026. After reviewing it with our client, we are unable to recommend acceptance of the $2,000 offer. We have the following specific concerns:</p>

<p><strong>1. System #1622893336 (2012 Prepaid PPA) &mdash; Section 8 Refund Not Addressed.</strong><br>
The PPA&rsquo;s performance-guarantee refund mechanism (Section 8) operates on a per-contract-period basis, not as a lifetime rolling average. The 105.4% lifetime figure does not extinguish our client&rsquo;s right to a refund for the specific outage period of November 7, 2025 through April 16, 2026. Please provide (a) the Section 8 calculation for the 2025&ndash;2026 contract year specifically, (b) the production-monitoring data underlying the 105.4% figure, and (c) the contractual provision authorizing lifetime averaging in lieu of per-period refund calculations. We note that your colleague Katherine Wilson calculated this correctly on April 22, 2026, using the formula: $20,000 &divide; 240 months &times; 5 months = $415; we would ask that you reconcile Gabby&rsquo;s response with that prior calculation.</p>

<p><strong>2. System #1772672455 (2017 Costco) &mdash; Compensation Rate.</strong><br>
The $0.11/kWh rate used in your response has no basis in the 2017 Costco Home Improvement Sales Contract. The Work Order incorporated into that contract states the system was designed to provide a 95% energy offset against an annual usage of 7,864 kWh &mdash; a value measured in retail SDG&amp;E electricity savings. Our client&rsquo;s actual SDG&amp;E rate schedule (EVTOU5-Residential) reflects effective rates of approximately $0.47&ndash;$0.70/kWh during the outage period depending on time-of-use tier. At a conservative blended rate of $0.45/kWh, the 6,149 kWh you acknowledge equals <strong>$2,767.05</strong> &mdash; more than your $2,000 total offer before accounting for the 2012 PPA or any other claim. Please identify the contract provision that authorizes $0.11/kWh; absent such a provision, the applicable rate is the actual retail rate our client was charged by SDG&amp;E.</p>

<p><strong>3. System #1772672455 (2017 Costco) &mdash; Active Limited Warranty.</strong><br>
The 2017 Costco contract includes a 10-year Limited Warranty running from the date the permit was signed by the building inspector (PTO: March 14, 2018 &mdash; expiration: March 14, 2028). Section 2 of the Limited Warranty warrants the system&rsquo;s electrical output against &ldquo;defects in parts Sunrun supplied.&rdquo; The 165-day system failure &mdash; which your own technician attributed to a faulty uplink circuit he replaced on April 22, 2026 &mdash; is a warranty-covered defect. The assertion that there are &ldquo;no production guarantees&rdquo; does not address the Limited Warranty obligation, which is a separate remedy. Furthermore, the Limited Warranty requires repair within a &ldquo;reasonable time&rdquo; (Section 4); 165 days is not reasonable under any standard.</p>

<p><strong>4. Outage Dates.</strong><br>
Your response does not identify the outage dates for either system. Please confirm in writing that (a) System #1622893336 was non-operational from November 7, 2025 through April 16, 2026, and (b) System #1772672455 was non-operational from November 7, 2025 through April 22, 2026. Our client has SDG&amp;E interval data and app screenshots documenting zero production throughout this period.</p>

<p><strong>5. System #1772672455 Restoration Status.</strong><br>
The April 22, 2026 technician visit replaced the uplink circuit but did not confirm full system restoration. A Sunrun-scheduled site visit is set for May 4, 2026. Any resolution must be conditioned on written confirmation of complete restoration, including 48 hours of production data showing normal output.</p>

<p>Our client&rsquo;s demand of <strong>$7,500.00</strong> remains standing. This figure includes direct damages at actual retail rates for both systems&rsquo; outage periods, Section 8 refund credit for the 2012 PPA, confirmed restoration of the 2017 system, and a written root-cause summary. All attorney fees and costs incurred from this point forward are being tracked and will be added to the settlement figure. As a reminder, our client&rsquo;s CLRA &sect; 1782 notice ripens on May 16, 2026, at which point a civil action becomes available and mandatory attorney&rsquo;s fees attach to any prevailing party.</p>

<p>We look forward to a revised offer that addresses these points. Please respond by May 9, 2026.</p>

<p>Respectfully,</p>
<p>Franklin T. Dunn, Esq.<br>
Callahan &amp; Blaine, PC<br>
19900 MacArthur Blvd., Suite 1200, Irvine, CA 92612<br>
714.241.4444 | fdunn@callahan-law.com</p>
</div>

<br>
</div>
'@ + $sig

$draftParams = @{
    Subject    = "RE: FW: Complaint received for Ravi Jain"
    Body       = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = "ES@callahan-law.com"; Name = "Edward Susolik" } }
    )
    CcRecipients = @(
        @{ EmailAddress = @{ Address = "fdunn@callahan-law.com"; Name = "Franklin T. Dunn" } }
    )
    Importance = "High"
}

$draft = New-MgUserMessage -UserId "RJain@technijian.com" -BodyParameter $draftParams
Write-Host "Draft created successfully." -ForegroundColor Green
Write-Host "Draft ID: $($draft.Id)" -ForegroundColor Cyan
Write-Host "Subject:  $($draft.Subject)" -ForegroundColor Cyan
Write-Host "To:       ES@callahan-law.com (Edward Susolik)" -ForegroundColor Cyan
Write-Host "CC:       fdunn@callahan-law.com (Franklin T. Dunn)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Open Outlook Drafts folder to review before sending." -ForegroundColor Yellow
