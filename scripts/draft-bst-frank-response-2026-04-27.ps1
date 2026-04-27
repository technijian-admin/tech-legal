# Draft response to Frank Dunn's 4/27 questions on BST cancellation methodology
# Attaches: signed MSA, damages analysis (privileged), source spreadsheet, invoice #28064
# Creates draft only - review in Outlook before sending.

$ErrorActionPreference = "Stop"

$toEmail    = "fdunn@callahan-law.com"
$toName     = "Franklin T. Dunn, Esq."
$ccList     = @(
    @{ EmailAddress = @{ Address = "es@callahan-law.com"; Name = "Edward Susolik, Esq." } }
)
$senderUpn  = "RJain@technijian.com"
$subject    = "RE: BST (Boston Group) -- Calculation Methodology, Signed Agreement, and Answers to Your Questions"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$bstDir     = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST"
$attachments = @(
    "$bstDir\exhibits\Boston_Group-Monthly_Service-signed.pdf",
    "$bstDir\deliverables\BST_Damages_Scenario_Analysis_INTERNAL.docx",
    "$bstDir\exhibits\bst_actualvsbillable.xlsx",
    "$bstDir\emails\_attachments\2026-04-03_1553_Boston+Group-28064-Invoice-Service+Cancellation.pdf"
)

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Validate attachments exist ---
Write-Host "Validating attachments..." -ForegroundColor Cyan
foreach ($f in $attachments) {
    if (-not (Test-Path $f)) { Write-Error "Missing: $f"; exit 1 }
    $sz = [math]::Round((Get-Item $f).Length / 1KB, 1)
    Write-Host "  OK  $([System.IO.Path]::GetFileName($f))  ($sz KB)" -ForegroundColor Gray
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
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Frank,</p>

<p>Thank you for the quick read on the file and for reaching out to Mr. Cron today. Below are answers to your questions and the supporting documents are attached. Ed is on copy.</p>

<p><strong>One factual correction up front on the contract term -- this matters.</strong></p>

<p>The Service Agreement <strong>does not state a fixed term</strong>. I want to flag this clearly because it is load-bearing for the cancellation-fee analysis:</p>

<ul>
  <li>&sect;&nbsp;4.01 says: "The initial term of this Agreement shall be as set forth on the monthly Service agreement or invoice." -- but the monthly service agreement page does not specify a term length anywhere.</li>
  <li>"Other Terms" &para; 1 on the Agreement page says only: "This service agreement shall start after it is signed and dated." No end date. No renewal language.</li>
  <li>&sect;&nbsp;4.05 governs voluntary termination on 30 days' notice (the section BST invoked).</li>
  <li>The "<strong>12 Months</strong>" reference under the "Under Contract" section is the <strong>billing-cycle baseline-reset mechanism</strong> (i.e., re-average the consumption-based baseline every 12 months), not the agreement term itself.</li>
</ul>

<p>Practical effect: the Agreement was effectively <strong>month-to-month, auto-renewing</strong> under &sect;&nbsp;4.05 from 2023-05-01 forward. BST was on service for 36 months only because they did not terminate earlier. We had three 12-month under-contract billing cycles by virtue of duration, but no contractual "36-month term."</p>

<p>Why this matters for your read on the methodology: under the natural textual reading of Section 5 of "Under Contract," "<em>the previous under contract period average</em>" most naturally refers to the immediately preceding 12-month cycle's average -- the same baseline that was being billed in the current (termination) cycle. That is the Method D read, and under Method D, the Cycle-3 cancellation fee = `$0 (Cycle 3 actuals ran below baseline every month, every role). I want you to have this candidly before the Cron call -- it is the single biggest hurdle on the cancellation-fee number.</p>

<p><strong>Confirming your understanding (with the term correction):</strong></p>

<ul>
  <li>BST gave 30-day written notice 2026-03-17, effective 2026-04-30 (per &sect;&nbsp;4.05). &#10003;</li>
  <li>Open invoices total <strong>`$12,443.95</strong> (the four monthlies you listed). &#10003;</li>
  <li>Cancellation Fee under "UNDER CONTRACT" Section 5 -- language is exactly as you quoted. &#10003;</li>
  <li>Invoice #28064 issued 2026-03-30 for <strong>`$126,442.50</strong>. &#10003;</li>
  <li>Settlement structure I have offered: <strong>`$12,443.95 (monthlies in full) + `$15,045.00 (cancellation compromise) = `$27,488.95 total by 4/30 COB</strong>. Late fees on the two overdue March invoices (#27890, #27949) are <em>not</em> being waived -- the standing concession is on the cancellation fee only. Per my 4/24 email to Jeff, I have also stated that if invoice #28064 is unpaid by 4/30, the 10% late fee (<strong>`$12,644.25</strong>) attaches 5/1 and will not be waived. &#10003;</li>
