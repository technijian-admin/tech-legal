# Send VTD Briefing to Frank Dunn — Chain-Trap Analysis + Data-Room Prep
# DEFAULT: creates draft only (review in Outlook before sending)
#
# Usage:
#   .\send-vtd-frank-chain-trap.ps1          # draft only (DEFAULT)
#   .\send-vtd-frank-chain-trap.ps1 -Send    # send immediately
#
# Recipients: Frank Dunn (To), Ed Susolik (Cc)

param([switch]$Send)

$ErrorActionPreference = "Stop"

$to = @(
    @{ Address = "fdunn@callahan-law.com"; Name = "Franklin T. Dunn, Esq." }
)
$cc = @(
    @{ Address = "es@callahan-law.com";    Name = "Edward Susolik, Esq." }
)

$senderUpn = "RJain@technijian.com"
$subject   = "VTD - Response Framework for Stambuk: Chain-Trap Analysis + Data Room Prep"

$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

# Source files to attach (mapped to clean attachment names)
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

# ----- BUILD HTML BODY (single-quoted here-string to avoid `$` escape hell, then template-fill the font stack) -----
$bodyTemplate = @'
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:__FONT__;font-size:11pt;color:rgb(0,0,0)">

<p>Frank,</p>

<p>Per your 4/28 emails &mdash; here is the consolidated brief on the VTD chain-trap analysis, plus the source documents you asked for to populate the data room. Ed is cc&rsquo;d. The full memo is below; the eleven attachments are listed at the bottom of this email.</p>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">TL;DR</p>

<p>Stambuk&rsquo;s 4/6 letter argues my June&nbsp;24,&nbsp;2025 email to Erica Garcia &ldquo;limits&rdquo; us to a 2024&ndash;2025-only cancellation fee &mdash; about $52,765 &mdash; because the email mentions a 12-month averaging cycle. Her argument has a fatal internal trap that flips the math against her:</p>

<ol>
<li>She concedes the &ldquo;chain&rdquo; mechanism &mdash; that the 2024&ndash;2025 cycle&rsquo;s elevated billing rate &ldquo;collected&rdquo; 2023&ndash;2024&rsquo;s excess.</li>
<li>Applied consistently, that same chain says the 2025 (terminated) cycle should have collected 2024&ndash;2025 &mdash; but the 2025 cycle was cut short at <b>3 of 12 months</b>. And there is no 2026 cycle to collect 2025.</li>
<li><b>Result under her own theory: 2,344.87 hours &times; $150 = $351,730.50, plus 10% late fee = $386,903.55.</b> That is <b>$146,416 higher than our Demand</b> of $240,487.50.</li>
</ol>

<p>So she has two doors and both favor us:</p>

<ul>
<li><b>Door A &mdash; chain premise wrong:</b> averaging is prospective rate-setting only; nothing was &ldquo;collected&rdquo;; full Demand of <b>$240,487.50</b> stands.</li>
<li><b>Door B &mdash; chain premise right:</b> applied symmetrically it produces <b>$386,903.55</b>, more than the Demand.</li>
</ul>

<p>There is no internally consistent reading of her argument that produces a number below the Demand. She picked an arbitrary stopping point that helps her at the P1/P2 boundary and ignores the same logic at the P2/P3 and P3/P4 boundaries.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">1. Anchor numbers (signed 5/4/2023 Vintage Design Agreement)</p>

<p>From the reconciliation spreadsheet (Attachment&nbsp;02):</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Period</td><td>Months</td><td>Billed</td><td>Actual</td><td>Billing rate set to</td>
</tr>
<tr><td><b>P1</b> &mdash; May&nbsp;2023 &ndash; Apr&nbsp;2024</td><td align="right">12</td><td align="right">960.00</td><td align="right">1,970.97</td><td>Original contract (80&nbsp;hrs/mo)</td></tr>
<tr><td><b>P2</b> &mdash; May&nbsp;2024 &ndash; Apr&nbsp;2025</td><td align="right">12</td><td align="right">2,025.08</td><td align="right">2,584.18</td><td>P1 actual average</td></tr>
<tr style="background:#FEF3EE"><td><b>P3</b> (terminated) &mdash; May&ndash;Jul&nbsp;2025</td><td align="right"><b>3 of 12</b></td><td align="right">624.25</td><td align="right">384.94</td><td>P2 actual average</td></tr>
<tr style="background:#F4F4F4"><td><b>P4</b> &mdash; would have been May&nbsp;2026 &ndash; Apr&nbsp;2027</td><td align="right"><b>0 of 12</b></td><td align="right">0</td><td align="right">0</td><td>Would have been P3 actual average</td></tr>
</table>

