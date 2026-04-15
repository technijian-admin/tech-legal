# Send AAVA MSA Package via DocuSign (Parallel Signing) with Branded Email Delivery
# ---------------------------------------------------------------------------------
# Envelope contains 4 documents:
#   1. MSA-AAVA.docx        (documentId = 1) — signature tabs here (LAST page, absolute x/y)
#   2. Schedule-A-AAVA.docx (documentId = 2) — NO tabs (governed by signed MSA per Section 1.01)
#   3. Schedule-B-AAVA.docx (documentId = 3) — NO tabs
#   4. Schedule-C-AAVA.docx (documentId = 4) — NO tabs
#
# Signers (PARALLEL — both routingOrder = 1, embedded via clientUserId):
#   - Ravi Jain <rjain@technijian.com>            (Technijian, CEO,  recipientId=1, clientUserId=tech_signer_1)
#   - Melissa Aventine <melissa@aventine-apartments.com> (Client, recipientId=2, clientUserId=client_signer_2)
#
# Flow: draft envelope (status=created) -> query MSA page count -> POST tabs (absolute coords,
#       last page of doc 1) -> PUT status=sent -> get signing URLs -> send branded emails via
#       Microsoft Graph (DocuSign's own emails are suppressed because signers are embedded).
#
# Usage:
#   .\send-aava-msa.ps1                 # full send (envelope + branded emails)
#   .\send-aava-msa.ps1 -DryRun         # create + send envelope, return URLs, SKIP branded email

param(
    [switch]$DryRun,
    [bool]$SendEmail = $true
)

if ($DryRun) { $SendEmail = $false }

# ============================================================
# CONFIGURATION
# ============================================================
$keysFile     = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$logoUrl      = "https://technijian.com/wp-content/uploads/2026/03/technijian-logo-full-color-600x125-1.png"
$returnUrl    = "https://technijian.com"

$clientRoot   = "C:\vscode\tech-legal\tech-legal\clients\AAVA"
$msaPath      = Join-Path $clientRoot "MSA-AAVA.docx"
$schedAPath   = Join-Path $clientRoot "Schedule-A-AAVA.docx"
$schedBPath   = Join-Path $clientRoot "Schedule-B-AAVA.docx"
$schedCPath   = Join-Path $clientRoot "Schedule-C-AAVA.docx"

# Signer identities
$SignerName   = "Ravi Jain"
$SignerEmail  = "rjain@technijian.com"
$SignerTitle  = "CEO"

$ClientSignerName  = "Melissa Aventine"
$ClientSignerEmail = "melissa@aventine-apartments.com"

# Email content
$EmailSubject = "Technijian MSA Renewal - Aventine at Aliso Viejo Apartments - Ready to Sign"

# DocuSign account (per instructions)
$AccountIdOverride = "fe3baf59-68ed-48a9-9ed7-5185f111c2a4"

# Absolute signature placement (LAST page of MSA)
# Left column (Technijian) x=72, Right column (Client) x=320
$TechX   = "72"
$ClientX = "320"
$YSign   = "420"
$YName   = "470"
$YTitle  = "500"
$YDate   = "530"

# ============================================================
# VALIDATION - verify all 4 documents exist
# ============================================================
$requiredDocs = @(
    @{ Id = "1"; Path = $msaPath;    Label = "MSA" },
    @{ Id = "2"; Path = $schedAPath; Label = "Schedule A" },
    @{ Id = "3"; Path = $schedBPath; Label = "Schedule B" },
    @{ Id = "4"; Path = $schedCPath; Label = "Schedule C" }
)

$missing = @()
foreach ($doc in $requiredDocs) {
    if (-not (Test-Path $doc.Path)) {
        $missing += $doc.Path
    }
}
if ($missing.Count -gt 0) {
    Write-Error "Missing required document(s):"
    foreach ($m in $missing) { Write-Error "  $m" }
    exit 1
}
Write-Host "All 4 AAVA documents verified." -ForegroundColor Green

