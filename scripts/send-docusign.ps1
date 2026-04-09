# DocuSign eSign - Send Document with Technijian-Branded Email
# Uses JWT Grant authentication via Node.js helper for RSA signing
# Suppresses DocuSign's built-in emails, sends branded emails via Microsoft Graph with embedded signing URLs
#
# Usage: .\send-docusign.ps1 -DocumentPath "path\to\doc.docx" -RecipientName "John Doe" -RecipientEmail "john@example.com"
#
# Flow: Create envelope with clientUserId (suppresses DocuSign email) -> Add tabs via anchors -> Send envelope
#       -> Get signing URLs via recipient view API -> Send branded emails via Microsoft Graph

param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentPath,

    [Parameter(Mandatory=$true)]
    [string]$RecipientName,

    [Parameter(Mandatory=$true)]
    [string]$RecipientEmail,

    [string]$ClientCompanyName = "",

    [string]$SignerName = "Ravi Jain",
    [string]$SignerEmail = "rjain@technijian.com",
    [string]$SignerTitle = "CEO",

    [string]$EmailSubject = "",
    [string]$EmailMessage = "",

    [switch]$DryRun
)

# --- Configuration ---
$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logoUrl = "https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png"
$returnUrl = "https://technijian.com"

# --- Read DocuSign credentials ---
Write-Host "Reading DocuSign credentials..." -ForegroundColor Cyan
$keysContent = Get-Content $keysFile -Raw
$ClientId = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

if (-not $ClientId -or -not $UserId -or -not $AccountId -or -not $rsaKey) {
    Write-Error "Failed to read DocuSign credentials from $keysFile"
    exit 1
}
Write-Host "DocuSign credentials loaded." -ForegroundColor Green

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
$folderName = [System.IO.Path]::GetFileNameWithoutExtension($DocumentPath)

# --- Set defaults ---
if (-not $EmailSubject) {
    $EmailSubject = "Technijian - $folderName - Signature Required"
}
if (-not $EmailMessage) {
    $EmailMessage = "Please review and sign the attached document from Technijian, Inc."
}

# --- Split names ---
$nameParts = $RecipientName.Trim() -split '\s+', 2
$recipientFirst = $nameParts[0]
$recipientLast = if ($nameParts.Length -gt 1) { $nameParts[1] } else { "" }

$signerParts = $SignerName.Trim() -split '\s+', 2
$signerFirst = $signerParts[0]
$signerLast = if ($signerParts.Length -gt 1) { $signerParts[1] } else { "" }

# ============================================================
# STEP 1: DocuSign JWT Authentication
# ============================================================
Write-Host "`nGenerating JWT token..." -ForegroundColor Cyan

$jwtHelperPath = Join-Path $scriptDir "docusign-jwt-helper.js"

# Write RSA key to temp file for Node
$tempKeyPath = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKeyPath -NoNewline

$jwt = & node $jwtHelperPath $ClientId $UserId $tempKeyPath 2>&1
Remove-Item $tempKeyPath -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Error "JWT generation failed: $jwt"
    exit 1
}

Write-Host "Authenticating with DocuSign..." -ForegroundColor Cyan
$OAuthUrl = "https://account.docusign.com/oauth/token"

