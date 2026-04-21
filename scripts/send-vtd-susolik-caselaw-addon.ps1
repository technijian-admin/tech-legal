# Add-on email to Ed Susolik with the 2020-2026 case law upgrade research.
# Companion to send-vtd-susolik-pod-update.ps1 which was sent earlier today.
#
# Usage:
#   .\send-vtd-susolik-caselaw-addon.ps1          # draft only (DEFAULT)
#   .\send-vtd-susolik-caselaw-addon.ps1 -Send    # send immediately

param([switch]$Send)
$ErrorActionPreference = "Stop"

$to = @( @{ Address = "es@callahan-law.com"; Name = "Edward Susolik, Esq." } )
$senderUpn = "RJain@technijian.com"
$subject   = "VTD - Add-On: 2020-2026 Case Law Upgrade Research"

$sigPath      = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"
$attachFolder = "C:\vscode\tech-legal\tech-legal\terminated-clients\VTD\send-packages\2026-04-17_ed-caselaw"

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

<p>Add-on to the email I sent earlier today about the POD-column disclosure evidence. While I was on the VTD matter, I ran a targeted 2020&ndash;2026 California sweep against the authorities in the 4/14 Case Law Research Memorandum to see if anything newer or stronger should be cited before the settlement conference.</p>

<p>Short version: the 4/14 memo is in better shape than I initially worried. Course of performance, &sect;&nbsp;1717 reciprocity, &sect;&nbsp;3287(a) prejudgment interest, and business-records doctrine are all settled and stable. Three meaningful upgrades, three adverse cases to have ready to distinguish. Full write-up and source links are in the attached document; this email is the summary.</p>

<p><b>Grade A &mdash; Cite in the memo</b></p>

<p>1. <b><i>Gormley v. Gonzalez</i></b> (2022) 84 Cal.App.5th 72. In a non-consumer contract, &sect;&nbsp;1671(b) creates "a general rule favoring the enforcement of liquidated damages provisions"; the challenger bears the burden. Pairs with <i>Ridgley</i> and sharpens the burden-shift. Belongs in &sect;&nbsp;2.</p>

<p>2. <b><i>Iyere v. Wise Auto Group</i></b> (2023) 87 Cal.App.5th 747. Bare "I don't recall signing" is insufficient to dispute authenticity; authentication may be "carried in any manner." First post-2020 published appellate decision to rebalance the e-sig authentication burden toward the proponent. Belongs in &sect;&nbsp;17 alongside <i>Fabian</i> and <i>Ruiz</i>. Caveat: <i>Iyere</i> concerned a physical signature and the court distinguished electronic ones, so cite for the burden framework, not as direct e-sig authority.</p>

<p>3. <b><i>People v. Hawkins</i></b> (2002) 98 Cal.App.4th 1428. Backstops the Evid.&nbsp;Code &sect;&nbsp;1552 presumption that printed representations of computer-generated information are accurate. Pre-2020 but stronger than <i>Aguimatang</i> alone on that narrow point. Belongs in &sect;&nbsp;23.</p>

<p><b>Grade B &mdash; Consider</b></p>

<p>4. <b><i>Constellation-F, LLC v. World Trading 23, Inc.</i></b> (2020) 45 Cal.App.5th 22 &mdash; &sect;&nbsp;1671 targets "unfair and unreasonable coercion." Analogy support for the arms-length cancellation-rate argument.</p>

<p>5. <b><i>Ramirez v. Charter Communications, Inc.</i></b> (2024) 16 Cal.5th 478 &mdash; 2024 California Supreme Court on unconscionability: assessed at time of formation, not hindsight; multiple unconscionable provisions trigger a <i>qualitative</i> severance analysis. Employment origin but generalizable. Defensive cite for &sect;&nbsp;15 if Vintage attacks the AAA clause.</p>

<p><b>Grade C &mdash; Adverse; have ready to distinguish</b></p>

<p>6. <b><i>Bannister v. Marinidence Opco, LLC</i></b> (2021) 64 Cal.App.5th 541 &mdash; e-sig authentication failed where pin was not user-specific. Likely Vintage playbook if Garcia denies signing. Distinguish: DocuSign tied to Garcia's Vintage corporate email; Certificate of Completion shows unique authentication, IP, and timestamp; 27 months of ratified performance settle attribution independently.</p>

<p>7. <b><i>Honchariw v. FJM Private Mortgage Fund, LLC</i></b> (2022) 83 Cal.App.5th 893 &mdash; late fees on full loan principal violated &sect;&nbsp;1671. Distinguish: <i>Honchariw</i> imposed fees on the entire balance triggered by a single default (disproportionality). The Technijian rate applies only to hours actually worked at overage, tied to measured usage, and sits at or below the Agreement's own out-of-contract rates.</p>

<p>8. <b><i>Graylee v. Castro</i></b> (2020) 52 Cal.App.5th 1107 &mdash; stipulated-judgment LD violated &sect;&nbsp;1671(b). Distinguish: residential-tenancy stipulated judgment, not a negotiated commercial-services rate between sophisticated parties.</p>

<p><b>Awareness only</b></p>

<p><i>Hohenshelt v. Superior Court</i> (2025) &mdash; CCP &sect;&sect;&nbsp;1281.97/1281.98 fee-payment deadlines; relevant to fee administration once arbitration is under way, not enforceability.<br>
<i>New England Country Foods, LLC v. Vanlaw Food Products</i> (2025) &mdash; &sect;&nbsp;1668 limits contractual limitations of liability for willful injury; only relevant if Vintage pivots to a &sect;&nbsp;1668 theory.</p>

<p><b>What is stable (no upgrade needed)</b></p>

<p>Course of performance and ratification (&sect;&nbsp;8&ndash;10), &sect;&nbsp;1717 reciprocity (&sect;&nbsp;11), &sect;&nbsp;3287(a) certainty (&sect;&nbsp;12), and the business-records foundation doctrine (&sect;&nbsp;23) are all settled; no material 2020&ndash;2026 opinion improves on the existing authority. Worth a one-sentence affirmation in the memo that the doctrine is stable post-2020.</p>

<p>All of the above is in the attached Word document with full holdings, distinguishing notes, and source links. Shepardize all citations before any filing.</p>

<p>I can regenerate <code>Case_Law_Research_Memorandum.docx</code> with these additions embedded whenever you confirm which to integrate.</p>

<p>Thanks, Ed.</p>

</div>
$sig
</body>
</html>
"@

Write-Host "Connecting to Graph..." -ForegroundColor Cyan
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome
Write-Host "Connected." -ForegroundColor Green

Write-Host "`nStaging attachments..." -ForegroundColor Cyan
$attachments = @()
$files = Get-ChildItem -Path $attachFolder -File | Sort-Object Name
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $b64   = [Convert]::ToBase64String($bytes)
    $ctype = switch -Wildcard ($f.Name) {
        "*.docx" { "application/vnd.openxmlformats-officedocument.wordprocessingml.document"; break }
        "*.pdf"  { "application/pdf"; break }
        "*.md"   { "text/markdown"; break }
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

$draftParams = @{
    Subject = $subject
    Body = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @($to | ForEach-Object { @{ EmailAddress = @{ Address = $_.Address; Name = $_.Name } } })
    Attachments  = $attachments
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

if ($Send) {
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "SENT to $($to[0].Address)." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts." -ForegroundColor Yellow
    Write-Host "  To: $($to[0].Address)"
    Write-Host "  Subject: $subject"
    Write-Host "`nReview in Outlook, then click Send or re-run with -Send." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
