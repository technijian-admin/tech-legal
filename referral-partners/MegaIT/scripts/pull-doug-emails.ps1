# Pull all emails to/from Douglas McGaugh (doug@megait.us) into MegaIT folder
# Saves .eml files with normalized YYYY-MM-DD_HHMM filename prefix.

$ErrorActionPreference = "Stop"

$inboxDir = "C:\vscode\tech-legal\tech-legal\subcontractors\MegaIT\emails\inbox"
$sentDir  = "C:\vscode\tech-legal\tech-legal\subcontractors\MegaIT\emails\sent"
$indexCsv = "C:\vscode\tech-legal\tech-legal\subcontractors\MegaIT\emails\_index.csv"
$peer     = "doug@megait.us"
$userId   = "RJain@technijian.com"

Write-Host "Reading credentials..." -ForegroundColor Cyan
$keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null
Write-Host "Connected." -ForegroundColor Green

# Use Invoke-MgGraphRequest for $value (raw MIME)

function Save-EmlByGraph {
    param($MessageId, $TargetPath, $Subject)
    $url = "https://graph.microsoft.com/v1.0/users/$userId/messages/$MessageId/`$value"
    try {
        Invoke-MgGraphRequest -Method GET -Uri $url -OutputFilePath $TargetPath -ErrorAction Stop
        return $true
    } catch {
        Write-Host "  ! Failed to save $Subject : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Sanitize-Filename {
    param($s)
    if (-not $s) { return "no-subject" }
    $s -replace '[\\\/\:\*\?\"\<\>\|]', '_' -replace '\s+', '_' | Out-Null
    $clean = $s -replace '[\\\/\:\*\?\"\<\>\|]', '_' -replace '\s+', '_'
    if ($clean.Length -gt 80) { $clean = $clean.Substring(0,80) }
    return $clean
}

$indexRows = New-Object System.Collections.ArrayList

# RECEIVED — from Doug to Ravi (use -Search; -Filter on `from` triggers InefficientFilter)
Write-Host "`nFetching RECEIVED messages from $peer..." -ForegroundColor Cyan
$searchFrom = "from:$peer"
$rawReceived = Get-MgUserMessage -UserId $userId -Search "`"$searchFrom`"" -Top 999 -Property "id,subject,receivedDateTime,from,toRecipients,ccRecipients,bodyPreview"
# Search returns broader matches; tighten to actual sender match
$received = $rawReceived | Where-Object { $_.From.EmailAddress.Address -eq $peer } | Sort-Object ReceivedDateTime
Write-Host "  Found $($received.Count) received message(s)." -ForegroundColor Gray

foreach ($m in $received) {
    $ts = ([datetime]$m.ReceivedDateTime).ToString("yyyy-MM-dd_HHmm")
    $subj = Sanitize-Filename $m.Subject
    $name = "${ts}_FROM_doug_${subj}.eml"
    $path = Join-Path $inboxDir $name
    $ok = Save-EmlByGraph -MessageId $m.Id -TargetPath $path -Subject $m.Subject
    if ($ok) {
        Write-Host "  [+] $name" -ForegroundColor Gray
        $cc = ($m.CcRecipients | ForEach-Object { $_.EmailAddress.Address }) -join ";"
        $to = ($m.ToRecipients | ForEach-Object { $_.EmailAddress.Address }) -join ";"
        [void]$indexRows.Add([PSCustomObject]@{
            Direction = "RECEIVED"
            DateUTC   = $m.ReceivedDateTime
            From      = $m.From.EmailAddress.Address
            To        = $to
            Cc        = $cc
            Subject   = $m.Subject
            Preview   = ($m.BodyPreview -replace "[\r\n]+", " ").Substring(0, [Math]::Min(140, $m.BodyPreview.Length))
            File      = $name
        })
    }
}

# SENT — Ravi sent to Doug (use Search across mailbox; Sent Items will be in result)
Write-Host "`nFetching SENT messages where $peer was a recipient..." -ForegroundColor Cyan
$searchTo = "to:$peer"
$rawSent = Get-MgUserMessage -UserId $userId -Search "`"$searchTo`"" -Top 999 -Property "id,subject,sentDateTime,receivedDateTime,from,toRecipients,ccRecipients,bodyPreview,parentFolderId"
# Filter to: Ravi sent (from is rjain) AND peer is in recipients
$sentToDoug = $rawSent | Where-Object {
    $_.From.EmailAddress.Address -eq $userId -and
    (
        ($_.ToRecipients | Where-Object { $_.EmailAddress.Address -eq $peer }) -or
        ($_.CcRecipients | Where-Object { $_.EmailAddress.Address -eq $peer })
    )
} | Sort-Object SentDateTime
Write-Host "  Found $($sentToDoug.Count) sent message(s) addressed to $peer." -ForegroundColor Gray

foreach ($m in $sentToDoug) {
    $ts = ([datetime]$m.SentDateTime).ToString("yyyy-MM-dd_HHmm")
    $subj = Sanitize-Filename $m.Subject
    $name = "${ts}_TO_doug_${subj}.eml"
    $path = Join-Path $sentDir $name
    $ok = Save-EmlByGraph -MessageId $m.Id -TargetPath $path -Subject $m.Subject
    if ($ok) {
        Write-Host "  [+] $name" -ForegroundColor Gray
        $cc = ($m.CcRecipients | ForEach-Object { $_.EmailAddress.Address }) -join ";"
        $to = ($m.ToRecipients | ForEach-Object { $_.EmailAddress.Address }) -join ";"
        [void]$indexRows.Add([PSCustomObject]@{
            Direction = "SENT"
            DateUTC   = $m.SentDateTime
            From      = $m.From.EmailAddress.Address
            To        = $to
            Cc        = $cc
            Subject   = $m.Subject
            Preview   = ($m.BodyPreview -replace "[\r\n]+", " ").Substring(0, [Math]::Min(140, $m.BodyPreview.Length))
            File      = $name
        })
    }
}

# Write CSV index
Write-Host "`nWriting index to $indexCsv..." -ForegroundColor Cyan
$indexRows | Sort-Object DateUTC | Export-Csv -Path $indexCsv -NoTypeInformation
Write-Host "Done. Total messages: $($indexRows.Count)" -ForegroundColor Green

Disconnect-MgGraph | Out-Null
