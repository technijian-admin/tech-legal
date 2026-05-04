# CCC MSA - DocuSign envelope, NATIVE email path, parallel signing
# - 1 document: MSA-CCC.docx (MSA + Schedule C Rate Card embedded)
# - Anchor tabs on documentId=1: /tSign/ /tName/ /tTitle/ /tDate/ (Technijian)
#                                 /cSign/ /cName/ /cTitle/ /cDate/ (Client)
# - NO clientUserId on either signer = DocuSign sends its OWN email with PERSISTENT (~120-day) URLs
# - status=sent on creation = DocuSign dispatches emails immediately
# - Parallel: routingOrder=1 for both Ravi and Chuck

# --- Configuration ---
$keysFile   = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$scriptDir  = "C:\vscode\tech-legal\tech-legal\scripts"
$nodeCommand = (Get-Command node, node.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
if (-not $nodeCommand -and (Test-Path "C:\Program Files\nodejs\node.exe")) {
    $nodeCommand = "C:\Program Files\nodejs\node.exe"
}
if (-not $nodeCommand) { Write-Error "Node.js not found"; exit 1 }

# --- Document ---
$docFolder = "C:\vscode\tech-legal\tech-legal\clients\CCC\02_MSA"
$docs = @(
    @{ id = "1"; path = "$docFolder\MSA-CCC.docx"; displayName = "MSA - Culp Construction Company" }
)
foreach ($d in $docs) {
    if (-not (Test-Path $d.path)) { Write-Error "Missing: $($d.path)"; exit 1 }
}

# --- Recipients ---
$techSignerName  = "Ravi Jain"
$techSignerEmail = "rjain@technijian.com"
$techSignerTitle = "CEO"

$clientSignerName  = "Chuck Culp"
$clientSignerEmail = "chas.culp@culpco.com"

$emailSubject = "Culp Construction Company - Master Service Agreement - Signature Required"
$emailBlurb   = "Chuck - please find attached the Master Service Agreement for Culp Construction Company. This agreement covers your home computer support and email services with Technijian. Please review and sign at your convenience. - Ravi"

# --- Read DocuSign credentials ---
Write-Host "Reading DocuSign credentials..." -ForegroundColor Cyan
$keysContent = Get-Content $keysFile -Raw
$ClientId  = [regex]::Match($keysContent, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$UserId    = [regex]::Match($keysContent, 'User ID:\*\*\s*(\S+)').Groups[1].Value
$AccountId = [regex]::Match($keysContent, 'Account ID:\*\*\s*(\S+)').Groups[1].Value
$rsaKey    = [regex]::Match($keysContent, '(?s)(-----BEGIN RSA PRIVATE KEY-----.*?-----END RSA PRIVATE KEY-----)').Groups[1].Value
if (-not $ClientId -or -not $UserId -or -not $AccountId -or -not $rsaKey) { Write-Error "Missing DocuSign creds"; exit 1 }
Write-Host "DocuSign credentials loaded." -ForegroundColor Green

# --- JWT auth via Node helper ---
Write-Host "Generating JWT and authenticating..." -ForegroundColor Cyan
$tempKey = [System.IO.Path]::GetTempFileName()
$rsaKey | Set-Content -Path $tempKey -NoNewline
$jwtHelper = Join-Path $scriptDir "docusign-jwt-helper.js"
$jwt = & $nodeCommand $jwtHelper $ClientId $UserId $tempKey 2>&1
Remove-Item $tempKey -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) { Write-Error "JWT generation failed: $jwt"; exit 1 }

$tokenResponse = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/token" -Method POST -Body @{
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    assertion  = $jwt
} -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token

$headers  = @{ "Authorization" = "Bearer $accessToken" }
$userInfo = Invoke-RestMethod -Uri "https://account.docusign.com/oauth/userinfo" -Headers $headers
$baseUri  = ($userInfo.accounts | Where-Object { $_.account_id -eq $AccountId }).base_uri
if (-not $baseUri) { $baseUri = "https://na1.docusign.net" }
$apiUrl = "$baseUri/restapi/v2.1/accounts/$AccountId"
Write-Host "Authenticated. API: $apiUrl" -ForegroundColor Green

