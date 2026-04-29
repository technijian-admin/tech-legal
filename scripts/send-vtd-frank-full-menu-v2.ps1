# Send VTD Briefing v2 to Frank Dunn — Full Menu of Readings (Course-of-Perf Lead + Matching-Duration Fallback)
# DEFAULT: creates draft only (review in Outlook before sending)
#
# Usage:
#   .\send-vtd-frank-full-menu-v2.ps1          # draft only (DEFAULT)
#   .\send-vtd-frank-full-menu-v2.ps1 -Send    # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$to = @( @{ Address = "fdunn@callahan-law.com"; Name = "Franklin T. Dunn, Esq." } )
$cc = @( @{ Address = "es@callahan-law.com";    Name = "Edward Susolik, Esq." } )

$senderUpn = "RJain@technijian.com"
$subject   = "VTD - Full Menu of Readings + Recommended Response Hierarchy"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$repoRoot = "C:\vscode\tech-legal\tech-legal"
$vtdRoot  = "$repoRoot\terminated-clients\VTD"
$attachmentMap = @(
    @{ Src = "$vtdRoot\emails\message-1-1537054.eml";
       Name = "01_Ravi_Erica_2025-06-24_Termination_Thread_FULL.eml" },
    @{ Src = "$vtdRoot\exhibits\vtd_actual_vs_bill.xlsx";
       Name = "02_VTD_Reconciliation_Actual_vs_Billed.xlsx" },
    @{ Src = "$vtdRoot\exhibits\Vintage_Design-Monthly_Service.pdf";
       Name = "03_VTD_Signed_Client_Monthly_Service_Agreement_2023-05-04.pdf" },
    @{ Src = "$vtdRoot\exhibits\vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx";
       Name = "04_VTD_Ticket_Time_Entries_Lifetime.xlsx" },
    @{ Src = "$vtdRoot\send-packages\2026-04-17_ed-update\VTD_2025-05-02_Monthly_Invoice_25438.eml";
       Name = "05_VTD_2025-05-02_Monthly_Invoice_25438.eml" },
    @{ Src = "$vtdRoot\send-packages\2026-04-17_ed-update\VTD_2025-06-02_Monthly_Invoice_25725.eml";
       Name = "06_VTD_2025-06-02_Monthly_Invoice_25725.eml" },
    @{ Src = "$vtdRoot\send-packages\2026-04-17_ed-update\VTD_2025-07-02_Monthly_Invoice_25953.eml";
       Name = "07_VTD_2025-07-02_Monthly_Invoice_25953.eml" },
    @{ Src = "$vtdRoot\send-packages\2026-04-17_ed-update\VTD_2025-08-01_Monthly_Invoice_26205.eml";
       Name = "08_VTD_2025-08-01_Monthly_Invoice_26205_TerminatedMonth.eml" },
    @{ Src = "$vtdRoot\send-packages\2026-04-17_ed-update\VTD_2025-07-05_Weekly_Invoice_25992.eml";
       Name = "09_VTD_2025-07-05_Weekly_Invoice_25992.eml" },
    @{ Src = "$vtdRoot\send-packages\2026-04-17_ed-update\VTD_2025-07-12_Weekly_Invoice_26029.eml";
       Name = "10_VTD_2025-07-12_Weekly_Invoice_26029.eml" },
    @{ Src = "$vtdRoot\send-packages\2026-04-17_ed-update\VTD_2025-07-21_Weekly_Invoice_26074.eml";
       Name = "11_VTD_2025-07-21_Weekly_Invoice_26074.eml" }
)

Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

$bodyTemplate = @'
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:__FONT__;font-size:11pt;color:rgb(0,0,0)">

<p>Frank,</p>

<p>For the 3:30 call. After re-reading the actual signed Client Monthly Service Agreement against Stambuk&rsquo;s 4/6 letter, I want to give you the full menu of how &para; 5 can be read, with our recommended hierarchy. The earlier brief I sent led with the chain-trap reductio; this one leads with course-of-performance + ratification (Tier 1) and reframes the chain argument as a sharper &ldquo;matching-duration&rdquo; wedge (Tier 2). The textual problem in &para; 5&rsquo;s &ldquo;previous&rdquo; wording is acknowledged and answered openly.</p>