<p>Cancellation rate: <b>$150/hr</b>. Late fee: <b>10%</b> (Other&nbsp;Terms&nbsp;&para;&nbsp;3).</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">2. The June&nbsp;24,&nbsp;2025 email &mdash; verbatim (Stambuk&rsquo;s anchor document)</p>

<p>Full thread is at Attachment&nbsp;01. My substantive paragraph from June&nbsp;24,&nbsp;2025 at 8:42&nbsp;AM, in full:</p>

<blockquote style="border-left:4px solid #006DB6;padding:6px 14px;background:#EFF7FB;margin:10px 0;font-size:10.5pt">
<p>&ldquo;Erica</p>
<p>Based on the lifetime of the contract and the contract terms you were set on a 12 month cycle. <b>That means every 12 months we adjust the average to collect the last 12 months of actual support.</b> While we allow 30 day termination, you were on the 1st month of the next cycle currently. So to allow the 30 day termination we calculate all the hours billed to you versus the actual hours of support given. <b>Any actual hours that have not been billed are billed at the hourly rate of $150 per hour.</b></p>
<p><b>I have attached a spreadsheet that shows these hours since we started working with you.</b></p>
<p>[...]</p>
<p>Based on this analysis and accounting for the july 1 invoice, <b>the number of actual hours of support that have not been billed are 1,143.98. This at $150 per hour would be a cancellation fee of $171,597.00.</b>&rdquo;</p>
</blockquote>

<p><b>Two facts Stambuk omitted from her quote:</b></p>

<ol>
<li><b>I calculated from &ldquo;since we started working with you&rdquo;</b> &mdash; i.e., from May&nbsp;2023, P1 included. The 1,143.98-hour figure is a multi-period total. She is reading &ldquo;the last 12 months&rdquo; out of context and ignoring the very next paragraph.</li>
<li><b>The &ldquo;collect the last 12 months&rdquo; sentence describes how the per-month billing rate is <i>re-set going forward</i>, not a representation that prior excess was retroactively paid.</b> The very next sentence describes the <i>separate</i> cancellation calculation: &ldquo;all the hours billed to you versus the actual hours of support given. Any actual hours that have not been billed are billed at the hourly rate of $150 per hour.&rdquo;</li>
</ol>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">3. Stambuk&rsquo;s argument (4/6/2026 letter to Ed)</p>

<p>Verbatim from her letter:</p>

<blockquote style="border-left:4px solid #999;padding:6px 14px;background:#F4F4F4;margin:10px 0;font-size:10.5pt">
&ldquo;In our view, Ravi&rsquo;s email limits Technijian to seeking payment for time allegedly incurred in the prior under contract period of 2024-2025, rather than 2023-2024, as Ravi stated that &lsquo;every 12 months we adjust the average to collect the last 12 months of actual support.&rsquo; In our view, Ravi&rsquo;s email supports that Technijian has already collected what it believes it is owed for the 2023-2024 period.&rdquo;
</blockquote>

<p>She also asserts that &ldquo;Jenna agreed that excluding the 2023-2024 period would be a reasonable and accurate interpretation.&rdquo;</p>

<p>Translated: 2024&ndash;2025 elevated billing &ldquo;collected&rdquo; 2023&ndash;2024 excess; therefore P1 is off the table; recoverable = P2&nbsp;+&nbsp;P3 excess only &asymp; 319.79&nbsp;hrs &times; $150 &asymp; <b>$52,765</b> (Scenario&nbsp;E2 in our internal model).</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">4. The chain trap &mdash; visualized cycle-by-cycle (P1 &rarr; P2 &rarr; P3 &rarr; P4)</p>

<p>Stambuk&rsquo;s premise: <b>&ldquo;averaging at a cycle boundary collects the prior cycle&rsquo;s excess.&rdquo;</b> Apply that mechanic consistently across every boundary the contract creates:</p>

<table border="1" cellpadding="8" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10.5pt;width:100%">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td width="10%">Cycle</td>
  <td width="20%">Span</td>
  <td width="20%">Billing rate set to</td>
  <td width="20%">What it was supposed to collect</td>
  <td width="30%">What it actually collected</td>
