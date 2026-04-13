# Send AAVA Executive Summary to Melissa via M365 Graph with Ravi's branded signature

$AttachmentPath = "C:\vscode\tech-legal\tech-legal\clients\AAVA\AAVA-Executive-Summary.docx"
$RecipientEmail = "melissa@aventine-apartments.com"
$RecipientName  = "Melissa Aventine"
$FromAddress    = "RJain@technijian.com"
$Subject        = "Technijian MSA Renewal for Aventine - Executive Summary and Signature Package"

$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$logoUrl      = "https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png"

# -------- Read M365 credentials --------
$m365Keys = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId) { $m365ClientId = [regex]::Match($m365Keys, 'App Client ID = (\S+)').Groups[1].Value }
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365TenantId) { $m365TenantId = [regex]::Match($m365Keys, 'Tenant ID = (\S+)').Groups[1].Value }
$m365Secret = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365Secret) { $m365Secret = [regex]::Match($m365Keys, '(?<=Tenant ID[^\n]+\n)Client Secret = (.+)').Groups[1].Value.Trim() }

if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to read M365 Graph credentials"
    exit 1
}

# -------- Authenticate with Microsoft Graph --------
Write-Host "Authenticating with Microsoft Graph..." -ForegroundColor Cyan
$graphTokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token" `
    -Method POST -Body @{
        grant_type    = "client_credentials"
        client_id     = $m365ClientId
        client_secret = $m365Secret
        scope         = "https://graph.microsoft.com/.default"
    } -ContentType "application/x-www-form-urlencoded"
$graphToken = $graphTokenResponse.access_token

# -------- Read and base64-encode the attachment --------
if (-not (Test-Path $AttachmentPath)) {
    Write-Error "Attachment not found: $AttachmentPath"
    exit 1
}
$fileBytes = [System.IO.File]::ReadAllBytes($AttachmentPath)
$fileBase64 = [Convert]::ToBase64String($fileBytes)
$fileName = [System.IO.Path]::GetFileName($AttachmentPath)