<p>Eleven attachments at the bottom &mdash; same data-room pack as before.</p>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">TL;DR</p>

<p>The Under Contract section is five paragraphs of substantive text. It can be read eight ways producing $0 to $386,903. Two strongest plain-text-grounded readings for us:</p>

<ol>
<li><b>Course-of-performance / ratification reading</b> &mdash; 27 months of paid invoices at the elevated averaged rate, no objection from Erica Garcia (VP Finance). Anchors at the <b>Demand: $240,487.50</b>.</li>
<li><b>Matching-duration reading</b> &mdash; the contract expressly chose <b>12 months</b> as the averaging period (&para; 1). The parties could have chosen 3 or 6 months but chose 12. That choice fixes the duration of the averaging &ldquo;collection&rdquo; mechanism. P3 ran only 3 of 12 months. P4 never ran. Result: <b>$386,903.55</b>. Strongest fallback wedge.</li>
</ol>

<p>Stambuk&rsquo;s E2 reading (~$52,765) and the strict textual reading ($0) both require silently overriding the contract&rsquo;s plain duration choice or its course-of-performance gloss. We have at least four arguments against each.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">1. Verbatim Contract Text &mdash; Under Contract &para;&para; 1&ndash;5 (page 4 of signed PDF)</p>

<blockquote style="border-left:4px solid #006DB6;padding:6px 14px;background:#EFF7FB;margin:10px 0;font-size:10.5pt">
<p>&ldquo;Under contract support is defined as support that will be charged monthly based on the average number of hours used, under the following conditions:</p>
<ol>
<li><b>The under-contract period shall be 12 Months.</b></li>
<li><b>A new average will be calculated after each under contract period.</b></li>
<li><b>The first month of the new average will be charged at the previous average</b> since that invoice will be due the first of the month.</li>
<li><b>If the average goes down a credit will be given on the next month&rsquo;s invoice. If the average goes up an extra charge will be given on the next month&rsquo;s invoice.</b></li>
<li>If this agreement is terminated, <b>any hours that exceeded the previous under contract period average, that were documented through ticketing, will be charged at a rate of $150 per hour</b> and will be assessed as the cancellation fee to the client and due before agreement is terminated.&rdquo;</li>
</ol>
</blockquote>

<p>POD Specifications on the same page set the initial monthly hours: CHD-TS1 OS Support 40 @ $15, CHD-TS1 OS Support.AH 20 @ $30, IRV-TS1 Tech Support 20 @ $125. Total initial = 80 hrs/mo.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">2. Anchor Hours</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Period</td><td>Months</td><td>Billed</td><td>Actual</td><td>Billing rate set to</td>
</tr>
<tr><td><b>P1</b> &mdash; May 23 &ndash; Apr 24</td><td align="right">12</td><td align="right">960.00</td><td align="right">1,970.97</td><td>Original 80 hrs/mo (per POD Specs)</td></tr>
<tr><td><b>P2</b> &mdash; May 24 &ndash; Apr 25</td><td align="right">12</td><td align="right">2,025.08</td><td align="right">2,584.18</td><td>P1 actual avg ~164.25 hrs/mo</td></tr>
<tr style="background:#FEF3EE"><td><b>P3</b> (terminated) &mdash; May&ndash;Jul 25</td><td align="right"><b>3 of 12</b></td><td align="right">624.25</td><td align="right">384.94</td><td>P2 actual avg ~215.35 hrs/mo</td></tr>
<tr style="background:#F4F4F4"><td><b>P4</b> &mdash; would have been May 26 &ndash; Apr 27</td><td align="right"><b>0 of 12</b></td><td align="right">0</td><td align="right">0</td><td>Would have been P3 actual avg</td></tr>
</table>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">3. June 24, 2025 Email &mdash; Verbatim (Stambuk&rsquo;s anchor)</p>