</ul>

<p><strong>Q1 / Q2: Documentation showing how `$126,442.50 was calculated; is it contract-inception-to-date?</strong></p>

<p>Yes -- <strong>`$126,442.50 is a contract-inception-to-date figure</strong>, calculated on a per-row overage basis (Method A in the analysis):</p>

<ul>
  <li><strong>842.95 hours x `$150/hr = `$126,442.50</strong> -- the figure stated in my 3/19 email to Jeff and used on invoice #28064.</li>
  <li><strong>931.62 hours x `$150/hr = `$139,743.00</strong> -- a fresh recalc from the spreadsheet. There is an unreconciled <strong>88.67-hour delta</strong> between the invoiced figure and the recalc. We should lock down a single defensible number before any formal demand. I flag this internally as an open item.</li>
</ul>

<p><strong>Source documents (attached):</strong></p>
<ol>
  <li><strong>Boston_Group-Monthly_Service-signed.pdf</strong> -- the signed Service Agreement (DocuSign FC626837-AEED-442F-9961-A81502402FC4)</li>
  <li><strong>BST_Damages_Scenario_Analysis_INTERNAL.docx</strong> -- privileged work product / for your eyes only. 5 methodology breakdown, role-by-role hours, Cycle-3 weakness candidly flagged. <em>Not for transmission to opposing party or counsel.</em></li>
  <li><strong>bst_actualvsbillable.xlsx</strong> -- source hours data (3 under-contract role rows x 36 months actual vs billable, with the baseline-reset pattern visible)</li>
  <li><strong>Invoice #28064 (Service Cancellation)</strong> -- the issued `$126,442.50 invoice</li>
</ol>

<p><strong>Q3: Calculation following your specific methodology (i-v).</strong></p>

<p>One factual note up front: BST's contracted under-contract roles are <strong>three</strong>, not four. The "four types" framing in your email maps to:</p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Role (per signed MSA POD spec)</th><th style="text-align:center">Under contract?</th><th style="text-align:left">Rate</th></tr>
</thead>
<tbody>
<tr><td>CHD-TS1 OS Support (Normal, offshore)</td><td style="text-align:center"><strong>YES</strong></td><td>`$15/hr</td></tr>
<tr><td>CHD-TS1 OS Support.AH (After-Hours, offshore)</td><td style="text-align:center"><strong>YES</strong></td><td>`$30/hr</td></tr>
<tr><td>IRV-TS1 Tech Support (Normal, onshore)</td><td style="text-align:center"><strong>YES</strong></td><td>`$125/hr</td></tr>
<tr><td>IRV-AD1 Systems Architect</td><td style="text-align:center">No (scheduled)</td><td>`$200/hr per occurrence</td></tr>
</tbody>
</table>

<p>Systems Architect time was billed separately throughout the term and is NOT part of the cancellation-fee math. The cancellation fee is computed on the three under-contract roles.</p>

<p><strong>i. When did the Current Under Contract Period begin?</strong> May 1, 2025 (Cycle 3 of three; 5/2025 - 4/2026 is the termination cycle).</p>

<p><strong>ii. Prior average usage of each support type for the Previous Under Contract Period (Cycle 2, 5/2024 - 4/2025):</strong></p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Role</th><th style="text-align:right">Cycle 2 baseline (hrs/mo)</th></tr>
</thead>
<tbody>
<tr><td>CHD-TS1 OS Support (Normal)</td><td style="text-align:right">56.59</td></tr>
<tr><td>CHD-TS1 OS Support.AH</td><td style="text-align:right">33.70</td></tr>
<tr><td>IRV-TS1 Tech Support (Normal)</td><td style="text-align:right">12.56</td></tr>
</tbody>
</table>

<p>These baselines became the billable rate used for Cycle 3 monthly invoices, per Section 5 paragraph 3 ("The first month of the new average will be charged at the previous average").</p>

