# Test: Send a sample branded signing email to Ravi to preview the template
param(
    [string]$TestRecipient = "rjain@technijian.com"
)

$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$logoUrl = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"
$sampleSignUrl = "https://na1.foxitesign.foxit.com/viewDocumentDirect?sample=test"

# --- Read M365 Graph credentials ---
$m365Keys = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId) { $m365ClientId = [regex]::Match($m365Keys, 'App Client ID = (\S+)').Groups[1].Value }
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365TenantId) { $m365TenantId = [regex]::Match($m365Keys, 'Tenant ID = (\S+)').Groups[1].Value }
$m365Secret = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365Secret) { $m365Secret = [regex]::Match($m365Keys, '(?<=Tenant ID[^\n]+\n)Client Secret = (.+)').Groups[1].Value.Trim() }

# --- Get Graph token ---
$graphTokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $m365ClientId
    client_secret = $m365Secret
    scope         = "https://graph.microsoft.com/.default"
}
$graphTokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token" `
    -Method POST -Body $graphTokenBody -ContentType "application/x-www-form-urlencoded"
$graphToken = $graphTokenResponse.access_token

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "Content-Type"  = "application/json"
}

# --- Build branded email ---
$htmlBody = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Document Ready for Signature</title>
</head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">

<div style="display:none;max-height:0;overflow:hidden;">Ravi Jain sent you a document to review and sign.</div>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F8F9FA;">
<tr><td align="center" style="padding:24px 16px;">

<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:#FFFFFF;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">

  <!-- Header with Logo -->
  <tr>
    <td style="padding:24px 32px;border-bottom:3px solid #006DB6;">
      <img src="$logoUrl" alt="Technijian" width="200" style="display:block;max-width:200px;height:auto;">
    </td>
  </tr>

  <!-- Hero Banner -->
  <tr>
    <td style="padding:40px 32px;background-color:#006DB6;text-align:center;">
      <h1 style="margin:0 0 12px;font-size:28px;font-weight:700;color:#FFFFFF;line-height:1.2;">
        Document Ready for Signature
      </h1>
      <p style="margin:0;font-size:16px;color:#FFFFFF;opacity:0.85;">
        Ravi Jain has sent you a document to review and sign.
      </p>
    </td>
  </tr>

  <!-- Body -->
  <tr>
    <td style="padding:32px;">
      <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">
        Hi Jose,
      </p>
      <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">
        Please review and sign the following document from <strong style="color:#1A1A2E;">Technijian, Inc.</strong>:
      </p>

      <!-- Document Card -->
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;border:1px solid #E9ECEF;border-radius:6px;overflow:hidden;">
        <tr>
          <td style="padding:16px 20px;background-color:#F8F9FA;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td style="vertical-align:middle;">
                  <p style="margin:0 0 4px;font-size:14px;font-weight:600;color:#1A1A2E;">SOW-TSC-001-CTO-Advisory</p>
                  <p style="margin:0;font-size:13px;color:#59595B;">Sent by Ravi Jain, CEO &bull; Technijian, Inc.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <!-- CTA Button -->
      <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
        <tr>
          <td style="background-color:#F67D4B;border-radius:6px;">
            <a href="$sampleSignUrl" style="display:inline-block;padding:16px 40px;font-size:18px;font-weight:600;color:#FFFFFF;text-decoration:none;letter-spacing:0.5px;">Review &amp; Sign Document</a>
          </td>
        </tr>
      </table>

      <p style="margin:24px 0 0;font-size:14px;color:#59595B;line-height:1.6;text-align:center;">
        If the button doesn't work, copy and paste this link into your browser:<br>
        <a href="$sampleSignUrl" style="color:#006DB6;word-break:break-all;font-size:12px;">$sampleSignUrl</a>
      </p>
    </td>
  </tr>

  <!-- Divider -->
  <tr>
    <td style="padding:0 32px;">
      <div style="border-top:2px solid #1EAAC8;"></div>
    </td>
  </tr>

  <!-- Help Section -->
  <tr>
    <td style="padding:20px 32px;">
      <p style="margin:0;font-size:13px;color:#59595B;line-height:1.6;">
        If you have any questions about this document, please contact <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">Ravi Jain</a> at <a href="mailto:rjain@technijian.com" style="color:#006DB6;text-decoration:none;">rjain@technijian.com</a> or call <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">949.379.8499</a>.
      </p>
    </td>
  </tr>

  <!-- Footer -->
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
</td></tr>
</table>
</body>
</html>
"@

# --- Send test email ---
$mailBody = @{
    Message = @{
        Subject = "TEST - Technijian Branded Signing Email Preview"
        Body = @{
            ContentType = "HTML"
            Content = $htmlBody
        }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = $TestRecipient; Name = "Ravi Jain" } }
        )
        From = @{ EmailAddress = @{ Address = "rjain@technijian.com"; Name = "Ravi Jain - Technijian" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/rjain@technijian.com/sendMail" `
        -Method POST -Headers $graphHeaders -Body $mailBody
    Write-Host "Test branded email sent to $TestRecipient" -ForegroundColor Green
}
catch {
    Write-Error "Failed: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
}
