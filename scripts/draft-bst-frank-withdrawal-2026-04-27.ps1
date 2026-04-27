# Final revised email to Frank Dunn — withdraws cancellation fee position entirely
# Position: pay the four monthly invoices ($12,443.95) only.

$ErrorActionPreference = "Stop"

$toEmail    = "fdunn@callahan-law.com"
$toName     = "Franklin T. Dunn, Esq."
$ccList     = @(
    @{ EmailAddress = @{ Address = "es@callahan-law.com"; Name = "Edward Susolik, Esq." } }
)
$senderUpn  = "RJain@technijian.com"
$subject    = "BST (Boston Group) -- Withdrawal of Cancellation Fee Position; Final Position is Monthly Invoices Only"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$bstDir     = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST"
$attachments = @(
    "$bstDir\exhibits\Boston_Group-Monthly_Service-signed.pdf",
    "$bstDir\exhibits\bst_actualvsbillable.xlsx"
)

# --- Credentials ---
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) { Write-Error "Failed to parse M365 credentials"; exit 1 }

# --- Validate attachments ---
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

<p>Updating my prior emails today. After re-reading the signed Agreement carefully and reconsidering the methodology, I need to <strong>withdraw the cancellation-fee position entirely</strong>. We made a miscalculation. I want you to walk into the Cron call with the cleanest possible posture, not a number we cannot defend.</p>

<h3 style="color:#006DB6;margin-bottom:6px">The miscalculation.</h3>

<p>The Service Agreement has no fixed term -- it is month-to-month, auto-renewing under &sect;&nbsp;4.05. The "12 Months" reference in the Under Contract section is the billing-cycle baseline-reset period, not a contract term.</p>

<p>Under the natural textual reading of Section 5 -- "<em>any hours that exceeded the previous under contract period average</em>":</p>
<ul>
  <li>Termination cycle = Cycle 3 (5/2025 -- 4/2026)</li>
  <li>Previous under contract period = Cycle 2 (5/2024 -- 4/2025)</li>
  <li>Cycle 3 actuals ran <strong>below</strong> Cycle 2 baselines every month for all three contracted roles (CHD-TS1 N, CHD-TS1 AH, IRV-TS1 N)</li>
  <li><strong>Hours that exceeded = 0 → cancellation fee = `$0</strong></li>
</ul>

<p>The `$126,442.50 figure on invoice #28064 was based on a stretched reading where "the previous" was treated as cumulative across all prior cycles. That is not what the clause says. Mr. Cron would demolish it on first push, and we would be exposed to a colorable BST credit counter-claim under &para;&nbsp;4 of Under Contract for Cycle&nbsp;3 under-consumption (~`$26,500).</p>

<h3 style="color:#006DB6;margin-bottom:6px">Revised position -- final.</h3>

<p>Technijian withdraws the cancellation-fee position. Specifically:</p>
<ul>
  <li><strong>Invoice #28064 (`$126,442.50) will be voided.</strong></li>
  <li><strong>The `$15,045 goodwill settlement comp is also withdrawn.</strong> No cancellation-related amount is being asserted.</li>
</ul>

<p>The remaining and final position is the four monthly/recurring invoices for services rendered, which are clean, contractually unambiguous, and supported by 36 months of weekly time-entry documentation with no timely disputes from BST:</p>

<table cellspacing="0" cellpadding="6" border="1" style="border-collapse:collapse;border-color:#cccccc;font-family:$fontStack;font-size:11pt">
<thead style="background-color:#f3f3f3">
<tr><th style="text-align:left">Invoice</th><th style="text-align:left">Type</th><th style="text-align:right">Amount</th><th style="text-align:left">Due</th><th style="text-align:left">Status</th></tr>
</thead>
<tbody>
<tr><td>#27890</td><td>Recurring</td><td style="text-align:right">`$552.00</td><td>3/31/2026</td><td>Past due, late fee assessed</td></tr>
<tr><td>#27949</td><td>March Monthly</td><td style="text-align:right">`$5,645.35</td><td>3/31/2026</td><td>Past due, late fee assessed</td></tr>
<tr><td>#28112</td><td>Recurring</td><td style="text-align:right">`$552.00</td><td>5/1/2026</td><td>Issued 4/1</td></tr>
<tr><td>#28143</td><td>April Monthly</td><td style="text-align:right">`$5,694.60</td><td>5/1/2026</td><td>Issued 4/1</td></tr>
<tr style="background-color:#f3f3f3;font-weight:bold"><td colspan="2">Total principal</td><td style="text-align:right">`$12,443.95</td><td colspan="2">Plus accrued late fees on the two overdue March invoices</td></tr>
</tbody>
</table>

<h3 style="color:#006DB6;margin-bottom:6px">For the call with Mr. Cron.</h3>

<p>Suggested opening: <em>"Technijian has re-reviewed the Agreement carefully and is withdrawing the cancellation-fee position. Invoice #28064 will be voided. The remaining outstanding obligation is the four monthly invoices totaling `$12,443.95 plus the assessed late fees on the two overdue March invoices. We are looking for written confirmation of payment by April 30, 2026, with mutual release scoped to the cancellation matter and the four invoices."</em></p>

