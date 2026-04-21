$ErrorActionPreference = "Stop"
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$statePath  = Join-Path $scriptDir "affg-sow004-rev2-state.json"
$state      = Get-Content $statePath -Raw | ConvertFrom-Json
$clientHtml = [string]([System.IO.File]::ReadAllText($state.clientHtmlFile))
$techHtml   = [string]([System.IO.File]::ReadAllText($state.techHtmlFile))

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(.+)').Groups[1].Value.Trim()
$tok = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tid/oauth2/v2.0/token" -Method POST -Body @{ grant_type='client_credentials'; client_id=$cid; client_secret=$sec; scope='https://graph.microsoft.com/.default' } -ContentType 'application/x-www-form-urlencoded'
$gH = @{ Authorization = "Bearer $($tok.access_token)"; 'Content-Type' = 'application/json' }
Write-Host "Token OK."

# Use Depth 4 (sufficient for Message/Body/ToRecipients structure); Depth 10 hangs on large HTML strings
$clientBody = @{
    Message = @{
        Subject = $state.emailSubject
        Body = @{ ContentType = "HTML"; Content = $clientHtml }
        ToRecipients = @( @{ EmailAddress = @{ Address = $state.clientEmail; Name = $state.clientName } } )
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 6 -Compress

Write-Host "Sending client email to $($state.clientEmail)..."
$r1 = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" -Method POST -Headers $gH -Body $clientBody -UseBasicParsing
Write-Host "Client response: $($r1.StatusCode)"

$techBody = @{
    Message = @{
        Subject = $state.emailSubject
        Body = @{ ContentType = "HTML"; Content = $techHtml }
        ToRecipients = @( @{ EmailAddress = @{ Address = $state.signerEmail; Name = $state.signerName } } )
    }
    SaveToSentItems = $true
} | ConvertTo-Json -Depth 6 -Compress

Write-Host "Sending Technijian email to $($state.signerEmail)..."
$r2 = Invoke-WebRequest -Uri "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/sendMail" -Method POST -Headers $gH -Body $techBody -UseBasicParsing
Write-Host "Technijian response: $($r2.StatusCode)"

Write-Host ""
Write-Host "=== DISPATCH COMPLETE ===" -ForegroundColor Green
Write-Host "Envelope: $($state.envelopeId)"
