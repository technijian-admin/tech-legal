# REVISED response to Frank Dunn — corrects 36-month term error, presents $0 textual cancellation fee
# This supersedes the prior draft (which had term wrong).

$ErrorActionPreference = "Stop"

$toEmail    = "fdunn@callahan-law.com"
$toName     = "Franklin T. Dunn, Esq."
$ccList     = @(
    @{ EmailAddress = @{ Address = "es@callahan-law.com"; Name = "Edward Susolik, Esq." } }
)
$senderUpn  = "RJain@technijian.com"
$subject    = "RE: BST (Boston Group) -- REVISED Analysis: No Stated Term, Section 5 Cancellation Fee = `$0 Under Textual Reading"
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

# --- Validate attachments ---
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

<p>I owe you a correction to my prior email before your call with Mr. Cron. Two factual issues changed the analysis materially -- I want you walking into that call with the cleaner picture, not the one I sent earlier today.</p>

<h3 style="color:#006DB6;margin-bottom:6px">1. The Agreement has no fixed term.</h3>

<p>I told you earlier the Service Agreement was a 36-month term. That was wrong. Re-reading the signed PDF carefully:</p>

<ul>
  <li>&sect;&nbsp;4.01 of the Terms &amp; Conditions: "The initial term of this Agreement shall be as set forth on the monthly Service agreement or invoice." But the monthly service agreement page <strong>does not specify a term length</strong>.</li>
  <li>"Other Terms" &para;&nbsp;1 says only: <em>"This service agreement shall start after it is signed and dated."</em> No end date, no renewal language, no fixed duration.</li>
  <li>&sect;&nbsp;4.05 governs voluntary termination on 30 days' notice -- which BST invoked.</li>
  <li>The "<strong>12 Months</strong>" reference in the "Under Contract" section is the <strong>billing-cycle baseline-reset period</strong>, not the agreement term.</li>
</ul>

<p>Practical effect: the Agreement was <strong>month-to-month, auto-renewing</strong> under &sect;&nbsp;4.05 from 2023-05-01 forward. BST was on service for 36 months because they did not terminate earlier -- not because there was a 36-month commitment.</p>

<h3 style="color:#006DB6;margin-bottom:6px">2. Under the natural textual reading of Section 5, the proper cancellation fee is `$0.</h3>

<p>Section 5 of "Under Contract" says:</p>
<blockquote style="border-left:3px solid #006DB6;padding-left:12px;color:#444;margin:8px 0">
"If this agreement is terminated, <strong>any hours that exceeded the previous under contract period average</strong>, that were documented through ticketing, will be charged at a rate of `$150 per hour and will be assessed as the cancellation fee to the client and due before agreement is terminated."
</blockquote>

<p>Parsing the variables at termination (effective 2026-04-30):</p>
<ul>
  <li>Termination cycle = <strong>Cycle 3 (5/2025 -- 4/2026)</strong> -- the cycle in which termination occurred</li>
  <li>"<em>The previous under contract period</em>" (singular) = <strong>Cycle 2 (5/2024 -- 4/2025)</strong> -- the immediately preceding 12-month cycle</li>
  <li>"<em>The previous under contract period average</em>" = the per-role averages that came out of Cycle 2 (which then became the Cycle 3 billing baselines per &para;&nbsp;3): CHD-TS1 N <strong>56.59</strong>, CHD-TS1 AH <strong>33.70</strong>, IRV-TS1 N <strong>12.56</strong></li>
  <li>"<em>Hours that exceeded</em>" = hours during Cycle 3 that exceeded those Cycle 2 baselines</li>
</ul>

<p><strong>Did Cycle 3 actuals ever exceed Cycle 2 baselines?</strong> No. Every month, every role, ran <em>under</em> the Cycle 2 baseline:</p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Role</th><th style="text-align:right">Highest Cycle 3 month actual</th><th style="text-align:right">Cycle 2 baseline</th><th style="text-align:center">Exceeded?</th></tr>
</thead>
<tbody>
<tr><td>CHD-TS1 OS Support (Normal)</td><td style="text-align:right">40.51 (May 2025)</td><td style="text-align:right">56.59</td><td style="text-align:center">No</td></tr>
<tr><td>CHD-TS1 OS Support.AH</td><td style="text-align:right">16.50 (Jan 2026)</td><td style="text-align:right">33.70</td><td style="text-align:center">No</td></tr>
<tr><td>IRV-TS1 Tech Support (Normal)</td><td style="text-align:right">11.25 (Oct 2025)</td><td style="text-align:right">12.56</td><td style="text-align:center">No</td></tr>
</tbody>
</table>

<p><strong>Hours that exceeded = 0. Proper cancellation fee under Section 5 = `$0.</strong></p>

<p>The `$126,442.50 figure on invoice #28064 was based on a stretched reading where "the previous" is interpreted to mean "any prior cycle's average cumulatively" -- i.e., summing per-role overages across all 36 months of service. That reading is not what the clause says. Mr. Cron will reject it cold and the natural textual reading wins.</p>

