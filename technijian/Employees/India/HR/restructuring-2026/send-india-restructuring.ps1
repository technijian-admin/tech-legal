# Send India Workforce Restructuring Instructions to Ajay/Gurdeep
# Cleans up 7 prior badly-formatted drafts, then creates ONE properly-branded draft
# with all 6 termination/retrenchment letter PDFs attached.
#
# DEFAULT: creates draft only (review in Outlook before sending)
# Recipient names left as first-name only -- Outlook auto-completes on open.
#
# Usage:
#   .\send-india-restructuring.ps1          # draft only (DEFAULT)
#   .\send-india-restructuring.ps1 -Send    # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

# ── Recipients ───────────────────────────────────────────────────────────────
$to = @(
    @{ Address = "ABhardwaj@technijian.com"; Name = "Ajay Bhardwaj" },
    @{ Address = "GKumar@technijian.com";    Name = "Gurdeep Kumar" }
)
$cc = @()

$senderUpn = "RJain@technijian.com"
$subject   = "CONFIDENTIAL - Workforce Restructuring: Action Items Before Monday May 11"

$sigPath           = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$letterPdfDir      = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\letters\pdf"
$letterSignedDir   = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\letters\pdf-signed"
$leavePdfDir       = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\leave-applications\pdf"
$leaveSignedDir    = "C:\vscode\tech-legal\tech-legal\technijian\Employees\India\HR\restructuring-2026\leave-applications\pdf-signed"

# Resolve a PDF path: prefer signed version if available, else fall back to unsigned.
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

$signedCount   = ($attachmentMap | Where-Object { $_.Signed -eq $true }).Count
$unsignedCount = ($attachmentMap | Where-Object { $_.Signed -eq $false }).Count
$pendingSig    = $unsignedCount -gt 0

# ── Auth ─────────────────────────────────────────────────────────────────────
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# ── Cleanup: delete the 7 prior drafts created by create-drafts.ps1 ──────────
Write-Host "`nDeleting prior 7 drafts..." -ForegroundColor Cyan
$badSubjects = @(
    "CONFIDENTIAL - Workforce Restructuring: Action Items Before Monday May 11",
    "Confidential: Notice of Termination of Employment - Devesh Bhattacharya",
    "Confidential: Notice of Termination of Employment - Rajat Kumar",
    "Confidential: Notice of Termination of Employment - Aditya Saraf",
    "Confidential: Notice of Termination of Employment - Suresh Kumar Sharma",
    "Confidential: Notice of Retrenchment - Yogesh Kumar",
    "Confidential: Notice of Retrenchment - Rahul Uniyal"
)

$drafts = Get-MgUserMessage -UserId $senderUpn -Filter "isDraft eq true" -Top 100 -Property "id,subject"
$deleted = 0
foreach ($d in $drafts) {
    if ($badSubjects -contains $d.Subject) {
        Remove-MgUserMessage -UserId $senderUpn -MessageId $d.Id -Confirm:$false
        Write-Host "  [x] Deleted: $($d.Subject)" -ForegroundColor DarkGray
        $deleted++
    }
}
Write-Host "Deleted $deleted prior draft(s)." -ForegroundColor Yellow

# ── Signature ────────────────────────────────────────────────────────────────
$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"

# ── Body (branded HTML, single-quoted here-string) ───────────────────────────
$bodyTemplate = @'
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:__FONT__;font-size:11pt;color:rgb(0,0,0)">

<p>Ajay, Gurdeep,</p>

<p>As discussed, we are proceeding with a planned restructuring of six team members effective <b>Monday, May 11, 2026</b>. Please treat this as strictly confidential.</p>

<p>All six letters are attached as PDFs. The leave applications for the three EL-burn employees are also attached. You need to print, seal in envelopes, and hand-deliver everything Monday morning.</p>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">By Sunday Evening (May 10)</p>

<p style="margin:10px 0 4px 0;font-weight:bold">1. Print and seal the letter packets</p>
<p>Print each attached PDF and seal in a separate envelope addressed to each person.</p>
<p>For <b>Yogesh Kumar, Rahul Uniyal, and Suresh Kumar Sharma</b>, also print the matching leave application (3 separate PDFs attached) and put it in the same envelope as their letter. They will sign the leave application Monday morning when they receive their letter.</p>

<p style="margin:10px 0 4px 0;font-weight:bold">2. IT access revocation &mdash; stage now, execute Monday morning at 9:30 AM IST sharp</p>
<p>Coordinate with whoever handles IT access to have the following ready to revoke at the exact moment letters are handed out: VPN, client RMM/monitoring tools, remote desktop, company email, client portal credentials, M365.</p>
<p>All six employees: Devesh Bhattacharya, Rajat Kumar, Aditya Saraf, Suresh Kumar Sharma, Yogesh Kumar, Rahul Uniyal.</p>
<blockquote style="border-left:4px solid #F67D4B;padding:8px 14px;background:#FEF3EE;margin:10px 0;font-size:10.5pt">
<b>Do not revoke early.</b> Stage the revocations and hold them until Monday morning. Early revocation tips off the affected staff and lets them act before delivery.
</blockquote>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Monday, May 11 &mdash; Morning Process (9:30 AM start)</p>