# -------- Ravi Jain Signature HTML --------
$raviSignature = @"
<table cellspacing="0" cellpadding="0" border="0" style="max-width:600px">
<tbody>
<tr><td colspan="2" style="border-top:3px solid rgb(246,125,75); padding-bottom:16px"></td></tr>
<tr>
<td style="padding-right:16px; vertical-align:top; width:120px">
<img alt="Ravi Jain" width="120" height="120" src="https://technijian.com/wp-content/uploads/2026/03/ravi-jain.jpg" style="width:120px; height:120px; border:2px solid rgb(233,236,239); border-radius:6px; display:block">
</td>
<td style="vertical-align:top">
<table cellspacing="0" cellpadding="0" border="0">
<tbody>
<tr><td style="line-height:1.3; padding-bottom:1px; color:rgb(26,26,46)">
<div style="line-height:1.3; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:18px"><span style="font-weight:700">Ravi Jain</span></div>
</td></tr>
<tr><td style="padding-bottom:2px; color:rgb(0,109,182)">
<div style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:13px"><span style="font-weight:600">CEO</span></div>
</td></tr>
<tr><td style="padding-bottom:8px; color:rgb(89,89,91)">
<div style="font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:12px">Technijian</div>
</td></tr>
<tr><td style="line-height:1.7; color:rgb(89,89,91)">
<div style="line-height:1.7; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif">
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">T:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">949.379.8499 x201</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">C:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">714.402.3164</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">S:</span>&nbsp;<span style="font-size:12px; color:rgb(89,89,91)">949.379.8501</span>&nbsp;<span style="font-size:11px; color:rgb(173,181,189)">(support)</span><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">E:</span>&nbsp;<a href="mailto:rjain@technijian.com" style="font-size:12px; color:rgb(0,109,182); text-decoration:none">rjain@technijian.com</a><br>
<span style="font-size:12px; color:rgb(0,109,182); font-weight:600">W:</span>&nbsp;<a href="https://technijian.com" style="font-size:12px; color:rgb(0,109,182); text-decoration:none">technijian.com</a>
</div>
</td></tr>
<tr><td style="padding-top:8px; padding-bottom:4px">
<table cellspacing="0" cellpadding="0" border="0"><tbody><tr>
<td style="padding-right:8px">
<a href="https://outlook.office.com/bookwithme/user/ceb349088c264d73b4854612958471e9@technijian.com/meetingtype/SVRwCe7HMUGxuT6WGxi68g2?anonymous&amp;ismsaljsauthenabled&amp;ep=mLinkFromTile" style="color:rgb(255,255,255); text-decoration:none; display:inline-block; padding:6px 16px; background-color:rgb(0,109,182); border-radius:4px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:12px; font-weight:600">Book a Meeting</a>
</td>
<td>
<a href="https://outlook.office365.com/owa/calendar/Meetingwithsupport@Technijian365.onmicrosoft.com/bookings/" style="color:rgb(255,255,255); text-decoration:none; display:inline-block; padding:6px 16px; background-color:rgb(246,125,75); border-radius:4px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:12px; font-weight:600">Book time with Support</a>
</td>
</tr></tbody></table>
</td></tr>
<tr><td style="line-height:1.6; padding-top:6px; color:rgb(173,181,189)">
<div style="line-height:1.6; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:11px">
<span style="color:rgb(0,109,182); font-weight:600">USA:</span>&nbsp;18 Technology Dr., Ste 141, Irvine, CA 92618<br>
<span style="color:rgb(0,109,182); font-weight:600">India:</span>&nbsp;Plot No. 07, 1st Floor, Panchkula IT Park, Panchkula, Haryana 134109
</div>
</td></tr>
</tbody></table>
</td>
</tr>
<tr><td colspan="2" style="padding-top:14px; padding-bottom:10px">
<table cellspacing="0" cellpadding="0" border="0" style="width:100%"><tbody><tr><td style="border-top:2px solid rgb(0,109,182)"></td></tr></tbody></table>
</td></tr>
<tr><td colspan="2" style="padding-bottom:10px">
<img alt="Technijian - Technology as a Solution" width="160" src="$logoUrl" style="width:160px; display:block">
</td></tr>
<tr><td colspan="2" style="padding-bottom:12px">
<div style="line-height:1; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:11px">
<a href="https://www.linkedin.com/company/technijian" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">LinkedIn</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.facebook.com/Technijian01/" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">Facebook</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.youtube.com/@TechnijianIT" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">YouTube</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.instagram.com/technijianinc/" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">Instagram</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://twitter.com/technijian_" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">X</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://www.tiktok.com/@technijian" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">TikTok</a>&nbsp;<span style="color:rgb(233,236,239)">|</span>&nbsp;<a href="https://in.pinterest.com/technijian01/" style="color:rgb(0,109,182); text-decoration:none; font-weight:600">Pinterest</a>
</div>
</td></tr>
<tr><td colspan="2" style="border-top:1px solid rgb(233,236,239); padding-top:8px">
<p style="line-height:1.4; margin:0px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:10px; color:rgb(173,181,189)">This email and any attachments are confidential and intended solely for the addressee. If you have received this message in error, please notify the sender immediately and delete it from your system. Unauthorized review, use, disclosure, or distribution is prohibited.</p>
</td></tr>
</tbody>
</table>
"@

# -------- Email Body --------
$emailBody = @"
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;color:rgb(26,26,46);">

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F8F9FA;">
<tr><td align="center" style="padding:24px 16px;">

