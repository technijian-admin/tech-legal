# Send SOW-VWC-002-SEO via DocuSign.
# Native email path (no clientUserId), hidden anchors, parallel signing, ASCII only.

$ErrorActionPreference = "Stop"

$DocumentPath  = "C:\vscode\tech-legal\tech-legal\clients\VWC\03_SOW\SOW-VWC-002-SEO.docx"
$ClientName    = "Sanford Coggins"
$ClientEmail   = "sanford@visionwisecapital.com"
$SignerName    = "Ravi Jain"
$SignerEmail   = "rjain@technijian.com"
$SignerTitle   = "Chief Executive Officer"

$EmailSubject = "Technijian - SOW-VWC-002 My SEO Program (12-month) - Signature Required"

$EmailBlurb = @"
Sanford,

Attached is the My SEO Program 12-month Statement of Work that we discussed. Quick recap of the structure:

- Effective May 1, 2026; runs through April 30, 2027.
- Months 1 to 3 (Foundation): website, technical SEO, content production, 5 keyword-targeted blogs per month at $1,000 per month.
- Months 4 to 12: AI Search Optimization, quarterly PR Releases, and Content Syndication automatically layer on, taking the monthly fee to $1,550 per month.
- Total 12-month investment: $16,950. Fixed monthly fee with unlimited service hours from a dedicated Technijian SEO pod.
- The Phase 2 add-ons activate automatically on August 1, 2026 - no change order required (Section 7.02).
- Confidentiality coordinates with the separate Mutual NDA going through DocuSign in parallel; the two documents are designed to interlock.

Please review and countersign at your convenience. I will sign in parallel.

Reach out if you want to walk through any section before signing - happy to do a 15-minute call.

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

# ==== Create draft WITHOUT clientUserId (native email path) ====
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
Write-Host "Creating draft envelope (SOW, native email path)..." -ForegroundColor Cyan
$draftResp = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $hJ -Body $draftPayload -TimeoutSec 60
$envelopeId = $draftResp.envelopeId
Write-Host "Draft envelope created: $envelopeId" -ForegroundColor Green

# ==== Place tabs via hidden anchors ====
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

# ==== Send -> native parallel email ====
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json -Compress) | Out-Null

$envelopeId | Out-File -FilePath (Join-Path $scriptDir "vwc-sow-002-envelope-id.txt") -Encoding ascii -NoNewline

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host " SOW ENVELOPE SENT (native DocuSign email)" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "Envelope ID        : $envelopeId"
Write-Host "Document           : $fileName"
Write-Host ("Technijian         : {0} [{1}]" -f $SignerName, $SignerEmail)
Write-Host ("Client             : {0} [{1}]" -f $ClientName, $ClientEmail)
Write-Host "Signing Order      : Parallel (routingOrder=1 for both)"
Write-Host "Subject            : $EmailSubject"
