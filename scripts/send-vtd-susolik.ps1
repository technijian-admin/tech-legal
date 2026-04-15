# Send VTD Settlement Package to Edward Susolik, Esq. via Microsoft Graph
# Creates draft -> attaches 8 files -> sends -> saves to Sent Items

$ErrorActionPreference = "Stop"

$recipientEmail = "es@callahan-law.com"
$recipientName  = "Edward Susolik"
$senderUpn      = "RJain@technijian.com"
$subject        = "Settlement Position Package - Technijian v. Vintage Design - For Your Review Before the Counsel Conference"

$vtdDir = "C:\vscode\tech-legal\tech-legal\terminated-clients\vtd"
$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$attachments = @(
    "$vtdDir\Settlement_Position_Memorandum.docx",
    "$vtdDir\Damages_Scenario_Analysis_INTERNAL.docx",
    "$vtdDir\Case_Law_Research_Memorandum.docx",
    "$vtdDir\Vintage_Design-Monthly_Service.pdf",
    "$vtdDir\vtd_InvoiceDetails_2023-01-01_to_2026-04-14.xlsx",
    "$vtdDir\vtd_actual_vs_bill.xlsx",
    "$vtdDir\Technijian Demand For Arb Complaint 10.23.25-169358.pdf",
    "$vtdDir\vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx"
)

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
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

# --- Build HTML body ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Ed,</p>

<p>Ahead of the counsel conference we discussed, I've put together a settlement package for your review. The goal is to arm you with a clean factual and legal position to present to Respondent's counsel, with the aim of resolving this before depositions.</p>

<p><strong>The Demand's material allegations align with the signed Agreement.</strong> The operative Agreement is the Client Monthly Service Agreement, signed via DocuSign on May 4, 2023 by Erica Garcia (VP Finance, Vintage Design) and me (Envelope ID B679C550-E41C-4E31-BE34-7F8FFF437C3D). The 12-month under-contract period, `$150/hour cancellation rate, POD rates (`$15 / `$30 / `$125), and signatory identity all match as pleaded. The only caption cleanup item is &quot;Delaware LLC&quot; to &quot;California corporation&quot; per the four corners of the signed Agreement, a routine correction under AAA Rule R-6.</p>