# ============================================================
# READ DOCUSIGN CREDENTIALS
# ============================================================
Write-Host "Reading DocuSign credentials..." -ForegroundColor Cyan
if (-not (Test-Path $keysFile)) {
    Write-Error "DocuSign keys file not found: $keysFile"
    exit 1
}
$keysContent = Get-Content $keysFile -Raw
$ClientId  = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId    = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
if (-not $AccountId) { $AccountId = $AccountIdOverride }
$rsaKey    = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

if (-not $ClientId -or -not $UserId -or -not $AccountId -or -not $rsaKey) {
    Write-Error "Failed to parse DocuSign credentials from $keysFile"
    exit 1
}
Write-Host "DocuSign credentials loaded." -ForegroundColor Green

# ============================================================
# READ M365 GRAPH CREDENTIALS
# ============================================================
Write-Host "Reading Microsoft Graph credentials..." -ForegroundColor Cyan
if (-not (Test-Path $m365KeysFile)) {
    Write-Error "M365 keys file not found: $m365KeysFile"
    exit 1
}
$m365Keys     = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365ClientId) { $m365ClientId = [regex]::Match($m365Keys, 'App Client ID = (\S+)').Groups[1].Value }
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $m365TenantId) { $m365TenantId = [regex]::Match($m365Keys, 'Tenant ID = (\S+)').Groups[1].Value }
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
if (-not $m365Secret) { $m365Secret = [regex]::Match($m365Keys, '(?<=Tenant ID[^\n]+\n)Client Secret = (.+)').Groups[1].Value.Trim() }

if (-not $m365ClientId -or -not $m365TenantId -or -not $m365Secret) {
    Write-Error "Failed to parse M365 Graph credentials from $m365KeysFile"
    exit 1
}
Write-Host "M365 credentials loaded." -ForegroundColor Green

# ============================================================
# STEP 1: DocuSign JWT Authentication
# ============================================================
Write-Host "`nGenerating JWT token..." -ForegroundColor Cyan

