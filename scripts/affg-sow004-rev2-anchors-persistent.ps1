# Create DocuSign envelope WITHOUT clientUserId (persistent URL ~120 days)
# + anchor-based tab placement (correct signature placement via hidden /tSign/ etc.)
# DocuSign sends its native email to both parties.

$ErrorActionPreference = "Stop"

$DocumentPath    = "C:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Rev1-Managed-Device-Migration.docx"
$RecipientName   = "Iris Liu"
$RecipientEmail  = "iris.liu@americanfundstars.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$EmailSubject    = "Please sign: SOW-AFFG-004 Rev 1 - Fleet Right-Sizing and Compliance"
$EmailBlurb      = "Iris, this is SOW-AFFG-004 Rev 1 for your signature. Earlier signature-related emails from us today have been voided; this one is the final. The signing link is valid for the envelope's lifetime (~120 days), so please review and sign at your convenience. -- Ravi Jain, Technijian"

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
$userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers @{ Authorization = "Bearer $($tok.access_token)" }
$baseUri  = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
$apiUrl   = "$baseUri/restapi/v2.1/accounts/$AccountId"
$hJ = @{ Authorization = "Bearer $($tok.access_token)"; "Content-Type" = "application/json" }

# --- Create draft envelope (NO clientUserId — persistent URL, DocuSign sends native email) ---
$fileName   = [System.IO.Path]::GetFileName($DocumentPath)
$fileBytes  = [System.IO.File]::ReadAllBytes($DocumentPath)
$base64File = [Convert]::ToBase64String($fileBytes)

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
Write-Host "Draft envelope: $envelopeId (no clientUserId)" -ForegroundColor Green

# --- Place tabs via ANCHORS ---
$techTabs = @{
    signHereTabs   = @(@{ anchorString = "/tSign/";  anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1"; recipientId = "1" })
    fullNameTabs   = @(@{ anchorString = "/tName/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1"; tabLabel = "tech_name" })
    textTabs       = @(@{ anchorString = "/tTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1"; tabLabel = "tech_title"; value = $SignerTitle; locked = "true" })
    dateSignedTabs = @(@{ anchorString = "/tDate/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1" })
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $hJ -Body $techTabs | Out-Null

$clientTabs = @{
    signHereTabs   = @(@{ anchorString = "/cSign/";  anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1"; recipientId = "2" })
    fullNameTabs   = @(@{ anchorString = "/cName/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2"; tabLabel = "client_name" })
    textTabs       = @(@{ anchorString = "/cTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2"; tabLabel = "client_title"; required = "true" })
    dateSignedTabs = @(@{ anchorString = "/cDate/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2" })
} | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $hJ -Body $clientTabs | Out-Null
Write-Host "Tabs placed via anchors" -ForegroundColor Green

# --- Send envelope (DocuSign sends native email to both) ---
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json) | Out-Null

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " SENT (DocuSign native email)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Envelope ID : $envelopeId"
Write-Host "URL life    : ~120 days (envelope lifetime)"
Write-Host "Placement   : Anchors (/tSign/, /cSign/, etc.) - correct pages"
Write-Host "Recipients  : Iris + Ravi, both via DocuSign native email"
