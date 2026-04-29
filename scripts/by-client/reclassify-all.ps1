# reclassify-all.ps1
#
# Comprehensive reclassification pass. Walks ALL pdf files in FileCabinet-new
# (regardless of which folder the worker put them in) and re-routes them based on:
#   1. Internal HR pattern (offer letter, NDA, etc.) -> TECHNIJIAN
#   2. Active client name pattern (e.g., "International Sportsmedicine" -> ISI)
#   3. Subject parse for company name -> ARCHIVED-<Company>
#   4. Else stay where it is (likely UNCLASSIFIED)
#
# This corrects the worker's mistake of routing client docs to TECHNIJIAN
# when the client uses gmail/yahoo personal emails.

param(
    [string]$Root        = "C:\Users\rjain\OneDrive - Technijian, Inc\Technijian Legal - Documents\FileCabinet-new",
    [string]$PatternsFile = (Join-Path $PSScriptRoot 'client-name-patterns.json'),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Root))         { throw "Root not found: $Root" }
if (-not (Test-Path $PatternsFile)) { throw "Patterns file not found: $PatternsFile" }

$patterns = Get-Content $PatternsFile -Raw | ConvertFrom-Json
$clientPatterns   = @($patterns.patterns)
$internalPatterns = @($patterns.internal_patterns | ForEach-Object { $_.ToLower() })

# Active client codes that can also appear as standalone tokens in subject/filename
# (e.g., "MGN-Estimate-CP-XXX" is from Magnespec)
$shortCodes = @(
    'AAVA','ACU','AFFG','ALE','ALG','AMP','ANI','AOC','ART','ASC','AYH',
    'B2I','BBC','BBE','BBTS','BRM','BST','BWH',
    'CAM','CBI','CBL','CCC','COB','CPM','CSS',
    'DTS','EAG','EBRMD','FAL','FOR','GRF','GSD',
    'HHOC','HIT','ICML','ISI','JDH','JSD',
    'KCC','KEI','KES','KRLMD','KSS',
    'LAG','LODC','MAX','MGN','MRM','MSW',
    'NAC','NOR','OKL','ONE','ORX',
    'PCAP','PCM','PMF',
    'RALF','RBS','RKEG','RMG','RSPMD',
    'SAS','SGC','SSCI','STW','SVE',
    'TALY','TCH','TOR','TSC',
    'USFI','VAF','VG','VWC','WCS'
)

# Build envelope-id -> subject map from log CSVs
$logs = Get-ChildItem -Path $PSScriptRoot -Filter 'export-byclient-log-*.csv'
$subjectByEnv = @{}
foreach ($log in $logs) {
    Import-Csv $log.FullName | ForEach-Object {
        if ($_.EnvelopeId -and $_.Subject) { $subjectByEnv[$_.EnvelopeId.Substring(0,8)] = $_.Subject }
        if ($_.EnvelopeId -and $_.DocName -and -not $subjectByEnv.ContainsKey($_.EnvelopeId.Substring(0,8))) {
            $subjectByEnv[$_.EnvelopeId.Substring(0,8)] = $_.DocName
        }
    }
}
Write-Host "Loaded $($subjectByEnv.Count) envelope subjects from log files"

function Test-Internal {
    param([string]$Text)
    # Normalize underscores -> spaces so older "Offer_Letter" matches "offer letter" patterns
    $t = ($Text -replace '_',' ' -replace '\s+',' ').ToLower()
    foreach ($p in $internalPatterns) {
        if ($t -match [regex]::Escape($p)) { return $true }
    }
    return $false
}

function Match-ClientPattern {
    param([string]$Text)
    foreach ($entry in $clientPatterns) {
        if ($Text -match "(?i)$($entry.match)") { return $entry.code }
    }
    return $null
}

function Parse-Company {
    param([string]$Text)
    if (-not $Text) { return $null }
    $clean = $Text -replace '^Complete with Docusign:\s*',''
    $clean = $clean -replace '^Please sign this\s+',''
    $clean = $clean -replace '\.(pdf|docx?|xlsx?|pptx?|txt|rtf)$',''
    # Normalize underscores -> spaces so the parser handles old portal naming
    $clean = $clean -replace '_',' '
    $clean = ($clean -replace '\s+',' ').Trim()
    if ($clean -match '^([^-]+?)[\s-]+(Estimate|Monthly\s+Service|Hourly\s+Rate|Invoice|Quote|SOW|Proposal|Contract|Agreement|MSA|NDA|MasterServiceAgreement|InvoiceAuth|CP-\d+)') {
        $company = $matches[1].Trim()
        return $company
    }
    return $null
}

function Get-SafeFolderName {
    param([string]$s, [int]$max = 60)
    if (-not $s) { return $null }
    $s = $s -replace '[\\/:*?"<>|#%&{}+`=@!$\x00-\x1F]', ''
    $s = ($s -replace '\s+',' ').Trim()
    if ($s.Length -gt $max) { $s = $s.Substring(0,$max).TrimEnd() }
    if (-not $s) { return $null }
    $s
}