<p><strong>iii. Actual usage for each role during the Current Under Contract Period (Cycle 3, monthly):</strong></p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Month</th><th style="text-align:right">CHD-TS1 N</th><th style="text-align:right">CHD-TS1 AH</th><th style="text-align:right">IRV-TS1 N</th></tr>
</thead>
<tbody>
<tr><td>5/2025</td><td style="text-align:right">40.51</td><td style="text-align:right">12.73</td><td style="text-align:right">2.50</td></tr>
<tr><td>6/2025</td><td style="text-align:right">36.12</td><td style="text-align:right">16.34</td><td style="text-align:right">4.25</td></tr>
<tr><td>7/2025</td><td style="text-align:right">34.36</td><td style="text-align:right">13.93</td><td style="text-align:right">1.00</td></tr>
<tr><td>8/2025</td><td style="text-align:right">14.95</td><td style="text-align:right">14.01</td><td style="text-align:right">8.00</td></tr>
<tr><td>9/2025</td><td style="text-align:right">14.96</td><td style="text-align:right">5.36</td><td style="text-align:right">1.50</td></tr>
<tr><td>10/2025</td><td style="text-align:right">9.97</td><td style="text-align:right">4.50</td><td style="text-align:right">11.25</td></tr>
<tr><td>11/2025</td><td style="text-align:right">17.82</td><td style="text-align:right">6.08</td><td style="text-align:right">2.00</td></tr>
<tr><td>12/2025</td><td style="text-align:right">29.91</td><td style="text-align:right">5.35</td><td style="text-align:right">0.50</td></tr>
<tr><td>1/2026</td><td style="text-align:right">25.05</td><td style="text-align:right">16.50</td><td style="text-align:right">1.00</td></tr>
<tr><td>2/2026</td><td style="text-align:right">28.22</td><td style="text-align:right">8.99</td><td style="text-align:right">0.00</td></tr>
<tr><td>3/2026</td><td style="text-align:right">9.00</td><td style="text-align:right">4.50</td><td style="text-align:right">0.00</td></tr>
<tr style="background-color:#f3f3f3;font-weight:bold"><td>Cycle 3 Total (11 mo)</td><td style="text-align:right">260.87</td><td style="text-align:right">108.29</td><td style="text-align:right">32.00</td></tr>
</tbody>
</table>

<p><strong>iv. What we charged BST each month during Cycle 3:</strong> Each Cycle-3 monthly invoice billed the Cycle-2 average per-role baseline -- 56.59 + 33.70 + 12.56 = <strong>102.85 hours total per month</strong>, at the corresponding role rates. So Cycle 3 billable totals (11 months):</p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Role</th><th style="text-align:right">Baseline x 11 mo (Billable)</th></tr>
</thead>
<tbody>
<tr><td>CHD-TS1 OS Support (Normal)</td><td style="text-align:right">622.49</td></tr>
<tr><td>CHD-TS1 OS Support.AH</td><td style="text-align:right">370.70</td></tr>
<tr><td>IRV-TS1 Tech Support (Normal)</td><td style="text-align:right">138.16</td></tr>
<tr style="background-color:#f3f3f3;font-weight:bold"><td>Total</td><td style="text-align:right">1,131.35</td></tr>
</tbody>
</table>

<p><strong>v. Difference between actual and billable for Cycle 3 (= cancellation fee under your Q3.b methodology):</strong></p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Role</th><th style="text-align:right">Cycle 3 Actual</th><th style="text-align:right">Cycle 3 Billable</th><th style="text-align:right">Net Cycle 3</th></tr>
</thead>
<tbody>
<tr><td>CHD-TS1 N</td><td style="text-align:right">260.87</td><td style="text-align:right">622.49</td><td style="text-align:right;color:darkred"><strong>-361.62</strong></td></tr>
<tr><td>CHD-TS1 AH</td><td style="text-align:right">108.29</td><td style="text-align:right">370.70</td><td style="text-align:right;color:darkred"><strong>-262.41</strong></td></tr>
<tr><td>IRV-TS1 N</td><td style="text-align:right">32.00</td><td style="text-align:right">138.16</td><td style="text-align:right;color:darkred"><strong>-106.16</strong></td></tr>
<tr style="background-color:#f3f3f3;font-weight:bold"><td>Total</td><td style="text-align:right">401.16</td><td style="text-align:right">1,131.35</td><td style="text-align:right;color:darkred"><strong>-730.19</strong></td></tr>
</tbody>
</table>

<p><strong>Under your termination-cycle-only methodology, the cancellation fee would be `$0</strong> -- Cycle 3 actuals ran below baseline every month for all three roles. This is the "Method D" weakness flagged candidly in the analysis (&sect;&nbsp;6.4). It is exactly the position Mr. Cron is likely to advance, and is precisely why the language clarification you proposed below is so important.</p>

<p><strong>Why we invoiced `$126,442.50 anyway.</strong> Section 5 says "any hours that exceeded <em>the previous under contract period average</em>" -- and we read "previous" to encompass the life of the contract (Cycles 1 + 2 cumulatively against their billable baselines), not just the current termination cycle. Under that life-of-contract per-row reading (Method A), summing max(0, Actual - Billable) across all 36 months and three roles totals 842.95 hours = `$126,442.50. The detailed walk-through is in the attached damages analysis at &sect;&sect;&nbsp;3-4.</p>

<p><strong>Q4: Basis for the `$15,045 settlement number.</strong></p>