# --- Build documents array ---
Write-Host "`nReading and encoding document..." -ForegroundColor Cyan
$docArray = @()
foreach ($d in $docs) {
    $bytes = [System.IO.File]::ReadAllBytes($d.path)
    $b64   = [Convert]::ToBase64String($bytes)
    $name  = [System.IO.Path]::GetFileName($d.path)
    $ext   = [System.IO.Path]::GetExtension($d.path).TrimStart('.')
    $docArray += @{
        documentBase64 = $b64
        name           = $d.displayName
        fileExtension  = $ext
        documentId     = $d.id
    }
    Write-Host "  doc $($d.id): $name ($([math]::Round($bytes.Length/1KB,1)) KB)" -ForegroundColor Gray
}

# --- Create envelope: NATIVE EMAIL PATH (no clientUserId, status=sent) ---
Write-Host "`nCreating envelope (status=sent, NO clientUserId, native DocuSign email path)..." -ForegroundColor Cyan
$envelopeBody = @{
    emailSubject = $emailSubject
    emailBlurb   = $emailBlurb
    status       = "sent"
    documents    = $docArray
    recipients   = @{
        signers = @(
            @{
                email        = $techSignerEmail
                name         = $techSignerName
                recipientId  = "1"
                routingOrder = "1"
                # NO clientUserId -> DocuSign sends native email with persistent (~120-day) URL
                tabs = @{
                    signHereTabs   = @( @{ anchorString = "/tSign/";  anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1" } )
                    fullNameTabs   = @( @{ anchorString = "/tName/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; tabLabel = "tech_name" } )
                    textTabs       = @( @{ anchorString = "/tTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; tabLabel = "tech_title"; value = $techSignerTitle; locked = "true" } )
                    dateSignedTabs = @( @{ anchorString = "/tDate/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1" } )
                }
            },
            @{
                email        = $clientSignerEmail
                name         = $clientSignerName
                recipientId  = "2"
                routingOrder = "1"
                # NO clientUserId -> DocuSign sends native email with persistent (~120-day) URL
                tabs = @{
                    signHereTabs   = @( @{ anchorString = "/cSign/";  anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1" } )
                    fullNameTabs   = @( @{ anchorString = "/cName/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; tabLabel = "client_name" } )
                    textTabs       = @( @{ anchorString = "/cTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; tabLabel = "client_title"; required = "true" } )
                    dateSignedTabs = @( @{ anchorString = "/cDate/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1" } )
                }
            }
        )
    }
} | ConvertTo-Json -Depth 12 -Compress

# Safety check: no clientUserId must appear in payload
if ($envelopeBody -match 'clientUserId') {
    Write-Error "SAFETY ABORT: payload contains clientUserId. This would suppress the native email and produce 5-min URLs. Refusing to send."
    exit 1
}
Write-Host "Safety check passed: NO clientUserId in payload (native email path)." -ForegroundColor Green

$sendHeaders = @{ "Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" }
$resp = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $sendHeaders -Body $envelopeBody -TimeoutSec 90
$envelopeId     = $resp.envelopeId
$envelopeStatus = $resp.status

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "ENVELOPE DISPATCHED via DocuSign native email (~120-day URL)" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "Envelope ID:  $envelopeId" -ForegroundColor White
Write-Host "Status:       $envelopeStatus" -ForegroundColor White
Write-Host "Signers (parallel, both routingOrder=1):" -ForegroundColor White
Write-Host "  1. $techSignerName <$techSignerEmail>" -ForegroundColor Gray
Write-Host "  2. $clientSignerName <$clientSignerEmail>" -ForegroundColor Gray
Write-Host "Document:" -ForegroundColor White
Write-Host "  1. MSA - Culp Construction Company" -ForegroundColor Gray
Write-Host ""
Write-Host "Both signers will receive DocuSign's native email shortly." -ForegroundColor Green
Write-Host "URLs in those emails are valid for the envelope's full ~120-day lifetime." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Yellow

# Save envelope ID for tracking
$envelopeId | Set-Content -Path "$scriptDir\ccc-msa-envelope-id.txt" -NoNewline
Write-Host "Envelope ID saved to: $scriptDir\ccc-msa-envelope-id.txt" -ForegroundColor Gray
