# Reply to Katherine Wilson re: her 4/17 refusal of the FORMAL DEMAND
# DEFAULT: Tier 1 reply only (Katherine), draft only
#
# Context: Katherine refused the $7,500 demand on 4/17/2026 with four factually
# incorrect statements (no Nov visit, third-party install, monitoring lag, no
# performance guarantee). This reply corrects the record using Sunrun's own
# Case #18181148 record, the production photos, and her own prior $450 offer,
# then restates the position. Tier 2 escalation held in reserve.
#
# Usage:
#   .\send-sunrun-reply-katherine.ps1         # draft only (DEFAULT)
#   .\send-sunrun-reply-katherine.ps1 -Send   # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

# --- Recipients ---
$toRecipients = @(
    @{ Address = "katherine.wilson@sunrun.com"; Name = "Katherine Wilson" }
)
# CC: warranty notice channel only. Holding AGC / executives in reserve for Round 3
# (after the Friday April 24 deadline). The letter body recommends Katherine refer
# the matter internally to her manager / appropriate legal / executive-resolution
# channel - that gives Sunrun the chance to escalate through proper internal channels
# before we escalate externally on Round 3.
$ccRecipients = @(
    @{ Address = "membercare@sunrun.com"; Name = "Sunrun Member Care (Warranty Notice)" }
)

$senderUpn = "RJain@technijian.com"
$subject   = "Re: FORMAL DEMAND - Solar System Disconnected 11/7/25-4/16/26 - 5 Caladium - Acct 0036 1837 1728 9 - Response Due Within 14 Days"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# --- Attachments: re-attach the production photos ---
$evidenceDir = "c:\VSCode\tech-legal\tech-legal\docs\personal\sunrun\evidence"
$attachmentFiles = @(
    "$evidenceDir\20260417-174746-25426.jpg",                          # 4/17 2012 PPA system - WORKING (30.5 kWh/day)
    "$evidenceDir\20260417-174746-25428.jpg",                          # 4/17 2017 Costco system - DEAD (0 kWh, error loading)
    "$evidenceDir\04-18-26\Screenshot_20260418_133016_Sunrun.jpg",     # 4/18 weekly chart - one system, 23.3 kWh Thu-Fri only
    "$evidenceDir\04-18-26\Screenshot_20260418_133023_Sunrun.jpg",     # 4/18 weekly chart - other system, 69.2 kWh Thu-Fri only
    "$evidenceDir\04-18-26\Screenshot_20260418_133034_Sunrun.jpg",     # 4/18 overview - 2017 system: "Outlier detected", 0.0 kWh
    "$evidenceDir\04-18-26\Screenshot_20260418_133100_Sunrun.jpg"      # 4/18 overview - 2012 system: "System normal"
)
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

<p>Katherine,</p>

<p>I have carefully reviewed every Sunrun communication on this matter from November 2025 through the date of this email. The factual record is now substantially worse for Sunrun than my April 16 letter assumed. This reply consolidates that record, corrects the multiple material errors in your April 17 response, and resets the basis for resolution.</p>

<p>Before going further: <strong>given the scope of the factual record set out below, my recommendation is that you refer this email to your manager and to whichever Sunrun internal track handles concealment, CLRA, and executive-resolution matters (Office of the General Counsel, Executive Resolution Team, or equivalent).</strong> The matter has outgrown the standard Service Pipeline workflow. I am offering Sunrun the opportunity to resolve this through the proper internal channel before I escalate externally. If you would prefer that I direct future correspondence to a different individual at Sunrun, please tell me by reply and I will do so.</p>

<h3 style="color:#b30000;">1. Sunrun&#39;s own portal documents the November engagement</h3>

<p>You wrote: &quot;Our records indicate we never came out to your home in November, contradicting your statement.&quot;</p>

<p>Sunrun Service Case <strong>#18181148</strong> is currently visible in my Service Cases panel at <a href="https://my.sunrun.com/cases">https://my.sunrun.com/cases</a>. Please pull that case in your CRM. Its fields read, verbatim from the portal:</p>