<blockquote style="border-left:4px solid #006DB6;padding:6px 14px;background:#EFF7FB;margin:10px 0;font-size:10.5pt">
<p>&ldquo;Erica</p>
<p>Based on the lifetime of the contract and the contract terms you were set on a 12 month cycle. <b>That means every 12 months we adjust the average to collect the last 12 months of actual support.</b> While we allow 30 day termination, you were on the 1st month of the next cycle currently. So to allow the 30 day termination we calculate all the hours billed to you versus the actual hours of support given. <b>Any actual hours that have not been billed are billed at the hourly rate of $150 per hour.</b></p>
<p><b>I have attached a spreadsheet that shows these hours since we started working with you.</b></p>
<p>[...]</p>
<p>Based on this analysis and accounting for the july 1 invoice, <b>the number of actual hours of support that have not been billed are 1,143.98. This at $150 per hour would be a cancellation fee of $171,597.00.</b>&rdquo;</p>
</blockquote>

<p><b>The framing matters.</b> I was treating the cancellation reconciliation as a <b>global lifetime calculation</b> &mdash; all hours billed vs. all hours actually delivered, since contract inception. Not a chain calculation, not a per-period reconciliation &mdash; one global delta. That is the simplest reading of &para; 5 and is what the parties contemporaneously implemented. The 1,143.98 figure pre-dated final July invoices being booked; the settled multi-period total later resolved to 1,330.76 net (Scenario A) or 1,457.50 (the Demand).</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">4. Stambuk&rsquo;s Argument (4/6/2026 letter)</p>

<blockquote style="border-left:4px solid #999;padding:6px 14px;background:#F4F4F4;margin:10px 0;font-size:10.5pt">
&ldquo;In our view, Ravi&rsquo;s email limits Technijian to seeking payment for time allegedly incurred in the prior under contract period of 2024-2025, rather than 2023-2024 [...]. Ravi&rsquo;s email supports that Technijian has already collected what it believes it is owed for the 2023-2024 period.&rdquo;
</blockquote>

<p>Translated: averaging &ldquo;collected&rdquo; P1; recoverable = P2 + P3 excess only &asymp; <b>$52,765</b>.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">5. Full Menu &mdash; Eight Readings of &para; 5</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt;width:100%">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td width="5%">#</td>
  <td width="30%">Reading</td>
  <td width="20%">Math</td>
  <td width="15%">Result</td>
  <td width="30%">Posture</td>
</tr>
<tr>
  <td>A</td>
  <td>Literal &ldquo;previous&rdquo; singular &mdash; period of termination only</td>
  <td>P3 actual &minus; P3 billed</td>
  <td><b>$0</b></td>
  <td>Worst case for us. Frank&rsquo;s BST textual reading. Defeated by &sect; 1641 + course of performance.</td>
</tr>
<tr style="background:#FEF3EE">
  <td>B</td>
  <td>Stambuk&rsquo;s E2 &mdash; averaging &ldquo;collected&rdquo; P1; only P2 + P3</td>
  <td>319.79 hrs &times; $150 + 10%</td>
  <td><b>$52,765</b></td>
  <td>Their position. &ldquo;Collect&rdquo; is not in the contract. No principled stopping rule.</td>
</tr>
<tr>
  <td>C</td>
  <td>Native rates knockdown (&sect; 1671(b) attack)</td>
  <td>1,330.76 &times; mixed rates + 10%</td>
  <td><b>$20,014</b></td>
  <td>Vintage&rsquo;s burden. Defeated by Out-of-Contract rate table on same page = $150 / $200.</td>
</tr>
<tr>
  <td>D</td>
  <td>Ravi&rsquo;s June 24 global calculation</td>
  <td>1,143.98 &times; $150</td>
  <td><b>$171,597</b></td>
  <td>Useful as anchor (&ldquo;we under-claimed at the time&rdquo;). Pre-dates final billing.</td>
</tr>
<tr>
  <td>E</td>
  <td>Conservative net excess (Scenario A)</td>
  <td>1,330.76 &times; $150 + 10%</td>
  <td><b>$219,575</b></td>
  <td>Most literal spreadsheet reading. Fallback anchor.</td>
</tr>
<tr style="background:#EFF7FB">
  <td>F &#9733;</td>
  <td><b>Demand on record</b> &mdash; $67.65 R-6 fix pending</td>
  <td>1,457.50 &times; $150 + 10%</td>
  <td><b>$240,487</b></td>
  <td><b>Tier-1 anchor.</b> Aligns with global lifetime methodology.</td>
