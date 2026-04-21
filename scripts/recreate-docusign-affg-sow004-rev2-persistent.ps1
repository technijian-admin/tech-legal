# Void e3cc8d1a... and recreate WITHOUT clientUserId so DocuSign sends its native email
# with a persistent signing URL (valid for envelope lifetime ~120 days).

$ErrorActionPreference = "Stop"

$DocumentPath    = "C:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Rev1-Managed-Device-Migration.docx"
$RecipientName   = "Iris Liu"
$RecipientEmail  = "iris.liu@americanfundstars.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$EmailSubject    = "Please sign: SOW-AFFG-004 Rev 1 - Fleet Right-Sizing and Compliance"
$EmailMessage    = "Iris, attached is SOW-AFFG-004 Rev 1. This is the corrected version covering the BYOD MAM-only approach, 10 managed endpoints, Azure Entra SSO, CloudBrink ZTNA, and IP-whitelist architecture we discussed. Please review and sign at your convenience.`r`n`r`nMy apologies for the earlier duplicate signature requests today - those were sent in error and have been voided. This is the final one.`r`n`r`nThank you,`r`nRavi"
$oldEnvelopeId   = "e3cc8d1a-1487-89ba-83dc-1c0fbefad2b9"

$keysFile        = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$scriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Auth ---
$keysContent = Get-Content $keysFile -Raw
$ClientId  = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId    = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey    = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

$nodeCommand = "C:\Program Files\nodejs\node.exe"
$tempKeyPath = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKeyPath -NoNewline
$jwtHelperPath = Join-Path $scriptDir "docusign-jwt-helper.js"
$jwt = & $nodeCommand $jwtHelperPath $ClientId $UserId $tempKeyPath 2>&1
Remove-Item $tempKeyPath -ErrorAction SilentlyContinue
$tok = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST `
    -Body @{ grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"; assertion = $jwt } `
    -ContentType "application/x-www-form-urlencoded"
$accessToken = $tok.access_token
$userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers @{ Authorization = "Bearer $accessToken" }
$baseUri  = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
$apiUrl   = "$baseUri/restapi/v2.1/accounts/$AccountId"
$hJ = @{ Authorization = "Bearer $accessToken"; "Content-Type" = "application/json" }
Write-Host "Auth OK." -ForegroundColor Green

# --- Void old envelope ---
$voidBody = @{ status = "voided"; voidedReason = "Recreating with persistent signing URL" } | ConvertTo-Json
Invoke-RestMethod -Uri "$apiUrl/envelopes/$oldEnvelopeId" -Method PUT -Headers $hJ -Body $voidBody | Out-Null
Write-Host "Voided old envelope $oldEnvelopeId" -ForegroundColor Green

# --- Create new envelope (NO clientUserId) + tabs + send in one call ---
$fileName   = [System.IO.Path]::GetFileName($DocumentPath)
$fileBytes  = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

# Determine page count by creating as draft first, then reading, then updating
$draftPayload = @{
    emailSubject = $EmailSubject
    emailBlurb   = $EmailMessage
    status       = "created"
    documents    = @(@{ documentBase64 = $base64File; name = $fileName; fileExtension = "docx"; documentId = "1" })
    recipients   = @{
        signers = @(
            @{ email = $SignerEmail;    name = $SignerName;    recipientId = "1"; routingOrder = "1" },
            @{ email = $RecipientEmail; name = $RecipientName; recipientId = "2"; routingOrder = "1" }
        )
    }
} | ConvertTo-Json -Depth 10

$draft = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $hJ -Body $draftPayload -TimeoutSec 60
$envelopeId = $draft.envelopeId
Write-Host "New draft envelope: $envelopeId" -ForegroundColor Green

# --- Determine last page ---
$docInfo   = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents" -Method GET -Headers $hJ
$pageCount = if ($docInfo.envelopeDocuments[0].pages -is [array]) { $docInfo.envelopeDocuments[0].pages.Count } else { [int]$docInfo.envelopeDocuments[0].pages }
$lastPage  = $pageCount.ToString()

# --- Absolute tab positioning (last page) ---
$TECH_X = 100
$techTabs = @{
    signHereTabs   = @(@{ xPosition="$TECH_X"; yPosition="210"; pageNumber=$lastPage; documentId="1"; recipientId="1"; scaleValue="1" })
    fullNameTabs   = @(@{ xPosition="$TECH_X"; yPosition="240"; pageNumber=$lastPage; documentId="1"; recipientId="1"; tabLabel="tech_name"; font="Arial"; fontSize="Size11" })
    textTabs       = @(@{ xPosition="$TECH_X"; yPosition="270"; pageNumber=$lastPage; documentId="1"; recipientId="1"; tabLabel="tech_title"; value=$SignerTitle; locked="true"; font="Arial"; fontSize="Size11"; width="200"; height="20" })
    dateSignedTabs = @(@{ xPosition="$TECH_X"; yPosition="300"; pageNumber=$lastPage; documentId="1"; recipientId="1"; font="Arial"; fontSize="Size11" })
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $hJ -Body $techTabs -TimeoutSec 30 | Out-Null

$CLI_X = 100
$clientTabs = @{
    signHereTabs   = @(@{ xPosition="$CLI_X"; yPosition="400"; pageNumber=$lastPage; documentId="1"; recipientId="2"; scaleValue="1" })
    fullNameTabs   = @(@{ xPosition="$CLI_X"; yPosition="430"; pageNumber=$lastPage; documentId="1"; recipientId="2"; tabLabel="client_name"; font="Arial"; fontSize="Size11" })
    textTabs       = @(@{ xPosition="$CLI_X"; yPosition="460"; pageNumber=$lastPage; documentId="1"; recipientId="2"; tabLabel="client_title"; required="true"; font="Arial"; fontSize="Size11"; width="200"; height="20" })
    dateSignedTabs = @(@{ xPosition="$CLI_X"; yPosition="490"; pageNumber=$lastPage; documentId="1"; recipientId="2"; font="Arial"; fontSize="Size11" })
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $hJ -Body $clientTabs -TimeoutSec 30 | Out-Null
Write-Host "Tabs placed on page $lastPage" -ForegroundColor Green

# --- Send envelope (DocuSign will send its native email to each recipient) ---
$sendBody = @{ status = "sent" } | ConvertTo-Json
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body $sendBody -TimeoutSec 60 | Out-Null
Write-Host "Envelope sent: $envelopeId (DocuSign native emails dispatched to both parties)" -ForegroundColor Green

Write-Host ""
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host " NEW ENVELOPE ACTIVE (persistent URLs)" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "New envelope ID : $envelopeId"
Write-Host "Voided prev ID  : $oldEnvelopeId"
Write-Host "Iris            : DocuSign native email with persistent URL"
Write-Host "Ravi            : DocuSign native email with persistent URL"

Set-Content -Path (Join-Path $scriptDir "affg-sow004-rev2-final-envelope.txt") -Value $envelopeId -Encoding UTF8
