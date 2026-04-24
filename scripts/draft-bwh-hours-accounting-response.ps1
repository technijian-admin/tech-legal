# Draft BWH response to Dave's 4/24 19:02 email about unpaid-hour reconciliation
# Attaches the master life-of-contract accounting xlsx
# Saves MessageId to bwh-hours-accounting-draft-id.txt
#
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\draft-bwh-hours-accounting-response.ps1

$ErrorActionPreference = "Stop"

$toEmail    = "dave@brandywine-homes.com"
$toName     = "Dave Barisic"
$senderUpn  = "RJain@technijian.com"
$subject    = "Re: MSA-BWH Redlines - Unpaid Hours Accounting + Full Ticket Detail Attached"
$idFile     = "C:\vscode\tech-legal\tech-legal\scripts\bwh-hours-accounting-draft-id.txt"
$sigPath    = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$attachPath = "C:\vscode\tech-legal\tech-legal\clients\BWH\06_Accounting\BWH-Hours-Accounting-Life-of-Contract.xlsx"

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 credentials"; exit 1
}

# --- Verify attachment ---
if (-not (Test-Path $attachPath)) {
    Write-Error "Attachment not found: $attachPath"; exit 1
}
$attachBytes    = [System.IO.File]::ReadAllBytes($attachPath)
$attachBase64   = [Convert]::ToBase64String($attachBytes)
$attachName     = [System.IO.Path]::GetFileName($attachPath)
Write-Host "Attachment: $attachName ($($attachBytes.Length) bytes)" -ForegroundColor Gray

# --- Signature ---
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

# --- HTML body ---
# Outlook-safe: solid-color backgrounds, no linear-gradient. Backtick-escape every literal dollar sign.
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:11pt;color:rgb(0,0,0)">

<p>Dave,</p>

<p>Thanks for the pushback on the numbers &mdash; you were right to question them. I had Tharunaa pull everything directly from the portal for the full life of the contract so we can put the uncertainty to bed, and I&rsquo;ve attached a single workbook (<strong>BWH-Hours-Accounting-Life-of-Contract.xlsx</strong>) that contains every ticket and every time entry from the start of our engagement through today. I want to walk you through what the numbers actually are, how the table on the invoice footer works, and why the figures you saw earlier didn&rsquo;t reconcile.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">1. The footer table format changed on Invoice #28148 &mdash; on purpose.</h3>

