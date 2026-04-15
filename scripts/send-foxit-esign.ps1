# Foxit eSign - Send Document for Signature with Technijian-Branded Email
# Usage: .\send-foxit-esign.ps1 -DocumentPath "path\to\doc.docx" -RecipientName "John Doe" -RecipientEmail "john@example.com"
#
# Flow: Create envelope (no Foxit email) -> Get signing URLs -> Send branded emails via Microsoft Graph

param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentPath,

    [Parameter(Mandatory=$true)]
    [string]$RecipientName,

    [Parameter(Mandatory=$true)]
    [string]$RecipientEmail,

    [string]$SignerName = "Ravi Jain",
    [string]$SignerEmail = "rjain@technijian.com",
    [string]$SignerTitle = "CEO",

    [string]$FolderName = "",
    [string]$EmailSubject = "",
    [string]$EmailMessage = ""
)

# --- Configuration ---
$foxitKeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md"
$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$baseUrl = "https://na1.foxitesign.foxit.com/api"
$logoUrl = "https://technijian.com/wp-content/uploads/2023/08/Logo.jpg"

# --- Read Foxit eSign credentials ---
Write-Host "Reading Foxit eSign credentials..." -ForegroundColor Cyan
$foxitKeys = Get-Content $foxitKeysFile -Raw
$clientId = [regex]::Match($foxitKeys, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $clientId) { $clientId = [regex]::Match($foxitKeys, 'Client ID\s*=\s*(\S+)').Groups[1].Value }
$clientSecret = [regex]::Match($foxitKeys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $clientSecret) { $clientSecret = [regex]::Match($foxitKeys, 'Client Secret\s*=\s*(\S+)').Groups[1].Value }

if (-not $clientId -or -not $clientSecret) {
    Write-Error "Failed to read Foxit eSign credentials from $foxitKeysFile"
    exit 1
}
Write-Host "Foxit credentials loaded." -ForegroundColor Green

# --- Read M365 Graph credentials ---
Write-Host "Reading Microsoft Graph credentials..." -ForegroundColor Cyan
$m365Keys = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId) { $m365ClientId = [regex]::Match($m365Keys, 'App Client ID = (\S+)').Groups[1].Value }
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365TenantId) { $m365TenantId = [regex]::Match($m365Keys, 'Tenant ID = (\S+)').Groups[1].Value }
$m365Secret = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365Secret) { $m365Secret = [regex]::Match($m365Keys, '(?<=Tenant ID[^\n]+\n)Client Secret = (.+)').Groups[1].Value.Trim() }

if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to read M365 Graph credentials from $m365KeysFile"
    exit 1
}
Write-Host "M365 credentials loaded." -ForegroundColor Green

# --- Validate document ---
if (-not (Test-Path $DocumentPath)) {
    Write-Error "Document not found: $DocumentPath"
    exit 1
}

$fileName = [System.IO.Path]::GetFileName($DocumentPath)
$fileExtension = [System.IO.Path]::GetExtension($DocumentPath).ToLower()

if ($fileExtension -notin @('.pdf', '.docx', '.doc')) {
    Write-Error "Unsupported file type: $fileExtension. Use .pdf, .docx, or .doc"
    exit 1
}

# --- Set defaults ---
if (-not $FolderName) {
    $FolderName = [System.IO.Path]::GetFileNameWithoutExtension($DocumentPath)
}
if (-not $EmailSubject) {
    $EmailSubject = "Technijian - $FolderName - Signature Required"
}

# --- Split names ---
$nameParts = $RecipientName.Trim() -split '\s+', 2
$recipientFirst = $nameParts[0]
$recipientLast = if ($nameParts.Length -gt 1) { $nameParts[1] } else { "" }

$signerParts = $SignerName.Trim() -split '\s+', 2
$signerFirst = $signerParts[0]
$signerLast = if ($signerParts.Length -gt 1) { $signerParts[1] } else { "" }

# ============================================================
# STEP 1: Create Foxit eSign envelope (NO email from Foxit)
# ============================================================
Write-Host "`nAuthenticating with Foxit eSign..." -ForegroundColor Cyan
$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "read-write"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/oauth2/access_token" -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "Foxit authentication successful." -ForegroundColor Green
}
catch {
    Write-Error "Foxit authentication failed: $($_.Exception.Message)"
    exit 1
}

$foxitHeaders = @{ "Authorization" = "Bearer $accessToken" }

Write-Host "Reading document: $fileName" -ForegroundColor Cyan
$fileBytes = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

