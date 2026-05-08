# Send Directors Briefing -- India Workforce Restructuring
# To Chandra P. Jain (cpjain@technijian.com) and Daya Krishan Sharma (DKSharma@technijian.com)
# Final settlement numbers, risk posture, and 6+3 attachment package.
#
# Usage:
#   .\send-directors-briefing.ps1          # draft only (DEFAULT)
#   .\send-directors-briefing.ps1 -Send    # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$to = @(
    @{ Address = "cpjain@technijian.com";    Name = "Chandra P. Jain" },
    @{ Address = "DKSharma@technijian.com";  Name = "Daya Krishan Sharma" }
)

$senderUpn = "RJain@technijian.com"
$subject   = "FINAL: India Workforce Restructuring -- Director Briefing & Notice Day Monday May 11"

$sigPath           = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$letterPdfDir      = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\letters\pdf"
$letterSignedDir   = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\letters\pdf-signed"
$leavePdfDir       = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\leave-applications\pdf"
$leaveSignedDir    = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\leave-applications\pdf-signed"

function Resolve-PdfPath($filename, $signedDir, $unsignedDir) {
    $signed = Join-Path $signedDir $filename
    if (Test-Path $signed) { return @{ Path = $signed; Signed = $true } }
    return @{ Path = (Join-Path $unsignedDir $filename); Signed = $false }
}

$letterFiles = @(
    "01-Devesh-Bhattacharya-Termination.pdf",
    "02-Rajat-Kumar-Termination.pdf",
    "03-Aditya-Saraf-Termination.pdf",
    "04-Suresh-Kumar-Sharma-Termination.pdf",
    "05-Yogesh-Kumar-Retrenchment.pdf",
    "06-Rahul-Uniyal-Retrenchment.pdf"
)
$leaveFiles = @(
    @{ Src = "01-Yogesh-Kumar-Leave-Application.pdf";        Out = "07-Yogesh-Kumar-Leave-Application.pdf" },
    @{ Src = "02-Rahul-Uniyal-Leave-Application.pdf";        Out = "08-Rahul-Uniyal-Leave-Application.pdf" },
    @{ Src = "03-Suresh-Kumar-Sharma-Leave-Application.pdf"; Out = "09-Suresh-Kumar-Sharma-Leave-Application.pdf" }
)
$attachmentMap = @()
foreach ($f in $letterFiles) {
    $r = Resolve-PdfPath $f $letterSignedDir $letterPdfDir
    $attachmentMap += @{ Src = $r.Path; Name = $f; Signed = $r.Signed }
}
foreach ($f in $leaveFiles) {
    $r = Resolve-PdfPath $f.Src $leaveSignedDir $leavePdfDir
    $attachmentMap += @{ Src = $r.Path; Name = $f.Out; Signed = $r.Signed }
}

Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# Cleanup any prior versions of this draft
Write-Host "`nRemoving prior director-briefing drafts (if any)..." -ForegroundColor Cyan
$drafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 100 -Property "id,subject"
$deleted = 0
foreach ($d in $drafts) {
    if ($d.Subject -like "*Director Briefing*" -or $d.Subject -like "*Directors Briefing*") {
        Remove-MgUserMessage -UserId $senderUpn -MessageId $d.Id -Confirm:$false
        Write-Host "  [x] Deleted: $($d.Subject)" -ForegroundColor DarkGray
        $deleted++
    }
}
Write-Host "Deleted $deleted prior draft(s)." -ForegroundColor Yellow

$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

$bodyTemplate = @'
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:__FONT__;font-size:11pt;color:rgb(0,0,0)">

<p>Chandra, Daya Krishan,</p>

<p>This is the final director-level briefing on the India workforce restructuring. <b>Notice day is Monday, May 11, 2026</b>; last working day for all six is May 31, 2026; full and final settlement disburses June 1, 2026. The cost has come in <b>materially below the figure circulated in the board memo</b> after a payroll-correct &sect;70 calculation.</p>

<p>All six retrenchment / termination letters and all three leave applications are attached as PDFs (9 files). The package has been finalised on India letterhead in compliance with IR Code 2020 and the Code on Wages.</p>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Headcount Context</p>

