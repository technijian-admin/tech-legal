# Send SOW-VWC-001-AI-Lead-Gen via DocuSign with NATIVE email (120-day persistent URL)
# Pattern: draft -> absolute-positioned tabs on last page -> send (no clientUserId, no Graph branded email)
# DocuSign sends its own email to each recipient with a signing URL valid for the envelope lifetime (~120 days).

$ErrorActionPreference = "Stop"

# ==== INPUTS ====
$DocumentPath    = "C:\vscode\tech-legal\tech-legal\clients\VWC\03_SOW\SOW-VWC-001-AI-Lead-Gen.docx"
$ClientName      = "Sanford Coggins"
$ClientEmail     = "sanford@visionwisecapital.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$EmailSubject    = "Technijian - SOW-VWC-001 AI / CTO Advisory (AI Lead Gen) - Signature Required"
$EmailBlurb      = "Sanford - thank you for the conversation. Attached is the short AI / CTO Advisory SOW covering the AI Lead Gen build at `$250/hr, with the first two hours at no charge. Please review and sign at your convenience. Reach out with any questions. - Ravi Jain, CEO, Technijian"

$keysFile        = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$scriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path

# ==== DocuSign JWT Auth ====
Write-Host "Authenticating to DocuSign..." -ForegroundColor Cyan
$keysContent = Get-Content $keysFile -Raw
$ClientId  = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId    = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey    = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value

if (-not $ClientId -or -not $UserId -or -not $AccountId -or -not $rsaKey) {
    Write-Error "Failed to read DocuSign credentials from $keysFile"
    exit 1
}

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

# ==== Create DRAFT envelope (NO clientUserId -> DocuSign will email native links on send) ====
if (-not (Test-Path $DocumentPath)) {
    Write-Error "Document not found: $DocumentPath"
    exit 1
}

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

Write-Host "Creating draft envelope..." -ForegroundColor Cyan
$draft = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $hJ -Body $draftPayload -TimeoutSec 60
$envelopeId = $draft.envelopeId
Write-Host "Draft envelope created: $envelopeId" -ForegroundColor Green

# ==== Count pages, last page = signature page ====
$docInfo = Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/documents" -Method GET -Headers $hJ
$pageCount = if ($docInfo.envelopeDocuments[0].pages -is [array]) { $docInfo.envelopeDocuments[0].pages.Count } else { [int]$docInfo.envelopeDocuments[0].pages }
$lastPage = $pageCount.ToString()
Write-Host "Document page count: $pageCount (tabs will be placed on page $lastPage)" -ForegroundColor Cyan

# ==== Place tabs via absolute x/y positioning on last page ====
# Standard SOW signature block: Technijian block upper, Client block lower
$techTabs = @{
    signHereTabs   = @(@{ xPosition="100"; yPosition="210"; pageNumber=$lastPage; documentId="1"; recipientId="1"; scaleValue="1" })
    fullNameTabs   = @(@{ xPosition="100"; yPosition="240"; pageNumber=$lastPage; documentId="1"; recipientId="1"; tabLabel="tech_name"; font="Arial"; fontSize="Size11" })
    textTabs       = @(@{ xPosition="100"; yPosition="270"; pageNumber=$lastPage; documentId="1"; recipientId="1"; tabLabel="tech_title"; value=$SignerTitle; locked="true"; font="Arial"; fontSize="Size11"; width="200"; height="20" })
    dateSignedTabs = @(@{ xPosition="100"; yPosition="300"; pageNumber=$lastPage; documentId="1"; recipientId="1"; font="Arial"; fontSize="Size11" })
} | ConvertTo-Json -Depth 6 -Compress
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $hJ -Body $techTabs | Out-Null
Write-Host "Technijian tabs placed." -ForegroundColor Green

$clientTabs = @{
    signHereTabs   = @(@{ xPosition="100"; yPosition="400"; pageNumber=$lastPage; documentId="1"; recipientId="2"; scaleValue="1" })
    fullNameTabs   = @(@{ xPosition="100"; yPosition="430"; pageNumber=$lastPage; documentId="1"; recipientId="2"; tabLabel="client_name"; font="Arial"; fontSize="Size11" })
    textTabs       = @(@{ xPosition="100"; yPosition="460"; pageNumber=$lastPage; documentId="1"; recipientId="2"; tabLabel="client_title"; required="true"; font="Arial"; fontSize="Size11"; width="200"; height="20" })
    dateSignedTabs = @(@{ xPosition="100"; yPosition="490"; pageNumber=$lastPage; documentId="1"; recipientId="2"; font="Arial"; fontSize="Size11" })
} | ConvertTo-Json -Depth 6 -Compress
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $hJ -Body $clientTabs | Out-Null
Write-Host "Client tabs placed." -ForegroundColor Green

# ==== Transition envelope to SENT -> DocuSign sends native emails to BOTH signers in parallel ====
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json -Compress) | Out-Null

# Save envelope ID for audit/recall
$envelopeId | Out-File -FilePath (Join-Path $scriptDir "vwc-sow-001-envelope-id.txt") -Encoding ascii -NoNewline

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host " ENVELOPE SENT (native DocuSign email, 120-day persistent URLs)" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "Envelope ID    : $envelopeId"
Write-Host "Document       : $fileName"
Write-Host "Technijian     : $SignerName <$SignerEmail>"
Write-Host "Client         : $ClientName <$ClientEmail>"
Write-Host "Signing Order  : Parallel (routingOrder=1 for both)"
Write-Host "Subject        : $EmailSubject"
Write-Host ""
Write-Host "Both recipients will receive a DocuSign email with a signing link valid for ~120 days." -ForegroundColor Yellow
