$ErrorActionPreference = "Stop"
$foxitKeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\foxit-esign.md"
$foxitKeys = Get-Content $foxitKeysFile -Raw
$clientId     = [regex]::Match($foxitKeys, 'Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$clientSecret = [regex]::Match($foxitKeys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tok = Invoke-RestMethod -Uri "https://na1.foxitesign.foxit.com/api/oauth2/access_token" -Method POST `
    -Body @{ grant_type="client_credentials"; client_id=$clientId; client_secret=$clientSecret; scope="read-write" } `
    -ContentType "application/x-www-form-urlencoded"
$hAuthOnly = @{ "Authorization" = "Bearer $($tok.access_token)" }
$hJson     = @{ "Authorization" = "Bearer $($tok.access_token)"; "Content-Type" = "application/json" }

$attempts = @(
    @{ Desc="cancelFolder body={folderId}";                                   Uri="https://na1.foxitesign.foxit.com/api/folders/cancelFolder";                    Headers=$hJson;     Body=(@{ folderId = 33313632 } | ConvertTo-Json) },
    @{ Desc="cancelFolder body={folderId,reason}";                            Uri="https://na1.foxitesign.foxit.com/api/folders/cancelFolder";                    Headers=$hJson;     Body=(@{ folderId = 33313632; reason = "Switching to DocuSign" } | ConvertTo-Json) },
    @{ Desc="cancelFolder body={folderId,cancelReason}";                      Uri="https://na1.foxitesign.foxit.com/api/folders/cancelFolder";                    Headers=$hJson;     Body=(@{ folderId = 33313632; cancelReason = "Switching to DocuSign" } | ConvertTo-Json) },
    @{ Desc="cancelFolder empty JSON body, folderId in querystring";          Uri="https://na1.foxitesign.foxit.com/api/folders/cancelFolder?folderId=33313632"; Headers=$hJson;     Body="{}" },
    @{ Desc="cancelFolder empty body, folderId in querystring, no CT header"; Uri="https://na1.foxitesign.foxit.com/api/folders/cancelFolder?folderId=33313632"; Headers=$hAuthOnly; Body=$null }
)

foreach ($a in $attempts) {
    Write-Host ""
    Write-Host "TRY: $($a.Desc)" -ForegroundColor Cyan
    try {
        if ($a.Body) {
            $resp = Invoke-RestMethod -Uri $a.Uri -Method POST -Headers $a.Headers -Body $a.Body -ErrorAction Stop
        } else {
            $resp = Invoke-RestMethod -Uri $a.Uri -Method POST -Headers $a.Headers -ErrorAction Stop
        }
        Write-Host "SUCCESS" -ForegroundColor Green
        $resp | ConvertTo-Json -Depth 6 | Write-Host
        exit 0
    } catch {
        $sc = $_.Exception.Response.StatusCode.value__
        Write-Host "  status=$sc message=$($_.Exception.Message)" -ForegroundColor DarkYellow
        if ($_.ErrorDetails) { Write-Host "  detail: $($_.ErrorDetails.Message)" -ForegroundColor DarkGray }
    }
}
Write-Error "All variants failed."
exit 1