<p>India active workforce per April 2026 payroll register: <b>22 employees</b> (excluding directors and vendor entries). The cut of 6 is <b>27% of the active workforce</b>. Retained headcount post-restructuring: <b>16 employees</b>. This is well below the IR Code &sect;78 prior-permission threshold (300 workers); no Government permission is required. The cut is concentrated entirely in the CSE department (full LIFO compliance, no &sect;71 departure memo needed).</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Headline Numbers</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Item</td><td>Original (gross-basis)</td><td>Final (Basic-only per IR Code §2(zh))</td><td>Saving</td>
</tr>
<tr><td>Cash to 6 employees (one-time F&amp;F)</td><td align="right">Rs. 7,19,287</td><td align="right"><b>Rs. 5,30,427</b></td><td align="right">Rs. 1,88,860</td></tr>
<tr><td>Re-skilling Fund deposit (Haryana, IR Code §83)</td><td align="right">Rs. 43,088</td><td align="right"><b>Rs. 22,014</b></td><td align="right">Rs. 21,074</td></tr>
<tr style="background:#FEF3EE"><td><b>All-in one-time cost</b></td><td align="right"><b>Rs. 7,62,375</b></td><td align="right"><b>Rs. 5,52,441</b></td><td align="right"><b>Rs. 2,09,934</b></td></tr>
<tr><td>USD equivalent at Rs.84/USD</td><td align="right">$9,076</td><td align="right"><b>$6,577</b></td><td align="right">$2,499</td></tr>
</table>

<p>The reduction comes from one structural correction: <b>under IR Code 2020 §2(zh), &ldquo;wages&rdquo; for retrenchment compensation and Re-skilling Fund deposit means Basic + DA only, not gross.</b> Our payroll has no DA component (Basic is exactly 50% of gross, which is Code on Wages compliant). The original calculation used gross. Rebuilding on Basic produces the lower legally-correct figure.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Per-Employee Settlement (Final)</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:9.5pt;width:100%">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>#</td><td>Employee</td><td>Pathway</td><td>May Salary</td><td>Notice Pay-in-Lieu (10d)</td><td>§70 Retrench Comp</td><td>EL Encashment</td><td>Cash to Employee</td><td>Re-skilling Fund</td>
</tr>
<tr>
  <td>1</td><td>Devesh Bhattacharya</td><td>Probation</td>
  <td align="right">50,000</td><td align="right">0</td><td align="right">0</td><td align="right">0</td>
  <td align="right"><b>50,000</b></td><td align="right">0</td>
</tr>
<tr style="background:#F4F4F4">
  <td>2</td><td>Rajat Kumar</td><td>Post-probation</td>
  <td align="right">42,500</td><td align="right">14,167</td><td align="right">0</td><td align="right">0</td>
  <td align="right"><b>56,667</b></td><td align="right">0</td>
</tr>
<tr>
  <td>3</td><td>Aditya Saraf</td><td>Non-worker</td>
  <td align="right">70,000</td><td align="right">23,333</td><td align="right">0</td><td align="right">0</td>
  <td align="right"><b>93,333</b></td><td align="right">0</td>
</tr>
<tr style="background:#F4F4F4">
  <td>4</td><td>Suresh Kumar Sharma</td><td>Post-probation + EL burn</td>
  <td align="right">40,000</td><td align="right">13,333</td><td align="right">0</td><td align="right">21,777</td>
  <td align="right"><b>75,110</b></td><td align="right">0</td>
</tr>
<tr style="background:#FEF3EE">
  <td>5</td><td>Yogesh Kumar</td><td><b>§70 Retrenchment</b></td>
  <td align="right">47,589</td><td align="right">15,863</td><td align="right">48,686</td><td align="right">0</td>
  <td align="right"><b>1,12,138</b></td><td align="right">12,171</td>
</tr>
<tr style="background:#FEF3EE">
  <td>6</td><td>Rahul Uniyal</td><td><b>§70 Retrenchment</b></td>
  <td align="right">38,585</td><td align="right">12,862</td><td align="right">39,370</td><td align="right">52,362</td>
  <td align="right"><b>1,43,179</b></td><td align="right">9,843</td>
</tr>
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td colspan="7" align="right">TOTALS (INR)</td><td align="right"><b>5,30,427</b></td><td align="right"><b>22,014</b></td>
</tr>
</table>