</tr>
<tr style="background:#FEF3EE">
  <td>G &#11088;</td>
  <td><b>Matching-duration / chain-extended</b> &mdash; 12 months chosen, 12 months required</td>
  <td>2,344.87 &times; $150 + 10%</td>
  <td><b>$386,903</b></td>
  <td><b>Strongest fallback wedge.</b> Grounded in &para; 1&rsquo;s 12-month period choice.</td>
</tr>
<tr>
  <td>H</td>
  <td>Aggressive monthly positive (Scenario D)</td>
  <td>1,878.67 &times; $150 + 10%</td>
  <td><b>$309,981</b></td>
  <td><b>Internal ceiling only.</b> Do not disclose.</td>
</tr>
</table>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">6. The Matching-Duration Argument &mdash; Why It&rsquo;s Sharper Than the Earlier Chain-Trap</p>

<p>The earlier chain-trap depended on Stambuk&rsquo;s <i>premise</i> that averaging &ldquo;collects.&rdquo; The matching-duration argument doesn&rsquo;t need her premise &mdash; it is grounded in the contract&rsquo;s express structural choice in &para; 1, made by the client at formation from the template&rsquo;s 3/6/12-month options:</p>

<blockquote style="border-left:4px solid #F67D4B;padding:8px 14px;background:#FEF3EE;margin:10px 0;font-size:10.5pt">
&ldquo;Even on Respondent&rsquo;s own theory that the elevated billing rate captures the prior period&rsquo;s elevated demand, the duration of that capture is fixed by the contract at 12 months &mdash; Under Contract &para; 1. The template offered Vintage Design a choice of 3, 6, or 12 months at contract formation. Vintage chose 12. That choice has consequences. P3 ran only 3 of 12. P4 never ran at all. Under Respondent&rsquo;s own theory, applied symmetrically to its own structural choice, 1,959.93 hours of P2 actuals and 384.94 hours of P3 actuals were never collected. 2,344.87 &times; $150 + 10% = <b>$386,903.55</b>.&rdquo;
</blockquote>

<p style="margin-top:12px;font-weight:bold">Why &para;&para; 3-4 read as a cycle-length mechanism (operational rationale).</p>

<p>The seemingly awkward &ldquo;first month of the new average&rdquo; language has a specific operational reason rooted in <b>Other Terms &para; 2</b> (page 4 of the signed Agreement, verbatim):</p>

<blockquote style="border-left:4px solid #006DB6;padding:6px 14px;background:#EFF7FB;margin:10px 0;font-size:10.5pt">
&ldquo;For Services rendered monthly, Client shall be invoiced on the <b>first day of previous month</b> due and payable by the first day of the current month of support.&rdquo;
</blockquote>

<p>That is <b>30-day advance invoicing on a net-30 basis</b>. The May invoice is generated and sent at the START of April. But the prior 12-month cycle does not finish until April 30. So when the May invoice has to be generated (early April), the cycle&rsquo;s last month has not completed yet &mdash; there is no finalized cycle average yet to apply.</p>

<p>&para; 3&rsquo;s solution: bill the first month of the new cycle (May) at the <b>previous</b> average. By the time the June invoice goes out (early May), Cycle 1 is fully closed and the new average is finalized &mdash; so &para; 4 applies the delta to that next invoice.</p>

<p>That gives the cycle this structural shape:</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Position in cycle</td><td>Billing basis</td><td>Source</td>
</tr>
<tr><td><b>Month 1</b></td><td>Previous cycle&rsquo;s average (transitional)</td><td>&para; 3</td></tr>
<tr><td><b>Month 2</b></td><td>New average + one-time delta charge/credit</td><td>&para; 4</td></tr>
<tr style="background:#FEF3EE"><td><b>Months 3 through N</b></td><td>New average (no further delta)</td><td>Implied; the cycle proper</td></tr>
</table>

<p>For a 12-month cycle (VTD&rsquo;s choice): <b>1 transitional + 11 months at the new (elevated) rate</b>. For a 6-month cycle: 1 + 5. For 3-month: 1 + 2.</p>

