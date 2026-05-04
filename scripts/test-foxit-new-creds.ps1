# Foxit eSign — New credentials test + watermark check
# Single signer: Ravi Jain (rjain@technijian.com)
# Sends branded Graph email with signing URL

$foxitKeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md"
$m365KeysFile  = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$docPath       = "C:\vscode\tech-legal\tech-legal\docs\foxit-test-doc.docx"
$baseUrl       = "https://na1.foxitesign.foxit.com/api"
$logoUrl       = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"

$signerName  = "Ravi Jain"
$signerEmail = "rjain@technijian.com"
$signerTitle = "CEO"
$folderName  = "Foxit-eSign-Integration-Test-2026-05-04-v2"

# ── Read Foxit credentials ──
Write-Host "Reading Foxit credentials..." -ForegroundColor Cyan
$foxitKeys   = Get-Content $foxitKeysFile -Raw
$clientId    = [regex]::Match($foxitKeys, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$clientSecret= [regex]::Match($foxitKeys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $clientId -or -not $clientSecret) { Write-Error "Missing Foxit creds"; exit 1 }
Write-Host "  Client ID: $clientId" -ForegroundColor Gray
Write-Host "Foxit credentials loaded." -ForegroundColor Green

# ── Read M365 credentials ──
Write-Host "Reading M365 credentials..." -ForegroundColor Cyan
$m365Keys    = Get-Content $m365KeysFile -Raw
$m365AppId   = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Tenant  = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret  = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365AppId -or -not $m365Tenant -or -not $m365Secret) { Write-Error "Missing M365 creds"; exit 1 }
Write-Host "M365 credentials loaded." -ForegroundColor Green

# ── Authenticate with Foxit ──
Write-Host "`nAuthenticating with Foxit eSign..." -ForegroundColor Cyan
$tokenResp = Invoke-RestMethod -Uri "$baseUrl/oauth2/access_token" -Method POST -ContentType "application/x-www-form-urlencoded" -Body @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "read-write"
}
$foxitToken = $tokenResp.access_token
Write-Host "Foxit auth OK. Token expires in $($tokenResp.expires_in) seconds." -ForegroundColor Green

$foxitHeaders = @{ "Authorization" = "Bearer $foxitToken"; "Content-Type" = "application/json" }

# ── Read and encode document ──
Write-Host "`nEncoding document..." -ForegroundColor Cyan
$docBytes = [System.IO.File]::ReadAllBytes($docPath)
$docB64   = [Convert]::ToBase64String($docBytes)
$docName  = [System.IO.Path]::GetFileName($docPath)
Write-Host "  $docName ($([math]::Round($docBytes.Length/1KB,1)) KB)" -ForegroundColor Gray

# ── Create envelope: single signer ──
Write-Host "`nCreating Foxit eSign envelope (single signer)..." -ForegroundColor Cyan
$nameParts = $signerName -split '\s+', 2
$body = @{
    folderName                                  = $folderName
    inputType                                   = "base64"
    base64FileString                            = @($docB64)
    fileNames                                   = @($docName)
    sendNow                                     = $true
    createEmbeddedSigningSession                = $true
    createEmbeddedSigningSessionForAllParties   = $true
    signInSequence                              = $false
    inPersonEnable                              = $false
    parties = @(
        @{
            firstName        = $nameParts[0]
            lastName         = if ($nameParts.Length -gt 1) { $nameParts[1] } else { "" }
            emailId          = $signerEmail
            permission       = "FILL_FIELDS_AND_SIGN"
            sequence         = 1
            workflowSequence = 1
        }
    )
    fields = @(
        @{ type="signature"; x=72; y=50;  width=220; height=35; pageNumber=-1; documentNumber=1; party=1; required=$true }
        @{ type="textfield"; x=72; y=90;  width=200; height=20; pageNumber=-1; documentNumber=1; party=1; name="signer_name";  value=$signerName;  required=$true }
        @{ type="textfield"; x=72; y=115; width=200; height=20; pageNumber=-1; documentNumber=1; party=1; name="signer_title"; value=$signerTitle; required=$true }
        @{ type="datefield"; x=72; y=140; width=140; height=20; pageNumber=-1; documentNumber=1; party=1; name="sign_date";    required=$true }
    )
} | ConvertTo-Json -Depth 10

$resp = Invoke-RestMethod -Uri "$baseUrl/folders/createfolder" -Method POST -Headers $foxitHeaders -Body $body
Write-Host "Envelope created. Folder ID: $($resp.folderId)" -ForegroundColor Green

# ── Extract signing URL ──
$signUrl = $null
if ($resp.folder -and $resp.folder.folderRecipientParties) {
    foreach ($p in $resp.folder.folderRecipientParties) {
        if ($p.partyDetails.emailId -eq $signerEmail -and $p.folderAccessURL) {
            $signUrl = $p.folderAccessURL
        }
    }
}
if (-not $signUrl -and $resp.embeddedSigningSessions) {
    foreach ($s in $resp.embeddedSigningSessions) {
        if ($s.emailIdOfSigner -eq $signerEmail) { $signUrl = $s.embeddedSessionURL }
    }
}