<p><strong>Damages &mdash; recalculated and confirmed, with one math correction.</strong> Reconciling every month of billed vs. actual ticketed hours across the three contracted support categories through the July 31, 2025 effective termination date: net excess totals 1,330.76 hours; gross positive excess is 1,413.94 hours; monthly positive excess is 1,878.67 hours. The Demand's pleaded 1,457.50 figure sits squarely within this defensible range. At `$150/hour plus the 10% late fee under &quot;Other Terms&quot; &para; 3, the contract-correct principal is <strong>`$240,487.50</strong> (`$218,625.00 + `$21,862.50). The Demand's pleaded `$240,555.15 reflects a `$67.65 arithmetic discrepancy in the late-fee line; the settlement memo anchors at the contract-correct `$240,487.50 and proposes a stipulated caption/damages amendment to conform the Demand. With prejudgment interest and attorneys' fees recoverable via T&amp;C &sect; 5.02 indemnity + Cal. Civ. Code &sect; 1717 reciprocity, total exposure runs approximately <strong>`$325,000&ndash;`$370,000</strong> through award.</p>

<p><strong>Significant leverage point I want to flag.</strong> Throughout the entire 27-month performance period, Technijian sent Vintage Design <strong>weekly zero-dollar invoices</strong> enumerating every ticket, time entry, and hour worked that week, accompanied by a <strong>30-day dispute window</strong> &mdash; approximately 140 such weekly notices across the life of the Agreement. Vintage Design disputed <strong>none</strong>. Combined with the 60-day objection waiver in T&amp;C &sect; 3.01 for monthly invoices (also none objected), every ticketed hour is effectively indisputable under course-of-performance principles (Cal. Com. Code &sect; 1303) plus <em>Cobb v. Pacific Mut. Life Ins. Co.</em> (1935) 4 Cal.2d 565 and <em>Gleason v. Klamer</em> (1980) 103 Cal.App.3d 782. I've built this into the memos as the primary rebuttal to the &quot;records aren't accurate&quot; defense.</p>

<p><strong>A few case-law framing notes for your Shepard pass.</strong> The case law memo now (i) relies on apparent authority plus ratification for the signatory-authority argument rather than a single-officer reading of Cal. Corp. Code &sect; 313; (ii) cites <em>Garrett</em>, <em>Beasley</em>, and <em>Greentree</em> as the &sect; 1671(b) framework, distinguishing them since each case invalidated the specific clause at issue; and (iii) cites <em>Ruiz</em> and <em>Fabian</em> for the DocuSign authentication <em>standard</em> that Technijian's completion certificate, IP/timestamp metadata, and 27 months of paid performance exceed. Flagging so nothing surprises you.</p>

<p><strong>Attached (Word format, on Technijian letterhead):</strong></p>

<ol>
<li><strong>Settlement_Position_Memorandum.docx</strong> &mdash; drafted as a firm, factual position letter you can send to Respondent's counsel (fill in the addressee line once confirmed). Anchors the ask at `$240,487.50, reconciles to the Demand with the `$67.65 correction noted, stipulates the caption amendment, and integrates controlling California authority for each issue the arbitrator will need to decide.</li>
<li><strong>Damages_Scenario_Analysis_INTERNAL.docx</strong> &mdash; <strong>attorney-client privileged / work product; not for opposing counsel.</strong> Walks through all six alternative damages readings (range: approximately `$0 to `$309,980.55) with arguments for and against each. Includes full legal rebuttals, with California authority, for why the three sub-floor readings Respondent will push (Scenarios C, E1, E2) are not legally plausible. Recommends: opening at the contract-correct `$240,487.50, landing zone `$150,000&ndash;`$180,000, walk-away floor `$125,000.</li>
<li><strong>Case_Law_Research_Memorandum.docx</strong> &mdash; 30 sections of California authority organized by argument, including the strengthened &sect; 9 covering the dual (weekly + monthly) dispute-window waivers, and &sect; 11 framed around the &sect; 5.02 indemnity / &sect; 1717 reciprocity fee-shifting theory. All citations flagged for Shepardizing before filing.</li>
</ol>

<p><strong>Supporting exhibits (PDFs and spreadsheets):</strong></p>

<ol start="4">
<li><strong>Vintage_Design-Monthly_Service.pdf</strong> &mdash; <em>Exhibit A:</em> the 5/4/2023 DocuSigned Agreement (Envelope ID B679C550-E41C-4E31-BE34-7F8FFF437C3D).</li>
<li><strong>vtd_InvoiceDetails_2023-01-01_to_2026-04-14.xlsx</strong> &mdash; <em>Exhibit B:</em> full monthly invoice ledger. Query window is wide; data runs through the July 31, 2025 termination.</li>
<li><strong>vtd_actual_vs_bill.xlsx</strong> &mdash; <em>Exhibit C:</em> month-by-month billed-vs-actual reconciliation across the three contracted support categories. This is the source for the 1,330.76 net excess and all supporting numbers in the memo.</li>
<li><strong>Technijian Demand For Arb Complaint 10.23.25-169358.pdf</strong> &mdash; <em>Exhibit F:</em> the filed Demand, for reference.</li>
<li><strong>vtd_TicketTimeEntries_2023-01-01_to_2026-04-14.xlsx</strong> &mdash; supporting ticket-level detail for Rule R-22 production. Query window is wide; ticket data runs through the July 31, 2025 termination.</li>
</ol>

<p><strong>Settlement strategy summary</strong> (detail in the internal analysis):</p>

<ul>
<li>Opening / stated in memo: <strong>`$240,487.50</strong> (contract-correct; Demand reconciled)</li>
<li>First concession: `$200,000&ndash;`$220,000 (Scenarios A/B territory)</li>
<li>Realistic landing zone: `$150,000&ndash;`$180,000</li>
<li><strong>Walk-away floor: `$125,000</strong> (below this, arbitrate to award; economics favor litigation given fees recoverable via &sect; 5.02 + &sect; 1717)</li>
<li>Internal ceiling (if pushed): `$309,980.55 (Scenario D &mdash; monthly positive excess at `$150/hour)</li>
</ul>

<p>A few items I'd like your input on:</p>

<ul>
<li><strong>Entity relationship.</strong> Please confirm the correct entity designation for the caption amendment (parent/DBA/successor between &quot;Vintage Design, LLC&quot; as pleaded and &quot;Vintage Design, a California corporation&quot; as on the signed Agreement).</li>
<li><strong>The 1,457.50 hour figure in the current Demand.</strong> It is defensible from the reconciliation spreadsheet (sits between gross positive 1,413.94 and monthly positive 1,878.67). If you have a specific methodology behind 1,457.50, I'd like to document it for deposition readiness.</li>
<li><strong>The `$67.65 late-fee discrepancy in the Demand.</strong> I'd like to align on whether to amend the Demand now under AAA Rule R-6 to the contract-correct `$240,487.50, or to flag it only at settlement as part of the stipulated caption/damages amendment.</li>
<li><strong>Termination notice and June 27, 2025 final invoice</strong> &mdash; both are in your file and referenced as Exhibits D and E in the memo.</li>
</ul>

<p>I'd like to meet briefly once you've had a chance to review, before any settlement outreach goes out. Let me know what works for a call this week.</p>

<p>Thanks, Ed.</p>

</div>
$sig
</body>
</html>
"@

# --- Connect to Graph ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected." -ForegroundColor Green

# --- Create draft ---
Write-Host "Creating draft message..." -ForegroundColor Cyan
$draftParams = @{
    Subject = $subject
    Body = @{
        ContentType = "HTML"
        Content     = $htmlBody
    }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $recipientEmail; Name = $recipientName } }
    )
}
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter $draftParams
Write-Host "Draft created. MessageId = $($draft.Id)" -ForegroundColor Green

# --- Attach files one at a time (avoids 4MB single-request limit) ---
Write-Host "Attaching files..." -ForegroundColor Cyan
foreach ($f in $attachments) {
    $name = [System.IO.Path]::GetFileName($f)
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

# --- Send ---
Write-Host "Sending..." -ForegroundColor Cyan
Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
Write-Host "`nSENT to $recipientEmail." -ForegroundColor Green
Write-Host "Subject: $subject" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
