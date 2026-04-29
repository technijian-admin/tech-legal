# Upload VTD billing attachment files to Frank Dunn's ShareFile data room request links.
# Monthly invoices -> monthly link; Weekly statements -> weekly link.
# Uses ShareFile public request-link upload API (no OAuth required).
# Idempotent: tracks uploaded files in a log and skips duplicates.

$ErrorActionPreference = "Stop"

# --- ShareFile request link IDs (parsed from Frank's email) ---
# https://callahan-law.sharefile.com/r-rc69bb0be5c304d06b836f2bdbf7027b1
# https://callahan-law.sharefile.com/r-re4180310375049dcad39eb2d7b25590f
$SF_SUBDOMAIN   = "callahan-law"
$SF_API_BASE    = "https://$SF_SUBDOMAIN.sf-api.com"
$REQUEST_MONTHLY = "c69bb0be5c304d06b836f2bdbf7027b1"
$REQUEST_WEEKLY  = "e4180310375049dcad39eb2d7b25590f"

$vtdDir      = "C:\vscode\tech-legal\tech-legal\terminated-clients\vtd"
$attachDir   = Join-Path $vtdDir "emails\billing_sent\_attachments"
$manifestPath= Join-Path $vtdDir "emails\_capture_manifest_2026-04-28.csv"
$logPath     = Join-Path $vtdDir "emails\_sharefile_upload_log_2026-04-29.csv"

# --- Load manifest and build date-prefix -> category map ---
$manifest = Import-Csv $manifestPath

$prefixMap = @{}
foreach ($row in $manifest) {
    if (-not $row.Date -or -not $row.File) { continue }
    try {
        $dt = [datetime]$row.Date
        $prefix = $dt.ToString("yyyy-MM-dd_HHmm")
        $subj = $row.Subject
        if ($subj -match "Weekly|weekly") {
            $prefixMap[$prefix] = "weekly"
        } else {
            # Monthly Invoice, plain Invoice (monthly support), or Monthly: all go to monthly
            $prefixMap[$prefix] = "monthly"
        }
    } catch {}
}

Write-Host "Loaded $($prefixMap.Count) date-prefix mappings from manifest." -ForegroundColor Cyan

# --- Load upload log (idempotency) ---
$uploaded = New-Object System.Collections.Generic.HashSet[string]
$uploadLog = New-Object System.Collections.Generic.List[object]
if (Test-Path $logPath) {
    $existingLog = Import-Csv $logPath
    foreach ($r in $existingLog) {
        $null = $uploaded.Add($r.FileName)
        $uploadLog.Add($r)
    }
    Write-Host "Resuming — $($uploaded.Count) files already uploaded (from log)." -ForegroundColor Yellow
}

# --- Helper: get ShareFile upload URI for a request link ---
function Get-SFUploadUri {
    param([string]$RequestId, [long]$FileSize, [string]$FileName)
    $uri = "$SF_API_BASE/sf/v3/FileRequests/$RequestId/Upload"
    $body = @{ Method = "Standard"; Raw = $false; FileSize = $FileSize } | ConvertTo-Json -Compress
    $resp = Invoke-RestMethod -Method POST -Uri $uri `
        -ContentType "application/json" -Body $body -UseBasicParsing
    return $resp
}

# --- Helper: upload a single file to a ChunkUri ---
function Upload-FileToSF {
    param([string]$ChunkUri, [string]$FilePath, [long]$FileSize)
    $finalUri = "$ChunkUri&index=0&offset=0&uploadsize=$FileSize&isLast=true&fmt=json"
    $boundary = [System.Guid]::NewGuid().ToString("N")
    $fname = [System.IO.Path]::GetFileName($FilePath)
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

    # Build multipart body manually
    $pre  = [System.Text.Encoding]::ASCII.GetBytes(
        "--$boundary`r`nContent-Disposition: form-data; name=`"File1`"; filename=`"$fname`"`r`nContent-Type: application/octet-stream`r`n`r`n"
    )
    $post = [System.Text.Encoding]::ASCII.GetBytes("`r`n--$boundary--`r`n")
    $body = New-Object byte[] ($pre.Length + $fileBytes.Length + $post.Length)
    [System.Buffer]::BlockCopy($pre, 0, $body, 0, $pre.Length)
    [System.Buffer]::BlockCopy($fileBytes, 0, $body, $pre.Length, $fileBytes.Length)
    [System.Buffer]::BlockCopy($post, 0, $body, $pre.Length + $fileBytes.Length, $post.Length)

    $resp = Invoke-RestMethod -Method POST -Uri $finalUri `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $body -UseBasicParsing
    return $resp
}

# --- Categorize and upload attachments ---
$files = Get-ChildItem $attachDir -File | Sort-Object Name
Write-Host "Found $($files.Count) attachment files to process." -ForegroundColor Cyan
Write-Host ""

$countMonthly = 0; $countWeekly = 0; $countSkipped = 0; $countError = 0

foreach ($f in $files) {
    if ($uploaded.Contains($f.Name)) {
        $countSkipped++
        continue
    }

    # Determine category from date prefix
    $prefix = ($f.Name -replace '^(\d{4}-\d{2}-\d{2}_\d{4}).*','$1')
    $category = $prefixMap[$prefix]
    if (-not $category) {
        # Fallback: if filename contains Weekly/monthly keywords
        if ($f.Name -match "Weekly") { $category = "weekly" }
        else { $category = "monthly" }
    }

    $requestId = if ($category -eq "weekly") { $REQUEST_WEEKLY } else { $REQUEST_MONTHLY }
    $fileSize  = $f.Length

    try {
        $uploadSpec = Get-SFUploadUri -RequestId $requestId -FileSize $fileSize -FileName $f.Name
        $chunkUri = $uploadSpec.ChunkUri
        if (-not $chunkUri) {
            throw "No ChunkUri in response: $($uploadSpec | ConvertTo-Json -Compress)"
        }

        $result = Upload-FileToSF -ChunkUri $chunkUri -FilePath $f.FullName -FileSize $fileSize

        if ($category -eq "weekly") { $countWeekly++ } else { $countMonthly++ }
        $null = $uploaded.Add($f.Name)
        $uploadLog.Add([pscustomobject]@{
            FileName = $f.Name
            Category = $category
            SizeBytes= $fileSize
            Status   = "OK"
            Timestamp= (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        })
        $color = if ($category -eq "weekly") { "DarkGray" } else { "Gray" }
        Write-Host "  [$category] $($f.Name)" -ForegroundColor $color
    } catch {
        $countError++
        Write-Host "  [ERROR] $($f.Name) : $_" -ForegroundColor Red
        $uploadLog.Add([pscustomobject]@{
            FileName = $f.Name
            Category = $category
            SizeBytes= $fileSize
            Status   = "ERROR: $_"
            Timestamp= (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        })
    }

    # Save log incrementally every 20 files
    if (($countMonthly + $countWeekly + $countError) % 20 -eq 0) {
        $uploadLog | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8 -Force
    }
}

# Final log save
$uploadLog | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8 -Force

Write-Host ""
Write-Host "=== Upload complete ===" -ForegroundColor Yellow
Write-Host "  Monthly uploaded : $countMonthly" -ForegroundColor Green
Write-Host "  Weekly  uploaded : $countWeekly" -ForegroundColor Green
Write-Host "  Skipped (already): $countSkipped" -ForegroundColor Cyan
Write-Host "  Errors           : $countError" -ForegroundColor Red
Write-Host "  Log: $logPath"
