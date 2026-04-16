# Send SOW-AFFG-003 + Presentation to Iris Liu
# Draft -> Attach -> Send pattern (2 attachments)

# ── Auth ──
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$senderUpn = "RJain@technijian.com"

# ── Signature ──
$raviSignature = Get-Content "c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw -Encoding UTF8

# ── Subject ──
$subject = "AFFG IT Compliance & VDI Implementation - SOW-AFFG-003 for Review"

# ── Body ──
$htmlBody = @"
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:#1A1A2E;">

<p>Hi Iris,</p>

<p>Following up on our compliance strategy review, please find attached the following documents for your review:</p>

<ol style="line-height:1.8;">
<li><strong>SOW-AFFG-003: IT Compliance &amp; VDI Implementation</strong> &mdash; The complete Statement of Work covering the 7-phase implementation</li>
<li><strong>AFFG IT Compliance Strategy &mdash; Revised Proposal Review</strong> &mdash; The supporting presentation mapping each design component to specific SEC, FINRA, and NIST citations</li>
</ol>

<p style="margin-top:16px;"><strong>Scope Summary:</strong></p>

<table cellspacing="0" cellpadding="8" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; width:100%; max-width:640px;">
<tr style="background-color:#006DB6; color:#FFFFFF;">
<td style="border:1px solid #006DB6; font-weight:600;">Phase</td>
<td style="border:1px solid #006DB6; font-weight:600;">Deliverable</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Phase 1</td>
<td style="border:1px solid #DEE2E6;">Technijian Horizon VDI Foundation (7 dedicated Windows 11 desktops)</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Phase 2</td>
<td style="border:1px solid #DEE2E6;">Access Lockdown (IP whitelists, SSO/2FA gateway, Intune MDM, device compliance)</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Phase 3</td>
<td style="border:1px solid #DEE2E6;">M365 Data Loss Prevention (DLP, OneDrive lockdown, email TLS enforcement)</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Phase 4</td>
<td style="border:1px solid #DEE2E6;">Veeam 365 Backup (7-year immutable retention per SEC Rule 17a-4)</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Phase 5</td>
<td style="border:1px solid #DEE2E6;">Monitoring &amp; Audit (My Audit UAM+DLP, compliance dashboard, mobile audit)</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Phase 6</td>
<td style="border:1px solid #DEE2E6;">Validation &amp; Testing (pen test, phishing simulation, gap assessment)</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Phase 7</td>
<td style="border:1px solid #DEE2E6;">Compliance Documentation (IRP, breach notification, BCP disclosure, compliance binder)</td>
</tr>
</table>

<p style="margin-top:16px;"><strong>Investment:</strong></p>

<table cellspacing="0" cellpadding="8" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; max-width:500px;">
<tr style="background-color:#006DB6; color:#FFFFFF;">
<td style="border:1px solid #006DB6; font-weight:600;">Item</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">Amount</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">One-time implementation (41 tickets, 128 hours)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$12,165.00</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Current monthly recurring</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$2,794.50/mo</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Proposed monthly recurring (post-implementation)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$5,770.45/mo</td>
</tr>
<tr style="background-color:#E8F4FD;">
<td style="border:1px solid #006DB6; font-weight:600;">Net monthly increase</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">+`$2,975.95/mo</td>
</tr>
</table>

<p style="margin-top:16px;">The recurring increase reflects the Technijian Horizon VDI environment for 7 in-scope agents, My Audit UAM+DLP with 1-year retention, Veeam 365 Backup for all 31 users, SSO/2FA gateway, and shared storage. The remaining 9 physical desktops continue with the standard endpoint security stack. Virtual Staff Support hours and rates are unchanged.</p>

<p>The full cost comparison is detailed in Section 8 of the SOW and in Schedule A of the MSA. Please review at your convenience, and feel free to use the booking link in my email signature to schedule a walkthrough if you have any questions.</p>

<p>Looking forward to hearing from you.</p>

</div>

$raviSignature
"@

# ── Proofread: check for stripped $ signs ──
if ($htmlBody -match '[\s>](\,\d{3})') {
    Write-Error "BLOCKED: Stripped dollar sign detected: '$($matches[1])'. Fix backtick escaping."
    Disconnect-MgGraph | Out-Null
    exit 1
}

# Check for placeholder text
if ($htmlBody -match '\[Your Name\]|TODO|TBD|\[INSERT') {
    Write-Error "BLOCKED: Placeholder text found in email body."
    Disconnect-MgGraph | Out-Null
    exit 1
}

Write-Host "Proofread passed. Creating draft..."

# ── Create draft ──
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject = $subject
    Body = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = "iris.liu@americanfundstars.com"; Name = "Iris Liu" } }
    )
}

Write-Host "Draft created: $($draft.Id)"

# ── Attach files ──
$attachments = @(
    "c:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-003-Compliance-Strategy.docx",
    "c:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\AFFG_Proposal_Revision_Review_Technijian.pptx"
)

foreach ($f in $attachments) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $b64   = [Convert]::ToBase64String($bytes)
    $null = New-MgUserMessageAttachment -UserId $senderUpn -MessageId $draft.Id -BodyParameter @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        Name          = [System.IO.Path]::GetFileName($f)
        ContentBytes  = $b64
    }
    Write-Host "Attached: $([System.IO.Path]::GetFileName($f))"
}

# ── Send ──
Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
Write-Host "Email sent to iris.liu@americanfundstars.com"

Disconnect-MgGraph | Out-Null