<p>Starting with the April 1 invoice (#28148), we replaced the old &ldquo;Support History (last 6 months)&rdquo; block with a cleaner four-column cumulative table so the unpaid-hour balance is explicit going forward. The columns are:</p>

<ul>
  <li><strong>UnPaid (Bef)</strong> &mdash; the running unpaid balance going <em>into</em> this billing cycle (carried from the previous monthly invoice).</li>
  <li><strong>Billed</strong> &mdash; the contracted hours billed on <em>this</em> monthly invoice (the allocation applied as a credit).</li>
  <li><strong>Actual(prev)</strong> &mdash; the actual hours worked during the <em>previous</em> month, taken directly from the Time Entries xlsx attached to that invoice email.</li>
  <li><strong>UnPaid (Aft)</strong> &mdash; the new running unpaid balance = Bef + Actual(prev) &minus; Billed.</li>
</ul>

<p>The change was intentional. The prior 6-month format showed per-month deltas but didn&rsquo;t clearly state the total carried-forward balance per the contract, and that created the confusion we&rsquo;re now untangling. Nothing changed about the underlying accounting &mdash; the same balance has been building on prior invoices; it simply wasn&rsquo;t displayed as a running cumulative total.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">2. The authoritative current balance is 1,007.30 hours (per Invoice #28148 footer).</h3>

<p>From the Invoice #28148 footer dated 4/1/2026:</p>

<table cellspacing="0" cellpadding="6" style="border-collapse:collapse;border:1px solid rgb(180,180,180);font-size:10.5pt">
  <thead>
    <tr style="background-color:rgb(31,78,120);color:white;font-weight:bold">
      <td style="border:1px solid rgb(180,180,180);padding:6px 10px">Role</td>
      <td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">UnPaid (Bef)</td>
      <td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">Billed</td>
      <td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">Actual(prev)</td>
      <td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">UnPaid (Aft)</td>
    </tr>
  </thead>
  <tbody>
    <tr><td style="border:1px solid rgb(180,180,180);padding:6px 10px">India Tech: Normal</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">572.20</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">58.13</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">59.74</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">573.81</td></tr>
    <tr><td style="border:1px solid rgb(180,180,180);padding:6px 10px">India Tech: After Hours</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">291.84</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">42.82</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">41.21</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">290.23</td></tr>
    <tr><td style="border:1px solid rgb(180,180,180);padding:6px 10px">Systems Architect</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">0.00</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">5.00</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">0.00</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">0.00</td></tr>
    <tr><td style="border:1px solid rgb(180,180,180);padding:6px 10px">USA Tech: Normal</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">140.94</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">15.26</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">17.58</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">143.26</td></tr>
    <tr style="background-color:rgb(217,225,242);font-weight:bold"><td style="border:1px solid rgb(180,180,180);padding:6px 10px">TOTAL</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">1,004.98</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">121.21</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">118.53</td><td style="border:1px solid rgb(180,180,180);padding:6px 10px;text-align:right">1,007.30</td></tr>
  </tbody>
</table>

<p>So the <strong>correct current unpaid balance per the most recent monthly invoice is 1,007.30 hours</strong>, not 687.67 and not 1,040.28. The two other figures that have been quoted in this thread came from internal snapshots I was pulling while trying to answer your question in real time; the invoice footer is the authoritative number, and that&rsquo;s what we should both be working off of going forward.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">3. The 687.67 figure I sent you on 4/1 was wrong. I&rsquo;m owning that.</h3>

<p>The table I sent you on 4/1 at 2:34 PM showed 687.67 total hours with a &ldquo;MonthStartDate 3/1/2026&rdquo; header. That was an internal query run by Tharunaa before Invoice #28148 was generated, and it did not match any valid cutoff of the life-of-contract unpaid balance. When you flagged the jump from 687.67 to 1,040.28 later that day, you were right &mdash; those two numbers can&rsquo;t both be correct 23 days apart. The 687.67 figure shouldn&rsquo;t have gone out; please disregard it. The 1,040.28 number I quoted during our 4/24 back-and-forth was also an interim estimate while we were building the current-cycle roll-forward; it should reconcile within a few hours up or down to the next monthly invoice footer, but the number you should anchor to is the 1,007.30 on Invoice #28148.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">4. Life-of-contract summary.</h3>

<p>Pulled directly from the Technijian Client Portal for the full life of the contract (May 2, 2023 through today):</p>

<ul>
  <li><strong>Total hours delivered:</strong> 4,050.10 hrs</li>
  <li><strong>Total contracted hours billed and credited:</strong> approximately 3,043 hrs across 36 monthly cycles</li>
  <li><strong>Current unpaid balance (per Invoice #28148):</strong> 1,007.30 hrs</li>
  <li><strong>Weekly invoices sent:</strong> 149 (100% marked Paid in the portal)</li>
  <li><strong>Monthly invoices sent (the ones with the footer table):</strong> 36</li>
</ul>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">5. What&rsquo;s in the attached workbook.</h3>

<p>The attached file has six tabs:</p>

<ol>
  <li><strong>Summary</strong> &mdash; the Bef/Billed/Actual/Aft table above plus the life-of-contract totals.</li>
  <li><strong>Life of Contract by Month</strong> &mdash; actual hours delivered per role per month, from May 2023 to April 2026.</li>
  <li><strong>All Time Entries</strong> &mdash; <em>every</em> time entry logged against Brandywine Homes over the full life of the contract: date, ticket title, requestor, POD, role, shift, assignee, hours, and invoice category. Filterable.</li>
  <li><strong>Jan 2026 Tickets (Invoice 27685)</strong> &mdash; the same Time Entries xlsx that was attached to the Feb 4 invoice email.</li>
  <li><strong>Feb 2026 Tickets (Invoice 27948)</strong> &mdash; same for the March 5 invoice email.</li>
  <li><strong>Mar 2026 Tickets (Invoice 28148)</strong> &mdash; same for the April 2 invoice email.</li>
</ol>

<p>Tabs 4, 5, and 6 are the same xlsx files you already received from billing@technijian.com with each monthly invoice &mdash; reproduced here so all the evidence sits in one place. The &ldquo;Actual(prev)&rdquo; column on each invoice footer ties directly to the totals on the matching tab.</p>

<h3 style="color:rgb(31,78,120);margin-bottom:6px">6. On the MSA negotiation.</h3>

<p>This accounting is the documented ticket-by-ticket breakdown you asked for in your 4/24 note on &sect;9.02. It answers the request; now we can have the §3.3(e)/§9.02 conversation on a shared-numbers basis. I still want to resolve this through the cycle mechanics in the new MSA rather than invoicing at Standard Rate, and the workbook should make clear that the balance is real, documented, and not going to shock you later.</p>

<p>Review the file at your pace. Happy to schedule time to walk through any tab with you if it would be useful.</p>

<p>Thank you,</p>

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

# --- Create draft (no attachment yet) ---
Write-Host "Creating draft..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body    = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $toEmail; Name = $toName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
$draftId = $draft.Id
Write-Host "Draft created. MessageId: $draftId" -ForegroundColor Green

# --- Attach xlsx ---
Write-Host "Attaching $attachName..." -ForegroundColor Cyan
$attachmentParams = @{
    "@odata.type"  = "#microsoft.graph.fileAttachment"
    Name           = $attachName
    ContentType    = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ContentBytes   = $attachBase64
}
New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draftId -BodyParameter $attachmentParams | Out-Null
Write-Host "Attached." -ForegroundColor Green

# Save MessageId
Set-Content -Path $idFile -Value $draftId -Encoding UTF8
Write-Host "Draft ready in Outlook Drafts. MessageId saved to: $idFile" -ForegroundColor Yellow
Write-Host "Subject : $subject" -ForegroundColor Gray
Write-Host "To      : $toEmail" -ForegroundColor Gray
Write-Host "Attach  : $attachName" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
Write-Host "`nPROOFREAD the draft in Outlook before sending." -ForegroundColor Yellow