<p>The `$15,045 is a <strong>goodwill compromise number</strong>, not a cleanly-derived contractual entitlement:</p>

<ul>
  <li><strong>100.30 hours x `$150/hr = `$15,045.00</strong></li>
  <li>Derived as a further concession on top of "Method C" (life-of-contract <em>net</em> = 134.84 hrs / `$20,226), which itself allows BST's negative-consumption months -- especially IRV-TS1, which ran 108+ hrs <em>under</em> baseline life-of-contract -- to fully offset positive overage months</li>
  <li>Method C is not authorized by the clause text (the clause says "any hours that exceeded" -- not net) but I offered it on 3/23 as a fast-resolution settlement number to avoid a fight</li>
  <li>I have <strong>not</strong> presented a detailed schedule for the `$15,045 to BST -- only a high-level "life-of-contract net overage" framing in the 3/23 email -- because it was offered as a compromise, not a contractual entitlement, and I did not want to lock us into the methodology if it gets rejected</li>
</ul>

<p>If Mr. Cron asks how we got there, the cleanest answer is "compromise figure giving BST credit for its life-of-contract negative net consumption, offered without prejudice and open through 4/30." We should not represent the `$15,045 as a clean arithmetic derivation.</p>

<p><strong>Q5: Weekly invoices supporting `$126,442.50.</strong></p>

<p>Acknowledged -- I will NOT pull and forward the full weekly-invoice production set unless the matter does not settle by 4/30. There are roughly 150 weekly invoices over 36 months, each accompanied by a per-ticket time-entry spreadsheet that shows offshore vs. onshore allocation. Summary: every weekly and every monthly invoice for the full term carried ticketing-level transparency, and Section 3.01 of the Agreement provides a 30-day dispute window on weeklies / 60-day on monthlies. <strong>BST filed zero timely disputes across the entire 36-month term.</strong> If Mr. Cron pushes the records-quality angle, that course-of-dealing posture is our response.</p>

<p><strong>Your suggested clause clarification.</strong></p>

<p>Strong yes. Your proposed inception-to-date language is precisely the read we are taking under Method A, and explicit clarification along those lines would have foreclosed Mr. Cron's likely Method D argument from the start. The proposed wording would be useful as a recital in any settlement agreement to nail down the parties' agreed interpretation, even retroactively. Happy to draft a settlement-agreement template that incorporates it -- let me know.</p>

<p><strong>Three open issues to flag before your call with Mr. Cron:</strong></p>

<ol>
  <li><strong>Cycle-3 weakness is real.</strong> Under Method D, cancellation fee = `$0. The life-of-contract Method A read (`$126,442.50) is defensible but contestable. The `$15,045 standing offer should hold; below that we have litigation risk on the cancellation-fee number.</li>
  <li><strong>88.67-hour reconciliation delta.</strong> 842.95 (stated to Jeff 3/19, used on invoice #28064) vs 931.62 (recalc from spreadsheet). This needs to resolve to one number before any formal demand letter. I lean toward standing on the invoiced 842.95 / `$126,442.50 to avoid an inconsistency. Your call.</li>
  <li><strong>Tech Heights / Leggett.</strong> Separate from the BST settlement. Documented unauthorized-access events -- CrowdStrike blocked an unauthorized Domain Admins elevation attempt on 4/2-4/3 (command captured: <code>net group "Domain Admins" thadmin /add /domain</code>), ESXi password change locking us out, monitoring agents removed. Reservation-of-rights language has been in every BST email; no separate Tech Heights demand has gone out. Want your read on whether a separate Tech Heights letter goes out this week regardless of how BST resolves.</li>
</ol>

<p>Happy to jump on a call before your Cron contact if helpful -- use the booking link in my signature, or my cell at 714.402.3164. I will be available all afternoon and evening.</p>

<p>Thank you, Frank.</p>

</div>
$sig
</body>
</html>
"@

# --- Connect ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body    = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $toEmail; Name = $toName } }
    )
    CcRecipients = $ccList
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

# --- Attach files (per-file to avoid 4MB single-request cap) ---
Write-Host "Attaching files..." -ForegroundColor Cyan
foreach ($f in $attachments) {
    $name  = [System.IO.Path]::GetFileName($f)
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $b64   = [Convert]::ToBase64String($bytes)
    $attachBody = @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        Name          = $name
        ContentBytes  = $b64
    }
    $null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draft.Id -BodyParameter $attachBody
    Write-Host "  attached  $name" -ForegroundColor Gray
}

Write-Host ""
Write-Host "DRAFT saved to Outlook Drafts." -ForegroundColor Yellow
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray
Write-Host "Cc      : es@callahan-law.com" -ForegroundColor Gray
Write-Host "Review and send from Outlook." -ForegroundColor Yellow

Disconnect-MgGraph | Out-Null