<p style="font-size:10pt;color:#59595B"><i>EL encashment for Rahul and Suresh is computed on Basic / 26 working days x remaining EL balance after notice-period leave-burn. Yogesh fully burns his 16.51-day balance during notice; no encashment payable.</i></p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Annual Cost Eliminated</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Item</td><td>Monthly</td><td>Annual</td><td>USD (annual)</td>
</tr>
<tr><td>Direct salary (gross)</td><td align="right">Rs. 2,88,674</td><td align="right">Rs. 34,64,088</td><td align="right">$41,239</td></tr>
<tr><td>EPF, ESIC, gratuity accrual, facilities (loaded ~15%)</td><td align="right">Rs. 43,300</td><td align="right">Rs. 5,19,613</td><td align="right">$6,186</td></tr>
<tr style="background:#FEF3EE"><td><b>Total annual run-rate eliminated</b></td><td align="right"><b>Rs. 3,31,974</b></td><td align="right"><b>Rs. 39,83,701</b></td><td align="right"><b>$47,425</b></td></tr>
</table>

<p><b>Payback period:</b> 5,52,441 / 3,31,974 &asymp; <b>1.66 months</b>. <b>Five-year cumulative net benefit:</b> Rs. 1,93,65,066 (~$2,30,536).</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Risk Posture</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt;width:100%">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>#</td><td>Employee</td><td>Risk Tier</td><td>Why</td>
</tr>
<tr>
  <td>1</td><td>Devesh Bhattacharya</td><td>Very Low</td>
  <td>5-week tenure, in probation period; offer letter probationary clause governs.</td>
</tr>
<tr>
  <td>2</td><td>Rajat Kumar</td><td>Very Low</td>
  <td>3-month tenure; no §70 exposure; clean post-probation termination.</td>
</tr>
<tr>
  <td>3</td><td>Aditya Saraf</td><td>Low</td>
  <td>4-month tenure; non-worker (Lead) classification; no §70 trigger.</td>
</tr>
<tr style="background:#F4F4F4">
  <td>4</td><td>Suresh Kumar Sharma</td><td>Low</td>
  <td>~11-month tenure; below 1-yr §70 threshold; leave-burn + notice pay handled.</td>
</tr>
<tr style="background:#FEF3EE">
  <td>5</td><td>Yogesh Kumar</td><td>Medium</td>
  <td>4-yr tenure, confirmed workman, §70 path. Statutory comp paid at correct Basic-only rate. Mid-year review documented underperformance is on file as supporting context.</td>
</tr>
<tr style="background:#FEF3EE">
  <td>6</td><td>Rahul Uniyal</td><td>Medium</td>
  <td>4-yr tenure, confirmed workman, §70 path. Same as Yogesh. EL encashment paid in full on accrued balance.</td>
</tr>
</table>

<p><b>Aggregate risk-adjusted exposure: low.</b> All six are CSE department, full LIFO order maintained (no §71 departure memo needed). Zero female employees on the cut list (no discrimination-claim vector). No cross-department selection. Yogesh and Rahul are the only §70 cases; both are textbook cost-reduction retrenchments well-supported by Supreme Court precedent (<i>Workmen of Sudder Office</i> 1971; <i>Hindustan Lever</i> 1973; <i>Western India Match</i> 1973).</p>

<p>Estimated risk-adjusted aggregate claim cost across all six: <b>Rs. 50,000 to Rs. 1,00,000</b>, almost entirely concentrated in the Yogesh/Rahul §70 path.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Strategic Decisions Locked In</p>

