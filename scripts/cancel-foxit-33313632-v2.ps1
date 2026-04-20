# Retry Foxit cancel with query params and form-encoded body
$ErrorActionPreference = "Stop"
$folderId = 33313632
$foxitKeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md"
$baseUrl = "https://na1.foxitesign.foxit.com/api"

$foxitKeys = Get-Content $foxitKeysFile -Raw
$clientId = [regex]::Match($foxitKeys, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$clientSecret = [regex]::Match($foxitKeys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tok = Invoke-RestMethod -Uri "$baseUrl/oauth2/access_token" -Method POST -Body @{ grant_type="client_credentials"; client_id=$clientId; client_secret=$clientSecret; scope="read-write" } -ContentType "application/x-www-form-urlencoded"
$hAuth = @{ "Authorization" = "Bearer $($tok.access_token)" }

$attempts = @(
    @{ Desc="POST cancelfolder?folderId (querystring)";       Method="POST"; Uri="$baseUrl/folders/cancelfolder?folderId=$folderId"; Body=$null; ContentType=$null },
    @{ Desc="POST cancelfolder (form-urlencoded)";            Method="POST"; Uri="$baseUrl/folders/cancelfolder";                    Body=@{ folderId = "$folderId" }; ContentType="application/x-www-form-urlencoded" },
    @{ Desc="POST /foldersV2/cancelfolder?folderId";          Method="POST"; Uri="$baseUrl/foldersV2/cancelfolder?folderId=$folderId"; Body=$null; ContentType=$null },
    @{ Desc="POST /folders/cancelFolder?folderId (camelCase)"; Method="POST"; Uri="$baseUrl/folders/cancelFolder?folderId=$folderId";  Body=$null; ContentType=$null },
    @{ Desc="POST /folders/cancel?folderId";                  Method="POST"; Uri="$baseUrl/folders/cancel?folderId=$folderId";        Body=$null; ContentType=$null }
)

foreach ($a in $attempts) {
    Write-Host "`n$($a.Desc)" -ForegroundColor Cyan
    try {
        if ($a.Body -and $a.ContentType) {
            $resp = Invoke-RestMethod -Uri $a.Uri -Method $a.Method -Headers $hAuth -Body $a.Body -ContentType $a.ContentType -ErrorAction Stop
        } else {
            $resp = Invoke-RestMethod -Uri $a.Uri -Method $a.Method -Headers $hAuth -ErrorAction Stop
        }
        Write-Host "SUCCESS:" -ForegroundColor Green
        Write-Host ($resp | ConvertTo-Json -Depth 6) -ForegroundColor Gray
        exit 0
    } catch {
        $sc = $_.Exception.Response.StatusCode.value__
        Write-Host "  $sc $($_.Exception.Message)" -ForegroundColor DarkYellow
        if ($_.ErrorDetails) { Write-Host "  detail: $($_.ErrorDetails.Message)" -ForegroundColor DarkGray }
    }
}
Write-Error "All variants failed."
exit 1