<p><strong>Mutual release scope -- critical.</strong> The mutual release language in any settlement <strong>must NOT release</strong> Technijian's claims against Tech Heights or Renwick "Rich" Leggett. Those are separate causes of action (CFAA, Cal. Penal Code &sect;&nbsp;502, tortious interference, trade secret misappropriation) arising from documented unauthorized-access conduct between 3/31 and 4/3 -- specifically including the ESXi password change, the CrowdStrike-blocked Domain Admins elevation attempt (command captured: <code>net group "Domain Admins" thadmin /add /domain</code>), and the post-3/31 removal of Technijian's monitoring agents. Reservation of rights against any third party (and against BST to the extent BST is implicated in those third-party acts) must be preserved.</p>

<p>The release should expressly cover: (i) the cancellation fee dispute and invoice #28064; (ii) any &para;&nbsp;4 credit claim by BST for Cycle 3 under-consumption; (iii) any other disputes related to invoiced/uninvoiced hours through 4/30/2026 -- conditioned on payment of the `$12,443.95 plus accrued late fees by 4/30 COB.</p>

<h3 style="color:#006DB6;margin-bottom:6px">Why this is the right call.</h3>

<ol>
  <li><strong>The textual reading of Section 5 yields `$0.</strong> Holding any cancellation-fee position invites a methodology fight we lose, plus exposes us to BST's `$26,500 &para;&nbsp;4 credit counter-claim and potential &sect;&nbsp;1717 fee exposure if BST prevails.</li>
  <li><strong>The monthly invoices are clean.</strong> Services rendered, weekly time-entry records, no timely disputes within the 60-day window per &sect;&nbsp;3.01. Standard collection action; the strongest possible posture.</li>
  <li><strong>Withdrawing the cancellation fee voluntarily preserves credibility.</strong> If we wait for Cron to force the issue, it is a concession under pressure rather than a corrected position.</li>
  <li><strong>Tech Heights / Leggett claims are unaffected.</strong> These continue on a separate track, with reservation of rights preserved in every BST email and in the proposed mutual release scope.</li>
</ol>

<h3 style="color:#006DB6;margin-bottom:6px">If BST refuses even the monthlies.</h3>

<p>Litigate the monthlies only. Clean facts: services rendered, ticketed time-entry records sent weekly with 30-day dispute window, monthly invoices sent with 60-day dispute window, zero timely objections across 36 months and ~150 weekly invoices. Course of dealing and account stated are both available defenses to any quality-of-records argument. Recoverable amount is small (~`$12,500 plus late fees) but the principle is clean.</p>

<h3 style="color:#006DB6;margin-bottom:6px">Frank's clause clarification proposal -- still endorsed.</h3>

<p>Your proposed inception-to-date language for Section 5 would have foreclosed exactly the textual problem we just identified. Worth incorporating into any settlement-agreement recital or into go-forward agreement templates. I will be revising the master Client Monthly Service Agreement template along the lines you suggested -- happy for your input on the final wording.</p>

<h3 style="color:#006DB6;margin-bottom:6px">Internal cleanup.</h3>

<p>The damages analysis (BST_Damages_Scenario_Analysis_INTERNAL.docx) circulated earlier today uses the now-corrected term framing throughout. <strong>Do not rely on its headline numbers.</strong> The underlying hours data is accurate; the methodology framing is wrong. I will rewrite it under separate cover so the file is clean for the record.</p>

<p>I would rather correct this now than have you defend an indefensible number. Apologies for the back-and-forth on a single matter today.</p>

<p>Available the rest of the day on cell at 714.402.3164.</p>

<p>Thank you, Frank.</p>

</div>
$sig
</body>
</html>
"@

# --- Connect ---
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

Disconnect-MgGraph | Out-Null
