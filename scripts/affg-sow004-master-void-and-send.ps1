# Void existing AFFG SOW-004 envelope (Rev 3 / 259a1266) and send the corrected master.
# Master SOW reflects:
#   - CloudBrink as Technijian-billed at $8/user/mo (was incorrectly listed as AFFG-procured)
#   - Generic "MacBook" model (Iris is choosing between Air/Pro/Neo)
#   - 10 Apple endpoints (4 Mac Mini + 6 MacBook), full §12 amendment + Exhibit A MSA Framework
#   - New monthly: $3,806.50/mo (+$1,012/mo net), one-time $5,340
#
# Pattern: NO clientUserId on either recipient (DocuSign native email, persistent URL ~120 days)
# Tabs:    Anchor-based via /tSign/ /tName/ /tTitle/ /tDate/ /cSign/ /cName/ /cTitle/ /cDate/

$ErrorActionPreference = "Stop"

$DocumentPath    = "C:\vscode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Managed-Device-Migration.docx"
$RecipientName   = "Iris Liu"
$RecipientEmail  = "iris.liu@americanfundstars.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$EmailSubject    = "Please sign: SOW-AFFG-004 - Managed Device Control Deployment (corrected)"
$EmailBlurb      = @"
Hi Iris,

This is the corrected and consolidated version of SOW-AFFG-004. It supersedes the prior envelope (now voided) and reflects the two updates we discussed:

  1. CloudBrink ZTNA per-user licensing is included in the Technijian monthly fee at `$8.00/user/month and replaces Cisco Umbrella (`$4.00/user/month). Net swap impact +`$4.00/user/month, included in the proposed monthly recurring. CloudBrink is no longer listed as AFFG-procured.

  2. The MacBook model is left open ("MacBook") so AFFG can pick the configuration that best fits -- Air, Pro, or Neo -- once Apple confirms availability. PMMAC pricing is identical across models.

Updated monthly recurring: `$2,794.50 to `$3,806.50 (net +`$1,012.00/month) for the full SEC Reg S-P 2024 / FINRA 3110 endpoint compliance posture across all 10 Apple endpoints.

The signing link is valid for the envelope's lifetime (~120 days) - please review and sign at your convenience.

Thank you,
Ravi Jain
"@
$oldEnvelopeId = "259a1266-cbaf-8c3a-803e-71fbbc3fc86a"

$keysFile  = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\docusign.md"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Auth ---
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
Write-Host "DocuSign auth OK." -ForegroundColor Green

# --- Void existing envelope ---
$voidBody = @{ status = "voided"; voidedReason = "Superseded by corrected master SOW reflecting CloudBrink Technijian-billed model and generic MacBook hardware (AFFG to choose model)" } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri "$apiUrl/envelopes/$oldEnvelopeId" -Method PUT -Headers $hJ -Body $voidBody | Out-Null
    Write-Host "Voided previous envelope: $oldEnvelopeId" -ForegroundColor Yellow
} catch {
    Write-Host "Void of $oldEnvelopeId returned: $($_.Exception.Message)" -ForegroundColor DarkYellow
    Write-Host "(Continuing -- envelope may already be voided/completed/deleted.)" -ForegroundColor DarkYellow
}

# --- Create draft envelope (NO clientUserId -- persistent URL, native DocuSign email) ---
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
} | ConvertTo-Json -Depth 10 -Compress

$draft = Invoke-RestMethod -Uri "$apiUrl/envelopes" -Method POST -Headers $hJ -Body $payload -TimeoutSec 60
$envelopeId = $draft.envelopeId
Write-Host "Draft envelope created: $envelopeId" -ForegroundColor Green

# --- Anchor-based tabs (Technijian / Ravi) ---
$techTabs = @{
    signHereTabs   = @(@{ anchorString = "/tSign/";  anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1"; recipientId = "1" })
    fullNameTabs   = @(@{ anchorString = "/tName/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1"; tabLabel = "tech_name" })
    textTabs       = @(@{ anchorString = "/tTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1"; tabLabel = "tech_title"; value = $SignerTitle; locked = "true" })
    dateSignedTabs = @(@{ anchorString = "/tDate/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "1" })
} | ConvertTo-Json -Depth 6 -Compress
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/1/tabs" -Method POST -Headers $hJ -Body $techTabs | Out-Null

# --- Anchor-based tabs (Client / Iris) ---
$clientTabs = @{
    signHereTabs   = @(@{ anchorString = "/cSign/";  anchorUnits = "pixels"; anchorXOffset = "50"; anchorYOffset = "-5"; documentId = "1"; recipientId = "2" })
    fullNameTabs   = @(@{ anchorString = "/cName/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2"; tabLabel = "client_name" })
    textTabs       = @(@{ anchorString = "/cTitle/"; anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2"; tabLabel = "client_title"; required = "true" })
    dateSignedTabs = @(@{ anchorString = "/cDate/";  anchorUnits = "pixels"; anchorXOffset = "55"; anchorYOffset = "-2"; documentId = "1"; recipientId = "2" })
} | ConvertTo-Json -Depth 6 -Compress
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId/recipients/2/tabs" -Method POST -Headers $hJ -Body $clientTabs | Out-Null
Write-Host "Anchor tabs placed for both signers" -ForegroundColor Green

# --- Send (DocuSign sends native email to both, persistent URL) ---
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json) | Out-Null

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " ENVELOPE SENT (DocuSign native email)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "New envelope ID : $envelopeId"
Write-Host "Voided prev ID  : $oldEnvelopeId"
Write-Host "URL life        : ~120 days (envelope lifetime)"
Write-Host "Placement       : Anchors (/tSign/ /cSign/ etc.) -- correct page placement"
Write-Host "Routing         : Parallel (Iris + Ravi at routingOrder=1)"
Write-Host "Recipients      : Iris Liu (iris.liu@americanfundstars.com), Ravi Jain (rjain@technijian.com)"

Set-Content -Path (Join-Path $scriptDir "affg-sow004-master-envelope-id.txt") -Value $envelopeId -Encoding UTF8
Write-Host ""
Write-Host "Envelope ID persisted to: affg-sow004-master-envelope-id.txt" -ForegroundColor Cyan
