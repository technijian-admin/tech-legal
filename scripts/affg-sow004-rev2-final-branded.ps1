# All-in-one: void existing envelope, create new WITH clientUserId, place tabs,
# send, get signing URLs, build canonical Technijian-branded email, dispatch via Graph.
# Ravi + Iris must click within ~5 min of send (embedded signing URL expiry).

$ErrorActionPreference = "Stop"

$DocumentPath    = "C:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Rev1-Managed-Device-Migration.docx"
$RecipientName   = "Iris Liu"
$RecipientEmail  = "iris.liu@americanfundstars.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$EmailSubject    = "Technijian - SOW-AFFG-004 Rev 1 - Signature Required"
$folderName      = "SOW-AFFG-004 Rev 1 - Fleet Right-Sizing and Compliance"
$oldEnvelopeId   = "b6062c50-1729-89e0-8023-13aceffb8651"
$logoUrl         = "https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png"

$keysFile     = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$sigPath      = Join-Path $scriptDir "ravi-signature.html"

# --- DocuSign auth ---
$keysContent = Get-Content $keysFile -Raw
$ClientId  = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId    = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey    = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value
$nodeCommand = "C:\Program Files\nodejs\node.exe"
$tempKeyPath = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKeyPath -NoNewline
$jwt = & $nodeCommand (Join-Path $scriptDir "docusign-jwt-helper.js") $ClientId $UserId $tempKeyPath 2>&1
Remove-Item $tempKeyPath -ErrorAction SilentlyContinue
$tok = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST `
    -Body @{ grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"; assertion = $jwt } `
    -ContentType "application/x-www-form-urlencoded"
$accessToken = $tok.access_token
$userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers @{ Authorization = "Bearer $accessToken" }
$baseUri  = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
$apiUrl   = "$baseUri/restapi/v2.1/accounts/$AccountId"
$hJ = @{ Authorization = "Bearer $accessToken"; "Content-Type" = "application/json" }
Write-Host "DocuSign auth OK." -ForegroundColor Green

# --- Void the currently-live envelope ---
$voidBody = @{ status = "voided"; voidedReason = "Recreating with branded email + embedded signing" } | ConvertTo-Json
Invoke-RestMethod -Uri "$apiUrl/envelopes/$oldEnvelopeId" -Method PUT -Headers $hJ -Body $voidBody | Out-Null
Write-Host "Voided $oldEnvelopeId" -ForegroundColor Green

# --- Create fresh envelope WITH clientUserId (embedded signers, DocuSign email suppressed) ---
$fileName   = [System.IO.Path]::GetFileName($DocumentPath)
$fileBytes  = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

$draftPayload = @{
    emailSubject = $EmailSubject
    emailBlurb   = "Please review and sign the attached document from Technijian, Inc."
    status       = "created"
    documents    = @(@{ documentBase64 = $base64File; name = $fileName; fileExtension = "docx"; documentId = "1" })
    recipients   = @{
        signers = @(
            @{ email = $SignerEmail;    name = $SignerName;    recipientId = "1"; routingOrder = "1"; clientUserId = "tech_signer_1" },
            @{ email = $RecipientEmail; name = $RecipientName; recipientId = "2"; routingOrder = "1"; clientUserId = "client_signer_2" }
        )
    }
} | ConvertTo-Json -Depth 10

$draft = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $hJ -Body $draftPayload -TimeoutSec 60
$envelopeId = $draft.envelopeId
Write-Host "New draft envelope: $envelopeId" -ForegroundColor Green

$docInfo = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents" -Method GET -Headers $hJ
$pageCount = if ($docInfo.envelopeDocuments[0].pages -is [array]) { $docInfo.envelopeDocuments[0].pages.Count } else { [int]$docInfo.envelopeDocuments[0].pages }
$lastPage = $pageCount.ToString()

