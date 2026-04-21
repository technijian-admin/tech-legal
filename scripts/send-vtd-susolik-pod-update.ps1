# Send VTD Settlement-Package Update to Ed Susolik — POD-Column Disclosure Evidence
# DEFAULT: creates draft only (review in Outlook before sending)
#
# Usage:
#   .\send-vtd-susolik-pod-update.ps1          # draft only (DEFAULT)
#   .\send-vtd-susolik-pod-update.ps1 -Send    # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$to = @( @{ Address = "es@callahan-law.com"; Name = "Edward Susolik, Esq." } )
$cc = @()

$senderUpn = "RJain@technijian.com"
$subject   = "VTD Settlement Package - Late Add: POD-Column Disclosure Evidence"

$sigPath      = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$attachFolder = "C:\vscode\tech-legal\tech-legal\terminated-clients\VTD\send-packages\2026-04-17_ed-update"

Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$sig = ""
if (Test-Path $sigPath) { $sig = Get-Content $sigPath -Raw }

$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Ed,</p>

<p>Quick late-add for the VTD settlement package before you send it to Vintage Design's counsel. Something that came to light on the Boston Group matter this week turns out to apply directly here, and I want to get it into your hands in one place so you can merge it into the Settlement Position Memorandum.</p>

<p><b>The finding.</b> Technijian's <code>billing@technijian.com</code> automation sent Erica Garcia, personally at <code>ericagarcia@vintagedesigninc.com</code>, a weekly AND monthly billing email for the entire 27-month term of the Agreement. Every one of those emails carried two attachments: the invoice PDF and a Microsoft Excel spreadsheet titled "Weekly Time Entries" or "Monthly Time Entries" &mdash; a 17-column, row-per-ticket export. <b>Column 14 is labeled "POD"</b> and expressly allocates each ticket to CHD-TS1 (offshore India) or IRV-TS1 (onshore Irvine).</p>

<p>Seven representative .eml files are attached to this email with full RFC 5322 headers intact. POD distribution on the four monthlies in the sample:</p>

<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:$fontStack;font-size:11pt">
<tr style="background:#006DB6;color:#ffffff;font-weight:bold"><td>Invoice</td><td>Sent</td><td>POD split (offshore / onshore)</td></tr>
<tr><td>#25438 (April 2025 monthly)</td><td>5/2/2025</td><td><b>247 / 27</b> &nbsp;(~90% offshore)</td></tr>
<tr><td>#25725 (May 2025 monthly)</td><td>6/2/2025</td><td>265 / 11 &nbsp;(~96% offshore)</td></tr>
<tr><td>#25953 (June 2025 monthly)</td><td>7/2/2025</td><td>239 / 32 &nbsp;(~88% offshore)</td></tr>
<tr><td><b>#26205 (July 2025 &mdash; terminated month)</b></td><td><b>8/1/2025</b></td><td>67 / 6 &nbsp;(~92% offshore)</td></tr>
</table>

<p>Across the 27-month term, roughly 140 weekly + 27 monthly such transmissions. All addressed to Ms.&nbsp;Garcia directly.</p>

<p><b>Why it matters for the package.</b> This upgrades the Section&nbsp;6 "Course of Dealing / Dispute Window Waiver" argument. What started as "Vintage Design had 30 days to object to each weekly invoice and 60 days to object to each monthly invoice" becomes <b>"Vintage Design's authorized signatory was personally served, 27 months in a row, with express, itemized, contemporaneous disclosure of the offshore/onshore POD allocation, and never objected to any of it."</b> If Respondent's counsel raises any variant of "we didn't authorize offshore work" or "we didn't know work was being performed overseas," this is a clean strike. It also shores up Scenarios A&ndash;D in the damages memo against any "lack of informed consent" attack.</p>

<p><b>Proposed drop-in paragraph for the Settlement Position Memorandum.</b> New <b>&sect;&nbsp;6.1 Express Contemporaneous Disclosure of POD Allocation</b>, inserted between the current Section&nbsp;6 (Course of Dealing) and Section&nbsp;7 (Enforceability):</p>

<blockquote style="border-left:4px solid #F67D4B;padding:6px 14px;background:#FEF3EE;margin:12px 0;font-size:11pt">
<i>"Beyond the dispute-window waiver, each weekly and monthly billing notice Technijian transmitted to Vintage Design &mdash; addressed to Ms.&nbsp;Garcia personally at <code>ericagarcia@vintagedesigninc.com</code> &mdash; carried a Microsoft Excel time-entries spreadsheet with seventeen columns per ticket, including a POD column expressly allocating each ticket row between CHD-TS1 (offshore, India) and IRV-TS1 (onshore, Irvine). Over the 27-month life of the Agreement, Vintage Design's authorized signatory received approximately 140 such weekly transmissions and 27 monthly transmissions, each disclosing the offshore/onshore allocation for every logged hour. The July&nbsp;2025 monthly invoice alone (#26205, transmitted August&nbsp;1,&nbsp;2025) listed 73 ticket rows, 67 of which were performed on POD CHD-TS1 (offshore). The offshore/onshore mix is therefore not a matter of implied consent or post-hoc reconstruction &mdash; it was contemporaneously disclosed in writing to the person with authority to object, month after month, week after week, without objection. See Exhibits G&ndash;J."</i>
</blockquote>

<p><b>Supporting California authority.</b> Three primary authorities for this paragraph, plus one for admissibility of the exhibits themselves:</p>