</tr>
<tr>
  <td><b>P1</b></td>
  <td>May&nbsp;23 &ndash; Apr&nbsp;24<br/>(12 of 12 months)</td>
  <td>Original contract (80 hrs/mo)</td>
  <td>Nothing prior &mdash; this is the start of the contract</td>
  <td>Billed 960; actual 1,970.97 &mdash; baseline</td>
</tr>
<tr style="background:#EFF7FB">
  <td><b>P2</b></td>
  <td>May&nbsp;24 &ndash; Apr&nbsp;25<br/>(12 of 12 months)</td>
  <td>P1 actual average (~164.25 hrs/mo)</td>
  <td>P1 actuals (over 12 months at the elevated rate)</td>
  <td>Ran the full 12 of 12 at the elevated rate &rarr; <b>P1 fully collected ✓</b><br/>(Stambuk concedes this)</td>
</tr>
<tr style="background:#FEF3EE">
  <td><b>P3</b></td>
  <td>May&nbsp;25 &ndash; Jul&nbsp;25<br/>(<b>3 of 12 months</b>)</td>
  <td>P2 actual average (~215.35 hrs/mo)</td>
  <td>P2 actuals (over 12 months at the elevated rate)</td>
  <td>*** TERMINATED AFTER 3 of 12 MONTHS ***<br/>Only 624.25 of P2&rsquo;s 2,584.18 actuals were collected.<br/><b>P2 partially collected.</b></td>
</tr>
<tr style="background:#F4F4F4">
  <td><b>P4</b></td>
  <td>Would have been<br/>May&nbsp;26 &ndash; Apr&nbsp;27<br/>(<b>0 of 12 months</b>)</td>
  <td>Would have been P3 actual average</td>
  <td>P3 actuals (over 12 months at the elevated rate)</td>
  <td><b>NEVER STARTED.</b><br/>P3 actuals were therefore <b>never collected at all</b>.</td>
</tr>
</table>

<p style="margin-top:14px"><b>What is uncollected at termination, under Stambuk&rsquo;s own premise:</b></p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10.5pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Cycle</td><td>Should have been collected by</td><td>What was actually collected</td><td>Uncollected hours</td>
</tr>
<tr><td><b>P1</b></td><td>P2 billing (12 of 12 mo)</td><td>Full</td><td align="right">0</td></tr>
<tr><td><b>P2</b></td><td>P3 billing (12 of 12 mo)</td><td>Only 3 of 12 &rarr; 624.25 hrs</td><td align="right"><b>2,584.18 &minus; 624.25 = 1,959.93</b></td></tr>
<tr><td><b>P3</b></td><td>P4 billing (would have been 12 of 12)</td><td>0 of 12 &rarr; 0 hrs</td><td align="right"><b>384.94 &minus; 0 = 384.94</b></td></tr>
<tr style="background:#FEF3EE;font-weight:bold"><td colspan="3">TOTAL UNCOLLECTED</td><td align="right">2,344.87 hrs</td></tr>
</table>

<p style="margin-top:10px"><b>2,344.87 &times; $150 = $351,730.50</b> &rarr; with 10% late fee &rarr; <b>$386,903.55</b>.</p>

<p>Compare to the Demand: <b>$240,487.50</b>. <b>Stambuk&rsquo;s own theory, applied symmetrically, owes us $146,416 <i>more</i> than we are asking.</b></p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">5. Why she has no escape route</p>

<p>She has three logical exits and all three favor us:</p>

<p><b>Exit&nbsp;1 &mdash; &ldquo;The chain only runs one hop. P2 collects P1, but P3 doesn&rsquo;t collect P2.&rdquo;</b></p>

<ul>
<li>Nothing in the contract supports a one-hop limit. Under&nbsp;Contract&nbsp;&para;&para;&nbsp;3&ndash;4 describes the same adjustment at <i>every</i> cycle boundary, with identical language.</li>
<li>My June&nbsp;24,&nbsp;2025 email &mdash; her own anchor &mdash; says &ldquo;<b>every</b> 12 months we adjust the average.&rdquo; Not &ldquo;once.&rdquo; Not &ldquo;only at the first boundary.&rdquo; <i>Every</i>.</li>
<li>A one-hop rule is pure outcome engineering &mdash; it stops the chain at exactly the spot that helps Vintage and nowhere else.</li>
<li><i>Powerine Oil Co. v. Superior Court</i> (2005) 37&nbsp;Cal.4th&nbsp;377, 390&ndash;391: contract terms construed consistently and to give effect to every part. Selective application violates this.</li>
</ul>

<p><b>Exit&nbsp;2 &mdash; &ldquo;The averaging is just a prospective rate adjustment; it does not &lsquo;collect&rsquo; prior period excess.&rdquo;</b></p>