Write-Host "Creating Foxit eSign envelope..." -ForegroundColor Cyan

$envelopeData = @{
    folderName          = $FolderName
    inputType           = "base64"
    base64FileString    = @($base64File)
    fileNames           = @($fileName)
    sendNow             = $true
    createEmbeddedSigningSession = $true
    createEmbeddedSigningSessionForAllParties = $true
    signInSequence      = $false
    inPersonEnable      = $false
    parties             = @(
        @{
            firstName         = $recipientFirst
            lastName          = $recipientLast
            emailId           = $RecipientEmail
            permission        = "FILL_FIELDS_AND_SIGN"
            sequence          = 1
            workflowSequence  = 1
        },
        @{
            firstName         = $signerFirst
            lastName          = $signerLast
            emailId           = $SignerEmail
            permission        = "FILL_FIELDS_AND_SIGN"
            sequence          = 2
            workflowSequence  = 2
        }
    )
    fields              = @(
        # Client: Signature
        @{
            type           = "signature"
            x              = 72
            y              = 50
            width          = 200
            height         = 30
            pageNumber     = -1
            documentNumber = 1
            party          = 1
            required       = $true
        },
        # Client: Name
        @{
            type           = "textfield"
            x              = 72
            y              = 85
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 1
            name           = "client_name"
            required       = $true
        },
        # Client: Title
        @{
            type           = "textfield"
            x              = 72
            y              = 110
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 1
            name           = "client_title"
            required       = $true
        },
        # Client: Date
        @{
            type           = "datefield"
            x              = 72
            y              = 135
            width          = 120
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 1
            name           = "client_date"
            required       = $true
        },
        # Technijian: Signature
        @{
            type           = "signature"
            x              = 350
            y              = 50
            width          = 200
            height         = 30
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            required       = $true
        },
        # Technijian: Name (prefilled)
        @{
            type           = "textfield"
            x              = 350
            y              = 85
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            name           = "tech_name"
            value          = $SignerName
            required       = $true
        },
        # Technijian: Title (prefilled)
        @{
            type           = "textfield"
            x              = 350
            y              = 110
            width          = 200
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            name           = "tech_title"
            value          = $SignerTitle
            required       = $true
        },
        # Technijian: Date
        @{
            type           = "datefield"
            x              = 350
            y              = 135
            width          = 120
            height         = 20
            pageNumber     = -1
            documentNumber = 1
            party          = 2
            name           = "tech_date"
            required       = $true
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/folders/createfolder" `
        -Method POST `
        -Headers $foxitHeaders `
        -Body $envelopeData `
        -ContentType "application/json"

    Write-Host "Envelope created successfully." -ForegroundColor Green
    Write-Host "Folder ID: $($response.folderId)" -ForegroundColor White
}
catch {
    Write-Error "Failed to create envelope: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error "API Response: $($_.ErrorDetails.Message)" }
    exit 1
}

# ============================================================
# STEP 2: Extract signing URLs
# ============================================================
Write-Host "`nExtracting signing URLs..." -ForegroundColor Cyan

$clientSignUrl = $null
$techSignUrl = $null

# Try folderAccessURL from parties
if ($response.folder -and $response.folder.folderRecipientParties) {
    foreach ($party in $response.folder.folderRecipientParties) {
        if ($party.partyDetails.emailId -eq $RecipientEmail -and $party.folderAccessURL) {
            $clientSignUrl = $party.folderAccessURL
        }
        elseif ($party.partyDetails.emailId -eq $SignerEmail -and $party.folderAccessURL) {
            $techSignUrl = $party.folderAccessURL
        }
    }
}

# Fallback: try embeddedSigningSessions
if (-not $clientSignUrl -and $response.embeddedSigningSessions) {
    foreach ($session in $response.embeddedSigningSessions) {
        if ($session.emailIdOfSigner -eq $RecipientEmail) {
            $clientSignUrl = $session.embeddedSessionURL
        }
        elseif ($session.emailIdOfSigner -eq $SignerEmail) {
            $techSignUrl = $session.embeddedSessionURL
        }
    }
}

if (-not $clientSignUrl -or -not $techSignUrl) {
    Write-Host "DEBUG: Full response:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 10 | Write-Host
    Write-Error "Could not extract signing URLs from Foxit response."
    exit 1
}

Write-Host "Client signing URL:     $clientSignUrl" -ForegroundColor White
Write-Host "Technijian signing URL: $techSignUrl" -ForegroundColor White

# ============================================================
# STEP 3: Get Microsoft Graph access token
# ============================================================
Write-Host "`nAuthenticating with Microsoft Graph..." -ForegroundColor Cyan

$graphTokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $m365ClientId
    client_secret = $m365Secret
    scope         = "https://graph.microsoft.com/.default"
}

try {
    $graphTokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token" `
        -Method POST -Body $graphTokenBody -ContentType "application/x-www-form-urlencoded"
    $graphToken = $graphTokenResponse.access_token
    Write-Host "Graph authentication successful." -ForegroundColor Green
}
catch {
    Write-Error "Graph authentication failed: $($_.Exception.Message)"
    exit 1
}

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "Content-Type"  = "application/json"
}

# ============================================================
# STEP 4: Build branded HTML email template
# ============================================================

function Build-SigningEmail {
    param(
        [string]$RecipName,
        [string]$SigningUrl,
        [string]$DocName,
        [string]$SenderName
    )

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
        $SenderName has sent you a document to review and sign.
      </p>
    </td>
  </tr>

  <!-- Body -->
  <tr>
    <td style="padding:32px;">
      <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">
        Hi $RecipName,
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
                  <p style="margin:0 0 4px;font-size:14px;font-weight:600;color:#1A1A2E;">$DocName</p>
                  <p style="margin:0;font-size:13px;color:#59595B;">Sent by $SenderName, $($SignerTitle) &bull; Technijian, Inc.</p>
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
        If you have any questions about this document, please contact <a href="mailto:$SignerEmail" style="color:#006DB6;text-decoration:none;">$SenderName</a> at <a href="mailto:$SignerEmail" style="color:#006DB6;text-decoration:none;">$SignerEmail</a> or call <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">949.379.8499</a>.
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
}

# ============================================================
# STEP 5: Send branded emails via Microsoft Graph
# ============================================================
Write-Host "`nSending branded signing emails via Microsoft Graph..." -ForegroundColor Cyan

# --- Send to Client ---
$clientHtml = Build-SigningEmail -RecipName $recipientFirst -SigningUrl $clientSignUrl -DocName $FolderName -SenderName $SignerName

$clientMailBody = @{
    Message = @{
        Subject = $EmailSubject
        Body = @{
            ContentType = "HTML"
            Content = $clientHtml
        }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = $RecipientEmail; Name = $RecipientName } }
        )
        From = @{ EmailAddress = @{ Address = $SignerEmail; Name = "Ravi Jain - Technijian" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$SignerEmail/sendMail" `
        -Method POST -Headers $graphHeaders -Body $clientMailBody
    Write-Host "Branded email sent to Client: $RecipientName <$RecipientEmail>" -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email to client: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
}

# --- Send to Technijian signer ---
$techHtml = Build-SigningEmail -RecipName $signerFirst -SigningUrl $techSignUrl -DocName $FolderName -SenderName "Technijian eSign"

$techMailBody = @{
    Message = @{
        Subject = $EmailSubject
        Body = @{
            ContentType = "HTML"
            Content = $techHtml
        }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = $SignerEmail; Name = $SignerName } }
        )
        From = @{ EmailAddress = @{ Address = $SignerEmail; Name = "Technijian eSign" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$SignerEmail/sendMail" `
        -Method POST -Headers $graphHeaders -Body $techMailBody
    Write-Host "Branded email sent to Technijian: $SignerName <$SignerEmail>" -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email to Technijian signer: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
}

# ============================================================
# STEP 6: Report results
# ============================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " BRANDED SIGNING EMAILS SENT" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Folder ID:    $($response.folderId)" -ForegroundColor White
Write-Host "Folder Name:  $FolderName" -ForegroundColor White
Write-Host "Document:     $fileName" -ForegroundColor White
Write-Host "Client:       $RecipientName <$RecipientEmail>" -ForegroundColor White
Write-Host "Technijian:   $SignerName <$SignerEmail>" -ForegroundColor White
Write-Host "Email From:   Ravi Jain - Technijian <$SignerEmail>" -ForegroundColor White
Write-Host "Status:       Branded emails sent via Microsoft Graph" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Green

$result = @{
    success         = $true
    folderId        = $response.folderId
    folderName      = $FolderName
    document        = $fileName
    brandedEmail    = $true
    signers         = @(
        @{ name = $RecipientName; email = $RecipientEmail; role = "Client"; signingUrl = $clientSignUrl },
        @{ name = $SignerName; email = $SignerEmail; role = "Technijian"; signingUrl = $techSignUrl }
    )
}
$result | ConvertTo-Json -Depth 5
