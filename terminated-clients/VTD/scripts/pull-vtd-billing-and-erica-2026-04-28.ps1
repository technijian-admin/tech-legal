# Pull VTD-related emails from two sources for the repo data room:
#   1. billing@technijian.com SENT folder — subject starting with "VTD"
#   2. Any RJain@technijian.com or billing@technijian.com folder — from ericagarcia@vintagedesigninc.com
#
# Saves THREE things per email:
#   - Raw .eml (MIME) — preserves the full message including attachments inline
#   - Separately-extracted attachment files into _attachments/ — for direct upload to the data room
#     (data room previously only got bodies, not attachments — this fixes that)
#   - Manifest CSV listing each pulled email with metadata + attachment names
#
# Idempotent: skips files that already exist locally.

$ErrorActionPreference = "Stop"

$vtdDir          = "C:\vscode\tech-legal\tech-legal\terminated-clients\vtd"
$billingSentDir  = Join-Path $vtdDir "emails\billing_sent"
$billingAttachDir= Join-Path $vtdDir "emails\billing_sent\_attachments"
$ericaDir        = Join-Path $vtdDir "emails\erica_garcia"
$ericaAttachDir  = Join-Path $vtdDir "emails\erica_garcia\_attachments"
$manifestPath    = Join-Path $vtdDir "emails\_capture_manifest_2026-04-28.csv"

New-Item -ItemType Directory -Force -Path $billingSentDir   | Out-Null
New-Item -ItemType Directory -Force -Path $billingAttachDir | Out-Null
New-Item -ItemType Directory -Force -Path $ericaDir         | Out-Null
New-Item -ItemType Directory -Force -Path $ericaAttachDir   | Out-Null

# --- Credentials ---
Write-Host "Reading M365 Graph credentials..." -ForegroundColor Cyan
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

# --- Connect ---
$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome
Write-Host "Connected to Graph." -ForegroundColor Green

# --- Helpers ---
function Sanitize-Filename {
    param([string]$s)
    if (-not $s) { return "unknown" }
    $s = $s -replace '[\\/:*?"<>|]', '_'
    $s = $s -replace '\s+', ' '
    if ($s.Length -gt 120) { $s = $s.Substring(0, 120) }
    return $s.Trim()
}

function Save-EmailAsEml {
    param(
        [string]$UserId,
        [string]$MessageId,
        [string]$OutPath
    )
    if (Test-Path $OutPath) { return $false }  # idempotent
    # Graph $value endpoint returns raw MIME (RFC 822) — that's the .eml format
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/messages/$MessageId/`$value"
    Invoke-MgGraphRequest -Method GET -Uri $uri -OutputFilePath $OutPath
    return $true
}

function Save-Attachments {
    param(
        [string]$UserId,
        [string]$MessageId,
        [string]$DateStr,
        [string]$AttachDir
    )
    # Returns array of saved attachment filenames
    $savedNames = @()
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/messages/$MessageId/attachments"
    try {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    } catch {
        Write-Host "    (no attachments or error: $_)" -ForegroundColor DarkGray
        return $savedNames
    }
    foreach ($a in $resp.value) {
        if ($a.'@odata.type' -ne '#microsoft.graph.fileAttachment') { continue }
        if (-not $a.contentBytes) { continue }
        $attName = Sanitize-Filename $a.name
        $outName = "${DateStr}_${attName}"
        $outFile = Join-Path $AttachDir $outName
        if (Test-Path $outFile) {
            $savedNames += $outName
            continue
        }
        try {
            $bytes = [Convert]::FromBase64String($a.contentBytes)
            [IO.File]::WriteAllBytes($outFile, $bytes)
            $savedNames += $outName
            Write-Host "      attach -> $outName" -ForegroundColor DarkGray
        } catch {
            Write-Host "      ERROR saving attachment $attName : $_" -ForegroundColor Red
        }
    }
    return $savedNames
}

# --- Build manifest ---
$manifest = New-Object System.Collections.Generic.List[object]

# =====================================================================
# SOURCE 1: billing@technijian.com SENT — subject starts with "VTD"
# =====================================================================
Write-Host ""
Write-Host "=== Source 1: billing@technijian.com SENT folder (subject starts with VTD) ===" -ForegroundColor Cyan

$billingUser = "billing@technijian.com"
$pageUri = "https://graph.microsoft.com/v1.0/users/$billingUser/mailFolders/sentitems/messages?`$filter=startswith(subject,'VTD')&`$top=200&`$count=true&`$select=id,subject,from,toRecipients,ccRecipients,sentDateTime,receivedDateTime,hasAttachments,internetMessageId"

$count = 0
$saved = 0
$skipped = 0
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $pageUri -Headers @{ ConsistencyLevel = "eventual" }
    foreach ($m in $resp.value) {
        $count++
        $dt = $m.sentDateTime
        if (-not $dt) { $dt = $m.receivedDateTime }
        $dateStr = ([datetime]$dt).ToString("yyyy-MM-dd_HHmm")
        $subj = Sanitize-Filename $m.subject
        $fileName = "$dateStr`_$subj.eml"
        $outPath  = Join-Path $billingSentDir $fileName
        $wasSaved = Save-EmailAsEml -UserId $billingUser -MessageId $m.id -OutPath $outPath
        if ($wasSaved) {
            $saved++
            Write-Host "  saved  $fileName" -ForegroundColor Gray
        } else {
            $skipped++
        }
        # Always extract attachments (even if .eml already existed) — data room needs the standalone files
        $attachNames = @()
        if ($m.hasAttachments) {
            $attachNames = Save-Attachments -UserId $billingUser -MessageId $m.id -DateStr $dateStr -AttachDir $billingAttachDir
        }
        $toAddrs = @(); foreach ($r in $m.toRecipients) { $toAddrs += $r.emailAddress.address }
        $ccAddrs = @(); foreach ($r in $m.ccRecipients) { $ccAddrs += $r.emailAddress.address }
        $manifest.Add([pscustomobject]@{
            Source        = "billing_sent"
            Date          = $dt
            From          = $m.from.emailAddress.address
            To            = ($toAddrs -join '; ')
            Cc            = ($ccAddrs -join '; ')
            Subject       = $m.subject
            HasAttachments= $m.hasAttachments
            AttachmentCount = $attachNames.Count
            AttachmentNames = ($attachNames -join '; ')
            InternetId    = $m.internetMessageId
            File          = $fileName
            Folder        = "billing_sent"
        })
    }
    $pageUri = $resp.'@odata.nextLink'
} while ($pageUri)