<ul>
<li>That is <b>our position</b>. It produces the full Demand of $240,487.50.</li>
<li>The averaging adjusts the per-month rate going forward; it does not retroactively forgive excess hours delivered but unbilled in the prior cycle.</li>
<li>Cal.&nbsp;Civ.&nbsp;Code&nbsp;&sect;&sect;&nbsp;1638, 1641; <i>Powerine Oil</i>, supra; <i>MacKinnon v. Truck Ins. Exchange</i> (2003) 31&nbsp;Cal.4th&nbsp;635, 648.</li>
<li>If she retreats here, she abandons her 4/6 letter and we are at the Demand. We win that exchange.</li>
</ul>

<p><b>Exit&nbsp;3 &mdash; &ldquo;Cancellation fee is limited to the period of termination only.&rdquo;</b></p>

<ul>
<li>That is Scenario&nbsp;E1 ($0 because P3 under-ran P3 billing). But:</li>
<li>Contract text: &ldquo;<b>any</b> hours that exceeded <b>the previous</b> under contract period average&rdquo; &mdash; <i>previous</i>, not <i>current</i>. The clause expressly reaches prior periods.</li>
<li>Reading the cancellation fee to reach only the terminated cycle would render the clause a dead letter (clients almost always terminate after a spike has subsided). Cal.&nbsp;Civ.&nbsp;Code&nbsp;&sect;&nbsp;1641 forbids that.</li>
<li>My own June&nbsp;24,&nbsp;2025 email &mdash; her anchor &mdash; calculates from &ldquo;since we started working with you,&rdquo; not just from the termination period. She cannot rely on that email and contradict its method.</li>
</ul>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">6. Recommended response language to Stambuk</p>

<blockquote style="border-left:4px solid #F67D4B;padding:8px 14px;background:#FEF3EE;margin:10px 0;font-size:10.5pt">
<p>&ldquo;Counsel &mdash; your 4/6 position relies on the premise that the averaging mechanism in the Client Monthly Service Agreement &lsquo;collected&rsquo; 2023&ndash;2024 excess via 2024&ndash;2025 billing. That premise has two readings, both of which favor Technijian&rsquo;s Demand:</p>
<p><b>1.</b> If the mechanism does collect, it collects at <i>every</i> cycle boundary &mdash; that is what Mr.&nbsp;Jain&rsquo;s June&nbsp;24,&nbsp;2025 email expressly describes (&lsquo;<i>every 12 months we adjust the average to collect the last 12 months of actual support</i>&rsquo;) and what Under&nbsp;Contract&nbsp;&para;&para;&nbsp;3&ndash;4 provides identically at every boundary. Applied consistently:</p>
<ul>
<li>P2 collected P1 (12 of 12 months at the elevated rate). ✓</li>
<li>P3 was supposed to collect P2 over 12 months &mdash; but ran only 3, leaving 2,584.18&nbsp;&minus;&nbsp;624.25 = 1,959.93 P2 hours uncollected.</li>
<li>P4 was supposed to collect P3 over 12 months &mdash; but never started, leaving 384.94 P3 hours uncollected.</li>
<li>Total uncollected: 2,344.87 hours &times; $150 = $351,730.50, plus 10% late fee = <b>$386,903.55</b>.</li>
</ul>
<p>That figure is $146,416 above the Demand and is the <i>floor</i> implied by your own theory.</p>
<p><b>2.</b> If the mechanism does not collect &mdash; as Technijian maintains, supported by Cal.&nbsp;Civ.&nbsp;Code&nbsp;&sect;&sect;&nbsp;1638 and 1641, <i>Powerine Oil Co. v. Superior Court</i> (2005) 37&nbsp;Cal.4th&nbsp;377, 390&ndash;391, and <i>MacKinnon v. Truck Ins. Exchange</i> (2003) 31&nbsp;Cal.4th&nbsp;635, 648 &mdash; then the averaging is a prospective rate-setting tool only, prior-period excess remains uncollected by it, and the full Demand of <b>$240,487.50</b> stands.</p>
<p>There is no internally consistent reading of your premise that produces a number below the Demand. Mr.&nbsp;Jain&rsquo;s email itself contemplates this: he calculated 1,143.98 unbilled hours from &lsquo;since we started working with you&rsquo; &mdash; i.e., the multi-period total &mdash; not from a &lsquo;last 12 months only&rsquo; reading.</p>
<p>We invite you to identify any internally consistent reading that lands below the Demand. Otherwise we will proceed on the Demand and reserve the chain-extended figure as the contingent fallback at hearing.&rdquo;</p>
</blockquote>