try {
    $tokenResponse = Invoke-RestMethod -Uri $OAuthUrl -Method POST -Body @{
        grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        assertion  = $jwt
    } -ContentType "application/x-www-form-urlencoded"
    $accessToken = $tokenResponse.access_token
    Write-Host "DocuSign authentication successful." -ForegroundColor Green
}
catch {
    Write-Error "DocuSign authentication failed: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

# --- Get base URI from userinfo ---
$headers = @{ "Authorization" = "Bearer $accessToken" }
$userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers $headers
$baseUri = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
if (-not $baseUri) { $baseUri = "https://na1.docusign.net" }
$apiUrl = "$baseUri/restapi/v2.1/accounts/$AccountId"
Write-Host "API Base: $apiUrl" -ForegroundColor Cyan

# ============================================================
# STEP 2: Create envelope with clientUserId (suppresses DocuSign email)
# ============================================================
Write-Host "`nReading document: $fileName" -ForegroundColor Cyan
$fileBytes = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

Write-Host "Creating draft envelope with embedded (clientUserId) signers..." -ForegroundColor Cyan

# clientUserId makes signers "embedded" — DocuSign will NOT send its own email
$draftEnvelope = @{
    emailSubject = $EmailSubject
    emailBlurb   = $EmailMessage
    status       = "created"
    documents    = @(
        @{
            documentBase64 = $base64File
            name           = $fileName
            fileExtension  = [System.IO.Path]::GetExtension($DocumentPath).TrimStart('.')
            documentId     = "1"
        }
    )
    recipients   = @{
        signers = @(
            @{
                email        = $SignerEmail
                name         = $SignerName
                recipientId  = "1"
                routingOrder = "1"
                clientUserId = "tech_signer_1"
            },
            @{
                email        = $RecipientEmail
                name         = $RecipientName
                recipientId  = "2"
                routingOrder = "1"
                clientUserId = "client_signer_2"
            }
        )
    }
} | ConvertTo-Json -Depth 10

$sendHeaders = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

$draftResponse = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $sendHeaders -Body $draftEnvelope -TimeoutSec 60
$envelopeId = $draftResponse.envelopeId
Write-Host "Draft envelope created: $envelopeId" -ForegroundColor Green

# Get page count from the document
$docInfo = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents" -Method GET -Headers $sendHeaders
$pagesArray = $docInfo.envelopeDocuments[0].pages
if ($pagesArray -is [array]) {
    $pageCount = $pagesArray.Count
} else {
    $pageCount = [int]$pagesArray
}
Write-Host "Document has $pageCount pages." -ForegroundColor Green

# ============================================================
# STEP 3: Add tabs using hidden anchor tags
# ============================================================
Write-Host "Placing signature fields using embedded anchor tags..." -ForegroundColor Cyan

# Technijian signer tabs (recipientId 1)
$techTabsJson = @{
    signHereTabs = @(
        @{ anchorString = "/tSign/"; anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1"; recipientId = "1" }
    )
    fullNameTabs = @(
        @{ anchorString = "/tName/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1"; tabLabel = "tech_name" }
    )
    textTabs = @(
        @{ anchorString = "/tTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1"; tabLabel = "tech_title"; value = $SignerTitle; locked = "true" }
    )
    dateSignedTabs = @(
        @{ anchorString = "/tDate/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1" }
    )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $sendHeaders -Body $techTabsJson -TimeoutSec 30 | Out-Null
Write-Host "  Technijian tabs placed (anchored to /tSign/, /tName/, /tTitle/, /tDate/)." -ForegroundColor Green

# Client signer tabs (recipientId 2)
$clientTabsJson = @{
    signHereTabs = @(
        @{ anchorString = "/cSign/"; anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1"; recipientId = "2" }
    )
    fullNameTabs = @(
        @{ anchorString = "/cName/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2"; tabLabel = "client_name" }
    )
    textTabs = @(
        @{ anchorString = "/cTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2"; tabLabel = "client_title"; required = "true" }
    )
    dateSignedTabs = @(
        @{ anchorString = "/cDate/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2" }
    )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $sendHeaders -Body $clientTabsJson -TimeoutSec 30 | Out-Null
Write-Host "  Client tabs placed (anchored to /cSign/, /cName/, /cTitle/, /cDate/)." -ForegroundColor Green

# ============================================================
# STEP 4: Send the envelope
# ============================================================
Write-Host "`nSending envelope..." -ForegroundColor Cyan

$sendBody = @{ status = "sent" } | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $sendHeaders -Body $sendBody -TimeoutSec 60 | Out-Null
    Write-Host "Envelope sent successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to send envelope: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error "API Response: $($_.ErrorDetails.Message)" }
    exit 1
}

# ============================================================
# STEP 5: Get signing URLs for both signers via recipient view API
# ============================================================
Write-Host "`nRetrieving signing URLs..." -ForegroundColor Cyan

# Technijian signer signing URL
$techViewBody = @{
    returnUrl            = $returnUrl
    authenticationMethod = "email"
    email                = $SignerEmail
    userName             = $SignerName
    clientUserId         = "tech_signer_1"
} | ConvertTo-Json

try {
    $techViewResponse = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/views/recipient" -Method POST -Headers $sendHeaders -Body $techViewBody -TimeoutSec 30
    $techSignUrl = $techViewResponse.url
    Write-Host "  Technijian signing URL: $techSignUrl" -ForegroundColor White
}
catch {
    Write-Error "Failed to get Technijian signing URL: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

# Client signer signing URL
$clientViewBody = @{
    returnUrl            = $returnUrl
    authenticationMethod = "email"
    email                = $RecipientEmail
    userName             = $RecipientName
    clientUserId         = "client_signer_2"
} | ConvertTo-Json

try {
    $clientViewResponse = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/views/recipient" -Method POST -Headers $sendHeaders -Body $clientViewBody -TimeoutSec 30
    $clientSignUrl = $clientViewResponse.url
    Write-Host "  Client signing URL:     $clientSignUrl" -ForegroundColor White
}
catch {
    Write-Error "Failed to get Client signing URL: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

# ============================================================
# DRY RUN: Stop here if -DryRun flag is set
# ============================================================
if ($DryRun) {
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " DRY RUN - ENVELOPE CREATED & SENT" -ForegroundColor Yellow
    Write-Host " (Branded emails NOT sent)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Envelope ID:      $envelopeId" -ForegroundColor White
    Write-Host "Document:         $fileName" -ForegroundColor White
    Write-Host "Page Count:       $pageCount" -ForegroundColor White
    Write-Host "Technijian:       $SignerName <$SignerEmail>" -ForegroundColor White
    Write-Host "  Signing URL:    $techSignUrl" -ForegroundColor White
    Write-Host "Client:           $RecipientName <$RecipientEmail>" -ForegroundColor White
    Write-Host "  Signing URL:    $clientSignUrl" -ForegroundColor White
    Write-Host "ClientUserId:     tech_signer_1 / client_signer_2" -ForegroundColor White
    Write-Host "DocuSign email:   SUPPRESSED (embedded signers)" -ForegroundColor White
    Write-Host "Branded email:    SKIPPED (dry run)" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Yellow

    @{
        success    = $true
        dryRun     = $true
        envelopeId = $envelopeId
        status     = "sent"
        document   = $fileName
        pageCount  = $pageCount
        signers    = @(
            @{ name = $SignerName; email = $SignerEmail; role = "Technijian"; signingUrl = $techSignUrl; clientUserId = "tech_signer_1" },
            @{ name = $RecipientName; email = $RecipientEmail; role = "Client"; signingUrl = $clientSignUrl; clientUserId = "client_signer_2" }
        )
    } | ConvertTo-Json -Depth 5
    exit 0
}

# ============================================================
# STEP 6: Authenticate with Microsoft Graph
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
# STEP 7: Build branded HTML email templates
# ============================================================

function Build-SigningEmail {
    param(
        [string]$RecipName,
        [string]$SigningUrl,
        [string]$DocName,
        [string]$SenderName,
        [bool]$IncludeSignature = $false
    )

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

$signatureBlock

</td></tr>
</table>
</body>
</html>
"@
}

# ============================================================
# STEP 8: Send branded emails via Microsoft Graph
# ============================================================
Write-Host "`nSending branded signing emails via Microsoft Graph..." -ForegroundColor Cyan

# --- Send to Client (with Ravi's full email signature) ---
$clientHtml = Build-SigningEmail -RecipName $recipientFirst -SigningUrl $clientSignUrl -DocName $folderName -SenderName $SignerName -IncludeSignature $true

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
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" `
        -Method POST -Headers $graphHeaders -Body $clientMailBody
    Write-Host "Branded email sent to Client: $RecipientName <$RecipientEmail>" -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email to client: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
}

# --- Send to Technijian signer (NO personal signature) ---
$techHtml = Build-SigningEmail -RecipName $signerFirst -SigningUrl $techSignUrl -DocName $folderName -SenderName "Technijian eSign" -IncludeSignature $false

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
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" `
        -Method POST -Headers $graphHeaders -Body $techMailBody
    Write-Host "Branded email sent to Technijian: $SignerName <$SignerEmail>" -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email to Technijian signer: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
}

# ============================================================
# STEP 9: Report results
# ============================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " BRANDED DOCUSIGN SIGNING EMAILS SENT" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Envelope ID:      $envelopeId" -ForegroundColor White
Write-Host "Document:         $fileName" -ForegroundColor White
Write-Host "Page Count:       $pageCount" -ForegroundColor White
Write-Host "Client:           $RecipientName <$RecipientEmail>" -ForegroundColor White
Write-Host "Technijian:       $SignerName <$SignerEmail>" -ForegroundColor White
Write-Host "Signing Order:    Parallel (both routingOrder=1)" -ForegroundColor White
Write-Host "DocuSign Email:   SUPPRESSED (embedded signers)" -ForegroundColor White
Write-Host "Branded Email:    Sent via Microsoft Graph" -ForegroundColor White
Write-Host "Email From:       Ravi Jain - Technijian <RJain@technijian.com>" -ForegroundColor White
Write-Host "Client Signature: Includes Ravi's full email signature" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Green

$result = @{
    success         = $true
    envelopeId      = $envelopeId
    status          = "sent"
    document        = $fileName
    pageCount       = $pageCount
    brandedEmail    = $true
    docusignEmail   = "suppressed"
    signers         = @(
        @{ name = $SignerName; email = $SignerEmail; role = "Technijian"; clientUserId = "tech_signer_1"; signingUrl = $techSignUrl },
        @{ name = $RecipientName; email = $RecipientEmail; role = "Client"; clientUserId = "client_signer_2"; signingUrl = $clientSignUrl }
    )
}
$result | ConvertTo-Json -Depth 5