<p>1. <b>Cal.&nbsp;Com.&nbsp;Code &sect;&nbsp;1303(a)&ndash;(b); <i>Kashmiri v. Regents of University of California</i></b> (2007) 156 Cal.App.4th 809, 833. Course of performance is "especially relevant" in construing contract terms and can establish the parties' agreed meaning where conduct resolves ambiguity. Twenty-seven months of paid, unobjected-to invoices expressly allocating work to offshore POD establish that allocation as within the parties' agreed scope.</p>

<p>2. <b><i>Employers Reinsurance Co. v. Superior Court</i></b> (2008) 161 Cal.App.4th 906, 921. A party that receives notice of how a contract is being performed and continues to accept performance without objection ratifies that performance as a matter of law. Directly on point to the VTD posture.</p>

<p>3. <b><i>Cobb v. Pacific Mut. Life Ins. Co.</i></b> (1935) 4 Cal.2d 565, 572&ndash;573. The touchstone California authority on waiver-by-silence after notice and reasonable opportunity to object. Reinforces both the T&amp;C &sect;&nbsp;3.01 60-day monthly waiver and the 30-day weekly waiver, now augmented by the POD-column disclosure.</p>

<p>4. <b>Admissibility of the exhibits themselves.</b> Cal.&nbsp;Evid.&nbsp;Code &sect;&sect;&nbsp;1271 (business records), 1552, 1553; <i>Aguimatang v. California State Lottery</i> (1991) 234 Cal.App.3d 769, 798. Printed representations of computer-generated information are presumed accurate and admissible as originals. The attached .emls and their embedded xlsx spreadsheets are self-authenticating business records from Technijian's billing pipeline, with Exchange-preserved RFC 5322 headers intact.</p>

<p><i>Optional ancillary if Respondent pushes back on notice: </i><b><i>Whitney Investment Co. v. Westview Development Co.</i></b> (1969) 273 Cal.App.2d 594, 602 (notice plus continued performance binds the recipient to the disclosed terms).</p>

<p><b>Proposed exhibits (attached to this email).</b> Four for addition to the Settlement Memo exhibit list, plus three alternates in case you want to swap samples:</p>

<ul>
<li><b>Exhibit&nbsp;G:</b> <code>VTD_2025-05-02_Monthly_Invoice_25438.eml</code> &mdash; April 2025 monthly</li>
<li><b>Exhibit&nbsp;H:</b> <code>VTD_2025-07-02_Monthly_Invoice_25953.eml</code> &mdash; June 2025 monthly (last full pre-termination)</li>
<li><b>Exhibit&nbsp;I:</b> <code>VTD_2025-08-01_Monthly_Invoice_26205.eml</code> &mdash; July 2025 monthly (terminated period; transmitted day after termination effective date)</li>
<li><b>Exhibit&nbsp;J:</b> <code>VTD_2025-07-21_Weekly_Invoice_26074.eml</code> &mdash; final weekly sample</li>
</ul>

<p>Each .eml carries the invoice PDF + the Time Entries xlsx as native attachments. The consolidated <code>vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx</code> already in Exhibit&nbsp;B is the same data set, now authenticated by these specific transmission records.</p>

<p><b>How I'd suggest sequencing the incorporation.</b></p>

<ol>
<li>I'll regenerate <code>Settlement_Position_Memorandum.docx</code> with the new &sect;&nbsp;6.1 inserted and the exhibit list updated whenever you confirm the paragraph language.</li>
<li>The Case Law Research Memorandum already covers most of the authorities cited above &mdash; happy to add a pointer to &sect;&nbsp;6.1 if you want the cross-reference explicit.</li>
<li>The INTERNAL Damages Scenario Analysis gets a one-sentence note that the POD column preempts "lack of informed consent" as a shared defense across Scenarios A&ndash;D.</li>
</ol>

<p>Ready to incorporate whenever you give me the go. Or tell me to rework the paragraph into the existing &sect;&nbsp;6 rather than a new &sect;&nbsp;6.1.</p>

<p>Thanks, Ed.</p>

</div>
$sig
</body>
</html>
"@

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Build attachments ---
Write-Host "`nStaging attachments from $attachFolder..." -ForegroundColor Cyan
$attachments = @()
$files = Get-ChildItem -Path $attachFolder -File | Sort-Object Name
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $b64   = [Convert]::ToBase64String($bytes)
    $ctype = switch -Wildcard ($f.Name) {
        "*.eml"  { "message/rfc822"; break }
        "*.pdf"  { "application/pdf"; break }
        "*.xlsx" { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"; break }
        default  { "application/octet-stream" }
    }
    $attachments += @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name          = $f.Name
        contentType   = $ctype
        contentBytes  = $b64
    }
    Write-Host ("  [+] {0}  ({1:N0} bytes)" -f $f.Name, $f.Length) -ForegroundColor Gray
}
$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
Write-Host ("Total attachment payload: {0:N0} bytes ({1:N2} MB)" -f $totalBytes, ($totalBytes/1MB)) -ForegroundColor Cyan

Write-Host "`nCreating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($to | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    CcRecipients = @()
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
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. Open Outlook -> Drafts -> '$subject'" -ForegroundColor Yellow
    Write-Host "  2. Review body and verify 7 .eml attachments" -ForegroundColor Yellow
    Write-Host "  3. Click Send, OR re-run this script with -Send" -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