<ul>
<li><strong>Subject:</strong> Metering</li>
<li><strong>Date opened:</strong> 11/10/2025</li>
<li><strong>Status:</strong> Service appointment has been scheduled</li>
<li><strong>Appointment Scheduled:</strong> Jan 27, 2026 between 12:00 PM - 5:00 PM PST</li>
</ul>

<p>Sunrun&#39;s own customer-facing system documents the November engagement. The portal record establishes the following internal timeline:</p>

<ul>
<li><strong>Nov 10, 2025:</strong> Sunrun opens Case #18181148, &quot;Metering&quot; issue identified.</li>
<li><strong>Jan 27, 2026:</strong> First scheduled service appointment &mdash; <strong>78 days</strong> after Sunrun opened the case.</li>
<li><strong>Apr 16, 2026:</strong> Service-tech repair attempt &mdash; <strong>158 days</strong> after Sunrun opened the case &mdash; and only a partial restoration (see Section 6 below).</li>
</ul>

<p>The 78-day gap between case opening and the first scheduled visit, on its face, breaches the &quot;commercially reasonable efforts&quot; obligation in Section 13(c) of the 2012 Prepaid PPA and the &quot;within a reasonable time&quot; obligation in Section 4 of the 2017 Limited Warranty. The 158-day total to a partial repair is unreasonable for a residential primary energy source by any measure.</p>

<h3 style="color:#b30000;">2. Sunrun&#39;s monitoring detected the issue on or before November 10, 2025, and Sunrun was silent for 67 days</h3>

<p>Sunrun&#39;s first written communication to me about this matter was sent on <strong>January 16, 2026</strong> &mdash; <strong>67 days after Sunrun opened Case #18181148</strong>. Its opening line, verbatim:</p>

<blockquote style="border-left:3px solid #999; padding-left:12px; color:#333;">
&quot;Hi Ravi, <strong>Our monitoring system has detected an issue with your solar system that requires maintenance.</strong> We&#39;d like to schedule your service visit at your convenience.&quot; &mdash; <em>Schedule Your Sunrun Service Appointment</em>, from noreply@ai.sunrun.com, January 16, 2026.
</blockquote>

<p>That email confirms two facts that materially change Sunrun&#39;s exposure here:</p>

<ul>
<li><strong>Sunrun&#39;s monitoring detected the failure</strong> &mdash; the duty to monitor and the actual fact of monitoring are both admitted by Sunrun in writing.</li>
<li><strong>Sunrun chose silence for 67 days</strong> after the case opened. There is no email, text, voicemail, or app notification to me from Sunrun between November 10, 2025 and January 15, 2026 about this issue. None.</li>
</ul>

<h3 style="color:#b30000;">3. Sunrun systematically used vague &quot;system issue&quot; language and never disclosed that the system was producing zero kilowatt-hours</h3>

<p>From January 16, 2026 forward, every Sunrun communication on this case used the same vague language. Not one of them disclosed that production was at zero. Verbatim excerpts from each:</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse; font-family:$fontStack; font-size:10pt;">
<thead style="background:#f2f2f2;">
<tr><th>Date</th><th>From</th><th>Sunrun&#39;s exact language</th></tr>
</thead>
<tbody>
<tr><td>Jan 16, 2026</td><td>noreply@ai.sunrun.com</td><td>&quot;detected an <strong>issue</strong> with your solar system that requires maintenance&quot;</td></tr>
<tr><td>Jan 18, 2026</td><td>noreply@ai.sunrun.com</td><td>&quot;address your <strong>system issue</strong>&quot;</td></tr>
<tr><td>Feb 5, 2026</td><td>noreply@ai.sunrun.com</td><td>&quot;We were unable to <strong>fully resolve your system issue</strong> during our recent visit&quot;</td></tr>
<tr><td>Feb 5, 2026</td><td>katherine.wilson@sunrun.com</td><td>&quot;remind you of your upcoming appointment&quot; &mdash; <strong>nothing about the underlying defect or its severity</strong></td></tr>
<tr><td>Feb 16, 2026</td><td>noreply@ai.sunrun.com</td><td>&quot;We may be able to <strong>remotely fix your system</strong>... follow the step-by-step <strong>power cycling instructions</strong>&quot;</td></tr>
<tr><td>Apr 10, 2026</td><td>noreply@ai.sunrun.com</td><td>&quot;you may be able to solve your issue sooner with a <strong>system reboot</strong>&quot;</td></tr>
</tbody>
</table>