# --- Tabs (absolute positioning, last page) ---
$techTabs = @{
    signHereTabs   = @(@{ xPosition="100"; yPosition="210"; pageNumber=$lastPage; documentId="1"; recipientId="1"; scaleValue="1" })
    fullNameTabs   = @(@{ xPosition="100"; yPosition="240"; pageNumber=$lastPage; documentId="1"; recipientId="1"; tabLabel="tech_name"; font="Arial"; fontSize="Size11" })
    textTabs       = @(@{ xPosition="100"; yPosition="270"; pageNumber=$lastPage; documentId="1"; recipientId="1"; tabLabel="tech_title"; value=$SignerTitle; locked="true"; font="Arial"; fontSize="Size11"; width="200"; height="20" })
    dateSignedTabs = @(@{ xPosition="100"; yPosition="300"; pageNumber=$lastPage; documentId="1"; recipientId="1"; font="Arial"; fontSize="Size11" })
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $hJ -Body $techTabs | Out-Null

$clientTabs = @{
    signHereTabs   = @(@{ xPosition="100"; yPosition="400"; pageNumber=$lastPage; documentId="1"; recipientId="2"; scaleValue="1" })
    fullNameTabs   = @(@{ xPosition="100"; yPosition="430"; pageNumber=$lastPage; documentId="1"; recipientId="2"; tabLabel="client_name"; font="Arial"; fontSize="Size11" })
    textTabs       = @(@{ xPosition="100"; yPosition="460"; pageNumber=$lastPage; documentId="1"; recipientId="2"; tabLabel="client_title"; required="true"; font="Arial"; fontSize="Size11"; width="200"; height="20" })
    dateSignedTabs = @(@{ xPosition="100"; yPosition="490"; pageNumber=$lastPage; documentId="1"; recipientId="2"; font="Arial"; fontSize="Size11" })
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $hJ -Body $clientTabs | Out-Null
Write-Host "Tabs placed on page $lastPage" -ForegroundColor Green

# --- Transition to sent (DocuSign email suppressed due to clientUserId) ---
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json) | Out-Null
Write-Host "Envelope sent: $envelopeId (DocuSign email suppressed)" -ForegroundColor Green

# --- Get embedded signing URLs ---
$techView = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/views/recipient" -Method POST -Headers $hJ -Body (@{
    returnUrl = "https://technijian.com"; authenticationMethod = "email"; email = $SignerEmail; userName = $SignerName; clientUserId = "tech_signer_1"
} | ConvertTo-Json)
$techSignUrl = $techView.url

$clientView = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/views/recipient" -Method POST -Headers $hJ -Body (@{
    returnUrl = "https://technijian.com"; authenticationMethod = "email"; email = $RecipientEmail; userName = $RecipientName; clientUserId = "client_signer_2"
} | ConvertTo-Json)
$clientSignUrl = $clientView.url
Write-Host "Signing URLs retrieved." -ForegroundColor Green

# ============================================================
# CANONICAL Build-SigningEmail (verbatim from send-docusign.ps1)
# ============================================================
function Build-SigningEmail {
    param([string]$RecipName, [string]$SigningUrl, [string]$DocName, [string]$SenderName, [bool]$IncludeSignature = $false)

    $signatureBlock = ""
    if ($IncludeSignature) {
        $signatureBlock = @"

<!-- Ravi Jain Email Signature -->
<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;margin:0 auto;">
<tr><td style="padding:24px 32px 0;">
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)">Thank you,</div>
<div style="font-family:Aptos,Aptos_EmbeddedFont,Aptos_MSFontService,Calibri,Helvetica,sans-serif; font-size:12pt; color:rgb(0,0,0)"><br></div>

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
<img alt="Technijian - Technology as a Solution" width="160" src="https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png" style="width:160px; display:block">
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
</td></tr>
</table>
"@
    }

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document Ready for Signature</title>
</head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">

<div style="display:none;max-height:0;overflow:hidden;">$SenderName sent you a document to review and sign.</div>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F8F9FA;">
<tr><td align="center" style="padding:24px 16px;">

