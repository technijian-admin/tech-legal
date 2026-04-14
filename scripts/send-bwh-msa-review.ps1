# Send BWH MSA + Schedules to Dave Barisic for review (non-DocuSign review copy)

$ClientDir      = "C:\vscode\tech-legal\tech-legal\clients\BWH"
$Attachments    = @(
    "MSA-BWH-Agreement.docx",
    "BWH-Schedule-A-Monthly-Services.docx",
    "BWH-Schedule-B-Subscriptions.docx",
    "BWH-Schedule-C-Rate-Card.docx"
)
$RecipientEmail = "dave@brandywine-homes.com"
$RecipientName  = "Dave Barisic"
$FromAddress    = "RJain@technijian.com"
$Subject        = "Brandywine Homes - MSA and Schedules for Review"

$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$logoUrl      = "https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png"

$m365Keys = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId) { $m365ClientId = [regex]::Match($m365Keys, 'App Client ID = (\S+)').Groups[1].Value }
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365TenantId) { $m365TenantId = [regex]::Match($m365Keys, 'Tenant ID = (\S+)').Groups[1].Value }
$m365Secret = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365Secret) { $m365Secret = [regex]::Match($m365Keys, '(?<=Tenant ID[^\n]+\n)Client Secret = (.+)').Groups[1].Value.Trim() }

Write-Host "Authenticating with Microsoft Graph..." -ForegroundColor Cyan
$graphTokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token" `
    -Method POST -Body @{
        grant_type    = "client_credentials"
        client_id     = $m365ClientId
        client_secret = $m365Secret
        scope         = "https://graph.microsoft.com/.default"
    } -ContentType "application/x-www-form-urlencoded"
$graphToken = $graphTokenResponse.access_token

# Build attachments array
$attachmentObjects = @()
foreach ($name in $Attachments) {
    $path = Join-Path $ClientDir $name
    if (-not (Test-Path $path)) {
        Write-Error "Missing: $path"
        exit 1
    }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $b64 = [Convert]::ToBase64String($bytes)
    $attachmentObjects += @{
        "@odata.type" = "#microsoft.graph.fileAttachment"
        name = $name
        contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        contentBytes = $b64
    }
    Write-Host "  Attached: $name ($([Math]::Round($bytes.Length/1024, 1)) KB)" -ForegroundColor Gray
}

# Ravi Jain signature
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
<tr><td colspan="2" style="border-top:1px solid rgb(233,236,239); padding-top:8px">
<p style="line-height:1.4; margin:0px; font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif; font-size:10px; color:rgb(173,181,189)">This email and any attachments are confidential and intended solely for the addressee. If you have received this message in error, please notify the sender immediately and delete it from your system. Unauthorized review, use, disclosure, or distribution is prohibited.</p>
</td></tr>
</tbody>
</table>
"@

$emailBody = @"
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;color:rgb(26,26,46);">

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F8F9FA;">
<tr><td align="center" style="padding:24px 16px;">

<table role="presentation" width="620" cellpadding="0" cellspacing="0" style="max-width:620px;width:100%;background-color:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">

  <tr>
    <td style="padding:24px 32px;border-bottom:3px solid #006DB6;">
      <img src="$logoUrl" alt="Technijian" width="200" style="display:block;max-width:200px;height:auto;">
    </td>
  </tr>

  <tr>
    <td style="padding:32px;">

      <p style="margin:0 0 16px;font-size:14pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);">Hi Dave,</p>

      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        Sorry the DocuSign link kept expiring on you. Attached are the full MSA and all three Schedules for your review outside of DocuSign:
      </p>

      <ol style="margin:0 0 16px 20px;padding:0;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.6;">
        <li><strong>MSA-BWH-Agreement.docx</strong> &mdash; Master Service Agreement (the legal body)</li>
        <li><strong>BWH-Schedule-A-Monthly-Services.docx</strong> &mdash; Monthly services, pricing, and support hours</li>
        <li><strong>BWH-Schedule-B-Subscriptions.docx</strong> &mdash; Subscription and license services</li>
        <li><strong>BWH-Schedule-C-Rate-Card.docx</strong> &mdash; Labor rate card for ad-hoc and project work</li>
      </ol>

      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        Once you've had a chance to review, I'll resend a fresh DocuSign envelope for signature &mdash; just let me know when you're ready and I'll make sure the new link stays active.
      </p>

      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        On the NewStar connection issue at the sales offices &mdash; I'll have the team open a ticket and dig into why the same fix isn't sticking. Will follow up on that separately so it doesn't get buried.
      </p>

      <p style="margin:0 0 16px;font-size:12pt;font-family:Aptos,Calibri,sans-serif;color:rgb(0,0,0);line-height:1.5;">
        If you'd prefer to walk through the documents together before signing, please grab time on my calendar via the booking link in my email signature.
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
        attachments = $attachmentObjects
    }
    saveToSentItems = $true
} | ConvertTo-Json -Depth 10

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "Content-Type"  = "application/json"
}

Write-Host "Sending MSA + Schedules to $RecipientEmail..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$FromAddress/sendMail" `
        -Method POST -Headers $graphHeaders -Body $mailBody -TimeoutSec 120 | Out-Null
    Write-Host "Email sent successfully." -ForegroundColor Green
    Write-Host "  To:      $RecipientName <$RecipientEmail>" -ForegroundColor White
    Write-Host "  From:    $FromAddress" -ForegroundColor White
    Write-Host "  Subject: $Subject" -ForegroundColor White
    Write-Host "  Attachments: $($Attachments.Count) files" -ForegroundColor White
}
catch {
    Write-Error "Failed to send email: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error "API Response: $($_.ErrorDetails.Message)" }
    exit 1
}