<p>Compare what those messages told me to what Sunrun&#39;s monitoring actually showed (and what SDG&amp;E&#39;s interval-meter records confirm): <strong>zero exportable kilowatt-hours in every Time-of-Use bucket from November 7, 2025 forward.</strong> Sunrun knew. Sunrun told me to try a &quot;system reboot.&quot;</p>

<p>While that was happening, Sunrun also sent me <strong>marketing communications during the outage</strong>:</p>

<ul>
<li><strong>March 15, 2026</strong> &mdash; from theCEO@sunrun.com, subject &quot;A Message From Mary: Get Ready to Celebrate.&quot;</li>
<li><strong>March 21, 2026</strong> &mdash; from theCXO@sunrun.com, subject &quot;Ravi, It&#39;s Here! Your Sunrun Value Report is Ready to View&quot; &mdash; a &quot;Value Report&quot; sent in the middle of four months of zero production.</li>
</ul>

<p>The duty to disclose the actual nature and severity of the defect was on Sunrun. Sunrun is the party that operates the monitoring system, holds the contractual maintenance obligation under PPA Section 2, and has materially superior knowledge under California concealment doctrine. The choice to use the word &quot;issue&quot; instead of &quot;your system has produced zero kWh since November 7&quot; was a choice. The choice to send a &quot;Value Report&quot; while the system produced zero was a choice. Together they support claims for fraudulent concealment under Cal. Civ. Code &sect;&sect; 1572 and 1710, deceit by suppression, and unfair business practices under Cal. Bus. &amp; Prof. Code &sect; 17200.</p>

<h3 style="color:#b30000;">4. Three separate appointments were scheduled, not one &mdash; and there are two witnesses</h3>

<p>Katherine wrote on April 17: &quot;We visited your property <strong>once</strong> on January 27th.&quot; That is also incorrect. Sunrun&#39;s own appointment-confirmation emails document at least three scheduled visits plus the unscheduled emergency visit:</p>

<ol>
<li><strong>January 27, 2026 (12pm-5pm)</strong> &mdash; confirmed by noreply@ai.sunrun.com on January 18, 2026. Visit occurred. <strong>My partner, Callie Wells, was present at the Property and spoke with the technicians.</strong> The technicians told her only that &quot;they need to come back.&quot; They did not disclose that the system had been producing zero kWh for 78 days at that point. They did not disclose any &quot;third-party interconnection&quot; finding to her. They left without restoring the system.</li>
<li><strong>February 23, 2026 (11am-3pm)</strong> &mdash; confirmed by noreply@ai.sunrun.com on February 5 and reminded on February 9 and February 16. Please produce the visit record, work order, and technician notes for this scheduled appointment. If the appointment was canceled, please produce the cancellation record. If it occurred, please produce what was found and what was communicated to me. I have no record from Sunrun stating either that it occurred or that it was canceled.</li>
<li><strong>April 22, 2026 (11am-3pm)</strong> &mdash; confirmed by noreply@ai.sunrun.com on April 12, 2026. Please confirm in writing whether this appointment is still scheduled in light of the unscheduled April 16 visit. Given that the 2017 Costco system remains non-operational as of April 18 (see Section 6 below), I expect that this appointment WILL proceed and that the 2017 system will be fully restored as a result.</li>
<li><strong>April 16, 2026 (unscheduled)</strong> &mdash; emergency visit triggered after I logged into my mySunrun app on April 15, 2026, discovered for the first time that production had been at zero, and emailed Katherine on April 15, 2026 at 6:56 PM PT stating, verbatim: <em>&quot;I was not aware the panels were completely zero for the past 4 months so I don&#39;t know if they are working or just a communication error.&quot;</em></li>
</ol>

<p><strong>Witnesses for any subsequent proceeding:</strong></p>

