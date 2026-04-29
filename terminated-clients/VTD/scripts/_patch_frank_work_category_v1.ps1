$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$senderUpn = "RJain@technijian.com"
$draftId   = "AAMkAGNlYjM0OTA4LThjMjYtNGQ3My1iNDg1LTQ2MTI5NTg0NzFlOQBGAAAAAAC88IffM67WS4tSyVwwqYmJBwBhk-ls8ubYRazD3tGgncxCAAAAAAEQAACgx7VhNWW1QYCgfGa-8kbOAAX693XBAAA="

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null

$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$draftId" + "?`$select=subject,body"
$draft  = Invoke-MgGraphRequest -Method GET -Uri $getUri
$html   = $draft.body.content

Write-Host "=== SUBJECT ===" -ForegroundColor Cyan
Write-Host $draft.subject
Write-Host ""
Write-Host "=== HTML (first 4000 chars) ===" -ForegroundColor Cyan
Write-Host $html.Substring(0, [Math]::Min(4000, $html.Length))

# Save full HTML to temp file for inspection
$tmpPath = "$env:TEMP\vtd_frank_draft_current.html"
$html | Out-File $tmpPath -Encoding UTF8
Write-Host ""
Write-Host "Full HTML saved to: $tmpPath" -ForegroundColor Yellow

Disconnect-MgGraph | Out-Null