<ol>
<li><b>Cost-reduction ground</b> stated explicitly under §70: post-September-2024 malware revenue compression + Q4 2024 / Q1 2025 client losses. Strong SC precedent.</li>
<li><b>No ex-gratia.</b> Statutory minimum only.</li>
<li><b>EL-burn during notice</b> for Yogesh (full 16.51 days), Rahul (20 days), Suresh (20 days). Cuts encashment liability materially.</li>
<li><b>All CSE.</b> No cross-department LIFO departure; zero exposure on selection methodology.</li>
<li><b>Salary-reduction strategy considered and rejected</b> &mdash; constructive-dismissal risk and adverse selection made it worse than clean retrenchment.</li>
<li><b>Misconduct / for-cause path considered and rejected</b> &mdash; performance is not misconduct under Indian law; manufacturing charges to skip §70 is <i>mala fide</i> and tribunals dismiss with reinstatement plus back wages. Unfavourable risk/reward by ~$10K saved against $30K-60K per-person exposure.</li>
<li><b>Re-skilling Fund</b> paid in full per §83 IR Code (no deferral). Compliance-sensitive.</li>
<li><b>No outstanding loans / advances</b> with any of the six (HR confirmed). Set-off lever not available.</li>
</ol>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Schedule</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td>Date</td><td>Action</td><td>Owner</td>
</tr>
<tr><td>Sun May 10 (today + 2)</td><td>Tech leads (Ajay/Gurdeep) print letter packets, seal envelopes, stage IT revocation list</td><td>Ajay Bhardwaj, Gurdeep Kumar</td></tr>
<tr style="background:#F4F4F4"><td><b>Mon May 11, 9:30 AM IST</b></td><td><b>Notice delivery</b> &mdash; six simultaneous one-on-one meetings; IT access revoked at handover; leave applications signed (Yogesh/Rahul/Suresh)</td><td>Ajay Bhardwaj, Gurdeep Kumar</td></tr>
<tr><td>Tue May 12 - Sat May 30</td><td>Notice period; Yogesh/Rahul/Suresh on paid leave; Devesh/Rajat continue working on non-sensitive tickets; Aditya already released</td><td>Ravi Jain</td></tr>
<tr style="background:#FEF3EE"><td><b>Sun May 31, EOD</b></td><td>Last working day; equipment returned</td><td>All</td></tr>
<tr><td><b>Mon Jun 1</b></td><td><b>Full and final settlement disbursed</b> (Rs. 5,30,427 to employees); Re-skilling Fund deposit (Rs. 22,014) initiated to Haryana state</td><td>Ravi Jain (CFO action)</td></tr>
<tr><td>Wk of Jun 8</td><td>§70(c) Government notice filing for Yogesh and Rahul</td><td>Ravi Jain / Ajay Bhardwaj</td></tr>
</table>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Sign-Off Status</p>

<p>The board memo (workforce-reduction-memo.docx) was previously signed at higher cash envelopes during plan iteration (7-person original, then 6-person at gross-basis). <b>The final 6-person plan with the corrected Basic-only &sect;70 calculation comes in well below all prior authorised envelopes</b>, so this does not require a new sign-off &mdash; this email constitutes notice of the final number coming in under budget.</p>

<p>If either of you wants the board memo regenerated with the updated final figure of <b>Rs. 5,52,441 / $6,577</b> and the corrected 22-person workforce baseline for the file, reply &ldquo;regenerate&rdquo; and I will turn it around today.</p>

<hr/>

<p>Available on call all day Sunday and on Monday morning during the delivery window (9:30 AM IST is approximately 9:00 PM PDT Sunday for me). Will send a delivery confirmation to both of you once Ajay/Gurdeep report all six packets handed over.</p>

__SIG__

</div>
</body>
</html>
'@

$htmlBody = $bodyTemplate.Replace('__FONT__', $fontStack).Replace('__SIG__', $sig)

if ($htmlBody -match '\$\s+\d') { throw "Detected stripped dollar sign before digit. Aborting." }
if ($htmlBody -match '__FONT__|__SIG__') { throw "Detected unfilled template placeholder. Aborting." }

Write-Host "`nStaging attachments..." -ForegroundColor Cyan
$attachments = @()
foreach ($map in $attachmentMap) {
    if (-not (Test-Path $map.Src)) { throw "Source file not found: $($map.Src)" }
    $bytes = [System.IO.File]::ReadAllBytes($map.Src)
    $b64   = [Convert]::ToBase64String($bytes)
    $attachments += @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name          = $map.Name
        contentType   = "application/pdf"
        contentBytes  = $b64
    }
    Write-Host ("  [+] {0}" -f $map.Name) -ForegroundColor Gray
}

Write-Host "`nCreating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject      = $subject
    Importance   = "high"
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($to | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    Attachments  = $attachments
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "`nSending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT to directors." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts for $senderUpn." -ForegroundColor Yellow
    Write-Host "  To: Chandra P. Jain <cpjain@technijian.com>; Daya Krishan Sharma <DKSharma@technijian.com>" -ForegroundColor Gray
    Write-Host "  Subject: $subject" -ForegroundColor Gray
    Write-Host ("  Attachments: {0} PDFs" -f $attachmentMap.Count) -ForegroundColor Gray
}

Disconnect-MgGraph | Out-Null