if (-not $signUrl) {
    Write-Host "DEBUG: Full response:" -ForegroundColor Yellow
    $resp | ConvertTo-Json -Depth 10
    Write-Error "Could not extract signing URL"; exit 1
}
Write-Host "Signing URL obtained." -ForegroundColor Green

# ── Authenticate with M365 Graph ──
Write-Host "`nAuthenticating with Microsoft Graph..." -ForegroundColor Cyan
$graphTokenResp = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365Tenant/oauth2/v2.0/token" `
    -Method POST -ContentType "application/x-www-form-urlencoded" -Body @{
        grant_type    = "client_credentials"
        client_id     = $m365AppId
        client_secret = $m365Secret
        scope         = "https://graph.microsoft.com/.default"
    }
$graphToken = $graphTokenResp.access_token
Write-Host "Graph auth OK." -ForegroundColor Green

$graphHeaders = @{ "Authorization" = "Bearer $graphToken"; "Content-Type" = "application/json" }

# ── Build branded email ──
$html = @"
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#F8F9FA;font-family:'Open Sans','Segoe UI',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F8F9FA;">
<tr><td align="center" style="padding:24px 16px;">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.06);">
  <tr><td style="padding:24px 32px;border-bottom:3px solid #006DB6;">
    <img src="$logoUrl" alt="Technijian" width="200" style="display:block;">
  </td></tr>
  <tr><td style="padding:40px 32px;background:#006DB6;text-align:center;">
    <h1 style="margin:0 0 10px;font-size:26px;font-weight:700;color:#fff;">Foxit eSign Integration Test</h1>
    <p style="margin:0;font-size:15px;color:rgba(255,255,255,.85);">New credentials verified &mdash; please sign the test document below.</p>
  </td></tr>
  <tr><td style="padding:32px;">
    <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">Hi Ravi,</p>
    <p style="margin:0 0 24px;font-size:15px;color:#59595B;line-height:1.6;">
      The new Foxit eSign API credentials (<code style="background:#F8F9FA;padding:2px 6px;border-radius:4px;font-size:13px;">076daa485...</code>) authenticated successfully.
      Please sign the test document below and verify the signed copy has <strong>no watermark</strong>.
    </p>
    <table cellpadding="0" cellspacing="0" style="margin:0 auto 24px;">
      <tr><td style="background:#F67D4B;border-radius:6px;">
        <a href="$signUrl" style="display:inline-block;padding:16px 40px;font-size:17px;font-weight:600;color:#fff;text-decoration:none;">Review &amp; Sign Test Document</a>
      </td></tr>
    </table>
    <p style="margin:0 0 8px;font-size:13px;color:#59595B;text-align:center;">Or copy this link into your browser:</p>
    <p style="margin:0;font-size:11px;color:#006DB6;text-align:center;word-break:break-all;"><a href="$signUrl" style="color:#006DB6;">$signUrl</a></p>
  </td></tr>
  <tr><td style="padding:0 32px;"><div style="border-top:2px solid #1EAAC8;"></div></td></tr>
  <tr><td style="padding:24px 32px;background:#1A1A2E;">
    <p style="margin:0 0 4px;font-size:13px;color:#fff;"><strong>Technijian, Inc.</strong></p>
    <p style="margin:0;font-size:12px;color:rgba(255,255,255,.6);">18 Technology Dr., Ste 141, Irvine CA 92618 &bull; 949.379.8499 &bull; technijian.com</p>
  </td></tr>
</table></td></tr></table></body></html>
"@

$mailBody = @{
    Message = @{
        Subject = "Foxit eSign Test — New Credentials — Signature Required"
        Body    = @{ ContentType = "HTML"; Content = $html }
        ToRecipients = @( @{ EmailAddress = @{ Address = $signerEmail; Name = $signerName } } )
        From    = @{ EmailAddress = @{ Address = $signerEmail; Name = "Ravi Jain - Technijian" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 10

# ── Send via Graph ──
Write-Host "`nSending branded signing email via Microsoft Graph..." -ForegroundColor Cyan
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$signerEmail/sendMail" `
    -Method POST -Headers $graphHeaders -Body $mailBody
Write-Host "Email sent to $signerName <$signerEmail>" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " FOXIT ESIGN TEST COMPLETE" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Foxit auth:   OK (new credentials confirmed)" -ForegroundColor White
Write-Host " Folder ID:    $($resp.folderId)" -ForegroundColor White
Write-Host " Document:     $docName" -ForegroundColor White
Write-Host " Signer:       $signerName <$signerEmail>" -ForegroundColor White
Write-Host " Email from:   Ravi Jain - Technijian <$signerEmail>" -ForegroundColor White
Write-Host " Email:        Branded Technijian template via Graph" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " CHECK: Sign the document and verify NO watermark on download." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