<p>Deliver all six letters simultaneously. One-on-one meetings, back-to-back, within 30 minutes total. Roles for the meetings are fixed:</p>
<ul>
<li><b>Ajay</b> &mdash; hands over the envelope to each employee, walks them through the letter, gets the acknowledgement strip signed, and signs the &ldquo;Handed over by&rdquo; line on the leave application (for Yogesh, Rahul, Suresh).</li>
<li><b>Gurdeep</b> &mdash; sits in as the witness in every meeting, writes the time on Ajay&rsquo;s copy of each letter, and signs the &ldquo;Witnessed by&rdquo; line on the leave application.</li>
</ul>
<p>Note the time and date of delivery on the office copy of each letter. The pre-printed signature blocks for both of you are already on the leave applications &mdash; just add your handwritten signature and the time.</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:__FONT__;font-size:10pt;width:100%">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold">
  <td width="30%">Employee</td><td>What happens Monday</td>
</tr>
<tr>
  <td>Aditya Saraf</td>
  <td>Released immediately. Signs acknowledgement, returns laptop and any other company equipment that morning. Access revoked at the same moment.</td>
</tr>
<tr style="background:#FEF3EE">
  <td>Yogesh Kumar<br/>Rahul Uniyal<br/>Suresh Kumar Sharma</td>
  <td>Letter handed over. Leave application signed (the one in their envelope). They go on paid leave from May 11 through May 31 &mdash; do not come to office, do not work. Returns equipment May 31. Access revoked Monday at handover.</td>
</tr>
<tr>
  <td>Devesh Bhattacharya<br/>Rajat Kumar</td>
  <td>Letter handed over. They continue working through May 31 to wrap up active tickets. Move them off any sensitive client systems Monday morning.</td>
</tr>
</table>

<p>If anyone refuses to sign the acknowledgement, that is fine &mdash; Gurdeep writes &ldquo;Delivered, refused to sign&rdquo; with the time on the office copy. The letter is still legally delivered the moment they take possession of the envelope.</p>

<p>If <b>Yogesh, Rahul, or Suresh refuses to sign the leave application</b>, do the following:</p>
<ol>
<li>Hold their leave form and deliver the letter only.</li>
<li>Inform them clearly &mdash; <b>refusing to sign the leave application means they will not be eligible for re-hire by Technijian when the cashflow situation improves and we are in a position to bring people back.</b> Employees who sign and complete the process cleanly stay on our re-hire list. Refusal removes them from it.</li>
<li>Call me before noon IST so I can adjust their settlement and update our records.</li>
</ol>

<hr/>

<p style="margin:14px 0 4px 0;font-weight:bold;font-size:13pt;color:#006DB6">Ground Rules</p>

<ul>
<li><b>Strictly confidential until Monday morning.</b> Do not discuss with anyone outside this thread &mdash; not other team leads, not other staff, not vendors. The IT revocation staging in item 2 is the most likely leak point; brief whoever stages it on a need-to-know basis only.</li>
<li>If any of the six asks pointed questions before Monday (about workload, about whether their position is secure, about anyone else), <b>do not answer.</b> Tell them to contact me directly. I will handle.</li>
<li>If any of the six is absent on Monday May 11, hold their packet and call me before 11:30 AM IST. We will arrange registered post + email as the fallback &mdash; the letter dates do not change.</li>
</ul>

<hr/>

<p>Please confirm by reply once (a) letter packets and leave applications are printed and sealed in envelopes, and (b) the IT revocation list is staged with whoever will execute it Monday morning.</p>

<p>Call me on my mobile if anything is unclear. We do this clean, simultaneous, and once.</p>

__SIG__

</div>
</body>
</html>
'@

$htmlBody = $bodyTemplate.Replace('__FONT__', $fontStack).Replace('__SIG__', $sig)

# ── Preflight ────────────────────────────────────────────────────────────────
if ($htmlBody -match '\$\s+\d') {
    throw "Detected stripped dollar sign before digit. Aborting."
}
if ($htmlBody -match '__FONT__|__SIG__') {
    throw "Detected unfilled template placeholder. Aborting."
}

# ── Stage attachments ────────────────────────────────────────────────────────
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
    $tag = if ($map.Signed -eq $true) { "[SIGNED]" } elseif ($map.Signed -eq $false) { "[unsigned]" } else { "[employee-sign]" }
    Write-Host ("  {0} {1}" -f $tag, $map.Name) -ForegroundColor Gray
}

# ── Create draft ─────────────────────────────────────────────────────────────
Write-Host "`nCreating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject      = $subject
    Importance   = "high"
    Body         = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($to | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    CcRecipients = @($cc | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    Attachments  = $attachments
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Write-Host "`nSending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts for $senderUpn." -ForegroundColor Yellow
    Write-Host "  To: Ajay Bhardwaj <ABhardwaj@technijian.com>; Gurdeep Kumar <GKumar@technijian.com>" -ForegroundColor Gray
    Write-Host "  Subject: $subject" -ForegroundColor Gray
    Write-Host ("  Attachments: {0} PDFs ({1} signed letters / {2} unsigned letters / 3 employee-sign leave apps)" -f $attachmentMap.Count, $signedCount, $unsignedCount) -ForegroundColor Gray
    if ($pendingSig) {
        Write-Host "`nWARNING: Some letters are still UNSIGNED." -ForegroundColor Red
        Write-Host "  -> Print PDFs from letters\pdf\, sign each as Director, scan back to letters\pdf-signed\ with the SAME filename, then re-run this script." -ForegroundColor Yellow
    } else {
        Write-Host "`nAll 6 letters are signed. Draft is ready to send." -ForegroundColor Green
    }
}

Disconnect-MgGraph | Out-Null
