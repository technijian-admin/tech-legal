# Branded summary email to Iris Liu for AFFG SOW-004 Rev 3 (companion to DocuSign envelope 39227686-865f-88a0-80a7-041ea8a44ca0)
# Sent via Microsoft Graph as rjain@technijian.com.
# Bounce-register check: iris.liu@americanfundstars.com is a primary client contact, not a broadcast address - no bounce risk.

param([switch]$DryRun)

$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$m365Keys = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId) { $m365ClientId = [regex]::Match($m365Keys, 'App Client ID = (\S+)').Groups[1].Value }
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365TenantId) { $m365TenantId = [regex]::Match($m365Keys, 'Tenant ID = (\S+)').Groups[1].Value }
$m365Secret = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365Secret) { $m365Secret = [regex]::Match($m365Keys, '(?<=Tenant ID[^\n]+\n)Client Secret = (.+)').Groups[1].Value.Trim() }
if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) { Write-Error "Failed to read M365 Graph credentials from $m365KeysFile"; exit 1 }
Write-Host "M365 credentials loaded." -ForegroundColor Green

$tokenUri = "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $m365ClientId
    client_secret = $m365Secret
    scope         = "https://graph.microsoft.com/.default"
    grant_type    = "client_credentials"
}
$tokenResp = Invoke-RestMethod -Uri $tokenUri -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
$token = $tokenResp.access_token
Write-Host "Graph authentication successful." -ForegroundColor Green

$senderUpn = "rjain@technijian.com"
$recipientEmail = "iris.liu@americanfundstars.com"
$recipientName = "Iris Liu"
$subject = "AFFG SOW-004 Rev 3 - What Changed and What You're Signing"