<ul>
<li><strong>Ravi Jain</strong> (homeowner) &mdash; can testify to all communications received and the absence of any disclosure that production was at zero.</li>
<li><strong>Callie Wells</strong> &mdash; was present at the Property during the January 27 visit, spoke directly with the Sunrun technicians on site, and was told only that they would need to come back. She was NOT told the system was producing zero kWh, and she was NOT told the technicians had identified any third-party installation.</li>
</ul>

<h3 style="color:#b30000;">5. There is no third-party solar system on the Property</h3>

<p>You wrote: &quot;We visited your property once on January 27th and confirmed that a third solar system had been added by a third party. The interconnection of this third-party system is the reason our system was turned off.&quot;</p>

<p>This is factually incorrect. The Property has <strong>two</strong> solar systems, <strong>both installed by Sunrun</strong>:</p>

<ol>
<li><strong>2012 Sunrun Solar Power Service Agreement (Prepaid PPA),</strong> Doc # PI139KV7A331V-A, executed 9/12/2012. Sunrun-owned, Sunrun-maintained, installed by Sunrun.</li>
<li><strong>2017 Costco Home Improvement Sales Contract (Customer-Owned),</strong> executed 10/12/2017, PTO 3/14/2018. Page 1 of that contract states: &quot;Dealer Company Name: Sunrun Installation Services Inc.,&quot; with Sunrun&#39;s dealer representative Roland Claudio signing on Sunrun&#39;s behalf. CSLB License #750184.</li>
</ol>

<p>I have never modified, expanded, or had any third party touch either system. <strong>Independent utility records confirm this.</strong> Every SDG&amp;E bill (already attached to my April 16 letter) lists exactly <strong>one</strong> System Size on the Net Energy Metering Summary &mdash; <strong>11.16 kW</strong> &mdash; and exactly <strong>one</strong> PTO date &mdash; <strong>March 14, 2018</strong>. If a third solar system existed on this Property, SDG&amp;E would carry a separate PTO record for it (every interconnected system requires its own PTO). It does not. There is one combined NEM account corresponding to the two Sunrun systems and nothing else.</p>

<p>For the avoidance of doubt, since 2018 there has been:</p>

<ul>
<li>no battery storage added (no Tesla Powerwall, no Enphase storage, no Generac);</li>
<li>no additional solar panels added by anyone;</li>
<li>no electrician work in the main panel or sub-panel (no service upgrades, no critical-load panel additions, no main-panel swap);</li>
<li>no roofing work that touched the panels or the array racking;</li>
<li>no EV charger installation that involved the solar interconnection.</li>
</ul>

<p>Please produce the January 27, 2026 work order, the technician&#39;s field notes, and any photographs taken at that visit. I expect they will show the same two-Sunrun-system configuration that has existed since 2018. If your tech recorded a &quot;third-party interconnection,&quot; the documentation will not survive comparison with the SDG&amp;E NEM record and the equipment actually present on the roof.</p>

<h3 style="color:#b30000;">6. The 2017 Costco system remains non-operational &mdash; Sunrun&#39;s own app flags &ldquo;Outlier detected&rdquo; as of Saturday, April 18</h3>

<p>You wrote: &quot;The technician visit yesterday, April 16, should have resolved the interconnection issue. We understand the panels are still not showing production on your monitoring app, but it can take some time for the production data to be accurately reflected in the monitoring application.&quot;</p>

<p>That explanation does not survive the screenshots I sent you at 5:47 PM on April 17 (re-attached for the record):</p>

<ul>
<li><strong>2012 PPA system:</strong> 30.5 kWh / Last 7 Days, 30 kWh yesterday, 30 kWh / Last 30 days &mdash; actively producing. All-time meter at 133,361 kWh, last updated 11:45 PM 4/16/26.</li>
<li><strong>2017 Costco system:</strong> 0 kWh yesterday, 0 kWh / Last 30 days, &quot;Error loading production data.&quot; All-time meter frozen at 51,132 kWh, last updated 9:30 AM 4/16/26.</li>
</ul>

<p>If the issue were a monitoring lag, both systems would show it. The 2012 PPA system &mdash; on the same property, on the same mySunrun account, updated at 11:45 PM on April 16 &mdash; shows normal production data. Only the 2017 Costco system does not. The 2017 Costco system was not actually restored on April 16.</p>

