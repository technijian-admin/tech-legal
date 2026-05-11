# SOW-AFFG-004 Rev 3 — persistent URL + anchor-based tabs (modeled on affg-sow004-rev2-anchors-persistent.ps1).
# Voids the broken Rev 3 envelope (39227686) sent with 5-min recipient-view URLs, then re-sends with persistent URL.
# DocuSign sends its native email containing the persistent signing URL (~120-day envelope lifetime) plus the
# revision summary in EmailBlurb.

$ErrorActionPreference = "Stop"

$DocumentPath    = "C:\VSCode\tech-legal\tech-legal\clients\AFFG\03_SOW\SOW-AFFG-004-Managed-Device-Migration.docx"
$RecipientName   = "Iris Liu"
$RecipientEmail  = "iris.liu@americanfundstars.com"
$SignerName      = "Ravi Jain"
$SignerEmail     = "rjain@technijian.com"
$SignerTitle     = "CEO"
$BrokenEnvelopeId = "39227686-865f-88a0-80a7-041ea8a44ca0"
$EmailSubject    = "Please sign: SOW-AFFG-004 Rev 3 - Updated Stack & Pricing"
$EmailBlurb      = @'
Hi Iris,

Per our discussion, this is SOW-AFFG-004 Rev 3 for your signature. Earlier signature emails sent today have been voided -- this is the active envelope. The DocuSign link below is valid for the full envelope lifetime (~120 days), so please review at your pace.

WHAT CHANGED FROM REV 2 TO REV 3
================================

Fleet (10 Apple endpoints + 10 personal phones):
- 4 Mac Minis (2 already onboarded - Phase 1 config-cleanup pass; 2 new) + 6 MacBook Neos
- 10 personally-owned cell phones via Intune BYOD: iOS via Apple Business Manager User Enrollment, Android via Intune work profile. Selective wipe only - personal data never touched.
- Offboarding 4 legacy devices: MACBOOK-PRO-4, KIKI, LEON, MAGGIE (NIST SP 800-88 wipe + chain-of-custody).

Final endpoint stack: ManageEngine Patch Management (PMMAC), CrowdStrike Falcon for Mac, Huntress macOS, CloudBrink ZTNA, Teramind / MyAudit UAM+DLP, My Remote.
Removed from prior draft: Cisco Umbrella, SSO/2FA gateway, Credential Manager.

ONE-TIME LABOR
==============
87 hours / $6,855.00 (50/25/25 milestones: $3,427.50 / $1,713.75 / $1,713.75)

MONTHLY SCHEDULE A
==================
Signed $2,794.50/mo -> Proposed $3,726.50/mo (delta: +$932.00/mo)
All line-item pricing maps to the Technijian Services Price List (Appendix A, rev 2026-03-23). CloudBrink licensing remains AFFG-procured (excluded from Schedule A). Intune for Macs and BYOD phones is included in your existing M365 E3 - no additional charge.

LEGAL TERMS (EXHIBIT A)
=======================
Section 2.05 - Operational Continuity Materials (new): admin/root credentials, DNS control, break-glass info, life-safety system info, and regulatorily-retained data must transfer to AFFG within 5 business days regardless of payment status. This is client-protective - your operations are never held hostage to a billing dispute.
Section 9.09 - Recruiting Cost Reimbursement (rewritten): documented out-of-pocket recruiting costs only, capped at $25,000 per individual, with explicit Cal. Bus. & Prof. Code Sec. 16600 acknowledgment and an employee-initiated-contact carve-out.
Section 12.08 - Template Currency Acknowledgment (new): Technijian's outside legal counsel review of the 2026 MSA framework is in progress. Either party may propose conforming edits to Exhibit A within 60 days of signature; Exhibit A is fully effective on execution either way.

Section 12 incorporation of the 2026 MSA framework into your signed Monthly Service Agreement is preserved unchanged in concept - only the Section 2.05, Section 9.09, and the new Section 12.08 text differs from Rev 2.

Happy to walk through anything before you sign - 15-minute call any time.

-- Ravi Jain, Technijian
'@

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
Write-Host "DocuSign auth OK. Base URI: $baseUri" -ForegroundColor Green

# --- Void the broken envelope (5-min URL one) ---
try {
    $voidBody = @{ status = "voided"; voidedReason = "Replaced with persistent-URL Rev 3 envelope" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$apiUrl/envelopes/$BrokenEnvelopeId" -Method PUT -Headers $hJ -Body $voidBody | Out-Null
    Write-Host "Voided broken envelope: $BrokenEnvelopeId" -ForegroundColor Yellow
} catch {
    Write-Host "Could not void $BrokenEnvelopeId (may already be in non-voidable state): $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# --- Create draft envelope (NO clientUserId - persistent URL, DocuSign sends native email) ---
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
Write-Host "Draft envelope created (no clientUserId): $envelopeId" -ForegroundColor Green

# --- Place tabs via ANCHORS (matches the 8 hidden DocuSign anchors in the docx body) ---
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
Write-Host "Tabs placed via 8 anchors (/tSign/ /tName/ /tTitle/ /tDate/ + /cSign/ /cName/ /cTitle/ /cDate/)" -ForegroundColor Green

# --- Send envelope ---
Invoke-RestMethod -Uri "$apiUrl/envelopes/$envelopeId" -Method PUT -Headers $hJ -Body (@{ status = "sent" } | ConvertTo-Json) | Out-Null

# --- Persist envelope id ---
Set-Content -Path (Join-Path $scriptDir "affg-sow004-rev3-final-envelope-id.txt") -Value $envelopeId -Encoding UTF8

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " ENVELOPE SENT (DocuSign native email + persistent URL)" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Envelope ID  : $envelopeId"
Write-Host "Voided       : $BrokenEnvelopeId"
Write-Host "URL lifetime : ~120 days (envelope lifetime)"
Write-Host "Placement    : Anchors (correct pages, right under sig labels)"
Write-Host "Recipients   : Iris Liu (CCO) + Ravi Jain - both via DocuSign native email"
Write-Host "Email subject: $EmailSubject"