<p>The averaging adjustment is therefore a <b>cycle-length mechanism</b> &mdash; not a single-month true-up. The new (elevated) rate operates for the back portion of each cycle. For VTD: the back <b>11 of 12</b> months.</p>

<p><b>Termination math under this clean reading.</b> P3 was supposed to run 11 months at the elevated rate (June 2025 &ndash; April 2026), plus 1 transitional (May 2025). P3 actually ran <b>2</b> months at the elevated rate (June and July) plus 1 transitional. <b>9 elevated-rate months never happened</b> &mdash; not because of an inferred premise, but because the contract&rsquo;s own cycle-length mechanism was structurally cut short.</p>

<p style="margin-top:12px;font-weight:bold">Recommended stipulation to lock the reading.</p>

<p>Putting the cycle-as-mechanism reading on the record forecloses Stambuk&rsquo;s &ldquo;one-month true-up&rdquo; escape route:</p>

<blockquote style="border-left:4px solid #F67D4B;padding:8px 14px;background:#FEF3EE;margin:10px 0;font-size:10.5pt">
&ldquo;The parties stipulate that Under Contract &para;&para; 1&ndash;4, read in conjunction with Other Terms &para; 2 (30-day advance invoicing on net-30), operate as a cycle-length mechanism: &para; 1 fixes the under-contract cycle length, which the client selects at contract formation from the options provided by the template (3, 6, or 12 months); the parties to this Agreement selected 12 months. &para; 2 calculates a new average after each cycle ends. &para; 3 charges the first month of the new cycle at the previous cycle&rsquo;s average for invoice-timing reasons (the new cycle&rsquo;s first invoice must issue before the prior cycle has fully closed and its average been finalized). &para; 4 applies the delta between old and new averages to the next month&rsquo;s invoice. Thereafter the new average governs billing for the remaining months of the cycle. The averaging adjustment is therefore a cycle-length mechanism &mdash; not a single-month true-up &mdash; and for this Agreement the new (elevated) rate operates for the back eleven months of each twelve-month cycle.&rdquo;
</blockquote>

<p>If Stambuk refuses to stipulate, the refusal is itself useful &mdash; she has to articulate a competing reading, and the only available one (one-month true-up) is textually weak under &para; 1 + &para; 2 + Other Terms &para; 2 read together.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">7. Defensive Stack &mdash; Five Arguments Against Reading A or B</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>#</td><td>Argument</td><td>Authority</td><td>Effect</td>
</tr>
<tr><td>1</td><td><b>Course of performance</b> &mdash; 27 months of paid elevated invoices, no objection</td><td>Cal. Com. Code &sect; 1303(a)&ndash;(b); <i>Wagner v. Glendale Adventist</i> (1989) 216 Cal.App.3d 1379, 1388; <i>Kashmiri v. Regents</i> (2007) 156 Cal.App.4th 809, 833</td><td>Establishes parties&rsquo; agreed reading: multi-period reconciliation</td></tr>
<tr><td>2</td><td><b>Ratification by signatory</b> &mdash; VP Finance personally paid each elevated invoice</td><td><i>Rakestraw v. Rodrigues</i> (1972) 8 Cal.3d 67, 73; <i>Pasadena Medi-Center</i> (1973) 9 Cal.3d 773</td><td>Cures interpretation-authority challenges</td></tr>
<tr><td>3</td><td><b>Whole-contract construction</b> &mdash; narrow &ldquo;previous&rdquo; reading renders &para; 5 a dead letter</td><td>Cal. Civ. Code &sect; 1641; <i>Powerine Oil</i> (2005) 37 Cal.4th 377, 390&ndash;391; <i>MacKinnon</i> (2003) 31 Cal.4th 635, 648</td><td>Defeats Reading A</td></tr>
<tr><td>4</td><td><b>&sect; 1671(b) burden on Vintage</b> to prove rate unreasonable at formation</td><td><i>Ridgley v. Topa Thrift</i> (1998) 17 Cal.4th 970, 977; <i>Hitz</i> (1995) 38 Cal.App.4th 274, 286&ndash;289</td><td>Defeats Reading C; Out-of-Contract table = $150 / $200</td></tr>
<tr><td>5</td><td><b>60-day waiver</b> in T&amp;C &sect; 3.01 &mdash; no objection to any monthly invoice</td><td><i>Cobb v. Pacific Mut. Life Ins.</i> (1935) 4 Cal.2d 565, 573</td><td>Forecloses ticketing-accuracy attacks</td></tr>
</table>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">8. Recommended Hierarchy</p>