Write-Host ("Source 1: found {0}, saved {1}, skipped (already present) {2}" -f $count, $saved, $skipped) -ForegroundColor Green

# =====================================================================
# SOURCE 2: emails FROM Erica Garcia — across RJain and billing mailboxes
# =====================================================================
Write-Host ""
Write-Host "=== Source 2: emails FROM ericagarcia@vintagedesigninc.com (RJain + billing mailboxes, all folders) ===" -ForegroundColor Cyan

$ericaAddr = "ericagarcia@vintagedesigninc.com"
$mailboxesToScan = @("RJain@technijian.com", "billing@technijian.com")

foreach ($mbox in $mailboxesToScan) {
    Write-Host ""
    Write-Host "  Scanning $mbox..." -ForegroundColor Cyan

    # Search across all folders in the mailbox via the user-level /messages endpoint
    $sub = "from:$ericaAddr"
    $encQ = [uri]::EscapeDataString('"' + $sub + '"')
    $pageUri = "https://graph.microsoft.com/v1.0/users/$mbox/messages?`$search=$encQ&`$top=100&`$select=id,subject,from,toRecipients,ccRecipients,sentDateTime,receivedDateTime,hasAttachments,internetMessageId,parentFolderId"

    $cnt = 0
    $sv  = 0
    $sk  = 0
    do {
        try {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $pageUri -Headers @{ ConsistencyLevel = "eventual" }
        } catch {
            Write-Host "    Error: $_" -ForegroundColor Red
            break
        }
        foreach ($m in $resp.value) {
            $fromAddr = $m.from.emailAddress.address
            if (-not $fromAddr) { continue }
            if ($fromAddr.ToLower() -ne $ericaAddr.ToLower()) { continue }  # tighten the search
            $cnt++
            $dt = $m.receivedDateTime
            if (-not $dt) { $dt = $m.sentDateTime }
            $dateStr = ([datetime]$dt).ToString("yyyy-MM-dd_HHmm")
            $subj = Sanitize-Filename $m.subject
            $mboxTag = $mbox -replace '@.*',''
            $fileName = "${dateStr}_${mboxTag}_${subj}.eml"
            $outPath = Join-Path $ericaDir $fileName
            $wasSaved = Save-EmailAsEml -UserId $mbox -MessageId $m.id -OutPath $outPath
            if ($wasSaved) {
                $sv++
                Write-Host "    saved  $fileName" -ForegroundColor Gray
            } else {
                $sk++
            }
            $attachNames = @()
            if ($m.hasAttachments) {
                $attachNames = Save-Attachments -UserId $mbox -MessageId $m.id -DateStr $dateStr -AttachDir $ericaAttachDir
            }
            $toAddrs = @(); foreach ($r in $m.toRecipients) { $toAddrs += $r.emailAddress.address }
            $ccAddrs = @(); foreach ($r in $m.ccRecipients) { $ccAddrs += $r.emailAddress.address }
            $manifest.Add([pscustomobject]@{
                Source        = "erica_${mboxTag}"
                Date          = $dt
                From          = $fromAddr
                To            = ($toAddrs -join '; ')
                Cc            = ($ccAddrs -join '; ')
                Subject       = $m.subject
                HasAttachments= $m.hasAttachments
                AttachmentCount = $attachNames.Count
                AttachmentNames = ($attachNames -join '; ')
                InternetId    = $m.internetMessageId
                File          = $fileName
                Folder        = "erica_garcia"
            })
        }
        $pageUri = $resp.'@odata.nextLink'
    } while ($pageUri)
    Write-Host ("  $mbox : found {0}, saved {1}, skipped {2}" -f $cnt, $sv, $sk) -ForegroundColor Green
}

# --- Save manifest ---
Write-Host ""
Write-Host "=== Writing manifest ===" -ForegroundColor Cyan
$manifest | Sort-Object Date | Export-Csv -Path $manifestPath -NoTypeInformation -Encoding UTF8
Write-Host "Manifest: $manifestPath  ($($manifest.Count) rows)" -ForegroundColor Green

Disconnect-MgGraph | Out-Null
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