# Branded HTML body. Solid-color hero (no gradients - Outlook-safe per workstation memory).
$html = @"
<!DOCTYPE html><html><head><meta charset="utf-8"><title>$subject</title></head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;color:#59595B;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F8F9FA;"><tr><td align="center" style="padding:24px 16px;">
<table role="presentation" width="640" cellpadding="0" cellspacing="0" style="max-width:640px;width:100%;background-color:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">
  <tr><td style="padding:24px 32px;border-bottom:3px solid #006DB6;"><img src="https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png" alt="Technijian" width="200" style="display:block;max-width:200px;height:auto;"></td></tr>
  <tr><td style="padding:32px 32px 8px;background-color:#006DB6;">
    <h1 style="margin:0 0 6px;font-size:22px;font-weight:700;color:#FFFFFF;line-height:1.25;">SOW-AFFG-004 Rev 3 - Revision Summary</h1>
    <p style="margin:0;font-size:14px;color:#FFFFFF;opacity:0.9;">Companion to your DocuSign signing email - please review before signing.</p>
  </td></tr>
  <tr><td style="height:6px;background-color:#F67D4B;"></td></tr>
  <tr><td style="padding:28px 32px 8px;font-size:15px;line-height:1.6;">
    <p style="margin:0 0 14px;">Hi Iris,</p>
    <p style="margin:0 0 14px;">Per our discussion, I have revised <strong style="color:#1A1A2E;">SOW-AFFG-004</strong> to <strong style="color:#1A1A2E;">Rev 3</strong> to reflect the final endpoint architecture and align all monthly pricing to the current Technijian Services Price List (Appendix A, rev 2026-03-23). The previous DocuSign envelope has been retired; you should have just received a fresh Rev 3 envelope from DocuSign with your signing link.</p>
    <p style="margin:0 0 6px;font-size:16px;font-weight:700;color:#1A1A2E;">What changed from Rev 2 to Rev 3</p>
  </td></tr>
  <tr><td style="padding:0 32px;font-size:15px;line-height:1.6;">
    <p style="margin:0 0 6px;font-weight:600;color:#006DB6;">Fleet (10 Apple endpoints + 10 personal phones)</p>
    <ul style="margin:0 0 14px;padding-left:22px;">
      <li><strong>4 Mac Minis</strong> (2 already onboarded - Phase 1 config-cleanup pass; 2 new) + <strong>6 MacBook Neos</strong></li>
      <li><strong>10 personally-owned cell phones</strong> via Intune BYOD: iOS through Apple Business Manager User Enrollment; Android through Intune work profile. Selective wipe only - your team's personal data is never touched.</li>
      <li>Offboarding 4 legacy devices: MACBOOK-PRO-4, KIKI, LEON, MAGGIE (NIST SP 800-88 wipe + chain-of-custody)</li>
    </ul>
    <p style="margin:0 0 6px;font-weight:600;color:#006DB6;">Final endpoint stack</p>
    <p style="margin:0 0 14px;">ManageEngine Patch Management (PMMAC), CrowdStrike Falcon for Mac, Huntress macOS, CloudBrink ZTNA, Teramind / MyAudit UAM+DLP, My Remote.<br><span style="color:#888;">Removed from prior draft: Cisco Umbrella, SSO/2FA gateway, Credential Manager.</span></p>
    <p style="margin:0 0 6px;font-weight:600;color:#006DB6;">One-time labor</p>
    <p style="margin:0 0 14px;"><strong>87 hours / `$6,855.00</strong> (50/25/25 milestones: `$3,427.50 / `$1,713.75 / `$1,713.75)</p>
    <p style="margin:0 0 6px;font-weight:600;color:#006DB6;">Monthly Schedule A delta</p>
    <p style="margin:0 0 6px;">Signed `$2,794.50/mo &rarr; Proposed <strong>`$3,726.50/mo</strong> (<strong style="color:#F67D4B;">+`$932.00/mo</strong>)</p>
    <table role="presentation" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;margin:0 0 14px;font-size:13px;">
      <tr><th align="left" style="padding:6px 8px;background-color:#006DB6;color:#FFF;border:1px solid #006DB6;">Line</th><th align="left" style="padding:6px 8px;background-color:#006DB6;color:#FFF;border:1px solid #006DB6;">Code</th><th align="right" style="padding:6px 8px;background-color:#006DB6;color:#FFF;border:1px solid #006DB6;">Unit</th><th align="right" style="padding:6px 8px;background-color:#006DB6;color:#FFF;border:1px solid #006DB6;">Qty</th><th align="right" style="padding:6px 8px;background-color:#006DB6;color:#FFF;border:1px solid #006DB6;">Monthly</th></tr>
      <tr><td style="padding:6px 8px;border:1px solid #E9ECEF;">CrowdStrike Falcon for Mac</td><td style="padding:6px 8px;border:1px solid #E9ECEF;">AVD</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$8.50</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">10</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$85.00</td></tr>
      <tr style="background-color:#F8F9FA;"><td style="padding:6px 8px;border:1px solid #E9ECEF;">Huntress macOS</td><td style="padding:6px 8px;border:1px solid #E9ECEF;">AVMH</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$6.00</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">10</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$60.00</td></tr>
      <tr><td style="padding:6px 8px;border:1px solid #E9ECEF;">Patch Management - macOS</td><td style="padding:6px 8px;border:1px solid #E9ECEF;">PMMAC</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$11.00</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">10</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$110.00</td></tr>
      <tr style="background-color:#F8F9FA;"><td style="padding:6px 8px;border:1px solid #E9ECEF;">My Remote (ScreenConnect)</td><td style="padding:6px 8px;border:1px solid #E9ECEF;">MR</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$2.00</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">10</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$20.00</td></tr>
      <tr><td style="padding:6px 8px;border:1px solid #E9ECEF;font-weight:600;">Teramind / MyAudit UAM+DLP / 1yr</td><td style="padding:6px 8px;border:1px solid #E9ECEF;">AMDLP1Y</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$108.10</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">10</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;">`$1,081.00</td></tr>
      <tr style="background-color:#FFF3E0;"><td colspan="4" style="padding:6px 8px;border:1px solid #E9ECEF;font-weight:700;color:#1A1A2E;">Per-Mac total</td><td align="right" style="padding:6px 8px;border:1px solid #E9ECEF;font-weight:700;color:#1A1A2E;">`$135.60 &rarr; `$1,356.00</td></tr>
    </table>
    <p style="margin:0 0 14px;font-size:13px;color:#777;"><em>Plus unchanged lines: M365 user services (`$263.50), IP services (`$42), domain services (`$70), Virtual Staff Support (`$1,995). CloudBrink licensing remains AFFG-procured. Intune for Macs and BYOD phones is included in your existing M365 E3 - no additional charge.</em></p>
    <p style="margin:0 0 6px;font-weight:600;color:#006DB6;">Legal terms (Exhibit A)</p>
    <ul style="margin:0 0 14px;padding-left:22px;">
      <li><strong>Section 2.05 - Operational Continuity Materials (new):</strong> admin / root credentials, DNS control, break-glass info, life-safety system info, and regulatorily-retained data must be transferred to AFFG within <strong>5 business days</strong> regardless of payment status. This is a client-protective addition - your operations are never held hostage to a billing dispute.</li>
      <li><strong>Section 9.09 - Recruiting Cost Reimbursement (rewritten):</strong> the prior 25% Personnel Transition Fee is replaced with documented out-of-pocket recruiting costs only, capped at `$25,000 per individual, with explicit Cal. Bus. &amp; Prof. Sec.16600 acknowledgment and a carve-out when an employee initiates contact on their own.</li>
      <li><strong>Section 12.08 - Template Currency Acknowledgment (new):</strong> Technijian's outside legal counsel review of the 2026 MSA framework is in progress. Either party may propose conforming edits to Exhibit A within 60 days of signature; Exhibit A is fully effective on execution either way.</li>
    </ul>
    <p style="margin:0 0 14px;">Section 12 incorporation of the 2026 MSA framework into your signed Monthly Service Agreement is preserved unchanged in concept - only the Section 2.05, Section 9.09, and the new Section 12.08 text differs from Rev 2.</p>
    <p style="margin:0 0 14px;">Happy to walk through anything before you sign - 15-minute call any time. Otherwise, the DocuSign signing link is in the companion email.</p>
  </td></tr>
  <tr><td style="padding:0 32px 24px;">
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;"><tr><td style="background-color:#F67D4B;border-radius:6px;">
      <a href="https://outlook.office.com/bookwithme/user/ceb349088c264d73b4854612958471e9@technijian.com/meetingtype/SVRwCe7HMUGxuT6WGxi68g2?anonymous&amp;ismsaljsauthenabled&amp;ep=mLinkFromTile" style="display:inline-block;padding:12px 28px;font-size:15px;font-weight:600;color:#FFF;text-decoration:none;">Book a 15-Minute Call</a>
    </td></tr></table>
  </td></tr>
  <tr><td style="padding:24px 32px;background-color:#1A1A2E;color:#FFF;font-size:12px;line-height:1.5;">
    <p style="margin:0 0 6px;"><strong>Ravi Jain</strong> &middot; CEO &middot; Technijian, Inc.</p>
    <p style="margin:0 0 4px;opacity:0.75;">18 Technology Dr., Ste 141, Irvine, CA 92618 &middot; <a href="tel:9493798499" style="color:#1EAAC8;text-decoration:none;">949.379.8499 x201</a></p>
    <p style="margin:0;opacity:0.75;"><a href="mailto:rjain@technijian.com" style="color:#1EAAC8;text-decoration:none;">rjain@technijian.com</a> &middot; <a href="https://technijian.com" style="color:#1EAAC8;text-decoration:none;">technijian.com</a></p>
  </td></tr>
</table>
</td></tr></table></body></html>
"@

# Sanity check - any literal $-digit patterns means a backtick was missed
if ($html -match '\$\d') {
    Write-Error "Unescaped currency literal detected (backtick missing in PowerShell here-string). Aborting send."
    exit 1
}

$mailPayload = @{
    message = @{
        subject = $subject
        body = @{ contentType = "HTML"; content = $html }
        toRecipients = @( @{ emailAddress = @{ address = $recipientEmail; name = $recipientName } } )
    }
    saveToSentItems = $true
}

if ($DryRun) {
    Write-Host "DRY RUN - would send to $recipientEmail (subject: $subject)" -ForegroundColor Yellow
    $html | Out-File -FilePath "C:\VSCode\tech-legal\tech-legal\scripts\affg-sow004-rev3-summary-preview.html" -Encoding UTF8
    Write-Host "Preview saved to scripts\affg-sow004-rev3-summary-preview.html"
    exit 0
}

$jsonBody = $mailPayload | ConvertTo-Json -Depth 10
$bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
$sendUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/sendMail"
try {
    Invoke-RestMethod -Uri $sendUri -Method POST -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json; charset=utf-8" } -Body $bytes
    Write-Host "Summary email sent to $recipientEmail (subject: $subject)" -ForegroundColor Green
} catch {
    Write-Error "Send failed: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Host $_.ErrorDetails.Message }
    exit 1
}