<p><strong>Update &mdash; Saturday, April 18, 2026, 1:30 PM PT:</strong> Two days after the alleged repair, I checked the mySunrun app again. The 2012 PPA system correctly shows &ldquo;System normal&rdquo; and is generating as expected. The 2017 Costco system now shows: <strong>Status: &ldquo;Outlier detected&rdquo;</strong> (displayed in amber on the overview screen, with a &ldquo;Click here to learn more&rdquo; prompt beneath it); <strong>Total: 0.0 kWh</strong> as of <code>--</code>. The weekly production chart for the period April 12&ndash;18 shows bars only on Thursday, April 16 and Friday, April 17 &mdash; the day of and day after the tech visit &mdash; then returns to zero on Saturday, April 18. Four screenshots taken at 1:30 PM PT on April 18, 2026 are attached to this message.</p>

<p>The &ldquo;Outlier detected&rdquo; designation is not a monitoring-lag artifact. It is Sunrun&#39;s own anomaly-detection flag appearing in the consumer-facing application, confirming that Sunrun&#39;s own monitoring infrastructure has identified the 2017 system as non-conforming two full days after the tech visit. The April 16 repair did not hold.</p>

<p>I expect another truck-roll from Sunrun within <strong>7 calendar days</strong> from the date of this email to complete the repair, at no charge to me, in accordance with Section 4 of the 2017 Limited Warranty. The April 22 scheduled appointment should proceed.</p>

<h3 style="color:#b30000;">7. Sunrun offered compensation 24 hours before refusing entirely &mdash; and Sunrun&#39;s own automation contradicts the &quot;no performance guarantee&quot; claim</h3>

<p>Katherine&#39;s email of April 16, 2026 (sent the day before my formal demand letter) reads, verbatim:</p>

