# Create draft email to Robert L. Evens (TALY) for MSA review
# Pattern: draft-only (NO Send-MgUserMessage). User reviews in Outlook Drafts before sending.

# ── Auth ──
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$senderUpn = "RJain@technijian.com"
$toAddr    = "rob@talleyassoc.com"
$toName    = "Robert L. Evens"

# ── Signature ──
$raviSignature = Get-Content "c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw -Encoding UTF8

# ── Subject ──
$subject = "Talley & Associates - proposed cost reductions and refreshed Master Service Agreement"

# ── Body ──
# NOTE: every literal $ sign is backtick-escaped to prevent PowerShell variable expansion in this here-string.
$htmlBody = @"
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:#1A1A2E;">

<p>Hi Rob,</p>

<p>I just finished a billing review on Talley &amp; Associates' account, and I want to walk you through two changes that should bring your monthly invoice down meaningfully. I've also drafted a refreshed Master Service Agreement so we can put the relationship on current paper &mdash; your existing contract has been on month-to-month rollover since the original 3-month term expired in April 2025, and our master agreement template has been substantially updated since then.</p>

<p>If you're good with what's below, I can send the package to you for electronic signature today and have it take effect retroactive to <strong>May 1, 2026</strong>, aligned with the start of the current billing period.</p>

<h3 style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; color:#006DB6; font-size:15px; margin-top:20px; margin-bottom:8px;">What I'm proposing</h3>

<p><strong>1. Switch US Tech Support from a committed monthly block to true hourly billing.</strong></p>

<p>Today you pay for <strong>1.38 hours/month</strong> of US-based Tech Support at the discounted contracted rate of `$125/hr &mdash; a fixed `$172.50 line on every monthly invoice, whether or not we use the time. Looking at the last 16 months of actual ticket data, you've averaged just <strong>0.90 hours/month</strong> of US Tech Support work, which is about 45% utilization of what you're paying for.</p>

<p>I'd like to drop the commitment entirely. You would pay only for the time we actually spend on US-based work, billed weekly in 15-minute increments. The rate moves from `$125/hr to `$150/hr (and `$250/hr for after-hours emergencies) because the discount is tied to the commitment &mdash; but at your usage level you still come out ahead on average, and on a light-usage month you save the full `$172.50.</p>

<p>India Tech Support stays on the current committed-hours model. The contracted rates there (`$15/hr Normal, `$30/hr After-Hours) are too good to give up.</p>

<p><strong>2. Remove Real-Time Penetration Testing and Site Assessment &mdash; pending your call.</strong></p>

<p>Two security line items together total <strong>`$92/month</strong>:</p>

<ul style="line-height:1.7;">
<li><strong>Real-Time Penetration Testing (RTPT)</strong> &mdash; continuous external attack-surface scanning across 6 of your public IPs. `$42/mo.</li>
<li><strong>Site Assessment (SA)</strong> &mdash; recurring web application security assessment for 1 domain. `$50/mo.</li>
</ul>

<p>Before I take these out I want to make sure removing them doesn't create a problem on your end. A few things to think through:</p>

<ul style="line-height:1.7;">
<li><strong>Cyber liability insurance.</strong> Most policies issued in 2024-2026 require ongoing vulnerability scanning and periodic penetration testing as a condition of coverage. Removing RTPT and SA could trigger a coverage gap, affect your renewal premium, or in the worst case give the carrier a basis to deny a claim. Worth a quick check with your broker.</li>
<li><strong>Client and regulatory requirements.</strong> If any of your own clients send you vendor security questionnaires, or if your firm is subject to GLBA's Safeguards Rule (the FTC's 2023 update covers a broad range of financial services and includes periodic vulnerability assessments and pen testing), or if you're working toward or maintaining SOC 2, these line items often map directly to required controls.</li>
<li><strong>Posture.</strong> Practically speaking, RTPT detects exploit attempts against your public IPs in real time. Without it, an attacker probing your perimeter goes unnoticed until something actually breaks.</li>
</ul>

<p>If none of those apply and you're comfortable with the risk, we can pull both line items immediately and the `$92/mo comes off the bill. If you want to keep them but feel they should be smaller in scope (fewer IPs, less frequent scanning), I'm happy to right-size instead. And if you want to keep them as-is, that's fine too &mdash; I just want to make sure the decision is yours, not a default.</p>

<h3 style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; color:#006DB6; font-size:15px; margin-top:20px; margin-bottom:8px;">Cost summary</h3>