<h3 style="color:#006DB6;margin-bottom:6px">3. BST may have a `$26,500+ credit argument under &para;&nbsp;4.</h3>

<p>&para;&nbsp;4 of Under Contract says: <em>"If the average goes down a credit will be given on the next month's invoice."</em> Cycle 3 averages ran substantially below Cycle 2 baselines:</p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Role</th><th style="text-align:right">Hours under baseline (11 mo)</th><th style="text-align:right">Rate</th><th style="text-align:right">Potential credit</th></tr>
</thead>
<tbody>
<tr><td>CHD-TS1 OS Support (Normal)</td><td style="text-align:right">361.62</td><td style="text-align:right">`$15</td><td style="text-align:right">`$5,424.30</td></tr>
<tr><td>CHD-TS1 OS Support.AH</td><td style="text-align:right">262.41</td><td style="text-align:right">`$30</td><td style="text-align:right">`$7,872.30</td></tr>
<tr><td>IRV-TS1 Tech Support (Normal)</td><td style="text-align:right">106.16</td><td style="text-align:right">`$125</td><td style="text-align:right">`$13,270.00</td></tr>
<tr style="background-color:#f3f3f3;font-weight:bold"><td>Total potential credit owed to BST</td><td></td><td></td><td style="text-align:right">~`$26,566.60</td></tr>
</tbody>
</table>

<p>If Mr. Cron is sharp, he raises this and offsets any cancellation fee theory entirely. Our response: &para;&nbsp;4 contemplates within-cycle running-average reconciliation, BST never invoked it during 36 months of service, and the right was effectively waived through performance plus the contractual 60-day dispute window. But the argument is real.</p>

<h3 style="color:#006DB6;margin-bottom:6px">4. Recalibrated settlement posture.</h3>

<p>Given the proper textual cancellation fee is `$0 and BST has a colorable credit argument, my prior anchor of `$126,442.50 was significantly overstated. Recommended revised posture:</p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Tier</th><th style="text-align:right">Number</th><th style="text-align:left">Composition</th></tr>
</thead>
<tbody>
<tr><td><strong>Best case (anchor)</strong></td><td style="text-align:right"><strong>`$27,488.95</strong></td><td>`$12,443.95 monthlies in full + `$15,045 goodwill cancellation comp + mutual release by 4/30</td></tr>
<tr><td>Acceptable middle</td><td style="text-align:right">~`$19,944</td><td>`$12,443.95 monthlies + `$7,500 cancellation comp + mutual release</td></tr>
<tr><td>Walk-away minimum</td><td style="text-align:right">`$12,443.95</td><td>Monthlies in full only, no cancellation fee, mutual release (preserves Tech Heights claims)</td></tr>
<tr><td>Worst case</td><td style="text-align:right">`$12,443.95</td><td>If BST refuses everything, litigate monthlies only -- clean and straightforward; drop cancellation fee posture entirely</td></tr>
</tbody>
</table>

<p>Important: <strong>the monthly invoices (`$12,443.95) are clean, contractually clear, services rendered.</strong> That obligation does not depend on Section 5 interpretation. We should never give those up.</p>

<h3 style="color:#006DB6;margin-bottom:6px">5. Three things this changes for the Cron call.</h3>

<ol>
  <li><strong>Do not anchor at `$126,442.50.</strong> The textual reading does not support it and Mr. Cron will use the analysis I just walked you through to demolish it. Anchor instead at the `$27,488.95 number.</li>
  <li><strong>If Cron raises &para;&nbsp;4 credits</strong>, our pivot is course-of-dealing/no timely objection over 36 months and ~150 weekly invoices. We can hold the line, but don't act surprised.</li>
  <li><strong>Do not extend the 4/30 deadline.</strong> The `$15,045 is a courtesy, not an entitlement. Let it expire if Cron stalls, and the position contracts to monthlies-only -- which is the cleanest litigation position anyway.</li>
</ol>

<h3 style="color:#006DB6;margin-bottom:6px">6. About the prior attachments.</h3>

<p>The damages analysis attached (BST_Damages_Scenario_Analysis_INTERNAL.docx) was prepared 2026-04-15 and uses the now-corrected "36-month term" framing throughout. The <em>data</em> in it is accurate (role-by-role hours, cycle baselines, Cycle 3 monthly distribution). But the methodology framing and conclusions are based on the wrong term assumption. <strong>Rely on this email's revised analysis</strong>, not on the analysis doc's headline numbers, when you talk to Mr. Cron. I will rewrite the analysis doc separately.</p>

<h3 style="color:#006DB6;margin-bottom:6px">7. Other items still apply.</h3>

<ul>
  <li><strong>Course of dealing on hours documentation</strong> -- 36 months of weekly + monthly invoices with per-ticket time-entry spreadsheets, zero timely disputes by BST. This is our best defense if BST tries to attack data quality. Unchanged.</li>
  <li><strong>Tech Heights / Leggett</strong> -- separate track. CrowdStrike-blocked unauthorized Domain Admins elevation attempt 4/2-4/3 (command captured: <code>net group "Domain Admins" thadmin /add /domain</code>), ESXi password change, monitoring agents removed. Not affected by the cancellation-fee analysis. Want your read on a separate Tech Heights demand letter regardless of how BST resolves.</li>
  <li><strong>Frank's clause clarification proposal</strong> -- still endorsed; if anything, more important now. The proposed inception-to-date language would foreclose exactly the textual problem we have here. Worth incorporating into any settlement-agreement recital so the parties' agreed interpretation is locked in retroactively.</li>
</ul>

<p>I am genuinely sorry for the confusion of two emails on the same matter in one afternoon. I would rather correct it now than have you anchor at a number we cannot defend in front of Mr. Cron.</p>

<p>Available the rest of the day on cell at 714.402.3164.</p>

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

# --- Attach files ---
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
Write-Host "Review and SEND from Outlook." -ForegroundColor Yellow

Disconnect-MgGraph | Out-Null
