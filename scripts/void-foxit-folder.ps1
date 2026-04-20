# Void a Foxit eSign folder/envelope by folder name search
# Finds the most recent folder matching the name and cancels it.
#
# Usage: .\void-foxit-folder.ps1 -FolderNameContains "AFFG - SOW-004 Rev 1" -Reason "Switching to DocuSign per client request"

param(
    [Parameter(Mandatory=$true)]
    [string]$FolderNameContains,
    [string]$Reason = "Superseded"
)

$ErrorActionPreference = "Stop"

$foxitKeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md"
$baseUrl = "https://na1.foxitesign.foxit.com/api"

# --- Auth ---
Write-Host "Reading Foxit eSign credentials..." -ForegroundColor Cyan
$foxitKeys = Get-Content $foxitKeysFile -Raw
$clientId = [regex]::Match($foxitKeys, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $clientId) { $clientId = [regex]::Match($foxitKeys, 'Client ID\s*=\s*(\S+)').Groups[1].Value }
$clientSecret = [regex]::Match($foxitKeys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
if (-not $clientSecret) { $clientSecret = [regex]::Match($foxitKeys, 'Client Secret\s*=\s*(\S+)').Groups[1].Value }

$tokenBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "read-write"
}
$tokenResponse = Invoke-RestMethod -Uri "$baseUrl/oauth2/access_token" -Method POST -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token
$headers = @{ "Authorization" = "Bearer $accessToken" }
Write-Host "Authenticated." -ForegroundColor Green

# --- List recent folders & find match ---
Write-Host "Searching for folder matching: $FolderNameContains" -ForegroundColor Cyan

$candidateEndpoints = @(
    "$baseUrl/folders/search?folderName=$([System.Uri]::EscapeDataString($FolderNameContains))",
    "$baseUrl/folders/list",
    "$baseUrl/folders",
    "$baseUrl/folders/listfolders"
)

$folders = $null
$workingEndpoint = $null
foreach ($ep in $candidateEndpoints) {
    try {
        Write-Host "  trying: $ep" -ForegroundColor DarkGray
        $resp = Invoke-RestMethod -Uri $ep -Method GET -Headers $headers -ErrorAction Stop
        $workingEndpoint = $ep
        $folders = $resp
        Write-Host "  ok" -ForegroundColor DarkGreen
        break
    } catch {
        Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

if (-not $folders) {
    Write-Warning "Could not list folders via API. Dumping raw response for inspection."
    Write-Host ($folders | ConvertTo-Json -Depth 8) -ForegroundColor DarkYellow
    exit 2
}

Write-Host "Working endpoint: $workingEndpoint" -ForegroundColor Green
Write-Host "Raw folder list (first 400 chars):"
$dump = ($folders | ConvertTo-Json -Depth 6)
Write-Host $dump.Substring(0, [Math]::Min(1500, $dump.Length)) -ForegroundColor Gray
