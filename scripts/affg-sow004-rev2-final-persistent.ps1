# Void 5f1cc4da... and recreate WITHOUT clientUserId so the signing URL in DocuSign's
# email is persistent for the envelope's lifetime (~120 days, well over the 7 days requested).

$ErrorActionPreference = "Stop"

$DocumentPath    = "C:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Rev1-Managed-Device-Migration.docx"
$RecipientName   = "Iris Liu"
$RecipientEmail  = "iris.liu@americanfundstars.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$oldEnvelopeId   = "5f1cc4da-0465-8184-8207-bf79e93c07ff"
$EmailSubject    = "Please sign: SOW-AFFG-004 Rev 1 - Fleet Right-Sizing and Compliance"
$EmailBlurb      = "Iris, this is SOW-AFFG-004 Rev 1 for your signature. Earlier emails today from us have been voided; this is the final one. The signing link is valid for the life of the envelope (120 days). Please review and sign at your convenience.

Ravi Jain
Technijian"

$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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
Write-Host "DocuSign auth OK. Base URI: $baseUri" -ForegroundColor Green

# --- Void current envelope ---
$voidBody = @{ status = "voided"; voidedReason = "Recreating with persistent URL" } | ConvertTo-Json
Invoke-RestMethod -Uri "$apiUrl/envelopes/$oldEnvelopeId" -Method PUT -Headers $hJ -Body $voidBody | Out-Null
Write-Host "Voided $oldEnvelopeId" -ForegroundColor Green

# --- Create new envelope WITHOUT clientUserId (so URL is persistent) ---
$fileName   = [System.IO.Path]::GetFileName($DocumentPath)
$fileBytes  = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

# Send as draft first, place tabs, then send. NO clientUserId — DocuSign sends native email with persistent URL.
$payload = @{
    emailSubject = $EmailSubject
    emailBlurb   = $EmailBlurb
    status       = "created"
    documents    = @(@{ documentBase64 = $base64File; name = $fileName; fileExtension = "docx"; documentId = "1" })
    recipients   = @{
        signers = @(
            @{ email = $SignerEmail;    name = $SignerName;    recipientId = "1"; routingOrder = "1" },
            @{ email = $RecipientEmail; name = $RecipientName; recipientId = "2"; routingOrder = "1" }
        )
    }
} | ConvertTo-Json -Depth 10

$draft = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $hJ -Body $payload -TimeoutSec 60
$envelopeId = $draft.envelopeId
Write-Host "New draft envelope (no clientUserId): $envelopeId" -ForegroundColor Green

$docInfo = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents" -Method GET -Headers $hJ
$pageCount = if ($docInfo.envelopeDocuments[0].pages -is [array]) { $docInfo.envelopeDocuments[0].pages.Count } else { [int]$docInfo.envelopeDocuments[0].pages }
$lastPage = $pageCount.ToString()

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

# --- Send envelope (DocuSign sends native email to both recipients with persistent URL) ---
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json) | Out-Null
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " ENVELOPE SENT WITH PERSISTENT URL" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Envelope ID : $envelopeId"
Write-Host "Voided      : $oldEnvelopeId"
Write-Host "URL life    : envelope lifetime (~120 days)"
Write-Host "Recipients  : Iris Liu, Ravi Jain (both getting DocuSign native email)"
Set-Content -Path (Join-Path $scriptDir "affg-sow004-rev2-final-envelope-id.txt") -Value $envelopeId -Encoding UTF8