<p><b>Tier 1 &mdash; lead with these:</b></p>
<ul>
<li>Course-of-performance / ratification at the Demand $240,487.50 anchor (Reading F).</li>
<li>Whole-contract construction defeats Reading A.</li>
<li>&sect; 1671(b) burden on Vintage defeats Reading C.</li>
</ul>

<p><b>Tier 2 &mdash; secondary structural arguments:</b></p>
<ul>
<li>Stambuk&rsquo;s &ldquo;collected&rdquo; premise has no textual basis (defeats Reading B on the merits).</li>
<li>Matching-duration argument (Reading G) &mdash; if Stambuk insists on her own framing.</li>
</ul>

<p><b>Tier 3 &mdash; internal-only ceilings, do not disclose:</b></p>
<ul>
<li>Scenario D ($309,981).</li>
<li>Walk-away floor ($125,000).</li>
</ul>

<p><b>Confronting the textual risk honestly.</b> &para; 5&rsquo;s &ldquo;previous&rdquo; wording is a real textual hook for Reading A ($0). We do not pretend it isn&rsquo;t there. We answer it with course of performance, ratification, and &sect; 1641. We do not anchor on a position that ignores the textual problem.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">9. Three Drop-In Response Paragraphs</p>

<p><b>Option 1 &mdash; Course-of-Performance Lead (recommended Tier 1):</b></p>

<blockquote style="border-left:4px solid #F67D4B;padding:8px 14px;background:#FEF3EE;margin:10px 0;font-size:10.5pt">
&ldquo;Counsel &mdash; Respondent&rsquo;s reading of Mr. Jain&rsquo;s June 24, 2025 email is foreclosed by 27 months of unobjected-to course of performance. Each monthly invoice from Technijian to Vintage Design carried, on its face, a Support History table identifying actual hours, billed hours, and &lsquo;unpaid hours due if support agreement is cancelled per monthly service agreement.&rsquo; Mr. Jain&rsquo;s June 24, 2025 email itself states the operative method: &lsquo;we calculate all the hours billed to you versus the actual hours of support given. Any actual hours that have not been billed are billed at the hourly rate of $150 per hour.&rsquo; That is a global lifetime calculation. Vintage paid each monthly invoice for 27 months without objection. Cal. Com. Code &sect; 1303(a)&ndash;(b); <i>Kashmiri v. Regents</i> (2007) 156 Cal.App.4th 809, 833; <i>Wagner v. Glendale Adventist Med. Ctr.</i> (1989) 216 Cal.App.3d 1379, 1388. The Demand of $240,487.50 (subject to the $67.65 late-fee correction under AAA Rule R-6) sits squarely within that course-of-performance reading.&rdquo;
</blockquote>

<p><b>Option 2 &mdash; Matching-Duration Wedge (Tier 2 fallback):</b></p>

<blockquote style="border-left:4px solid #F67D4B;padding:8px 14px;background:#FEF3EE;margin:10px 0;font-size:10.5pt">
&ldquo;Counsel &mdash; Respondent&rsquo;s reading depends on the premise that the averaging mechanism in Under Contract &para;&para; 3&ndash;4 &lsquo;collected&rsquo; 2023&ndash;2024&rsquo;s excess via 2024&ndash;2025&rsquo;s elevated billing rate. The duration of that &lsquo;collection&rsquo; is not Respondent&rsquo;s choice &mdash; it is fixed by &para; 1: &lsquo;The under-contract period shall be 12 Months.&rsquo; The parties could have chosen 3 months or 6 months. They chose 12. By Respondent&rsquo;s own theory, applied symmetrically to that structural choice: P2 ran a full 12 of 12 months at the elevated rate, fully collecting P1 (Respondent concedes); P3 ran only 3 of 12 months, leaving 1,959.93 of P2&rsquo;s 2,584.18 actuals uncollected; P4 never started, leaving 384.94 of P3&rsquo;s actuals uncollected. 2,344.87 &times; $150 + 10% = <b>$386,903.55</b> &mdash; $146,416 above the Demand. Respondent has no principled basis to apply the 12-month duration choice to the P1/P2 boundary but not the P2/P3 or P3/P4 boundaries.&rdquo;
</blockquote>

