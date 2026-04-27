# Resend NDA-VWC-001 with branded letterhead (inline, not section header).
# Voids envelope b8ec5bbd-48d3-8aae-831c-090102cf61d5 (plain-white version) and sends fresh.
# Native DocuSign email path (no clientUserId), hidden anchors, parallel signing, ASCII only.

$ErrorActionPreference = "Stop"

$DocumentPath  = "C:\vscode\tech-legal\tech-legal\clients\VWC\01_NDA\NDA-VWC-001.docx"
$ClientName    = "Sanford Coggins"
$ClientEmail   = "sanford@visionwisecapital.com"
$SignerName    = "Ravi Jain"
$SignerEmail   = "rjain@technijian.com"
$SignerTitle   = "Chief Executive Officer"
$BadEnvelopeId = "b8ec5bbd-48d3-8aae-831c-090102cf61d5"

$EmailSubject = "Technijian and VisionWise Capital - Mutual NDA - Signature Required"

$EmailBlurb = @"
Sanford,

Quick correction - I am replacing the previous NDA envelope with a properly Technijian-branded version. Same agreement, same terms, just the right letterhead.

Ahead of moving the My SEO Program proposal forward (and to keep the existing AI / CTO Advisory engagement well-documented), please find attached a Mutual Non-Disclosure Agreement between Technijian and VisionWise Capital.

Why we are sending this now: the SEO work involves exchange of compliance, trademark, fund, and investor-targeting materials, and the AI Lead Gen advisory has already touched investor-prospecting strategy. A standalone mutual NDA covers all of that under a single confidentiality framework rather than relying on the per-engagement clauses inside each SOW. It also satisfies the carve-out in SOW-VWC-001-AI-Lead-Gen Section 2.2, which expressly contemplates a separate NDA before either party shares regulated investor information.

The NDA is mutual, runs two years, and survives for three years on confidential information. There is no commitment to a future engagement embedded in it.

Please countersign at your convenience. I will sign in parallel.

Thank you,
Ravi Jain
CEO, Technijian, Inc.
"@

$keysFile  = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ==== AUTH ====
Write-Host "Authenticating to DocuSign..." -ForegroundColor Cyan
$keysContent = [System.IO.File]::ReadAllText($keysFile)
$ClientId  = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId    = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey    = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

$nodeCommand = (Get-Command node,node.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
if (-not $nodeCommand -and (Test-Path "C:\Program Files\nodejs\node.exe")) { $nodeCommand = "C:\Program Files\nodejs\node.exe" }

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

# ==== STEP 1: Void the unbranded envelope ====
Write-Host ""
Write-Host "Voiding plain-white envelope $BadEnvelopeId..." -ForegroundColor Yellow
$voidPayload = @{
    status = "voided"
    voidedReason = "Replacing with Technijian-branded letterhead version. Same terms, branded format."
} | ConvertTo-Json -Compress
try {
    Invoke-RestMethod -Uri "$apiUrl/envelopes/$BadEnvelopeId" -Method PUT -Headers $hJ -Body $voidPayload | Out-Null
    Write-Host "Voided successfully." -ForegroundColor Green
} catch {
    Write-Host "Void warning: $_" -ForegroundColor Yellow
}

# ==== STEP 2: Create draft WITHOUT clientUserId (native email path) ====
$fileName   = [System.IO.Path]::GetFileName($DocumentPath)
$fileBytes  = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

$draftPayload = @{
    emailSubject = $EmailSubject
    emailBlurb   = $EmailBlurb
    status       = "created"
    documents    = @(@{ documentBase64 = $base64File; name = $fileName; fileExtension = "docx"; documentId = "1" })
    recipients   = @{
        signers = @(
            @{ email = $SignerEmail; name = $SignerName; recipientId = "1"; routingOrder = "1" },
            @{ email = $ClientEmail; name = $ClientName; recipientId = "2"; routingOrder = "1" }
        )
    }
} | ConvertTo-Json -Depth 10 -Compress

Write-Host ""
Write-Host "Creating draft envelope (branded NDA, native email path)..." -ForegroundColor Cyan
$draftResp = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $hJ -Body $draftPayload -TimeoutSec 60
$envelopeId = $draftResp.envelopeId
Write-Host "Draft envelope created: $envelopeId" -ForegroundColor Green

# ==== STEP 3: Place tabs via hidden anchors ====
$techTabsPayload = @{
    signHereTabs   = @(@{ anchorString="/tSign/"; anchorUnits="pixels"; anchorXOffset="50"; anchorYOffset="-5"; documentId="1"; recipientId="1" })
    fullNameTabs   = @(@{ anchorString="/tName/"; anchorUnits="pixels"; anchorXOffset="55"; anchorYOffset="-2"; documentId="1"; recipientId="1"; tabLabel="tech_name" })
    textTabs       = @(@{ anchorString="/tTitle/"; anchorUnits="pixels"; anchorXOffset="55"; anchorYOffset="-2"; documentId="1"; recipientId="1"; tabLabel="tech_title"; value=$SignerTitle; locked="true" })
    dateSignedTabs = @(@{ anchorString="/tDate/"; anchorUnits="pixels"; anchorXOffset="55"; anchorYOffset="-2"; documentId="1"; recipientId="1" })
} | ConvertTo-Json -Depth 6 -Compress
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $hJ -Body $techTabsPayload | Out-Null
Write-Host "Technijian tabs placed (anchored)." -ForegroundColor Green

$clientTabsPayload = @{
    signHereTabs   = @(@{ anchorString="/cSign/"; anchorUnits="pixels"; anchorXOffset="50"; anchorYOffset="-5"; documentId="1"; recipientId="2" })
    fullNameTabs   = @(@{ anchorString="/cName/"; anchorUnits="pixels"; anchorXOffset="55"; anchorYOffset="-2"; documentId="1"; recipientId="2"; tabLabel="client_name" })
    textTabs       = @(@{ anchorString="/cTitle/"; anchorUnits="pixels"; anchorXOffset="55"; anchorYOffset="-2"; documentId="1"; recipientId="2"; tabLabel="client_title"; required="true" })
    dateSignedTabs = @(@{ anchorString="/cDate/"; anchorUnits="pixels"; anchorXOffset="55"; anchorYOffset="-2"; documentId="1"; recipientId="2" })
} | ConvertTo-Json -Depth 6 -Compress
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $hJ -Body $clientTabsPayload | Out-Null
Write-Host "Client tabs placed (anchored)." -ForegroundColor Green

# ==== STEP 4: Send -> native parallel email ====
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json -Compress) | Out-Null

$envelopeId | Out-File -FilePath (Join-Path $scriptDir "vwc-nda-001-envelope-id.txt") -Encoding ascii -NoNewline

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host " BRANDED NDA ENVELOPE SENT (native DocuSign email)" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "Voided envelope    : $BadEnvelopeId"
Write-Host "New envelope ID    : $envelopeId"
Write-Host "Document           : $fileName (with branded letterhead)"
Write-Host ("Technijian         : {0} [{1}]" -f $SignerName, $SignerEmail)
Write-Host ("Client             : {0} [{1}]" -f $ClientName, $ClientEmail)
Write-Host "Signing Order      : Parallel (routingOrder=1 for both)"
Write-Host "Subject            : $EmailSubject"
