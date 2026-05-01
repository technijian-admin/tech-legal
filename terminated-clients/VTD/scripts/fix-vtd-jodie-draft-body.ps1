# Fix the rendering issues in the Jodie draft body:
#  1. The `$0.00` reference for invoice #36128 was stripped because PowerShell -replace
#     interpreted $0 as a regex backreference. Restore explicitly.
#  2. Replace all non-ASCII glyphs with HTML entities so Outlook renders them correctly:
#     em dash, en dash, right arrow, division sign, multiplication sign, minus sign,
#     paragraph mark, Greek delta, smart quotes, ellipsis.
#
# This script does NOT send. It only PATCHes the existing draft body in Outlook Drafts.

$ErrorActionPreference = 'Stop'
$keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$tenantId = ($keys | Select-String -Pattern 'Tenant ID:\*\*\s*([^\s]+)').Matches[0].Groups[1].Value
$clientId = ($keys | Select-String -Pattern 'App Client ID:\*\*\s*([^\s]+)').Matches[0].Groups[1].Value
$clientSecret = ($keys | Select-String -Pattern 'Client Secret:\*\*\s*([^\s]+)').Matches[0].Groups[1].Value
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$cred = New-Object System.Management.Automation.PSCredential($clientId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $cred -NoWelcome

$draftId = 'AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAEQAACgx7VhNWW1QYCgfGa-8kbOAAYGdetVAAA='

# --- Build a clean HTML reply with all non-ASCII as HTML entities ---
# Single-quoted here-string preserves literal $.  ALL special glyphs use named entities.
$replyHtml = @'
<div style="font-family: Aptos, Calibri, Arial, sans-serif; font-size: 11pt; color: #000;">

<p>Jodie,</p>

<p>Thanks for the careful review and for laying out the reconciliation questions clearly. I have completed a full rebuild against the actual emails sent to Erica Garcia from billing@technijian.com over the 27-month service period (May 2023 through July 2025). Below is a detailed walkthrough of the billing logistics, the transmission cadence, and direct answers to each of your questions, with worked examples. Three attachments support the discussion: a per-month reconciliation, a missing-entry analysis, and a draft template Callahan can adapt for transmission to opposing counsel.</p>

<h3 style="margin-bottom: 4px;">1. How the monthly invoice is structured</h3>

<p>The monthly invoice is a hybrid document that bills two different service months at once:</p>

<ul>
  <li><strong>Online-services line items</strong> (AV protection, patch management, secure DNS, my-remote, backup storage, etc.) bill for the <strong>same month the invoice is dated</strong>. Vintage was paying for licenses, RMM agents, and continuous protection in real time.</li>
  <li><strong>Support-hour line items</strong> (OffShore_Support.R, OffShore_Support.R.AF, Tech_Support.R) bill <strong>30 days in advance</strong> for the <strong>following month</strong>. The contract is net-30, so Vintage paid the support charge before the support month began.</li>
</ul>

<p>Worked example:</p>

<blockquote style="border-left: 3px solid #ccc; padding-left: 12px; color: #333;">
The invoice dated June 1, 2024 (transmitted via email on June 2, 2024) covered:
<br>&nbsp;&nbsp;&bull; <strong>June 2024 online services</strong> (AVD, AVMS, MR, PMW, SI, OPS-NET, DKIM, etc.) &mdash; current month
<br>&nbsp;&nbsp;&bull; <strong>July 2024 support hours</strong> (offshore normal, offshore after-hours, onshore normal at the prior cycle&rsquo;s monthly average) &mdash; advance month
<br>Payment was due July 1, 2024 (net-30 from the invoice date).
</blockquote>

<h3 style="margin-bottom: 4px;">2. How the monthly time-entry spreadsheet is structured</h3>

<p>Each monthly invoice email also contained a &ldquo;Monthly Time Entries for [InvoiceID].xlsx&rdquo; attachment. That spreadsheet reports the <strong>actual hours worked during the prior month</strong> &mdash; in arrears. It is a record of what already happened, complementing the forward-looking invoice.</p>

<p>Continuing the same example:</p>

<blockquote style="border-left: 3px solid #ccc; padding-left: 12px; color: #333;">
The June 1, 2024 invoice email (transmitted June 2, 2024) carried a &ldquo;Monthly Time Entries for [&hellip;].xlsx&rdquo; attachment that detailed every ticket time entry recorded for <strong>May 2024 support work</strong>. Each row shows Title, Date Requested, Requestor, Start, End, Normal Qty (column H), After-Hours Qty (column J), and POD (column N: CHD-TS1 = offshore, IRV-TS1 = onshore).
</blockquote>

<p>So in any given monthly email Vintage received: a forward-looking invoice (current-month online + next-month support) plus a backward-looking time-entry record (prior-month actual work).</p>

<h3 style="margin-bottom: 4px;">3. How weekly emails fit in (and why time entries can arrive after the monthly was sent)</h3>

<p>In addition to the monthly cadence, Technijian sent weekly emails. Each weekly email carried a &ldquo;Weekly Time Entries for [InvoiceID].xlsx&rdquo; attachment listing every time entry recorded during that week. These weekly files are an incremental running record of work performed.</p>

<p>An important practical detail: techs sometimes submit a time entry after the monthly cutoff for the prior month has already passed. When that happens, the late entry does not appear on the monthly attachment for the month in which the work was done; it appears on a <strong>subsequent weekly attachment</strong> after the tech logs it. Both the monthly and the follow-on weekly attachments are sent to ericagarcia@vintagedesigninc.com from billing@technijian.com.</p>

<p>For purposes of reconstructing the actual hours worked in any given month, both the monthly and the weekly attachments must be consulted. The reconciliation rebuild attached does exactly that: it walks every monthly and weekly Time Entries xlsx attachment, deduplicates by ticket title plus start time, and aggregates per service month.</p>

<h3 style="margin-bottom: 4px;">4. What is and is not part of the cancellation-fee reconciliation</h3>

<p>Several categories of work appear on the time-entry spreadsheets but are <strong>not</strong> within the scope of the Client Monthly Service Agreement&rsquo;s under-contract billing or the cancellation-fee calculation:</p>

<ul>
  <li><strong>Onsite tech-support visits.</strong> Onsite work (Corona office visits, server moves, phone setups, hardware deployments) is billed separately as out-of-contract hourly work. Before April 2024, Technijian transmitted out-of-contract hours combined onto the regular weekly invoice. From April 2024 onward, out-of-contract work was sent on dedicated &ldquo;Weekly Out of Contract Invoice&rdquo; emails. Either way, these onsite hours are tagged Contract = &ldquo;Hourly&rdquo; on the time-entry spreadsheet (rather than &ldquo;Under Contract&rdquo;) and are excluded from the under-contract reconciliation.</li>
  <li><strong>Discrete projects with their own invoices</strong> &mdash; for example, the RA-02 server migration project that ran in August and September 2024. Project work is invoiced as an Invoice-type ticket bundle, separately from the monthly service contract. These hours appear in our time-tracking system but are not part of the under-contract monthly cycle.</li>
  <li><strong>System-auto-generated alert tickets</strong> &mdash; Veeam backup-failure alerts, Network Detective audit-baseline checks, Passportal sync alerts. These are programmatically created tickets that close in seconds; they roll into the monthly invoice totals but are filtered by the time-entry spreadsheet generator.</li>
</ul>

<p>The reconciliation rebuild and the cancellation-fee math include only Contract = &ldquo;Under Contract&rdquo; line items, which is the correct scope for paragraph 5 of the Client Monthly Service Agreement (the cancellation fee), distinct from the operational averaging adjustment in paragraphs 3 and 4 explained in section 6 below.</p>

<h3 style="margin-bottom: 4px;">5. The first-month exception (May 2023 and June 2023)</h3>

<p>The advance-billing pattern depends on having a prior under-contract period to anchor the next-month support charge. At the start of the relationship there was no prior period, so the first two months were handled differently:</p>

<ul>
  <li><strong>The May 2023 invoice</strong> (#36127, $6,902.00) was issued before May 1, 2023 so Vintage could pay by May 1 for May current-month services (both online services and support hours). This is the only invoice in the entire relationship that bills support hours for the same month it is dated.</li>
  <li><strong>The June 2023 invoice</strong> (#36128, $0.00 in the register) was also issued upfront alongside the May bill. Vintage prepaid the June service before May 1. After the prepayment was applied, the register shows the line items zeroed out. The companion entry on the same date (#36372 at $7,551.50) is the canonical billing record once the standard advance-billing pattern began.</li>
  <li><strong>From early June 2023 onward</strong>, the standard pattern took effect: the June 1, 2023 invoice email (transmitted June 2) carried both the advance billing for July 2023 services AND the time-entry attachment reporting May 2023 actuals (the first under-contract reporting month).</li>
</ul>

<h3 style="margin-bottom: 4px;">6. How the averaging adjustment in paragraphs 3 and 4 actually works</h3>

<p>The signed Client Monthly Service Agreement at Under Contract paragraphs 3 and 4 reads:</p>

<blockquote style="border-left: 3px solid #ccc; padding-left: 12px; color: #333;">
&ldquo;The first month of the new average will be charged at the previous average since that invoice will be due the first of the month.&rdquo;
<br><br>&ldquo;If the average goes down a credit will be given on the next month&rsquo;s invoice. If the average goes up an extra charge will be given on the next month&rsquo;s invoice.&rdquo;
</blockquote>

<p>These two paragraphs describe an <strong>operational placeholder-and-reconciliation mechanism</strong>, not a collection-of-unpaid-hours mechanism. The reason this mechanism exists is the 30-day advance-billing convention described in section 1 above.</p>

<p>When a 12-month under-contract cycle is about to close, Technijian must already issue the first invoice for the next cycle 30 days in advance. At that point the prior cycle is still in its final month &mdash; the actual hours for the 12th month have not yet been logged. The new monthly average can therefore only be computed from the first <strong>11 months (N minus 1)</strong> of actual data.</p>

<p>The first invoice of the new cycle is consequently charged at the <strong>previous cycle&rsquo;s average</strong> (paragraph 3) as a placeholder, because the new cycle&rsquo;s true 12-month average is not yet computable.</p>

<p>Once the 12th month closes and the full prior-period actuals are known, the true new average is calculated. The difference between the placeholder rate (used for the first month of the new cycle) and the true new average is then reconciled on the <strong>next month&rsquo;s invoice via a one-time adjustment line item</strong> (paragraph 4):</p>

<ul>
  <li>If the <strong>new average is higher</strong> than the placeholder, an <strong>extra charge</strong> is added to that next invoice as an adjustment line.</li>
  <li>If the <strong>new average is lower</strong>, a <strong>credit</strong> is applied on that next invoice.</li>
</ul>

<p>This adjustment is purely a smoothing mechanism for the cycle transition. It corrects for the operational reality that the new cycle&rsquo;s first month was billed at the old rate before the new rate could be computed. It does <strong>not</strong> retroactively collect unpaid hours from the prior period, and it has nothing to do with the cancellation fee in paragraph 5.</p>

<p>Worked example:</p>

<blockquote style="border-left: 3px solid #ccc; padding-left: 12px; color: #333;">
Period 1 ran May 2023 through April 2024. The first invoice of Period 2 had to be issued before April 2024&rsquo;s actuals were finalized. The new monthly average was therefore computed from the first 11 months of Period 1 (May 2023 through March 2024). The first month of Period 2 was charged at the prior cycle&rsquo;s rate as a placeholder. After April 2024 closed and the full Period 1 average was finalized, the next monthly invoice carried a one-time adjustment line reconciling the difference between the placeholder rate and the true Period 1 average. The adjustment is settled on a single invoice, on a single line item, and applies to a single month.
</blockquote>

<p>Stambuk&rsquo;s April 6, 2026 letter reads paragraph 4 (&ldquo;if the average goes up an extra charge will be given on the next month&rsquo;s invoice&rdquo;) as evidence that the averaging mechanism is the vehicle by which Technijian &ldquo;collects&rdquo; prior-period excess hours. That reading is mechanically wrong. The &ldquo;extra charge&rdquo; in paragraph 4 is a one-time placeholder-to-true-average reconciliation, applied to a single month, settled on the very next invoice. It is not a 12-month elevated rate that &ldquo;collects&rdquo; prior unbilled hours over the following year. The cancellation fee in paragraph 5 (&ldquo;any hours that exceeded the previous under contract period average&rdquo;) is the separate, distinct mechanism that addresses unbilled actual hours at termination.</p>

<h3 style="margin-bottom: 4px;">7. Direct answers to your questions</h3>

<p><strong>(a) The reconciliation gap with the prior summary.</strong> The summary I provided before captured the right numbers, but my first-pass rebuild against the email pipeline alone was incomplete because it walked only the monthly attachments. When the monthly and weekly Under-Contract entries are aggregated together and deduplicated, the period totals reconcile within a few hours of the prior summary at every period:</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; font-size: 10pt;">
  <thead>
    <tr style="background-color: #f2f2f2;">
      <th align="left">Period</th>
      <th align="right">Prior Summary (hrs)</th>
      <th align="right">Rebuilt monthly + weekly (hrs)</th>
      <th align="right">Diff</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>P1 (May 2023 &ndash; Apr 2024)</td><td align="right">1,970.97</td><td align="right">1,990.79</td><td align="right">+19.82</td></tr>
    <tr><td>P2 (May 2024 &ndash; Apr 2025)</td><td align="right">2,584.18</td><td align="right">2,665.69</td><td align="right">+81.51</td></tr>
    <tr><td>P3 (May 2025 &ndash; Jul 2025, terminated)</td><td align="right">384.94</td><td align="right">388.36</td><td align="right">+3.42</td></tr>
  </tbody>
</table>

<p>The specific May 2023 anomaly you flagged (&ldquo;the Excel summary shows only 2.75 hours&rdquo; of onshore Tech Services) was a consequence of that first-pass exclusion. With the rebuild, May 2023 onshore (Tech_Support.R) actuals are 33.72 hours, drawn from the time-entry xlsx attached to the June 2, 2023 monthly invoice email &mdash; the first arrears reporting month, consistent with the convention.</p>

<p><strong>(b) June 2023 duplicate (Portal #4254 / #4255 vs. #4442).</strong> The canonical June 2023 invoice in the production set is the one transmitted June 2, 2023 (Portal #4442, register #36372 at $7,551.50). The earlier May 9, 2023 batch (Portal #4253, #4254, #4255) carried the prepaid May and June bills upfront under the first-month exception described above. Use #4442 as the canonical June 2023 monthly; the earlier prepaid records are not needed in the production set.</p>

<p><strong>(c) August 2025 invoice #26205 (register #43406, $10,530.70).</strong> Termination was effective July 31, 2025. This invoice, dated August 1, 2025, would have advance-billed September 2025 support and current-month August 2025 online services &mdash; neither service month was ever performed. The invoice should not have been issued. It should be excluded from the production set, and we will void it in our billing system.</p>

<p><strong>(d) Descriptive narrative for Vintage.</strong> A clearer version of the read-along, accounting for both the dual-period invoice content and the late-submission pattern:</p>

<blockquote style="border-left: 3px solid #ccc; padding-left: 12px; color: #333;">
Under the Client Monthly Service Agreement, Vintage Design was billed on a hybrid cycle. Each monthly invoice covered two service months simultaneously: the online-services line items (AV protection, patch management, etc.) charged for the same month the invoice was dated; the support-hour line items charged 30 days in advance for the following month. Net-30 payment terms applied throughout. The May 2023 and June 2023 invoices were the only exceptions: those were issued upfront before May 1, 2023 to be paid by May 1 and June 1 respectively, before any prior period existed against which to compute an advance.
<br><br>Each monthly invoice email also included a &ldquo;Monthly Time Entries&rdquo; spreadsheet detailing the actual hours of support work performed during the prior month. Time entries logged by techs after the monthly cutoff appear on subsequent weekly time-entry spreadsheets, also transmitted to Vintage Design.
<br><br>Tech Services categorize as: Offshore Support normal hours (CHD-TS1:Support:N/Remote, item code OffShore_Support.R, columns H + N on the spreadsheet); Offshore Support after-hours (CHD-TS1:Support:AH/Remote, OffShore_Support.R.AF, columns J + N); Onshore Tech Support normal hours (IRV-TS1:Support:N/Remote, Tech_Support.R, columns H + N).
<br><br>Following each completed 12-month under-contract period, the monthly billed quantity for the next cycle was computed from the prior period&rsquo;s actual monthly average. Onsite tech-support visits and discrete project work are not part of this monthly cycle; they were billed separately and appear on weekly out-of-contract or project invoices.
</blockquote>

<h3 style="margin-bottom: 4px;">8. Cancellation-fee math &mdash; two framings</h3>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; font-size: 10pt;">
  <thead>
    <tr style="background-color: #f2f2f2;">
      <th align="left">Method</th>
      <th align="right">Hours</th>
      <th align="right">at $150/hr</th>
      <th align="right">+ 10% late</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Cycle-as-mechanism: (P2 actual + P3 actual) minus P3 billed</td><td align="right">2,472.02</td><td align="right">$370,803.00</td><td align="right">$407,883.30</td></tr>
    <tr><td>Inception-to-termination unbilled (with first-month adjustment)</td><td align="right">1,567.88</td><td align="right">$235,182.00</td><td align="right">$258,700.20</td></tr>
    <tr><td>Demand on record (filed October 23, 2025)</td><td align="right">&mdash;</td><td align="right">&mdash;</td><td align="right">$240,487.50</td></tr>
  </tbody>
</table>

<p>The $240,487.50 Demand sits comfortably within the inception-to-termination unbilled range. The cycle-as-mechanism figure is the contingent fallback if Stambuk presses her cycle-mechanism premise &mdash; that produces over $146,000 above the Demand under symmetric application of her own theory.</p>

<h3 style="margin-bottom: 4px;">9. Averaging math &mdash; favorable to us</h3>

<p>One finding from the rebuild that strengthens our position: at both cycle boundaries, the actual billing system applied the averaging mechanism <strong>below</strong> the contract rate, not above it.</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse: collapse; font-size: 10pt;">
  <thead>
    <tr style="background-color: #f2f2f2;">
      <th align="left">Boundary</th>
      <th align="left">Category</th>
      <th align="right">Prior actual avg / 12</th>
      <th align="right">Next monthly billed</th>
      <th align="right">Diff</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>P1 to P2</td><td>OffShore Normal</td><td align="right">81.86</td><td align="right">76.77</td><td align="right">-5.10</td></tr>
    <tr><td>P1 to P2</td><td>OffShore After-Hours</td><td align="right">62.56</td><td align="right">64.48</td><td align="right">+1.92</td></tr>
    <tr><td>P1 to P2</td><td>Tech Support</td><td align="right">21.47</td><td align="right">20.00</td><td align="right">-1.47</td></tr>
    <tr><td>P2 to P3</td><td>OffShore Normal</td><td align="right">114.87</td><td align="right">96.35</td><td align="right">-18.52</td></tr>
    <tr><td>P2 to P3</td><td>OffShore After-Hours</td><td align="right">91.60</td><td align="right">77.66</td><td align="right">-13.94</td></tr>
    <tr><td>P2 to P3</td><td>Tech Support</td><td align="right">15.68</td><td align="right">20.00</td><td align="right">+4.33</td></tr>
  </tbody>
</table>

<p>Stambuk&rsquo;s premise is that the averaging mechanism in paragraphs 3 and 4 &ldquo;fully collected&rdquo; Period 1&rsquo;s excess via Period 2&rsquo;s elevated billing rate. The data shows Period 2&rsquo;s monthly billed quantity for offshore support was actually below Period 1&rsquo;s actual monthly average. The averaging under-billed Vintage Design relative to the contract math, so the &ldquo;fully collected&rdquo; theory does not survive contact with the data.</p>

<h3 style="margin-bottom: 4px;">10. Spreadsheet completeness</h3>

<p>Across the 27-month service period, our time-tracking system records 5,029.51 in-scope under-contract hours. Of those:</p>

<ul>
  <li><strong>4,920.56 hours (97.8%)</strong> are itemized on a time-entry spreadsheet that was transmitted to Vintage Design &mdash; either a Monthly Time Entries attachment or a Weekly Time Entries attachment, including the late-submission entries that fell on a follow-on weekly.</li>
  <li><strong>108.95 hours appeared, on first cut, to be unitemized.</strong> When I broadened the search to include weekly attachments with &ldquo;Hourly&rdquo; Contract entries (the pre-April 2024 combined-weekly format) and the dedicated Out-of-Contract weeklies, 93.00 of those hours were recovered &mdash; almost entirely onsite tech-support work by Kraig Stickel and Hamid Yaghoubi, billed via the OOC channel.</li>
  <li><strong>15.95 hours across 23 entries (0.32% of the global total)</strong> are not separately itemized on any time-entry spreadsheet. Of those: 7.51 hours across 8 entries are the RA-02 Migration project (separately invoiced as a project ticket bundle); 8.44 hours across 15 entries are system-auto-generated alert tickets (Veeam backup-failure alerts, Network Detective audit-baseline checks, Passportal sync alerts) that close in seconds and roll into the monthly invoice totals rather than being separately itemized.</li>
</ul>

<p>The 23 unitemized entries are listed in detail in attachment 2.</p>

<h3 style="margin-bottom: 4px;">11. Attachments</h3>

<ul>
  <li><strong>VTD_Actual_vs_Billed_Reconciliation.xlsx</strong> &mdash; six sheets covering per-month reconciliation (billed vs. actual by category); period totals (P1, P2, P3); averaging validation; canonical billed source (from the invoice register); email-actual source (from the time-entry attachments); and the voided-register-IDs list.</li>
  <li><strong>VTD_Missing_Entries_Detail.xlsx</strong> &mdash; three sheets: per-month spreadsheet-coverage summary; the 23 unitemized entries with full ticket detail; and the 1,278 entries that were on weekly attachments only (the late-submission category, illustrating how the monthly + weekly transmission pattern works in practice).</li>
  <li><strong>Stambuk_Response_Template_2026-04-30.docx</strong> &mdash; a draft template Callahan can adapt and transmit to opposing counsel (Stambuk and Barnum at Baker &amp; Hostetler). Details in section 11 below.</li>
</ul>

<h3 style="margin-bottom: 4px;">12. Draft language for the Stambuk transmission</h3>

<p>I have also drafted suggested language for Callahan to adapt when transmitting the reconciliation to opposing counsel. The draft is in <strong>Stambuk_Response_Template_2026-04-30.docx</strong>. It is structured to:</p>

<ul>
  <li>Lead with the inception-to-termination unbilled at $235,182.00 (with 10% late = $258,700.20), anchored at the $240,487.50 Demand on record.</li>
  <li>Address the April 6, 2026 averaging argument by surfacing the under-billing finding from section 9 above &mdash; the data shows the averaging mechanism applied below the contract rate, defeating the &ldquo;fully collected&rdquo; theory.</li>
  <li>Dispose of the August 2025 invoice issue by acknowledging it should not have been issued and confirming we are voiding it.</li>
  <li>Reference the ShareFile production set as the basis for the documents-of-record analysis.</li>
  <li>Hold the cycle-as-mechanism / chain-trap analysis from the April 28&ndash;29 briefings <strong>in reserve</strong> as a contingent fallback &mdash; it is intentionally not deployed in the draft. If Stambuk presses her cycle-mechanism premise after seeing the under-billing finding, the chain-trap is the next move.</li>
</ul>

<p>Internal-only notes at the bottom of the document flag what should not transmit (Scenario D ceiling, walk-away floor, Jenna Griffin concession question, R-6 conformation pending). Edit and transmit at Callahan&rsquo;s discretion.</p>

<p>Happy to walk through any of this on a call if helpful before we package it for production.</p>

<p>Best,<br>Ravi Jain<br>CEO, Technijian</p>
</div>
'@

# Sanity: confirm currency literals preserved
$dollarHits = ([regex]::Matches($replyHtml, '\$\d|\$\d')).Count
"Dollar refs in body: $dollarHits"
if ($dollarHits -lt 12) { throw "ABORT: dollar count too low ($dollarHits)" }

# Confirm no raw non-ASCII glyphs that Outlook may misrender
$nonAscii = [regex]::Matches($replyHtml, '[^\x00-\x7F]')
"Non-ASCII glyph count in HTML: $($nonAscii.Count)"
if ($nonAscii.Count -gt 0) {
    "  Sample non-ASCII chars: $((($nonAscii | Select-Object -First 10) | ForEach-Object { '[U+' + ([int][char]$_.Value).ToString('X4') + ']' }) -join ' ')"
}

# Get current draft body and replace OUR portion (everything before the quoted original) with the new HTML
$msg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/messages/$draftId"
$existingBody = $msg.body.content

# The existing draft has structure: <html>...<body><div>OUR REPLY</div><div id="appendonsend"></div>QUOTED-ORIGINAL...</body></html>
# Find the marker between our reply and the quoted original.
$marker = '<div id="appendonsend"'
$idx = $existingBody.IndexOf($marker)
if ($idx -lt 0) {
    # Fallback: try other markers
    foreach ($m in @('<hr','<div class="OutlookMessageHeader"','From:</b>','From: ')) {
        $idx2 = $existingBody.IndexOf($m)
        if ($idx2 -gt 0) { $idx = $idx2; $marker = $m; break }
    }
}
if ($idx -lt 0) { throw "Could not find boundary between reply and quoted original" }
"Boundary marker '$marker' found at idx $idx"

# Find the body start position so we preserve <html><head><body>
$bodyOpenIdx = $existingBody.IndexOf('<body')
$bodyOpenEnd = $existingBody.IndexOf('>', $bodyOpenIdx) + 1

# Construct new full body: html-head + body open tag + new reply + quoted-original + closing tags
$prefix = $existingBody.Substring(0, $bodyOpenEnd)         # <html><head>...</head><body...>
$suffix = $existingBody.Substring($idx)                    # quoted original onward

$newBody = $prefix + "`n" + $replyHtml + "`n" + $suffix

# Sanity: verify currency restored
if ($newBody -notmatch '\$0\.00' -and $newBody -notmatch '$0\.00') {
    throw "ABORT: $0.00 reference missing from final body"
}

# PATCH the body
$patchObj = @{ body = @{ contentType = 'HTML'; content = $newBody } } | ConvertTo-Json -Depth 10 -Compress
Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/messages/$draftId" -Body $patchObj -ContentType 'application/json' | Out-Null
"Body patched."

# Verify
Start-Sleep -Seconds 2
$verify = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/messages/$draftId`?`$select=subject,toRecipients,ccRecipients,isDraft,hasAttachments,bodyPreview,webLink"
"--- Final draft state ---"
"  isDraft:        $($verify.isDraft)"
"  Subject:        $($verify.subject)"
"  To:             $((($verify.toRecipients | ForEach-Object { $_.emailAddress.address }) -join '; '))"
"  Cc:             $((($verify.ccRecipients | ForEach-Object { $_.emailAddress.address }) -join '; '))"
"  HasAttachments: $($verify.hasAttachments)"
"  Preview (first 200 chars): $($verify.bodyPreview.Substring(0, [Math]::Min(200, $verify.bodyPreview.Length)))"

# Spot-check that $0.00 is in the body now
$msg2 = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/messages/$draftId"
if ($msg2.body.content -match '\$0\.00' -or $msg2.body.content -match '$0\.00') {
    "  `$0.00 reference: PRESENT (PASSES)"
} else {
    "  `$0.00 reference: MISSING (FAIL)"
}
$specials = [regex]::Matches($msg2.body.content.Substring(0, [Math]::Min(15000, $msg2.body.content.Length)), '[^\x00-\x7F]')
"  Non-ASCII glyphs in our reply portion: $($specials.Count)"
