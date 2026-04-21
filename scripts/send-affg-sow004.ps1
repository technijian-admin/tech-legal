# Send AFFG Managed Device Strategy Presentation to Iris Liu
# Draft -> Attach pptx -> Send pattern

# -- Auth --
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$senderUpn = "RJain@technijian.com"

# -- Signature --
$raviSignature = Get-Content "c:\vscode\tech-legal\tech-legal\scripts\ravi-signature.html" -Raw -Encoding UTF8

# -- Subject --
$subject = "AFFG Managed Device Strategy - Proposal & SOW-AFFG-004 for Review"

# -- Body --
$htmlBody = @"
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:#1A1A2E;">

<p>Hi Iris,</p>

<p>Attached is the <strong>AFFG Managed Device Strategy</strong> proposal. This proposes taking AFFG from the current network (per our signed Monthly Service Agreement) to a fully SEC/FINRA-compliant endpoint posture built on 9 Intune-managed company laptops, 9 Intune MDM-managed company phones, CloudBrink ZTNA, Entra Conditional Access, MyAudit endpoint DLP, and the SSO/2FA gateway on all managed endpoints.</p>

<p><strong>SOW-AFFG-004 &mdash; Managed Device Control Deployment</strong></p>

<table cellspacing="0" cellpadding="8" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; width:100%; max-width:640px;">
<tr style="background-color:#006DB6; color:#FFFFFF;">
<td style="border:1px solid #006DB6; font-weight:600;">Phase</td>
<td style="border:1px solid #006DB6; font-weight:600;">Deliverable</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Phase 1</td>
<td style="border:1px solid #DEE2E6;">Endpoint Foundation &mdash; Intune Autopilot, compliance policies, security stack, DLP, SSO/2FA, Credential Manager on 9 laptops</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Phase 2</td>
<td style="border:1px solid #DEE2E6;">Access Control &mdash; Entra Conditional Access, CloudBrink ZTNA, Schwab/IBKR custodian access migration</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Phase 3</td>
<td style="border:1px solid #DEE2E6;">Mobile Device Control &mdash; Intune MDM + App Protection on 9 company phones, remote wipe</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Phase 4</td>
<td style="border:1px solid #DEE2E6;">User Cutover &mdash; data migration, training, 2-week pilot, legacy office-IP decommission</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Phase 5</td>
<td style="border:1px solid #DEE2E6;">Monitoring &amp; Validation &mdash; fleet monitoring, mobile audit, end-to-end security validation, gap assessment</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Phase 6</td>
<td style="border:1px solid #DEE2E6;">Documentation &mdash; compliance documentation suite, Schedule A amendment</td>
</tr>
</table>

<p style="margin-top:16px;">Every control component maps to a specific citation under Reg S-P (2024 Amendments), FINRA 3110/4370, SEC 17a-4, and NIST SP 800-53 Rev 5.</p>

<p><strong>Investment:</strong></p>

<table cellspacing="0" cellpadding="8" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; max-width:500px;">
<tr style="background-color:#006DB6; color:#FFFFFF;">
<td style="border:1px solid #006DB6; font-weight:600;">Item</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">Amount</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">One-time implementation (26 tickets, 89 hours)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$6,525.00</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">Current monthly recurring (signed MSA)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$2,794.50/mo</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Proposed monthly recurring (post-implementation)</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$3,734.90/mo</td>
</tr>
<tr style="background-color:#E8F4FD;">
<td style="border:1px solid #006DB6; font-weight:600;">Net monthly increase</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">+`$940.40/mo</td>
</tr>
</table>

<p style="margin-top:16px;">The monthly recurring change reflects consolidating the existing desktop security stack from 16 units down to 9 managed laptops (&minus;`$185.50/mo) and adding the new managed laptop control stack: MyAudit UAM+DLP, SSO/2FA, and Credential Manager on 9 endpoints (+`$1,125.90/mo). Intune management for both laptops and phones is covered by AFFG&rsquo;s existing M365 E3 license &mdash; no additional Technijian charge. CloudBrink ZTNA subscription is procured by AFFG directly and sits outside Schedule A. Virtual Staff Support hours and rates remain unchanged.</p>

<p>The SOW also includes a <strong>Section 12 amendment</strong> that brings AFFG under Technijian&rsquo;s 2026 MSA Framework (attached as Exhibit A in the SOW) &mdash; adding Confidentiality, Limitation of Liability with enhanced cap for data-protection breaches, Dispute Resolution, Personnel Transition Fee, and the CCPA/CPRA &plus; Reg S-P 48-hour breach-notification data-protection provisions your compliance program needs under the 2024 amendments.</p>

<p>The SOW document is coming to you separately via DocuSign for signature. Please review the strategy deck first, and feel free to use the booking link in my email signature to schedule a walkthrough if you&rsquo;d like to discuss before signing.</p>

<p>Looking forward to hearing from you.</p>

</div>

$raviSignature
"@

# -- Proofread: check for stripped dollar signs --
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

# -- Create draft --
$draft = New-MgUserMessage -UserId $senderUpn -BodyParameter @{
    Subject = $subject
    Body = @{ ContentType = "HTML"; Content = $htmlBody }
    ToRecipients = @(
        @{ EmailAddress = @{ Address = "iris.liu@americanfundstars.com"; Name = "Iris Liu" } }
    )
}

Write-Host "Draft created: $($draft.Id)"

# -- Attach presentation --
$attachments = @(
    "c:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\AFFG_Managed_Device_Strategy_Technijian.pptx"
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

# -- Send --
Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
Write-Host "Email sent to iris.liu@americanfundstars.com"

Disconnect-MgGraph | Out-Null
