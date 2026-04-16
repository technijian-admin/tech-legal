# Send BST (Boston Group) Termination Reconciliation Package to Edward Susolik, Esq. via Microsoft Graph
# DEFAULT: creates draft only (review in Outlook before sending)
# To actually send: run with -Send flag
#
# Usage:
#   .\send-bst-susolik.ps1              # draft only (DEFAULT)
#   .\send-bst-susolik.ps1 -Send        # send immediately

param([switch]$Send)

$ErrorActionPreference = "Stop"

$recipientEmail = "es@callahan-law.com"
$recipientName  = "Edward Susolik"
$senderUpn      = "RJain@technijian.com"
$subject        = "BST (Boston Group) - Termination Reconciliation Package - Counsel Engaged"

$bstDir  = "C:\vscode\tech-legal\tech-legal\terminated-clients\BST"
$sigPath = "C:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html"

$attachments = @(
    "$bstDir\BST_Settlement_Position_Memorandum.docx",
    "$bstDir\BST_Damages_Scenario_Analysis_INTERNAL.docx",
    "$bstDir\BST_Case_Law_Research_Memorandum.docx",
    "$bstDir\Boston_Group-Monthly_Service-signed (2).pdf",
    "$bstDir\bst_actualvsbillable (1).xlsx",
    "$bstDir\attachments\2026-04-03_1553_Boston+Group-28064-Invoice-Service+Cancellation.pdf",
    "$bstDir\attachments\2026-03-17_1826_BP-70C36_20260317_112415.pdf"
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

# --- Build HTML body (backtick-escape every literal $ per memory) ---
$fontStack = "Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif"
$htmlBody = @"
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head>
<body dir="ltr">
<div style="font-family:$fontStack;font-size:12pt;color:rgb(0,0,0)">

<p>Ed,</p>

<p>Following up on our March 19 call about the ex-employee pattern and the two clients moving to Tech Heights, I am sending the full BST (Boston Group) file now that we've hit the April 30 termination date and Jeffrey Klein's counsel is in the loop (his March 23 email said "our attorney is reviewing the contract"; no firm or name identified yet, we may hear from them directly or can request identification).</p>

<p>This is the parallel matter to Vintage Design. Same signed MSA template (DocuSign Envelope <strong>FC626837-AEED-442F-9961-A81502402FC4</strong>), same `$150/hour Under Contract cancellation language, same weekly ticket-invoice dispute-window mechanic, same account-stated posture. The damages picture is materially different though, see `$3-4 of the internal analysis.</p>

<p><strong>Current posture</strong></p>
<ul>
<li>Termination notice received 2026-03-17; effective date 2026-04-30.</li>
<li>My 3/19 and 3/23 emails to Jeff established Technijian's contract-basis figure (<strong>`$126,442.50</strong>) and placed a settlement concession on the table (<strong>`$15,045</strong> life-of-contract net), open through close of business 4/30.</li>
<li>Jeff's 3/23 response: counsel engaged.</li>
<li>Jeff's 4/1 email confirms BST has directed Tech Heights (Rich Leggett) to proceed without our cooperation. Between 3/31 and 4/1, the BST ESXi host password was changed without authorization and the AD server (BST-HQ-AD-01) went offline while Tech Heights was working in the environment. Technijian support reported this in writing on 4/1.</li>
</ul>

<p><strong>What's in the package (attached in Word + PDF + Excel)</strong></p>

<p><em>Privileged / work product, do not disclose to BST or BST counsel:</em></p>
<ol>
<li><strong>BST_Damages_Scenario_Analysis_INTERNAL.docx</strong> &mdash; five damages methodologies, range `$0 to `$139,743, with reconciliation of my 3/19 figure (842.95 hrs / `$126,442.50) to my recalc (931.62 hrs / `$139,743). Includes the strategic/risk analysis, including the Cycle-3-zero-overage weakness we need to confront.</li>
</ol>

<p><em>For eventual transmission to BST counsel:</em></p>
<ol start="2">
<li><strong>BST_Settlement_Position_Memorandum.docx</strong> &mdash; settlement-communication letter, ready to go out under your name when we identify counsel. Restates the `$126,442.50 contract position and the `$15,045 concession standing through 4/30. Reserves third-party tort rights.</li>
</ol>

<p><em>Supporting authority:</em></p>
<ol start="3">
<li><strong>BST_Case_Law_Research_Memorandum.docx</strong> &mdash; 25 issues of California authority. Adapted from the Vintage Design memo for overlapping issues (&sect; 1671(b), account stated, course of dealing, &sect; 1717 fees, prejudgment interest, UETA / DocuSign). Adds new sections on tortious interference with contract (Tech Heights / Leggett), CFAA and CDAFA (ESXi password change), trade secrets, and &sect; 16600 analysis of the anti-hire clause.</li>
</ol>

<p><em>Primary exhibits:</em></p>
<ol start="4">
<li><strong>Boston_Group-Monthly_Service-signed (2).pdf</strong> &mdash; signed MSA (DocuSign FC626837-AEED-442F-9961-A81502402FC4).</li>
<li><strong>bst_actualvsbillable (1).xlsx</strong> &mdash; source hours data driving all calculations.</li>
<li><strong>Boston+Group-28064-Invoice-Service+Cancellation.pdf</strong> &mdash; the cancellation-fee invoice issued 3/23 (`$126,442.50 contract-basis).</li>
<li><strong>BP-70C36_20260317_112415.pdf</strong> &mdash; Jeff Klein's original signed termination notice letter dated 2026-03-17.</li>
</ol>

<p><strong>Key strategic questions I need your judgment on</strong></p>
<ol>
<li><strong>Number reconciliation before any formal demand.</strong> My 3/19 email to Jeff stated 842.95 hrs &rarr; `$126,442.50. My fresh recalc from the spreadsheet yields 931.62 hrs &rarr; `$139,743. Unreconciled delta of 88.67 hrs. Before we send any formal demand letter, I want us anchored to a single defensible number. I suggest we go with the invoiced figure (`$126,442.50) to avoid a consistency issue, but I want your call.</li>
<li><strong>The `$15,045 concession and the 4/30 deadline.</strong> Options: (a) let it expire per its own terms at COB 4/30 and revert to the `$126,442.50 invoice; (b) hold it open for a short extension if BST counsel contacts us in good faith; (c) withdraw it and move to formal demand. My inclination is (b) if counsel surfaces by 4/30 and engages substantively, otherwise (a).</li>
<li><strong>Tech Heights / Leggett &mdash; separate track or bundled.</strong> The tortious interference, CFAA / CDAFA, and trade-secret exposure against Tech Heights and Leggett personally is real but is a separate posture from the BST settlement. Options: (i) preserve only, relying on the reservation-of-rights language in any settlement with BST; (ii) send a parallel demand to Tech Heights / Leggett now with a specific deadline; (iii) bundle into one demand if BST coordinates the transition with Tech Heights in writing. My inclination is (i), but I defer to you on whether serving (ii) now creates useful pressure on the BST settlement too.</li>
<li><strong>The Cycle-3 weakness.</strong> Under the strictest reading of the Under Contract clause, the termination-cycle-only overage is `$0 because actual consumption ran under baseline every single month in Cycle 3. My position (Method A) is that the clause says "any hours that exceeded," not "any hours in the termination cycle that exceeded," and life-of-contract overage is the right read. BST counsel will likely push the narrower reading. Settlement Memo &sect; 4 frames our response, worth your critique before we lock it in.</li>
<li><strong>BST's counsel identification.</strong> Jeff has not named the attorney or firm. I plan to send a short follow-up asking for it (either from me in a day-to-day capacity, or from you on letterhead, your call).</li>
</ol>

<p><strong>Timeline</strong></p>
<ul>
<li><strong>4/30/2026 (next 2 weeks):</strong> Settlement offer expires by its terms. Transition complete.</li>
<li><strong>Before 4/30:</strong> Open for counsel to engage. If no contact, revert to `$126,442.50 invoice.</li>
<li><strong>5/1 onward:</strong> Evaluate formal demand, separate Tech Heights action, or referral to AAA under &sect; 6.10 if MSA has same clause as VTD (to confirm).</li>
</ul>

<p>Any update on Vintage Design? Both matters are linked by the Leggett pattern and we should think about strategic sequencing.</p>

<p>Happy to get on a call this week.</p>

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

if ($Send) {
    Write-Host "Sending..." -ForegroundColor Cyan
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "`nSENT to $recipientEmail." -ForegroundColor Green
} else {
    Write-Host "`nDRAFT saved to Outlook Drafts folder for RJain@technijian.com." -ForegroundColor Yellow
    Write-Host "Review in Outlook, then either:" -ForegroundColor Yellow
    Write-Host "  - Click Send from Outlook, OR" -ForegroundColor Yellow
    Write-Host "  - Re-run this script with -Send flag to send automatically" -ForegroundColor Yellow
}
Write-Host "Subject: $subject" -ForegroundColor Gray

Disconnect-MgGraph | Out-Null