<p><b>Option 3 &mdash; Whole-Contract Construction (Tier 2 against Reading A):</b></p>

<blockquote style="border-left:4px solid #F67D4B;padding:8px 14px;background:#FEF3EE;margin:10px 0;font-size:10.5pt">
&ldquo;Counsel &mdash; to the extent Respondent reads &para; 5&rsquo;s &lsquo;the previous under contract period average&rsquo; as limited to the immediately preceding cycle, that reading renders &para; 5 a dead letter. Clients almost invariably terminate after a usage spike has subsided. A cancellation clause that reaches only the terminated cycle would have no practical work to do. Cal. Civ. Code &sect; 1641 forecloses that reading. <i>Powerine Oil Co. v. Superior Court</i> (2005) 37 Cal.4th 377, 390&ndash;391; <i>MacKinnon v. Truck Ins. Exchange</i> (2003) 31 Cal.4th 635, 648.&rdquo;
</blockquote>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">10. Talking Points for the 3:30 Call</p>

<ol>
<li>Confirm Tier-1 anchor: course of performance + ratification &rarr; Demand $240,487.50.</li>
<li>Confirm matching-duration ($386,903.55) as the Tier-2 wedge if Stambuk insists on her chain theory.</li>
<li>Confirm Scenario D ($309,981) and the $125K walk-away floor are internal-only.</li>
<li>Decide whether to file the AAA Rule R-6 amendment now to fix the $67.65 late-fee error, or fold it into settlement stipulation.</li>
<li>Sign-off on Option 1 / Option 2 / Option 3 response language above before any external use.</li>
<li>Schedule the data-room upload (11 files / 3.48 MB) once we close on which version of the response to send.</li>
</ol>

<p>See you at 3:30.</p>

<p>&mdash; Ravi</p>

__SIG__

</div>
</body>
</html>
'@

$htmlBody = $bodyTemplate.Replace('__FONT__', $fontStack).Replace('__SIG__', $sig)

if ($htmlBody -match '\$\s+\d') {
    throw "Detected stripped dollar sign before digit. Aborting."
}
if ($htmlBody -match '__FONT__|__SIG__') {
    throw "Detected unfilled template placeholder. Aborting."
}

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

Write-Host "`nStaging attachments..." -ForegroundColor Cyan
$attachments = @()
foreach ($map in $attachmentMap) {
    if (-not (Test-Path $map.Src)) { throw "Source file not found: $($map.Src)" }
    $bytes = [System.IO.File]::ReadAllBytes($map.Src)
    $b64   = [Convert]::ToBase64String($bytes)
    $ctype = switch -Wildcard ($map.Name) {
        "*.eml"  { "message/rfc822"; break }
        "*.pdf"  { "application/pdf"; break }
        "*.xlsx" { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"; break }
        default  { "application/octet-stream" }
    }
    $attachments += @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name          = $map.Name
        contentType   = $ctype
        contentBytes  = $b64
    }
    Write-Host ("  [+] {0}" -f $map.Name) -ForegroundColor Gray
}

Write-Host "`nCreating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($to | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    CcRecipients = @($cc | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    Attachments  = $attachments
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft v2 created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "`nSending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT to $($to[0].Address)." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT v2 saved to Outlook Drafts for $senderUpn." -ForegroundColor Yellow
    Write-Host "  To: $($to[0].Address)" -ForegroundColor Gray
    Write-Host "  Cc: $($cc[0].Address)" -ForegroundColor Gray
    Write-Host "  Subject: $subject" -ForegroundColor Gray
    Write-Host "`nNote: v1 draft (chain-trap-only) is also in Drafts." -ForegroundColor Yellow
    Write-Host "Pick which one to send after the 3:30 call." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
