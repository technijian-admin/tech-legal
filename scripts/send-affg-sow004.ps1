# Send AFFG SOW-AFFG-004 Rev 2 (macOS fleet) to Iris Liu
# Default mode: CREATE DRAFT ONLY (user reviews in Outlook before sending).
# Pass -Send to actually deliver.
#
# Usage:
#   .\send-affg-sow004.ps1             # creates draft in RJain@technijian.com > Drafts
#   .\send-affg-sow004.ps1 -Send       # creates draft AND sends to iris.liu@americanfundstars.com

param(
    [switch]$Send
)

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
$subject = "AFFG SOW-004 Rev 2 - Revised for Apple-only Fleet - Review Before Tomorrow's Meeting"

# -- Body --
$htmlBody = @"
<div style="font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:12pt; color:#1A1A2E;">

<p>Hi Iris,</p>

<p>Thanks for sending over the current device inventory &mdash; I&rsquo;ve folded it into a revised <strong>SOW-AFFG-004</strong> (attached). Summary of where we landed so you can review before tomorrow&rsquo;s meeting:</p>

<p><strong>Current managed inventory (from your list):</strong></p>

<table cellspacing="0" cellpadding="8" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; width:100%; max-width:640px;">
<tr style="background-color:#006DB6; color:#FFFFFF;">
<td style="border:1px solid #006DB6; font-weight:600;">Host</td>
<td style="border:1px solid #006DB6; font-weight:600;">Device</td>
<td style="border:1px solid #006DB6; font-weight:600;">OS</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">DANIELS-MAC-MINI</td>
<td style="border:1px solid #DEE2E6;">Mac Mini (Mac16,10), 16 GB</td>
<td style="border:1px solid #DEE2E6;">macOS Tahoe 26.3.1</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">MACBOOK-PRO-4</td>
<td style="border:1px solid #DEE2E6;">MacBook Pro (Mac14,9), 16 GB</td>
<td style="border:1px solid #DEE2E6;">macOS Tahoe 26.3.1</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">KIKI</td>
<td style="border:1px solid #DEE2E6;">Surface Pro 8, 16 GB</td>
<td style="border:1px solid #DEE2E6;">Windows 11 Home</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">LEON</td>
<td style="border:1px solid #DEE2E6;">Lenovo V15 G2 IJL, 32 GB</td>
<td style="border:1px solid #DEE2E6;">Windows 11 Pro</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">MAGGIE</td>
<td style="border:1px solid #DEE2E6;">Surface Pro 8, 8 GB</td>
<td style="border:1px solid #DEE2E6;">Windows 11 Home</td>
</tr>
</table>

<p style="margin-top:16px;"><strong>Offboarding under this SOW (4 devices):</strong></p>
<ul style="line-height:1.7;">
<li>MACBOOK-PRO-4 &mdash; MacBook Pro</li>
<li>KIKI &mdash; Surface Pro 8</li>
<li>LEON &mdash; Lenovo V15 G2 IJL</li>
<li>MAGGIE &mdash; Surface Pro 8</li>
</ul>
<p>Each device gets a NIST SP 800-88 disk wipe plus chain-of-custody documentation (Phase 4, ticket AFFG-004-017). DANIELS-MAC-MINI stays in service.</p>

<p><strong>Onboarding under this SOW (9 new Apple endpoints):</strong></p>
<ul style="line-height:1.7;">
<li>3 Mac Minis (new)</li>
<li>6 Apple Neo notebooks (new)</li>
</ul>
<p>All 9 enroll via Apple Business Manager into Intune Automated Device Enrollment &mdash; macOS-only management going forward, no Windows in the managed fleet.</p>

<p><strong>Updated hours and cost (Rev 1 &rarr; Rev 2):</strong></p>

<table cellspacing="0" cellpadding="8" border="0" style="border-collapse:collapse; font-family:Aptos,Calibri,Helvetica,sans-serif; font-size:11pt; max-width:560px;">
<tr style="background-color:#006DB6; color:#FFFFFF;">
<td style="border:1px solid #006DB6; font-weight:600;">Item</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">Rev 1 (Windows)</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">Rev 2 (Apple)</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Hours</td>
<td style="border:1px solid #DEE2E6; text-align:right;">89 hrs</td>
<td style="border:1px solid #DEE2E6; text-align:right;">90 hrs</td>
</tr>
<tr>
<td style="border:1px solid #DEE2E6;">One-time implementation</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$6,525.00</td>
<td style="border:1px solid #DEE2E6; text-align:right;">`$6,990.00</td>
</tr>
<tr style="background-color:#F8F9FA;">
<td style="border:1px solid #DEE2E6;">Net monthly recurring change</td>
<td style="border:1px solid #DEE2E6; text-align:right;">+`$940.40/mo</td>
<td style="border:1px solid #DEE2E6; text-align:right;">+`$1,003.40/mo</td>
</tr>
<tr style="background-color:#E8F4FD;">
<td style="border:1px solid #006DB6; font-weight:600;">Proposed monthly recurring</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">`$3,734.90/mo</td>
<td style="border:1px solid #006DB6; font-weight:600; text-align:right;">`$3,797.90/mo</td>
</tr>
</table>

<p style="margin-top:16px;">The hour delta reflects Apple Business Manager setup being slightly simpler than Windows Autopilot (&minus;1 hr), offset by the 4-device offboarding work added to Phase 4 (+2 hrs). The monthly uplift shifts from +`$940.40 to +`$1,003.40 because macOS patch management (PMMAC at `$11/device) runs higher than Windows (PMW at `$4/device) across the 9 endpoints.</p>

<p>The Section 12 amendment incorporating Technijian&rsquo;s 2026 MSA Framework into our signed Monthly Service Agreement is still in place as Exhibit A of the SOW &mdash; no changes there.</p>

<p>Let&rsquo;s walk through the inventory, offboarding plan, and cost deltas in tomorrow&rsquo;s meeting. Once we&rsquo;re aligned, I&rsquo;ll route the updated SOW through DocuSign for signature.</p>

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

# -- Attach revised SOW-004 docx --
$attachments = @(
    "c:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Managed-Device-Migration.docx"
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

# -- Send or stop at draft --
if ($Send) {
    Send-MgUserMessage -UserId $senderUpn -MessageId $draft.Id
    Write-Host "Email SENT to iris.liu@americanfundstars.com"
} else {
    Write-Host ""
    Write-Host "DRAFT created (not sent). Review in Outlook > Drafts, then re-run with -Send to deliver."
    Write-Host "  Draft ID: $($draft.Id)"
    Write-Host "  Subject:  $subject"
    Write-Host "  To:       iris.liu@americanfundstars.com"
}

Disconnect-MgGraph | Out-Null