# Walk all files
$allFiles = Get-ChildItem -Path $Root -Recurse -Filter '*.pdf' | Where-Object {
    $_.Name -notmatch '_certificate\.pdf$'
}

$plan = @{}        # destFolder -> @(file, ...)
$noChange = 0
$totalScanned = 0

foreach ($f in $allFiles) {
    $totalScanned++
    $currentFolder = $f.Directory.Name

    if ($f.BaseName -notmatch '_([0-9a-f]{8})$') { continue }
    $envIdShort = $matches[1]

    $subject = if ($subjectByEnv.ContainsKey($envIdShort)) { $subjectByEnv[$envIdShort] } else { '' }
    $docName = $f.BaseName -replace "_$envIdShort$",'' -replace '^\d{4}-\d{2}-\d{2}_',''
    # Normalize underscores -> spaces so "Via_Auto_Finance" matches "via auto finance"
    $combined = ("$subject $docName" -replace '_',' ' -replace '\s+',' ')

    # 1. Active client pattern match (catches misclassified clients with personal emails)
    $code = Match-ClientPattern -Text $combined
    if ($code) {
        if ($currentFolder -ne $code) {
            if (-not $plan.ContainsKey($code)) { $plan[$code] = @() }
            $plan[$code] += $f
        } else {
            $noChange++
        }
        continue
    }

    # 1b. Subject contains a standalone client code token (e.g., "MGN-Estimate-CP-XXX")
    $codeMatch = $null
    foreach ($sc in $shortCodes) {
        # Match $sc when bordered by non-letter (or start/end) — case-sensitive uppercase only
        if ($combined -cmatch "(?<![A-Z])$sc(?![A-Z])") { $codeMatch = $sc; break }
    }
    if ($codeMatch) {
        if ($currentFolder -ne $codeMatch) {
            if (-not $plan.ContainsKey($codeMatch)) { $plan[$codeMatch] = @() }
            $plan[$codeMatch] += $f
        } else {
            $noChange++
        }
        continue
    }

    # 2. Internal HR pattern → TECHNIJIAN
    if (Test-Internal -Text $combined) {
        if ($currentFolder -ne 'TECHNIJIAN') {
            if (-not $plan.ContainsKey('TECHNIJIAN')) { $plan['TECHNIJIAN'] = @() }
            $plan['TECHNIJIAN'] += $f
        } else {
            $noChange++
        }
        continue
    }

    # 3. Subject parse for company → ARCHIVED-<Company>
    $company = Parse-Company -Text $docName
    if (-not $company) { $company = Parse-Company -Text $subject }
    if ($company) {
        $folderName = Get-SafeFolderName "ARCHIVED-$company"
        if ($folderName -and $currentFolder -ne $folderName) {
            if (-not $plan.ContainsKey($folderName)) { $plan[$folderName] = @() }
            $plan[$folderName] += $f
        } else {
            $noChange++
        }
        continue
    }

    # 4. Otherwise leave as-is
    $noChange++
}

# Report
Write-Host ""
Write-Host "Scan complete:" -ForegroundColor Cyan
Write-Host "  Files scanned       : $totalScanned"
Write-Host "  Already in correct folder : $noChange"
Write-Host "  Files to relocate   : $(($plan.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum)"
Write-Host ""
Write-Host "Move plan:" -ForegroundColor Cyan
foreach ($k in ($plan.Keys | Sort-Object)) {
    Write-Host ("  -> {0,-50} {1,4}" -f $k, $plan[$k].Count)
}

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY-RUN — no files moved. Re-run without -DryRun to apply." -ForegroundColor Yellow
    exit 0
}

# Execute moves
Write-Host ""
Write-Host "Applying moves..." -ForegroundColor Yellow
$moved = 0
foreach ($destFolder in $plan.Keys) {
    $destPath = Join-Path $Root $destFolder
    New-Item -ItemType Directory -Path $destPath -Force | Out-Null
    foreach ($f in $plan[$destFolder]) {
        Move-Item -Path $f.FullName -Destination (Join-Path $destPath $f.Name) -Force
        $certName = ($f.BaseName + '_certificate.pdf')
        $certPath = Join-Path $f.Directory.FullName $certName
        if (Test-Path $certPath) {
            Move-Item -Path $certPath -Destination (Join-Path $destPath $certName) -Force
        }
        $moved++
    }
}

# Clean up empty folders
$emptyDirs = Get-ChildItem -Path $Root -Directory | Where-Object {
    -not (Get-ChildItem -Path $_.FullName -File -ErrorAction SilentlyContinue)
}
foreach ($d in $emptyDirs) {
    Remove-Item -Path $d.FullName -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "  Removed empty folder: $($d.Name)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "DONE - Moved $moved files (+ matching certificates)" -ForegroundColor Green