<table cellspacing="0" cellpadding="8" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; max-width:680px; width:100%;">
<tr style="background-color:#006DB6; color:#FFFFFF;">
<td style="border:1px solid #006DB6; font-weight:600;">Line</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">Today</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">After</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Desktop endpoint stack (&times;7 desktops) &mdash; CrowdStrike, Huntress, patch, secure internet, remote</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$185.50</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$185.50</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Network monitoring (&times;32 devices)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$128.00</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$128.00</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Backup storage (1 TB)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$50.00</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$50.00</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Real-Time Pen Testing (6 IPs)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$42.00</td>
<td style="border:1px solid #DEE2E6; text-align:right; color:#F67D4B;">`$0 if you approve</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Site Assessment (1 domain)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$50.00</td>
<td style="border:1px solid #DEE2E6; text-align:right; color:#F67D4B;">`$0 if you approve</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">US Tech Support &mdash; committed 1.38 h &times; `$125/hr</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$172.50</td>
<td style="border:1px solid #DEE2E6; text-align:right; color:#F67D4B;">`$0 (moves to hourly `$150/hr ad-hoc)</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">India Tech Support &mdash; committed (Normal + After-Hours)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$96.75</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$96.75</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Tax</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$7.75</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$7.75</td>
</tr>
<tr style="background-color:#E8F4FD;">
<td style="border:1px solid #006DB6; font-weight:700;">Monthly recurring invoice</td>
<td style="border:1px solid #006DB6; font-weight:700; text-align:right;">`$724.75</td>
<td style="border:1px solid #006DB6; font-weight:700; text-align:right;">`$468.00</td>
</tr>
</table>

<p style="margin-top:14px;"><strong>Visible recurring savings: `$256.75/month, about 35% off the monthly invoice.</strong></p>

<p>US Tech Support work, when it happens, gets billed separately on a weekly invoice at the new ad-hoc rates. At your historical average of 0.90 h/month that adds roughly `$135/month, for a <strong>blended steady state of about `$603/month versus `$724.75 today (about 17% real savings)</strong>. Light-usage months will save more, heavy-usage months may save less. India Tech Support still appears as the same fixed line.</p>

<p>If you also approve removing RTPT and SA, take another <strong>`$92/month</strong> off both the recurring invoice and the blended figure.</p>

<h3 style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; color:#006DB6; font-size:15px; margin-top:20px; margin-bottom:8px;">About the new MSA</h3>

<p>Attached you'll find four documents that together replace the existing Monthly Support contract:</p>

<ol style="line-height:1.8;">
<li><strong>Master Service Agreement (MSA-TALY-2026)</strong> &mdash; 12-month initial term with 60-day renewal notice, Net 30 payment terms, current-form data protection and insurance language.</li>
<li><strong>Schedule A</strong> &mdash; Monthly Managed Services, including the cycle-based billing model for India Tech Support, the new hourly (ad-hoc) model for US Tech Support, and the Service Order with the exact line items above.</li>
<li><strong>Schedule B</strong> &mdash; Subscription Services framework (no active subscriptions today; this is in place so any future Microsoft 365, SSL, or domain registration additions are clean).</li>
<li><strong>Schedule C</strong> &mdash; full Rate Card with every role and per-line-item price across the entire Technijian service catalog, so any future additions are transparent and pre-priced.</li>
</ol>

<p>Two carve-outs worth flagging in the Service Order: the existing India Tech Support cycle credit balance carries forward, and the open AR on the partially-paid March 2026 invoice (#27954, `$240.45 short-pay) is preserved separately for normal AR reconciliation &mdash; it is not waived by signing the new MSA.</p>

<h3 style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; color:#006DB6; font-size:15px; margin-top:20px; margin-bottom:8px;">Next steps</h3>

<p>If the cost reductions and the MSA look right to you, just reply with:</p>

<ol style="line-height:1.7;">
<li>Whether to drop RTPT and SA, keep them, or right-size them; and</li>
<li>A green light to proceed.</li>
</ol>