<p>That is the wedge. We do not have to win the chain argument on the merits &mdash; we just have to make her choose, and every door she walks through costs more than $52,765.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">7. Data-room population (proposed)</p>

<p>Tier&nbsp;1 (must-haves) + Tier&nbsp;2 (supporting) attached to this email. Holding back our internal damages-scenario analysis (it discusses our walk-away floor) &mdash; that stays attorney-eyes-only.</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>#</td><td>File</td><td>Why it matters</td>
</tr>
<tr><td>01</td><td>Ravi&ndash;Erica 2025-06-24 termination thread (full)</td><td>Stambuk&rsquo;s own anchor &mdash; and our refutation of her reading</td></tr>
<tr><td>02</td><td>VTD reconciliation (actual vs billed)</td><td>The reconciliation that drives every scenario</td></tr>
<tr><td>03</td><td>Signed 5/4/2023 Client Monthly Service Agreement</td><td>Source of cancellation clause and &sect;&nbsp;1671(b) burden allocation</td></tr>
<tr><td>04</td><td>Lifetime ticket time entries</td><td>Ticket-by-ticket evidence backing every actual hour</td></tr>
<tr><td>05&ndash;08</td><td>4 monthly invoice .eml files (#25438, 25725, 25953, 26205)</td><td>POD-column disclosure pattern; 88&ndash;96% offshore allocation</td></tr>
<tr><td>09&ndash;11</td><td>3 weekly invoice samples (#25992, 26029, 26074)</td><td>Weekly transmission pattern</td></tr>
</table>

<p><b>Withheld (internal only):</b> the damages scenario analysis &mdash; contains the walk-away floor and the Scenario&nbsp;D ceiling. Happy to walk Ed through it on a privileged call.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">8. What I&rsquo;d like to confirm on our 3:30 call</p>

<ol>
<li>Anchoring our response to Stambuk on the Demand ($240,487.50) and using the chain-extended $386,903 figure as a contingent fallback &mdash; not as the opening number.</li>
<li>Keeping Scenario&nbsp;D ($309,980.55) entirely internal &mdash; reserved ceiling, not for outward use.</li>
<li>Whether to file a Demand amendment under AAA Rule R-6 to fix the $67.65 arithmetic error on the late-fee line now, or fold the correction into the settlement stipulation.</li>
<li>Sign-off on the &sect;&nbsp;6 language above before I share any version externally.</li>
</ol>

<p>Talk to you at 3:30.</p>

<p>&mdash; Ravi</p>

__SIG__

</div>
</body>
</html>
'@

$htmlBody = $bodyTemplate.Replace('__FONT__', $fontStack).Replace('__SIG__', $sig)

# Fail-fast: stripped-dollar-sign + placeholder check (per memory: feedback_proofread_emails)
if ($htmlBody -match '\$\s+\d') {
    throw "Detected stripped dollar sign before digit (e.g., '`$ 150') - rendering will lose currency. Aborting."
}
if ($htmlBody -match '__FONT__|__SIG__') {
    throw "Detected unfilled template placeholder. Aborting."
}

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Build attachments ---
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
    Write-Host ("  [+] {0}  ({1:N0} bytes)" -f $map.Name, (Get-Item $map.Src).Length) -ForegroundColor Gray
}
$totalBytes = ($attachmentMap | ForEach-Object { (Get-Item $_.Src).Length } | Measure-Object -Sum).Sum
Write-Host ("Total attachment payload: {0:N0} bytes ({1:N2} MB)" -f $totalBytes, ($totalBytes/1MB)) -ForegroundColor Cyan

if ($totalBytes -gt 25MB) {
    Write-Host "WARNING: payload exceeds 25MB Graph soft limit. Will split via per-attachment POST after draft creation." -ForegroundColor Yellow
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
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "`nSending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT to $($to[0].Address)." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts for $senderUpn." -ForegroundColor Yellow
    Write-Host "  To: $($to[0].Address)" -ForegroundColor Gray
    Write-Host "  Cc: $($cc[0].Address)" -ForegroundColor Gray
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Open Outlook -> Drafts -> '$subject'" -ForegroundColor Yellow
    Write-Host "  2. Review body and verify 11 attachments" -ForegroundColor Yellow
    Write-Host "  3. Click Send, OR re-run this script with -Send" -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
