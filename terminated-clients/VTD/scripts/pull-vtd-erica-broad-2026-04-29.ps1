# Broader Erica/Vintage capture — searches billing@technijian.com for any inbound from
# "Erica Garcia" (name) or "vintagedesigninc.com" (domain), not just ericagarcia@vintagedesigninc.com.
# Idempotent: skips files already saved.

$ErrorActionPreference = "Stop"

$vtdDir         = "C:\vscode\tech-legal\tech-legal\terminated-clients\vtd"
$ericaDir       = Join-Path $vtdDir "emails\erica_garcia"
$ericaAttachDir = Join-Path $vtdDir "emails\erica_garcia\_attachments"
$manifestPath   = Join-Path $vtdDir "emails\_capture_manifest_erica_broad_2026-04-29.csv"

New-Item -ItemType Directory -Force -Path $ericaDir       | Out-Null
New-Item -ItemType Directory -Force -Path $ericaAttachDir | Out-Null

# --- Credentials ---
$m365Keys     = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

$secureSecret = ConvertTo-SecureString $m365Secret -AsPlainText -Force
$credential   = New-Object System.Management.Automation.PSCredential($m365ClientId, $secureSecret)
Connect-MgGraph -TenantId $m365TenantId -ClientSecretCredential $credential -NoWelcome

function Sanitize-Filename {
    param([string]$s)
    if (-not $s) { return "unknown" }
    $s = $s -replace '[\\/:*?"<>|]', '_'
    $s = $s -replace '\s+', ' '
    if ($s.Length -gt 120) { $s = $s.Substring(0, 120) }
    return $s.Trim()
}

function Save-EmailAsEml {
    param([string]$UserId, [string]$MessageId, [string]$OutPath)
    if (Test-Path $OutPath) { return $false }
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/messages/$MessageId/`$value"
    Invoke-MgGraphRequest -Method GET -Uri $uri -OutputFilePath $OutPath
    return $true
}

function Save-Attachments {
    param([string]$UserId, [string]$MessageId, [string]$DateStr, [string]$AttachDir)
    $savedNames = @()
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/messages/$MessageId/attachments"
    try { $resp = Invoke-MgGraphRequest -Method GET -Uri $uri } catch { return $savedNames }
    foreach ($a in $resp.value) {
        if ($a.'@odata.type' -ne '#microsoft.graph.fileAttachment') { continue }
        if (-not $a.contentBytes) { continue }
        $attName = Sanitize-Filename $a.name
        $outName = "${DateStr}_${attName}"
        $outFile = Join-Path $AttachDir $outName
        if (Test-Path $outFile) { $savedNames += $outName; continue }
        try {
            $bytes = [Convert]::FromBase64String($a.contentBytes)
            [IO.File]::WriteAllBytes($outFile, $bytes)
            $savedNames += $outName
        } catch {}
    }
    return $savedNames
}

# Multiple search strategies in billing@technijian.com
$queries = @(
    'from:vintagedesigninc.com',
    '"Erica Garcia"',
    '"vintagedesigninc.com"',
    'from:erica',
    'from:egarcia'
)

$mbox = "billing@technijian.com"
$manifest = New-Object System.Collections.Generic.List[object]
$seenIds = New-Object System.Collections.Generic.HashSet[string]

foreach ($q in $queries) {
    Write-Host ""
    Write-Host "=== Search: $q in $mbox ===" -ForegroundColor Cyan
    $encQ = [uri]::EscapeDataString('"' + $q + '"')
    $pageUri = "https://graph.microsoft.com/v1.0/users/$mbox/messages?`$search=$encQ&`$top=100&`$select=id,subject,from,toRecipients,ccRecipients,sentDateTime,receivedDateTime,hasAttachments,internetMessageId"

    $cnt = 0; $sv = 0; $sk = 0
    do {
        try {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $pageUri -Headers @{ ConsistencyLevel = "eventual" }
        } catch {
            Write-Host "  Error: $_" -ForegroundColor Red
            break
        }
        foreach ($m in $resp.value) {
            if ($seenIds.Contains($m.id)) { continue }
            $null = $seenIds.Add($m.id)

            $fromAddr = $m.from.emailAddress.address
            $fromName = $m.from.emailAddress.name
            # Filter: must be from Erica or from vintagedesigninc.com domain
            if (-not $fromAddr) { continue }
            $isVintage = ($fromAddr.ToLower().EndsWith('@vintagedesigninc.com')) -or
                         ($fromName -and $fromName.ToLower().Contains('erica garcia'))
            if (-not $isVintage) { continue }

            $cnt++
            $dt = $m.receivedDateTime
            if (-not $dt) { $dt = $m.sentDateTime }
            $dateStr = ([datetime]$dt).ToString("yyyy-MM-dd_HHmm")
            $subj = Sanitize-Filename $m.subject
            $fileName = "${dateStr}_billing_${subj}.eml"
            $outPath = Join-Path $ericaDir $fileName
            $wasSaved = Save-EmailAsEml -UserId $mbox -MessageId $m.id -OutPath $outPath
            if ($wasSaved) { $sv++; Write-Host "  saved  $fileName" -ForegroundColor Gray }
            else { $sk++ }
            $attachNames = @()
            if ($m.hasAttachments) {
                $attachNames = Save-Attachments -UserId $mbox -MessageId $m.id -DateStr $dateStr -AttachDir $ericaAttachDir
            }
            $toAddrs = @(); foreach ($r in $m.toRecipients) { $toAddrs += $r.emailAddress.address }
            $ccAddrs = @(); foreach ($r in $m.ccRecipients) { $ccAddrs += $r.emailAddress.address }
            $manifest.Add([pscustomobject]@{
                Query    = $q
                Date     = $dt
                From     = $fromAddr
                FromName = $fromName
                To       = ($toAddrs -join '; ')
                Cc       = ($ccAddrs -join '; ')
                Subject  = $m.subject
                HasAttachments  = $m.hasAttachments
                AttachmentCount = $attachNames.Count
                AttachmentNames = ($attachNames -join '; ')
                File     = $fileName
            })
        }
        $pageUri = $resp.'@odata.nextLink'
    } while ($pageUri)

    Write-Host ("  Query '$q': matched-vintage {0}, saved-new {1}, skipped {2}" -f $cnt, $sv, $sk) -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Total unique vintage senders found: $($manifest.Count) ===" -ForegroundColor Yellow

$manifest | Sort-Object Date | Export-Csv -Path $manifestPath -NoTypeInformation -Encoding UTF8
Write-Host "Manifest: $manifestPath" -ForegroundColor Green

# Also report distinct sender addresses found
Write-Host ""
Write-Host "Distinct sender addresses from vintagedesigninc.com / Erica Garcia:" -ForegroundColor Yellow
$manifest | Group-Object From | Sort-Object Count -Descending | Format-Table Count, Name -AutoSize

Disconnect-MgGraph | Out-Null
