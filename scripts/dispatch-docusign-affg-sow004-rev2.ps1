# STAGE 2: After Ravi approves the preview HTML from stage 1, send the branded
# emails to Iris + Ravi via Microsoft Graph.

$ErrorActionPreference = "Stop"
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$statePath  = Join-Path $scriptDir "affg-sow004-rev2-state.json"
if (-not (Test-Path $statePath)) { Write-Error "State file missing: $statePath. Run stage 1 first."; exit 1 }

$state = Get-Content $statePath -Raw | ConvertFrom-Json
$clientHtml = Get-Content $state.clientHtmlFile -Raw
$techHtml   = Get-Content $state.techHtmlFile   -Raw

# --- M365 credentials ---
$m365KeysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md"
$m365Keys     = Get-Content $m365KeysFile -Raw
$m365ClientId = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365TenantId = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$m365Secret   = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()

$graphToken = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$m365TenantId/oauth2/v2.0/token" -Method POST `
    -Body @{ grant_type="client_credentials"; client_id=$m365ClientId; client_secret=$m365Secret; scope="https://graph.microsoft.com/.default" } `
    -ContentType "application/x-www-form-urlencoded").access_token
$gH = @{ "Authorization" = "Bearer $graphToken"; "Content-Type" = "application/json" }

# --- Send client email ---
$clientMailBody = @{
    Message = @{
        Subject = $state.emailSubject
        Body = @{ ContentType = "HTML"; Content = $clientHtml }
        ToRecipients = @( @{ EmailAddress = @{ Address = $state.clientEmail; Name = $state.clientName } } )
        From = @{ EmailAddress = @{ Address = $state.signerEmail; Name = "Ravi Jain - Technijian" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" -Method POST -Headers $gH -Body $clientMailBody
Write-Host "Client email sent to $($state.clientName) <$($state.clientEmail)>" -ForegroundColor Green

# --- Send Technijian email (no personal signature) ---
$techMailBody = @{
    Message = @{
        Subject = $state.emailSubject
        Body = @{ ContentType = "HTML"; Content = $techHtml }
        ToRecipients = @( @{ EmailAddress = @{ Address = $state.signerEmail; Name = $state.signerName } } )
        From = @{ EmailAddress = @{ Address = $state.signerEmail; Name = "Technijian eSign" } }
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" -Method POST -Headers $gH -Body $techMailBody
Write-Host "Technijian email sent to $($state.signerName) <$($state.signerEmail)>" -ForegroundColor Green

Write-Host ""
Write-Host "=== DISPATCHED ===" -ForegroundColor Yellow
Write-Host "Envelope: $($state.envelopeId)"
Write-Host "Client  : $($state.clientEmail)"
Write-Host "Ravi    : $($state.signerEmail)"