<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">

  <tr>
    <td style="padding:24px 32px;border-bottom:3px solid #006DB6;">
      <img src="$logoUrl" alt="Technijian" width="200" style="display:block;max-width:200px;height:auto;">
    </td>
  </tr>

  <tr>
    <td style="padding:32px;">

      <p style="margin:0 0 16px;font-size:14pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">Hi Melissa,</p>

      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        Thank you again for your partnership with Technijian. I'd like to walk you through the renewal package for Aventine at Aliso Viejo Apartments, effective <strong>May 1, 2026</strong>.
      </p>

      <h2 style="margin:24px 0 8px;font-size:14pt;font-family:Aptos,Calibri,sans-serif;color:#006DB6;">Attached to this email</h2>
      <ul style="margin:0 0 16px 20px;padding:0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.6;">
        <li><strong>AAVA Executive Summary</strong> (PDF/DOCX) &mdash; a plain-language walkthrough of the renewal: what changed, your monthly savings, the current unpaid support hours balance, and how we can reduce that balance over time. Please review this first.</li>
      </ul>

      <h2 style="margin:24px 0 8px;font-size:14pt;font-family:Aptos,Calibri,sans-serif;color:#006DB6;">Sent separately via DocuSign</h2>
      <p style="margin:0 0 8px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        You will receive a separate email titled <em>"Technijian MSA Renewal &ndash; Aventine at Aliso Viejo Apartments &ndash; Ready to Sign"</em> containing the full signature package:
      </p>
      <ol style="margin:0 0 16px 20px;padding:0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.6;">
        <li><strong>Master Service Agreement (MSA-AAVA-2026)</strong> &mdash; the main legal agreement (this is where you sign)</li>
        <li><strong>Schedule A &mdash; Monthly Managed Services</strong> &mdash; pricing, service parts, and the Unpaid Balance Acknowledgment</li>
        <li><strong>Schedule B &mdash; Subscription and License Services</strong> &mdash; governing terms for future subscription additions (no active subscriptions today)</li>
        <li><strong>Schedule C &mdash; Rate Card</strong> &mdash; hourly rates for ad-hoc and project work</li>
      </ol>
      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        Signing parallel with me means we both receive the envelope at the same time &mdash; no waiting.
      </p>

      <h2 style="margin:24px 0 8px;font-size:14pt;font-family:Aptos,Calibri,sans-serif;color:#006DB6;">The short version</h2>
      <table role="presentation" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin:0 0 16px 0;">
        <tr><td style="padding:4px 12px 4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);"><strong>Monthly recurring:</strong></td><td style="padding:4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">$539.60 &rarr; <strong style="color:#006DB6;">$333.35</strong> (save $206.25/mo)</td></tr>
        <tr><td style="padding:4px 12px 4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);"><strong>Term:</strong></td><td style="padding:4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">12 months, effective May 1, 2026</td></tr>
        <tr><td style="padding:4px 12px 4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);"><strong>Removed:</strong></td><td style="padding:4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">Site Assessment ($50), USA Tech contracted hours ($156.25)</td></tr>
        <tr><td style="padding:4px 12px 4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);"><strong>USA support:</strong></td><td style="padding:4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">Available ad-hoc at Rate Card rates ($150/hr normal)</td></tr>
        <tr><td style="padding:4px 12px 4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);"><strong>Unpaid balance:</strong></td><td style="padding:4px 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">$1,094.85 carried forward (see Executive Summary for full explanation)</td></tr>
      </table>

      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        The most important detail to read in the Executive Summary is the section on <strong>Unpaid Balance</strong>. The way we're structuring this renewal gives you immediate savings, but at your current March 2026 support usage the unpaid hours will grow at about $98.70/month. We laid out three options for managing that &mdash; the simplest is to work together on reducing support volume so the balance starts going down instead of up.
      </p>

      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        Please review the Executive Summary, then sign the DocuSign package when it arrives. If you have any questions, reply here or call me directly at 949.379.8499.
      </p>

      <p style="margin:24px 0 0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">Thank you,</p>

      $raviSignature

    </td>
  </tr>

</table>

</td></tr>
</table>

</body>
</html>
"@

# -------- Build Graph message --------
$mailBody = @{
    message = @{
        subject = $Subject
        body = @{
            contentType = "HTML"
            content = $emailBody
        }
        toRecipients = @(
            @{ emailAddress = @{ address = $RecipientEmail; name = $RecipientName } }
        )
        attachments = @(
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                name = $fileName
                contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                contentBytes = $fileBase64
            }
        )
    }
    saveToSentItems = $true
} | ConvertTo-Json -Depth 10

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "Content-Type"  = "application/json"
}

Write-Host "Sending Executive Summary to $RecipientEmail..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$FromAddress/sendMail" `
        -Method POST -Headers $graphHeaders -Body $mailBody -TimeoutSec 60 | Out-Null
    Write-Host "Executive Summary sent successfully." -ForegroundColor Green
    Write-Host "  To:     $RecipientName <$RecipientEmail>" -ForegroundColor White
    Write-Host "  From:   $FromAddress" -ForegroundColor White
    Write-Host "  Subject: $Subject" -ForegroundColor White
    Write-Host "  Attach:  $fileName" -ForegroundColor White
}
catch {
    Write-Error "Failed to send email: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error "API Response: $($_.ErrorDetails.Message)" }
    exit 1
}