<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">

  <tr>
    <td style="padding:24px 32px;border-bottom:3px solid #006DB6;">
      <img src="$logoUrl" alt="Technijian" width="200" style="display:block;max-width:200px;height:auto;">
    </td>
  </tr>

  <tr>
    <td style="padding:40px 32px;background-color:#006DB6;text-align:center;">
      <h1 style="margin:0 0 12px;font-size:28px;font-weight:700;color:#FFFFFF;line-height:1.2;">
        Document Ready for Signature
      </h1>
      <p style="margin:0;font-size:16px;color:#FFFFFF;opacity:0.85;">
        $SenderName has sent you a document to review and sign.
      </p>
    </td>
  </tr>

  <tr>
    <td style="padding:32px;">
      <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">
        Hi $RecipName,
      </p>
      <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">
        Please review and sign the following document from <strong style="color:#1A1A2E;">Technijian, Inc.</strong>:
      </p>

      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;border:1px solid #E9ECEF;border-radius:6px;overflow:hidden;">
        <tr>
          <td style="padding:16px 20px;background-color:#F8F9FA;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td style="vertical-align:middle;">
                  <p style="margin:0 0 4px;font-size:14px;font-weight:600;color:#1A1A2E;">$DocName</p>
                  <p style="margin:0;font-size:13px;color:#59595B;">Sent by $SenderName, $($SignerTitle) &bull; Technijian, Inc.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
        <tr>
          <td style="background-color:#F67D4B;border-radius:6px;">
            <a href="$SigningUrl" style="display:inline-block;padding:16px 40px;font-size:18px;font-weight:600;color:#FFFFFF;text-decoration:none;letter-spacing:0.5px;">Review &amp; Sign Document</a>
          </td>
        </tr>
      </table>

      <p style="margin:24px 0 0;font-size:14px;color:#59595B;line-height:1.6;text-align:center;">
        If the button doesn't work, copy and paste this link into your browser:<br>
        <a href="$SigningUrl" style="color:#006DB6;word-break:break-all;font-size:12px;">$SigningUrl</a>
      </p>
    </td>
  </tr>

  <tr>
    <td style="padding:0 32px;">
      <div style="border-top:2px solid #1EAAC8;"></div>
    </td>
  </tr>

  <tr>
    <td style="padding:20px 32px;">
      <p style="margin:0;font-size:13px;color:#59595B;line-height:1.6;">
        If you have any questions about this document, please contact <a href="mailto:$SignerEmail" style="color:#006DB6;text-decoration:none;">$SenderName</a> at <a href="mailto:$SignerEmail" style="color:#006DB6;text-decoration:none;">$SignerEmail</a> or call <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">949.379.8499</a>.
      </p>
    </td>
  </tr>

  <tr>
    <td style="padding:24px 32px;background-color:#1A1A2E;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td>
            <p style="margin:0 0 8px;font-size:13px;color:#FFFFFF;"><strong>Technijian, Inc.</strong></p>
            <p style="margin:0 0 4px;font-size:12px;color:#FFFFFF;opacity:0.7;">18 Technology Dr., Ste 141, Irvine, CA 92618</p>
            <p style="margin:0 0 4px;font-size:12px;color:#FFFFFF;opacity:0.7;"><a href="tel:9493798499" style="color:#1EAAC8;text-decoration:none;">949.379.8499</a> &bull; <a href="https://technijian.com" style="color:#1EAAC8;text-decoration:none;">technijian.com</a></p>
            <p style="margin:8px 0 0;font-size:11px;color:#FFFFFF;opacity:0.5;">technology as a solution</p>
          </td>
        </tr>
      </table>
    </td>
  </tr>

</table>

$signatureBlock

</td></tr>
</table>
</body>
</html>
"@
}

# --- Build both emails ---
$recipFirst  = ($RecipientName -split '\s+', 2)[0]
$signerFirst = ($SignerName -split '\s+', 2)[0]
$clientHtml = Build-SigningEmail -RecipName $recipFirst -SigningUrl $clientSignUrl -DocName $folderName -SenderName $SignerName -IncludeSignature $true
$techHtml   = Build-SigningEmail -RecipName $signerFirst -SigningUrl $techSignUrl -DocName $folderName -SenderName "Technijian eSign" -IncludeSignature $false

# --- Graph token ---
$m365Keys = [System.IO.File]::ReadAllText($m365KeysFile)
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
$gtok = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tid/oauth2/v2.0/token" -Method POST `
    -Body @{ grant_type='client_credentials'; client_id=$cid; client_secret=$sec; scope='https://graph.microsoft.com/.default' } `
    -ContentType 'application/x-www-form-urlencoded'
$gH = @{ Authorization = "Bearer $($gtok.access_token)"; 'Content-Type' = 'application/json' }

# --- Send to Iris (client — with Ravi's signature) ---
$clientPayload = @{
    Message = @{
        Subject = $EmailSubject
        Body = @{ ContentType = "HTML"; Content = [string]$clientHtml }
        ToRecipients = @( @{ EmailAddress = @{ Address = $RecipientEmail; Name = $RecipientName } } )
        From = @{ EmailAddress = @{ Address = $SignerEmail; Name = "Ravi Jain - Technijian" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 6 -Compress
$r1 = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" -Method POST -Headers $gH -Body $clientPayload -UseBasicParsing
Write-Host "Client email sent (Iris): $($r1.StatusCode)" -ForegroundColor Green

# --- Send to Ravi (internal — no personal signature) ---
$techPayload = @{
    Message = @{
        Subject = $EmailSubject
        Body = @{ ContentType = "HTML"; Content = [string]$techHtml }
        ToRecipients = @( @{ EmailAddress = @{ Address = $SignerEmail; Name = $SignerName } } )
        From = @{ EmailAddress = @{ Address = $SignerEmail; Name = "Technijian eSign" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 6 -Compress
$r2 = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" -Method POST -Headers $gH -Body $techPayload -UseBasicParsing
Write-Host "Technijian email sent (Ravi): $($r2.StatusCode)" -ForegroundColor Green

$sentAt = Get-Date
Write-Host ""
Write-Host "===================================" -ForegroundColor Yellow
Write-Host " SENT. CLICK WITHIN 5 MINUTES." -ForegroundColor Yellow
Write-Host "===================================" -ForegroundColor Yellow
Write-Host "New envelope : $envelopeId"
Write-Host "Sent at      : $sentAt"
Write-Host "Expires      : $($sentAt.AddMinutes(5))"
Write-Host "Iris         : inbox"
Write-Host "Ravi         : inbox"
