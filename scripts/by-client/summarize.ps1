# summarize.ps1
# Print per-client document counts and total stats for the new FileCabinet structure.

param(
    [string]$Root = "C:\Users\rjain\OneDrive - Technijian, Inc\Technijian Legal - Documents\FileCabinet-new"
)

if (-not (Test-Path $Root)) { Write-Host "Root not found: $Root"; exit 1 }

$clients = Get-ChildItem -Path $Root -Directory | Sort-Object Name
$total = 0
$totalCert = 0

Write-Host ""
Write-Host "Per-client breakdown:" -ForegroundColor Cyan
Write-Host ("{0,-18} {1,7} {2,7} {3,12}" -f 'Client','Signed','Certs','Size MB')
Write-Host ('-' * 50)

foreach ($c in $clients) {
    $signed = @(Get-ChildItem -Path $c.FullName -Filter '*.pdf' | Where-Object { $_.Name -notmatch '_certificate\.pdf$' })
    $certs  = @(Get-ChildItem -Path $c.FullName -Filter '*_certificate.pdf')
    $sizeMb = [math]::Round((($signed + $certs) | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    $total += $signed.Count
    $totalCert += $certs.Count
    Write-Host ("{0,-18} {1,7} {2,7} {3,12}" -f $c.Name, $signed.Count, $certs.Count, $sizeMb)
}

Write-Host ('-' * 50)
Write-Host ("{0,-18} {1,7} {2,7}" -f 'TOTAL', $total, $totalCert)
Write-Host ""

# Aggregate from all log CSVs
$logs = Get-ChildItem -Path $PSScriptRoot -Filter 'export-byclient-log-*.csv'
if ($logs) {
    $allLog = $logs | ForEach-Object { Import-Csv $_.FullName }
    $doneCount  = @($allLog | Where-Object { $_.Status -eq 'done' }).Count
    $errCount   = @($allLog | Where-Object { $_.Status -eq 'error' }).Count
    Write-Host "From log files:" -ForegroundColor Cyan
    Write-Host "  Done    : $doneCount"
    Write-Host "  Errors  : $errCount"
    if ($errCount -gt 0) {
        Write-Host ""
        Write-Host "Errors:" -ForegroundColor Yellow
        $allLog | Where-Object { $_.Status -eq 'error' } | ForEach-Object {
            Write-Host "  [$($_.EnvelopeId.Substring(0,8))] $($_.Subject) -> $($_.Error)"
        }
    }
}