$jwtHelperPath = Join-Path $scriptDir "docusign-jwt-helper.js"
$nodeCommand = (Get-Command node,node.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
if (-not $nodeCommand -and (Test-Path "C:\Program Files\nodejs\node.exe")) {
    $nodeCommand = "C:\Program Files\nodejs\node.exe"
}
if (-not (Test-Path $jwtHelperPath)) {
    Write-Error "JWT helper not found: $jwtHelperPath"
    exit 1
}

$tempKeyPath = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKeyPath -NoNewline

if (-not $nodeCommand) {
    Write-Error "Node.js was not found. Install Node.js or add node.exe to PATH."
    exit 1
}

$jwt = & $nodeCommand $jwtHelperPath $ClientId $UserId $tempKeyPath 2>&1
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
$headers  = @{ "Authorization" = "Bearer $accessToken" }
$userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers $headers
$baseUri  = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
if (-not $baseUri) { $baseUri = "https://na1.docusign.net" }
$apiUrl   = "$baseUri/restapi/v2.1/accounts/$AccountId"
Write-Host "API Base: $apiUrl" -ForegroundColor Cyan

# ============================================================
# STEP 2: Build documents array (base64) and create draft envelope
# ============================================================
Write-Host "`nEncoding documents..." -ForegroundColor Cyan

function Convert-DocToBase64Record {
    param([string]$Path, [string]$DocumentId)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $b64   = [Convert]::ToBase64String($bytes)
    $name  = [System.IO.Path]::GetFileName($Path)
    $ext   = [System.IO.Path]::GetExtension($Path).TrimStart('.')
    return @{
        documentBase64 = $b64
        name           = $name
        fileExtension  = $ext
        documentId     = $DocumentId
    }
}

$docsPayload = @(
    Convert-DocToBase64Record -Path $msaPath    -DocumentId "1",
    Convert-DocToBase64Record -Path $schedAPath -DocumentId "2",
    Convert-DocToBase64Record -Path $schedBPath -DocumentId "3",
    Convert-DocToBase64Record -Path $schedCPath -DocumentId "4"
)
# Note: commas between Convert-DocToBase64Record calls above accidentally chain; build array correctly:
$docsPayload = @()
$docsPayload += (Convert-DocToBase64Record -Path $msaPath    -DocumentId "1")
$docsPayload += (Convert-DocToBase64Record -Path $schedAPath -DocumentId "2")
$docsPayload += (Convert-DocToBase64Record -Path $schedBPath -DocumentId "3")
$docsPayload += (Convert-DocToBase64Record -Path $schedCPath -DocumentId "4")

Write-Host "Creating draft envelope with 4 documents and 2 embedded signers (parallel)..." -ForegroundColor Cyan

$draftEnvelope = @{
    emailSubject = $EmailSubject
    emailBlurb   = "Please review and sign the AAVA Master Service Agreement renewal package."
    status       = "created"
    documents    = $docsPayload
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
                email        = $ClientSignerEmail
                name         = $ClientSignerName
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

try {
    $draftResponse = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $sendHeaders -Body $draftEnvelope -TimeoutSec 120
    $envelopeId = $draftResponse.envelopeId
    Write-Host "Draft envelope created: $envelopeId" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create draft envelope: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error "API Response: $($_.ErrorDetails.Message)" }
    exit 1
}

# ============================================================
# STEP 3: Query MSA page count (document 1)
# ============================================================
Write-Host "`nQuerying MSA page count..." -ForegroundColor Cyan

try {
    $docInfo = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents" -Method GET -Headers $sendHeaders -TimeoutSec 30
}
catch {
    Write-Error "Failed to query envelope documents: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

# Find MSA (documentId = 1) entry
$msaEntry = $docInfo.envelopeDocuments | Where-Object { $_.documentId -eq "1" } | Select-Object -First 1
if (-not $msaEntry) {
    Write-Error "Could not locate MSA (documentId=1) in envelope documents response."
    exit 1
}

# Try nested pages array first; fall back to /pages endpoint
$msaPageCount = $null
if ($msaEntry.pages) {
    if ($msaEntry.pages -is [array]) {
        $msaPageCount = $msaEntry.pages.Count
    } else {
        $msaPageCount = [int]$msaEntry.pages
    }
}
if (-not $msaPageCount -or $msaPageCount -lt 1) {
    try {
        $pagesResp = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents/1/pages" -Method GET -Headers $sendHeaders -TimeoutSec 30
        if ($pagesResp.pages) {
            $msaPageCount = @($pagesResp.pages).Count
        }
    }
    catch {
        Write-Warning "Could not fetch MSA pages via /pages endpoint: $($_.Exception.Message)"
    }
}
if (-not $msaPageCount -or $msaPageCount -lt 1) {
    Write-Error "Unable to determine MSA page count."
    exit 1
}
$lastPage = [string]$msaPageCount
Write-Host "MSA page count: $msaPageCount (signature tabs will go on page $lastPage)" -ForegroundColor Green

# ============================================================
# STEP 4: POST tabs with absolute x/y coordinates on last page of MSA
# ============================================================
Write-Host "`nPlacing signature tabs on MSA page $lastPage (absolute coordinates)..." -ForegroundColor Cyan

# --- Technijian tabs (recipientId=1, left column x=72) ---
$techTabs = @{
    signHereTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $TechX; yPosition = $YSign; recipientId = "1" }
    )
    fullNameTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $TechX; yPosition = $YName; recipientId = "1"; tabLabel = "tech_name" }
    )
    textTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $TechX; yPosition = $YTitle; recipientId = "1"; tabLabel = "tech_title"; value = $SignerTitle; locked = "true" }
    )
    dateSignedTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $TechX; yPosition = $YDate; recipientId = "1" }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $sendHeaders -Body $techTabs -TimeoutSec 30 | Out-Null
    Write-Host "  Technijian tabs placed (x=$TechX on page $lastPage)." -ForegroundColor Green
}
catch {
    Write-Error "Failed to place Technijian tabs: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

# --- Client tabs (recipientId=2, right column x=320) ---
$clientTabs = @{
    signHereTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $ClientX; yPosition = $YSign; recipientId = "2" }
    )
    fullNameTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $ClientX; yPosition = $YName; recipientId = "2"; tabLabel = "client_name" }
    )
    textTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $ClientX; yPosition = $YTitle; recipientId = "2"; tabLabel = "client_title"; required = "true" }
    )
    dateSignedTabs = @(
        @{ documentId = "1"; pageNumber = $lastPage; xPosition = $ClientX; yPosition = $YDate; recipientId = "2" }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $sendHeaders -Body $clientTabs -TimeoutSec 30 | Out-Null
    Write-Host "  Client tabs placed (x=$ClientX on page $lastPage)." -ForegroundColor Green
}
catch {
    Write-Error "Failed to place Client tabs: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

# ============================================================
# STEP 5: Send the envelope (status = sent)
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
# STEP 6: Get signing URLs for both embedded signers
# ============================================================
Write-Host "`nRetrieving signing URLs..." -ForegroundColor Cyan

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
    Write-Host "  Technijian signing URL obtained." -ForegroundColor Green
}
catch {
    Write-Error "Failed to get Technijian signing URL: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

$clientViewBody = @{
    returnUrl            = $returnUrl
    authenticationMethod = "email"
    email                = $ClientSignerEmail
    userName             = $ClientSignerName
    clientUserId         = "client_signer_2"
} | ConvertTo-Json

try {
    $clientViewResponse = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/views/recipient" -Method POST -Headers $sendHeaders -Body $clientViewBody -TimeoutSec 30
    $clientSignUrl = $clientViewResponse.url
    Write-Host "  Client signing URL obtained." -ForegroundColor Green
}
catch {
    Write-Error "Failed to get Client signing URL: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

# ============================================================
# DRY RUN: stop before sending branded email
# ============================================================
if ($DryRun -or -not $SendEmail) {
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " DRY RUN - ENVELOPE CREATED & SENT" -ForegroundColor Yellow
    Write-Host " (Branded emails NOT sent)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Envelope ID:     $envelopeId" -ForegroundColor White
    Write-Host "MSA Pages:       $msaPageCount (tabs on page $lastPage)" -ForegroundColor White
    Write-Host "Documents:       4 (MSA + Sched A, B, C)" -ForegroundColor White
    Write-Host "Technijian:      $SignerName <$SignerEmail>" -ForegroundColor White
    Write-Host "  Signing URL:   $techSignUrl" -ForegroundColor White
    Write-Host "Client:          $ClientSignerName <$ClientSignerEmail>" -ForegroundColor White
    Write-Host "  Signing URL:   $clientSignUrl" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Yellow

    @{
        success    = $true
        dryRun     = $true
        envelopeId = $envelopeId
        status     = "sent"
        msaPageCount = $msaPageCount
        documents  = @("MSA-AAVA.docx", "Schedule-A-AAVA.docx", "Schedule-B-AAVA.docx", "Schedule-C-AAVA.docx")
        signers    = @(
            @{ name = $SignerName;       email = $SignerEmail;       role = "Technijian"; signingUrl = $techSignUrl;   clientUserId = "tech_signer_1" },
            @{ name = $ClientSignerName; email = $ClientSignerEmail; role = "Client";     signingUrl = $clientSignUrl; clientUserId = "client_signer_2" }
        )
    } | ConvertTo-Json -Depth 5
    exit 0
}

# ============================================================
# STEP 7: Microsoft Graph authentication (client credentials)
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
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
    exit 1
}

$graphHeaders = @{
    "Authorization" = "Bearer $graphToken"
    "Content-Type"  = "application/json"
}

# ============================================================
# STEP 8: Branded HTML email builder (AAVA MSA renewal body)
# ============================================================
function Build-AavaSigningEmail {
    param(
        [string]$RecipFirstName,
        [string]$SigningUrl,
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
  <title>MSA Renewal Ready for Signature</title>
</head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:'Open Sans','Segoe UI',Helvetica,Arial,sans-serif;">

<div style="display:none;max-height:0;overflow:hidden;">Your Technijian MSA renewal package for Aventine at Aliso Viejo Apartments is ready for signature.</div>

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
        MSA Renewal - Ready to Sign
      </h1>
      <p style="margin:0;font-size:16px;color:#FFFFFF;opacity:0.85;">
        Aventine at Aliso Viejo Apartments
      </p>
    </td>
  </tr>

  <!-- Body -->
  <tr>
    <td style="padding:32px;">
      <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">
        Hi $RecipFirstName,
      </p>

      <p style="margin:0 0 16px;font-size:16px;color:#59595B;line-height:1.6;">
        Your Master Service Agreement renewal package for <strong style="color:#1A1A2E;">Aventine at Aliso Viejo Apartments</strong> is ready for signature. The envelope contains four (4) documents:
      </p>

      <!-- Document List -->
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px;border:1px solid #E9ECEF;border-radius:6px;overflow:hidden;">
        <tr><td style="padding:14px 20px;background-color:#F8F9FA;border-bottom:1px solid #E9ECEF;">
          <p style="margin:0 0 2px;font-size:14px;font-weight:600;color:#1A1A2E;">1. Master Service Agreement (MSA-AAVA-2026)</p>
          <p style="margin:0;font-size:13px;color:#59595B;">The main legal agreement governing our services <strong style="color:#F67D4B;">(signatures required here)</strong></p>
        </td></tr>
        <tr><td style="padding:14px 20px;background-color:#FFFFFF;border-bottom:1px solid #E9ECEF;">
          <p style="margin:0 0 2px;font-size:14px;font-weight:600;color:#1A1A2E;">2. Schedule A - Monthly Managed Services</p>
          <p style="margin:0;font-size:13px;color:#59595B;">Pricing, service parts, and the Unpaid Balance Acknowledgment</p>
        </td></tr>
        <tr><td style="padding:14px 20px;background-color:#F8F9FA;border-bottom:1px solid #E9ECEF;">
          <p style="margin:0 0 2px;font-size:14px;font-weight:600;color:#1A1A2E;">3. Schedule B - Subscription and License Services</p>
          <p style="margin:0;font-size:13px;color:#59595B;">Governing terms for future subscription additions (no active subscriptions today)</p>
        </td></tr>
        <tr><td style="padding:14px 20px;background-color:#FFFFFF;">
          <p style="margin:0 0 2px;font-size:14px;font-weight:600;color:#1A1A2E;">4. Schedule C - Rate Card</p>
          <p style="margin:0;font-size:13px;color:#59595B;">Hourly rates for ad-hoc and project work</p>
        </td></tr>
      </table>

      <!-- Key Points -->
      <p style="margin:0 0 12px;font-size:16px;font-weight:700;color:#1A1A2E;">Key points of this renewal:</p>
      <ul style="margin:0 0 24px;padding-left:20px;font-size:15px;color:#59595B;line-height:1.7;">
        <li>New effective date: <strong style="color:#1A1A2E;">May 1, 2026</strong></li>
        <li>Monthly recurring total reduced from <strong style="color:#1A1A2E;">`$539.60</strong> to <strong style="color:#006DB6;">`$333.35</strong> (a <strong style="color:#F67D4B;">`$206.25 monthly savings</strong>)</li>
        <li>12-month initial term</li>
        <li>Site Assessment removed; USA Tech Support moved to ad-hoc hourly billing</li>
        <li>Accumulated unpaid support hours balance of <strong style="color:#1A1A2E;">`$1,094.85</strong> carries forward and is disclosed in Schedule A</li>
      </ul>

      <p style="margin:0 0 24px;font-size:15px;color:#59595B;line-height:1.6;">
        Please click the button below to review and sign. If you have any questions, reply to this email or call <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">949.379.8499</a>.
      </p>

      <!-- CTA Button -->
      <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
        <tr>
          <td style="background-color:#F67D4B;border-radius:6px;">
            <a href="$SigningUrl" style="display:inline-block;padding:16px 40px;font-size:18px;font-weight:600;color:#FFFFFF;text-decoration:none;letter-spacing:0.5px;">Review &amp; Sign MSA Package</a>
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
        If you have any questions about this renewal, please contact <a href="mailto:$SignerEmail" style="color:#006DB6;text-decoration:none;">$SignerName</a> at <a href="mailto:$SignerEmail" style="color:#006DB6;text-decoration:none;">$SignerEmail</a> or call <a href="tel:9493798499" style="color:#006DB6;text-decoration:none;">949.379.8499</a>.
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
# STEP 9: Send branded emails via Microsoft Graph
# ============================================================
Write-Host "`nSending branded signing emails via Microsoft Graph..." -ForegroundColor Cyan

# --- Client (Melissa): personalized greeting + Ravi's full signature block ---
$clientHtml = Build-AavaSigningEmail -RecipFirstName "Melissa" -SigningUrl $clientSignUrl -SenderName $SignerName -IncludeSignature $true

$clientMailBody = @{
    Message = @{
        Subject = $EmailSubject
        Body = @{
            ContentType = "HTML"
            Content = $clientHtml
        }
        ToRecipients = @(
            @{ EmailAddress = @{ Address = $ClientSignerEmail; Name = $ClientSignerName } }
        )
        From = @{ EmailAddress = @{ Address = $SignerEmail; Name = "Ravi Jain - Technijian" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 10

$clientEmailSent = $false
try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" `
        -Method POST -Headers $graphHeaders -Body $clientMailBody
    Write-Host "  Branded email sent to Client: $ClientSignerName <$ClientSignerEmail>" -ForegroundColor Green
    $clientEmailSent = $true
}
catch {
    Write-Error "Failed to send email to client: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
}

# --- Technijian (Ravi): personalized greeting, NO personal signature (he IS the signature) ---
$techHtml = Build-AavaSigningEmail -RecipFirstName "Ravi" -SigningUrl $techSignUrl -SenderName "Technijian eSign" -IncludeSignature $false

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

$techEmailSent = $false
try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" `
        -Method POST -Headers $graphHeaders -Body $techMailBody
    Write-Host "  Branded email sent to Technijian: $SignerName <$SignerEmail>" -ForegroundColor Green
    $techEmailSent = $true
}
catch {
    Write-Error "Failed to send email to Technijian signer: $($_.Exception.Message)"
    if ($_.ErrorDetails) { Write-Error $_.ErrorDetails.Message }
}

# ============================================================
# FINAL REPORT
# ============================================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host " AAVA MSA PACKAGE SENT FOR SIGNATURE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Envelope ID:      $envelopeId" -ForegroundColor White
Write-Host "MSA Page Count:   $msaPageCount (tabs placed on page $lastPage)" -ForegroundColor White
Write-Host "Documents:        4 (MSA + Schedule A, B, C)" -ForegroundColor White
Write-Host "Technijian:       $SignerName <$SignerEmail>" -ForegroundColor White
Write-Host "  Signing URL:    $techSignUrl" -ForegroundColor White
Write-Host "  Email Sent:     $techEmailSent" -ForegroundColor White
Write-Host "Client:           $ClientSignerName <$ClientSignerEmail>" -ForegroundColor White
Write-Host "  Signing URL:    $clientSignUrl" -ForegroundColor White
Write-Host "  Email Sent:     $clientEmailSent" -ForegroundColor White
Write-Host "Signing Order:    Parallel (both routingOrder=1)" -ForegroundColor White
Write-Host "DocuSign Email:   SUPPRESSED (embedded signers)" -ForegroundColor White
Write-Host "Branded Email:    Sent via Microsoft Graph (from RJain@technijian.com)" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Green

$result = @{
    success         = $true
    envelopeId      = $envelopeId
    status          = "sent"
    msaPageCount    = $msaPageCount
    documents       = @("MSA-AAVA.docx", "Schedule-A-AAVA.docx", "Schedule-B-AAVA.docx", "Schedule-C-AAVA.docx")
    brandedEmail    = $true
    docusignEmail   = "suppressed"
    signers         = @(
        @{ name = $SignerName;       email = $SignerEmail;       role = "Technijian"; clientUserId = "tech_signer_1";   signingUrl = $techSignUrl;   emailSent = $techEmailSent },
        @{ name = $ClientSignerName; email = $ClientSignerEmail; role = "Client";     clientUserId = "client_signer_2"; signingUrl = $clientSignUrl; emailSent = $clientEmailSent }
    )
}
$result | ConvertTo-Json -Depth 5
