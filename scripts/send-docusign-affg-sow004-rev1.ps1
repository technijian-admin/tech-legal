# Send AFFG SOW-004 Rev 1 via DocuSign using ABSOLUTE x/y positioning on the LAST page
# Implements the pattern from feedback_docusign_anchors.md: draft-then-tabs-then-send
# - No anchor strings (they hit the header company names, not the signature block)
# - Parallel signing (both routingOrder = 1)
# - Embedded signers (DocuSign email suppressed, branded email sent via Graph)

$ErrorActionPreference = "Stop"

$DocumentPath    = "C:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Rev1-Managed-Device-Migration.docx"
$RecipientName   = "Iris Liu"
$RecipientEmail  = "iris.liu@americanfundstars.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$EmailSubject    = "Technijian - SOW-AFFG-004 Rev 1 - Signature Required"
$EmailMessage    = "Please review and sign SOW-AFFG-004 Rev 1 (Fleet Right-Sizing and Compliance Configuration)."

$keysFile     = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$sigPath      = Join-Path $scriptDir "ravi-signature.html"

# --- DocuSign credentials ---
$keysContent = Get-Content $keysFile -Raw
$ClientId  = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId    = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey    = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

# --- M365 credentials ---
$m365Keys     = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()

# --- JWT → DocuSign token ---
$nodeCommand = (Get-Command node,node.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
if (-not $nodeCommand -and (Test-Path "C:\Program Files\nodejs\node.exe")) { $nodeCommand = "C:\Program Files\nodejs\node.exe" }
$tempKeyPath = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKeyPath -NoNewline
$jwtHelperPath = Join-Path $scriptDir "docusign-jwt-helper.js"
$jwt = & $nodeCommand $jwtHelperPath $ClientId $UserId $tempKeyPath 2>&1
Remove-Item $tempKeyPath -ErrorAction SilentlyContinue
$tokenResponse = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST -Body @{
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    assertion  = $jwt
} -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token
$headers     = @{ "Authorization" = "Bearer $accessToken" }
$userInfo    = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers $headers
$baseUri     = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
$apiUrl      = "$baseUri/restapi/v2.1/accounts/$AccountId"
$sendHeaders = @{ "Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" }
Write-Host "DocuSign auth OK. API: $apiUrl" -ForegroundColor Green

# --- STEP 1: Create draft envelope (no tabs) ---
$fileName   = [System.IO.Path]::GetFileName($DocumentPath)
$fileBytes  = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

$draftEnvelope = @{
    emailSubject = $EmailSubject
    emailBlurb   = $EmailMessage
    status       = "created"
    documents    = @(
        @{ documentBase64 = $base64File; name = $fileName; fileExtension = "docx"; documentId = "1" }
    )
    recipients   = @{
        signers = @(
            @{ email = $SignerEmail;    name = $SignerName;    recipientId = "1"; routingOrder = "1"; clientUserId = "tech_signer_1" },
            @{ email = $RecipientEmail; name = $RecipientName; recipientId = "2"; routingOrder = "1"; clientUserId = "client_signer_2" }
        )
    }
} | ConvertTo-Json -Depth 10

$draft = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $sendHeaders -Body $draftEnvelope -TimeoutSec 60
$envelopeId = $draft.envelopeId
Write-Host "Draft envelope: $envelopeId" -ForegroundColor Green

# --- STEP 2: Determine last page ---
$docInfo   = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents" -Method GET -Headers $sendHeaders
$pageCount = if ($docInfo.envelopeDocuments[0].pages -is [array]) { $docInfo.envelopeDocuments[0].pages.Count } else { [int]$docInfo.envelopeDocuments[0].pages }
$lastPage  = $pageCount.ToString()
Write-Host "Document pages: $pageCount (placing tabs on page $lastPage)" -ForegroundColor Green

# --- STEP 3: Add absolute-positioned tabs per recipient ---
# Letter = 612 x 792 pts at 72 DPI. SOW has the signature block on the last page at roughly:
#   TECHNIJIAN, INC. block (upper) at y ~180
#   AMERICAN FUNDSTARS FINANCIAL GROUP LLC block (lower) at y ~360
# These y values land the tabs directly on the By:/Name:/Title:/Date: lines.

$TECH_X = 100
$TECH_Y_SIG   = 210   # overlays "By: _______"
$TECH_Y_NAME  = 240   # overlays "Name: _____"
$TECH_Y_TITLE = 270   # overlays "Title: ______"
$TECH_Y_DATE  = 300   # overlays "Date: ______"

$CLI_X  = 100
$CLI_Y_SIG   = 400
$CLI_Y_NAME  = 430
$CLI_Y_TITLE = 460
$CLI_Y_DATE  = 490

# Technijian (recipient 1)
$techTabs = @{
    signHereTabs = @(
        @{ xPosition = "$TECH_X"; yPosition = "$TECH_Y_SIG"; pageNumber = $lastPage; documentId = "1"; recipientId = "1"; scaleValue = "1" }
    )
    fullNameTabs = @(
        @{ xPosition = "$TECH_X"; yPosition = "$TECH_Y_NAME"; pageNumber = $lastPage; documentId = "1"; recipientId = "1"; tabLabel = "tech_name"; font = "Arial"; fontSize = "Size11" }
    )
    textTabs = @(
        @{ xPosition = "$TECH_X"; yPosition = "$TECH_Y_TITLE"; pageNumber = $lastPage; documentId = "1"; recipientId = "1"; tabLabel = "tech_title"; value = $SignerTitle; locked = "true"; font = "Arial"; fontSize = "Size11"; width = "200"; height = "20" }
    )
    dateSignedTabs = @(
        @{ xPosition = "$TECH_X"; yPosition = "$TECH_Y_DATE"; pageNumber = $lastPage; documentId = "1"; recipientId = "1"; font = "Arial"; fontSize = "Size11" }
    )
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $sendHeaders -Body $techTabs -TimeoutSec 30 | Out-Null
Write-Host "Technijian tabs placed on page $lastPage at ($TECH_X, $TECH_Y_SIG..$TECH_Y_DATE)" -ForegroundColor Green

# Client (recipient 2)
$clientTabs = @{
    signHereTabs = @(
        @{ xPosition = "$CLI_X"; yPosition = "$CLI_Y_SIG"; pageNumber = $lastPage; documentId = "1"; recipientId = "2"; scaleValue = "1" }
    )
    fullNameTabs = @(
        @{ xPosition = "$CLI_X"; yPosition = "$CLI_Y_NAME"; pageNumber = $lastPage; documentId = "1"; recipientId = "2"; tabLabel = "client_name"; font = "Arial"; fontSize = "Size11" }
    )
    textTabs = @(
        @{ xPosition = "$CLI_X"; yPosition = "$CLI_Y_TITLE"; pageNumber = $lastPage; documentId = "1"; recipientId = "2"; tabLabel = "client_title"; required = "true"; font = "Arial"; fontSize = "Size11"; width = "200"; height = "20" }
    )
    dateSignedTabs = @(
        @{ xPosition = "$CLI_X"; yPosition = "$CLI_Y_DATE"; pageNumber = $lastPage; documentId = "1"; recipientId = "2"; font = "Arial"; fontSize = "Size11" }
    )
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $sendHeaders -Body $clientTabs -TimeoutSec 30 | Out-Null
Write-Host "Client tabs placed on page $lastPage at ($CLI_X, $CLI_Y_SIG..$CLI_Y_DATE)" -ForegroundColor Green

# --- STEP 4: Send envelope ---
$sendBody = @{ status = "sent" } | ConvertTo-Json
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $sendHeaders -Body $sendBody -TimeoutSec 60 | Out-Null
Write-Host "Envelope sent: $envelopeId" -ForegroundColor Green

# --- STEP 5: Get embedded signing URLs ---
$clientRedirect = "https://technijian.com"
$techRecipientViewBody = @{
    authenticationMethod = "none"
    clientUserId         = "tech_signer_1"
    email                = $SignerEmail
    userName             = $SignerName
    returnUrl            = $clientRedirect
} | ConvertTo-Json
$techView = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/views/recipient" -Method POST -Headers $sendHeaders -Body $techRecipientViewBody
$techSigningUrl = $techView.url

$clientRecipientViewBody = @{
    authenticationMethod = "none"
    clientUserId         = "client_signer_2"
    email                = $RecipientEmail
    userName             = $RecipientName
    returnUrl            = $clientRedirect
} | ConvertTo-Json
$clientView = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/views/recipient" -Method POST -Headers $sendHeaders -Body $clientRecipientViewBody
$clientSigningUrl = $clientView.url

Write-Host "Signing URLs retrieved." -ForegroundColor Green

# --- STEP 6: Send branded emails via M365 Graph ---
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

$senderUpn = "RJain@technijian.com"
$sig = if (Test-Path $sigPath) { Get-Content $sigPath -Raw } else { "" }
$logoUrl = "https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png"

function Build-SigningEmail {
    param($Recipient, $RecipientLabel, $SigningUrl, $ExtraContext)
    return @"
<html><body style="font-family:Aptos,Calibri,sans-serif;font-size:12pt;color:#1A1A2E">
<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="600" style="max-width:600px;border-collapse:collapse;background:#fff">
<tr><td style="background:#006DB6;padding:18px 24px"><img src="$logoUrl" width="260" alt="Technijian" style="display:block;border:0"></td></tr>
<tr><td style="background:#F67D4B;height:4px;font-size:0;line-height:0">&nbsp;</td></tr>
<tr><td style="padding:28px 24px">
<p style="margin:0 0 14px 0">$RecipientLabel,</p>
<p style="margin:0 0 14px 0">Please review and sign <strong>SOW-AFFG-004 Rev 1 &mdash; Fleet Right-Sizing and Compliance Configuration</strong>. $ExtraContext</p>
<p style="margin:20px 0"><a href="$SigningUrl" style="background:#006DB6;color:#fff;text-decoration:none;padding:14px 28px;display:inline-block;border-radius:4px;font-weight:600">Review &amp; Sign Document</a></p>
<p style="margin:20px 0 14px 0;font-size:10pt;color:#59595B">If the button does not work, paste this link in your browser:<br>$SigningUrl</p>
<p style="margin:20px 0 0 0">Thank you,</p>
</td></tr>
</table>
$sig
</body></html>
"@
}

# Client email
$clientBody = Build-SigningEmail -Recipient $RecipientEmail -RecipientLabel "Iris" -SigningUrl $clientSigningUrl -ExtraContext "This revision reflects the corrections we discussed (BYOD MAM-only, 10 managed endpoints, Azure Entra SSO, CloudBrink ZTNA, IP whitelist architecture)."
$clientMsg = @{
    Message = @{
        Subject = $EmailSubject
        Body = @{ ContentType = "HTML"; Content = $clientBody }
        ToRecipients = @( @{ EmailAddress = @{ Address = $RecipientEmail; Name = $RecipientName } } )
    }
    SaveToSentItems = $true
}
Send-MgUserMail -UserId $senderUpn -BodyParameter $clientMsg

# Technijian email
$techBody = Build-SigningEmail -Recipient $SignerEmail -RecipientLabel "Ravi" -SigningUrl $techSigningUrl -ExtraContext "AFFG SOW-004 Rev 1 for your signature (parallel with Iris)."
$techMsg = @{
    Message = @{
        Subject = $EmailSubject
        Body = @{ ContentType = "HTML"; Content = $techBody }
        ToRecipients = @( @{ EmailAddress = @{ Address = $SignerEmail; Name = $SignerName } } )
    }
    SaveToSentItems = $true
}
Send-MgUserMail -UserId $senderUpn -BodyParameter $techMsg

Disconnect-MgGraph | Out-Null

Write-Host ""
Write-Host "=========================================="-ForegroundColor Yellow
Write-Host " DocuSign envelope sent (absolute positioning)" -ForegroundColor Yellow
Write-Host "=========================================="-ForegroundColor Yellow
Write-Host "Envelope ID : $envelopeId"
Write-Host "Pages       : $pageCount (tabs on page $lastPage)"
Write-Host "Signers     : Parallel (Ravi + Iris, both routingOrder=1)"
Write-Host "Branded mail: Sent via M365 Graph to both parties"
Write-Host "Ravi URL    : $techSigningUrl"