<blockquote style="border-left:3px solid #999; padding-left:12px; color:#333;">
&quot;You do not have a performance guarantee on your contract but since the delay in fixing the issue took so long <strong>I will be able to compensate you `$450 for missed savings from the down time.</strong>&quot;
</blockquote>

<p>That offer is an admission that (a) Sunrun acknowledged the delay was its responsibility, and (b) Sunrun acknowledged a duty to compensate for missed savings. The position adopted 24 hours later &mdash; that Sunrun &quot;cannot and will not compensate&quot; &mdash; was adopted only after the formal demand letter arrived, not because the contracts or facts changed. They did not.</p>

<p>The same April 16, 2026 message asserted that I &quot;do not have a performance guarantee on your contract.&quot; That assertion is provably false. <strong>Approximately two minutes earlier on the same day</strong>, Sunrun&#39;s own automated system at no-reply@email.sunrun.com sent me an email titled &quot;Your Early Performance Guarantee Information&quot; that reads, verbatim:</p>

<blockquote style="border-left:3px solid #999; padding-left:12px; color:#333;">
&quot;Thank you for contacting Sunrun about your <strong>Early Performance Guarantee credit</strong>. While you aren&#39;t eligible for a credit at this time, we want to ensure you&#39;re getting the best performance and savings possible. <strong>We&#39;ll proceed with your regularly scheduled annual or bi-annual calculation to confirm your system is meeting its promised production.</strong>&quot;
</blockquote>

<p>Sunrun&#39;s own customer-relationship-management system identifies an Early Performance Guarantee on the account, with a regularly scheduled production-shortfall calculation. Independently, the <strong>2012 Sunrun Solar Power Service Agreement Section 8 (&quot;Guaranteed Output and Refunds&quot;)</strong> provides a separate written production guarantee with an annual refund mechanism. Section 8(e) carves out only grid failure and customer-caused shutdown; neither applies. I am owed a Section 8(c) refund check at the next anniversary date for the kWh shortfall during the outage, and that obligation is independent of the broader compensation discussion in this thread.</p>

<h3 style="color:#b30000;">8. Updated legal claims and exposure</h3>

<p>The factual record I have laid out above significantly expands the legal claims available to me. The April 16, 2026 demand letter rested on breach of warranty, breach of contract, and the implied covenant of good faith and fair dealing. With the documented concealment narrative, the claims now include:</p>

<ul>
<li><strong>Fraudulent concealment / deceit by suppression</strong> &mdash; Cal. Civ. Code &sect;&sect; 1572, 1709, 1710. A party with a duty to disclose (here, Sunrun, which both monitored the system and held PPA Section 2 maintenance obligations) who intentionally suppresses a material fact (here, that the system was producing zero kWh) to a counterparty who reasonably relies on the suppression (here, my reasonable belief that &quot;system issue&quot; meant a minor defect, and my attribution of higher utility bills to EV charging) is liable for the resulting damages.</li>
<li><strong>Consumer Legal Remedies Act &mdash; misrepresentation</strong> &mdash; Cal. Civ. Code &sect; 1770(a)(14) (representing that a transaction confers rights, remedies, or obligations that it does not have, or denying rights that exist). Katherine&#39;s &quot;you do not have a performance guarantee&quot; statement, contradicted by Sunrun&#39;s own automated email the same day, fits this provision precisely.</li>
<li><strong>Unfair Competition Law &mdash; non-disclosure prong</strong> &mdash; Cal. Bus. &amp; Prof. Code &sect; 17200. California courts treat non-disclosure of material facts to a consumer by a party with superior knowledge as &quot;unfair&quot; under the UCL. Restitution is available.</li>
<li><strong>Punitive damages exposure</strong> &mdash; Cal. Civ. Code &sect; 3294. Concealment by a corporate defendant supports punitive damages on a clear-and-convincing showing of fraud or malice. The pattern documented above &mdash; 67 days of complete silence after monitoring detected the failure, four months of vague &quot;system issue&quot; emails while production was at zero, and a &quot;Value Report&quot; sent during the outage &mdash; would not be difficult to present.</li>
<li><strong>Limitation-of-liability clauses do not survive these claims</strong> &mdash; controlling and very recent California Supreme Court authority is squarely on point. In <em>New England Country Foods, LLC v. Vanlaw Food Products, Inc.</em>, S282968 (Cal. April 24, 2025), the California Supreme Court held categorically that Cal. Civ. Code &sect; 1668 invalidates not only complete liability waivers but also <strong>any provision that limits damages &mdash; including caps on direct damages and exclusions of consequential damages &mdash; for willful misconduct, fraud, or violation of law (whether willful or negligent).</strong> See also <em>Tunkl v. Regents</em>, 60 Cal.2d 92 (1963); <em>City of Santa Barbara v. Superior Court</em>, 41 Cal.4th 747 (2007); <em>Health Net of California, Inc. v. Department of Health Services</em>, 113 Cal.App.4th 224 (2003). Under <em>New England Country Foods</em> and Civ. Code &sect; 1668, the 2012 PPA &sect; 15 cap and the 2017 contract&#39;s consequential-damages exclusion are unenforceable to the extent the claims plead concealment, fraud, CLRA, or UCL violations &mdash; which they would.</li>
</ul>

<h3 style="color:#b30000;">9. Position going forward</h3>

<p>Given that (a) Sunrun&#39;s own portal records contradict the &quot;no November engagement&quot; claim, (b) there is no third-party system, (c) the 2017 Costco system remains non-operational as of Saturday, April 18 &mdash; with Sunrun&#39;s own app flagging &ldquo;Outlier detected&rdquo; and 0.0 kWh, two days after the alleged repair &mdash; and (d) Sunrun offered `$450 in compensation 24 hours before refusing entirely, my position has not improved with the new information.</p>

<p>I remain willing to resolve this in correspondence on the following terms:</p>