<p>I'll then send the four documents to you via Foxit eSign for electronic signature. Once signed, the new MSA and Service Order take effect retroactive to <strong>May 1, 2026</strong>, and we'll void and reissue the current pending May 1 invoice (#28363, for the June service period) at the new lower rates so the savings hit immediately.</p>

<p>Happy to jump on a quick call if it's easier to work through any of this live &mdash; let me know.</p>

</div>

$raviSignature
"@

# ── Save preview to disk for visual proofread ──
$previewPath = "c:\tmp\taly-rob-msa-preview-$(Get-Date -Format yyyyMMdd-HHmmss).html"
$htmlBody | Out-File -FilePath $previewPath -Encoding UTF8
Write-Host "Preview saved: $previewPath" -ForegroundColor Cyan

# ── Proofread checks ──
Write-Host "`n=== PROOFREAD PASS 1: stripped currency / placeholders ===" -ForegroundColor Yellow
if ($htmlBody -match '[\s>](\,\d{3})') {
    Write-Error "BLOCKED: Stripped dollar sign detected: '$($matches[1])'."
    Disconnect-MgGraph | Out-Null
    exit 1
}
if ($htmlBody -match '\[Your Name\]|TODO|TBD|\[INSERT|\{\{') {
    Write-Error "BLOCKED: Placeholder text found in email body."
    Disconnect-MgGraph | Out-Null
    exit 1
}
if ($htmlBody -match 'href=""') {
    Write-Error "BLOCKED: Empty href in body."
    Disconnect-MgGraph | Out-Null
    exit 1
}
# Internal path leak check (per feedback_no_internal_repo_paths_external_email)
$internalPathPatterns = @('c:\\vscode', 'C:\\Users\\rjain', 'OneDrive - Technijian', '\\tech-legal\\', '\\terminated-clients\\')
foreach ($p in $internalPathPatterns) {
    if ($htmlBody -match $p) {
        Write-Error "BLOCKED: Internal path '$p' in email body."
        Disconnect-MgGraph | Out-Null
        exit 1
    }
}
Write-Host "Pass 1: OK" -ForegroundColor Green

Write-Host "`n=== PROOFREAD PASS 2: dollar amount sanity (every `$ should be backtick-escaped or HTML-entity) ===" -ForegroundColor Yellow
# Look for lone $ followed by digits (would indicate failed escaping in PowerShell, though here-string already handled it)
# After PowerShell parses the here-string, literal dollars survive — verify sample amounts are present:
$expected = @('$724.75', '$468.00', '$256.75', '$172.50', '$92', '$185.50', '$128.00', '$50.00', '$42.00', '$96.75', '$135', '$603', '$240.45')
$missing = @()
foreach ($v in $expected) { if ($htmlBody -notmatch [regex]::Escape($v)) { $missing += $v } }
if ($missing.Count -gt 0) {
    Write-Error "BLOCKED: Expected dollar amounts missing from rendered body: $($missing -join ', ')"
    Disconnect-MgGraph | Out-Null
    exit 1
}
Write-Host "Pass 2: OK (all $($expected.Count) expected amounts found)" -ForegroundColor Green

Write-Host "`n=== PROOFREAD PASS 3: prose redundancy / repetition signals ===" -ForegroundColor Yellow
# Check for adjacent same-root word repetition flagged by feedback_proofread_emails
$prose = $htmlBody -replace '<[^>]+>', ' ' -replace '\s+', ' '
# Specific patterns from prior incidents: "proposal. This proposes...", duplicate "Intune" in same sentence
$redFlags = @('proposal\. This propos', 'agreement\. This agree', 'Intune.*Intune', 'attached.*attached')
foreach ($rf in $redFlags) {
    if ($prose -match $rf) {
        Write-Warning "Prose repetition flag (review manually): pattern '$rf'"
    }
}
Write-Host "Pass 3: OK (manual prose review still required by user before send)" -ForegroundColor Green

# ── Create draft (NOT sent) ──
Write-Host "`nCreating draft in $senderUpn drafts folder..." -ForegroundColor Cyan
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject = $subject
    Body = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = $toAddr; Name = $toName } }
    )
}
Write-Host "Draft created: $($draft.Id)" -ForegroundColor Green
$draft.Id | Out-File -FilePath "c:\vscode\tech-legal\tech-legal\scripts\taly-rob-msa-draft-id.txt" -Encoding ASCII

# ── Attach the four DOCX files ──
$attachments = @(
    "c:\vscode\tech-legal\tech-legal\clients\TALY\02_MSA\MSA-TALY-2026.docx",
    "c:\vscode\tech-legal\tech-legal\clients\TALY\02_MSA\Schedule-A-TALY.docx",
    "c:\vscode\tech-legal\tech-legal\clients\TALY\02_MSA\Schedule-B-TALY.docx",
    "c:\vscode\tech-legal\tech-legal\clients\TALY\02_MSA\Schedule-C-TALY.docx"
)
foreach ($f in $attachments) {
    if (-not (Test-Path $f)) {
        Write-Error "Attachment missing: $f"
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $b64   = [Convert]::ToBase64String($bytes)
    $null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draft.Id -BodyParameter @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        Name          = [System.IO.Path]::GetFileName($f)
        ContentBytes  = $b64
        ContentType   = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    }
    Write-Host "  Attached: $([System.IO.Path]::GetFileName($f)) ($([math]::Round($bytes.Length/1KB,1)) KB)" -ForegroundColor Green
}

Write-Host "`n=== DRAFT READY FOR REVIEW ===" -ForegroundColor Cyan
Write-Host "Open Outlook -> Drafts -> 'Talley & Associates - proposed cost reductions...'" -ForegroundColor Cyan
Write-Host "Preview HTML: $previewPath" -ForegroundColor Cyan
Write-Host "Draft ID:     $($draft.Id)" -ForegroundColor Cyan

Disconnect-MgGraph | Out-Null
