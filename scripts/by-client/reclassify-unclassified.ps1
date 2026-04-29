# reclassify-unclassified.ps1
#
# Post-pass that reorganizes the UNCLASSIFIED bucket into per-company subfolders
# by parsing the original envelope subject from the export log CSVs.
#
# Pattern: "Company Name-Estimate-CP-NNNNN" or "Company_Name-Monthly_Service"
# Companies become "ARCHIVED-<Company-Name>" folders alongside active clients.

param(
    [string]$Root = "C:\Users\rjain\OneDrive - Technijian, Inc\Technijian Legal - Documents\FileCabinet-new"
)

$ErrorActionPreference = 'Stop'

$unclassDir = Join-Path $Root 'UNCLASSIFIED'
if (-not (Test-Path $unclassDir)) {
    Write-Host "No UNCLASSIFIED folder found at $unclassDir"
    exit 0
}

# Build envelope-id -> subject map from all log CSVs
$logs = Get-ChildItem -Path $PSScriptRoot -Filter 'export-byclient-log-*.csv'
$subjectByEnv = @{}
foreach ($log in $logs) {
    Import-Csv $log.FullName | ForEach-Object {
        if ($_.EnvelopeId -and $_.Subject) { $subjectByEnv[$_.EnvelopeId] = $_.Subject }
    }
}

function Parse-Company {
    param([string]$Subject, [string]$DocName)
    foreach ($s in @($DocName, $Subject)) {
        if (-not $s) { continue }
        # Remove common DocuSign envelope prefixes first
        $clean = $s -replace '^Complete with Docusign:\s*',''
        $clean = $clean -replace '^Please sign this\s+',''
        # Strip filename extension if present
        $clean = $clean -replace '\.(pdf|docx?|xlsx?|pptx?|txt|rtf)$',''
        # Match "Company-DocType-..." or "Company_DocType_..."
        if ($clean -match '^([^-_]+(?:[-_][^-_]+)*?)[\s_-]+(Estimate|Monthly[\s_]+Service|Hourly[\s_]+Rate|Invoice|Quote|SOW|Proposal|Contract|Agreement|MSA|NDA|MasterServiceAgreement|InvoiceAuth|CP)') {
            $company = $matches[1] -replace '_',' '
            $company = $company -replace '\s+',' '
            $company = $company.Trim()
            return $company
        }
    }
    return $null
}

function Is-InternalDoc {
    param([string]$Subject, [string]$DocName)
    $combined = "$Subject $DocName".ToLower()
    $patterns = @(
        'job offer',
        'offer letter',
        'appointment letter',
        'confirmation letter',
        'confiramtion letter',
        'employee handbook',
        'increment letter',
        'warning letter',
        'termination letter',
        'exit letter',
        'separation letter',
        'resignation letter',
        'nda technijian',
        'technijian nda',
        'salary slip',
        'pay slip'
    )
    foreach ($p in $patterns) {
        if ($combined -match [regex]::Escape($p)) { return $true }
    }
    return $false
}

function Get-SafeFolderName {
    param([string]$s, [int]$max = 60)
    if (-not $s) { return $null }
    $s = $s -replace '[\\/:*?"<>|#%&{}+`=@!$\x00-\x1F]', ''
    $s = $s -replace '\s+',' '
    $s = $s.Trim()
    if ($s.Length -gt $max) { $s = $s.Substring(0,$max).TrimEnd() }
    if (-not $s) { return $null }
    $s
}

# Walk UNCLASSIFIED files, extract envelope id from filename suffix
$files = Get-ChildItem -Path $unclassDir -Filter '*.pdf'
$moved = 0
$kept  = 0
$grouped = @{}

foreach ($f in $files) {
    # Skip certificates - they'll move with their parent doc
    if ($f.Name -match '_certificate\.pdf$') { continue }

    # Filename format: <date>_<docname>_<envid8>.pdf
    if ($f.BaseName -match '_([0-9a-f]{8})$') {
        $envIdShort = $matches[1]
        $matchEnv = $subjectByEnv.Keys | Where-Object { $_.StartsWith($envIdShort) } | Select-Object -First 1
        $subject = if ($matchEnv) { $subjectByEnv[$matchEnv] } else { '' }

        # Also extract docname from filename for parsing fallback
        $docName = $f.BaseName -replace "_$envIdShort$",'' -replace '^\d{4}-\d{2}-\d{2}_',''

        # First check: is this an internal HR doc misclassified as UNCLASSIFIED?
        if (Is-InternalDoc -Subject $subject -DocName $docName) {
            $folderName = 'TECHNIJIAN'
            if (-not $grouped.ContainsKey($folderName)) { $grouped[$folderName] = @() }
            $grouped[$folderName] += $f
            continue
        }

        $company = Parse-Company -Subject $subject -DocName $docName
        if ($company) {
            $folderName = Get-SafeFolderName "ARCHIVED-$company"
            if ($folderName) {
                if (-not $grouped.ContainsKey($folderName)) { $grouped[$folderName] = @() }
                $grouped[$folderName] += $f
                continue
            }
        }
    }
    $kept++
}

# Execute moves
foreach ($folderName in $grouped.Keys) {
    $destDir = Join-Path $Root $folderName
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    foreach ($f in $grouped[$folderName]) {
        # Move signed file
        Move-Item -Path $f.FullName -Destination (Join-Path $destDir $f.Name) -Force
        # Move companion certificate file
        $certName = ($f.BaseName + '_certificate.pdf')
        $certPath = Join-Path $unclassDir $certName
        if (Test-Path $certPath) {
            Move-Item -Path $certPath -Destination (Join-Path $destDir $certName) -Force
        }
        $moved++
    }
}

Write-Host ""
Write-Host "Reclassification complete:" -ForegroundColor Cyan
Write-Host "  Moved into ARCHIVED-* folders : $moved"
Write-Host "  Stayed in UNCLASSIFIED         : $kept"
Write-Host ""
Write-Host "Per-archive-folder counts:" -ForegroundColor Cyan
foreach ($k in ($grouped.Keys | Sort-Object)) {
    Write-Host ("  {0,-50} {1,4}" -f $k, $grouped[$k].Count)
}