<ol>
<li><strong>`$7,500.00</strong> as full reimbursement (paid by check or applied as an SDG&amp;E account credit), AND</li>
<li><strong>Restoration of the 2017 Costco system to full operational status within 7 calendar days</strong> from the date of this email, at no charge to me, AND</li>
<li><strong>Written confirmation of the 2012 PPA Section 8 refund</strong> for the current anniversary year, calculated and paid as required by the contract, AND</li>
<li><strong>Written confirmation that the April 22, 2026 scheduled appointment will proceed</strong> if needed to complete the 2017 system repair, with a written summary delivered to me afterward identifying root cause.</li>
</ol>

<p>The `$7,500.00 figure is a settlement number, not a damages ceiling. It reflects: (a) `$2,583.00 in documented excess SDG&amp;E charges December 2025 through April 2026; (b) approximately `$2,500.00 in projected excess SDG&amp;E charges through the November 6, 2026 NEM true-up; and (c) the 2012 PPA Section 8 refund for the kWh shortfall during the outage. <strong>If Sunrun forces this matter to a CLRA filing, JAMS arbitration, or civil action, the claims pleaded will include fraudulent concealment, deceit by suppression, CLRA misrepresentation, and a UCL non-disclosure claim, with punitive damages exposure under Civ. Code &sect; 3294. The settlement number does not survive that filing.</strong></p>

<p>If the 2017 Costco system is not producing within 7 calendar days from the date of this email, the settlement number increases by the documented additional production loss accrued during that period.</p>

<p>If Sunrun&#39;s position remains that it &quot;will not compensate,&quot; I will proceed without further notice with: (i) a CSLB complaint against License #750184 (Sunrun Installation Services) and #858087 (Costco) attaching this thread and the November-through-April email record; (ii) a BBB complaint at Sunrun&#39;s San Francisco profile; (iii) a CPUC Consumer Affairs Branch complaint; (iv) the CLRA 30-day notice clock, which began running with the April 16 letter and ripens into a CLRA lawsuit on May 16, 2026 (Cal. Civ. Code &sect; 1782); and (v) a JAMS arbitration demand on the 2012 PPA Section 16 claims, with the small-claims action on the 2017 contract preserved.</p>

<p>Please confirm by <strong>Friday, April 24, 2026</strong> whether Sunrun is willing to revisit its position with the corrected factual record above, or whether I should proceed. I am open to a call &mdash; my mobile and the office line are in my signature.</p>

<h3 style="color:#b30000;">10. Document preservation &mdash; expanded</h3>

<p>Sunrun, Sunrun Installation Services, Inc., and any affiliated entity are hereby placed on continuing notice to preserve all documents, communications, and electronic records relating to:</p>

<ul>
<li>The account and customer file for Ravi Jain at 5 Caladium, Rancho Santa Margarita, CA 92688 (NEM Meter #06688420);</li>
<li>Service Case #18181148 in Sunrun&#39;s CRM, including the case-creation entry, all internal status updates, all internal communications about how the case was classified (e.g., as &quot;Metering&quot; rather than &quot;System Down&quot; or equivalent), and any decision documentation about not notifying the customer of zero production;</li>
<li>All <strong>monitoring telemetry from the SolarEdge inverters and the Sunrun monitoring system at the Property from October 1, 2025 through the date of full restoration</strong>, at the highest available resolution (interval data, not just daily aggregates);</li>
<li>The work order, technician field notes, technician GPS records, photographs, and remote-monitoring readings for each of: the November 10, 2025 engagement (whether physical or remote), the January 27, 2026 visit, the February 23, 2026 scheduled appointment (whether it occurred or was canceled), the April 16, 2026 emergency visit, and the April 22, 2026 scheduled appointment;</li>
<li>All scripts, templates, and decision rules used by Sunrun&#39;s automated email system (noreply@ai.sunrun.com) for choosing the language &quot;system issue&quot;, &quot;your issue&quot;, and &quot;system reboot&quot; in customer communications about Case #18181148; and</li>
<li>All internal communications among Sunrun personnel, including but not limited to Katherine Wilson and any field-operations and customer-engagement managers, regarding this case and my account.</li>
</ul>

<p>Spoliation of any such records will be raised in any subsequent proceeding and may support an adverse inference instruction.</p>

<p>Sincerely,</p>

<p>Ravi Jain<br>
5 Caladium, Rancho Santa Margarita, CA 92688</p>

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

# --- Connect to Graph ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Build recipients for Graph ---
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
    Write-Host "Recommend send time: tomorrow ~7am PT (top of Katherine's 7am-3:30pm PT window)." -ForegroundColor Cyan
}

Disconnect-MgGraph | Out-Null