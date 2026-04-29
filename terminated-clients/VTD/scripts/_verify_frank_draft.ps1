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

$getUri = "https://graph.microsoft.com/v1.0/users/$senderUpn/messages/$draftId" + "?`$select=body"
$draft  = Invoke-MgGraphRequest -Method GET -Uri $getUri
$html   = $draft.body.content

Write-Host "=== Section 2 region ===" -ForegroundColor Cyan
$idxSec2 = $html.IndexOf("<h3>2.")
$idxSec3 = $html.IndexOf("<h3>3.")
if ($idxSec2 -ge 0 -and $idxSec3 -gt $idxSec2) {
    Write-Host $html.Substring($idxSec2, $idxSec3 - $idxSec2)
} else {
    Write-Host "Could not locate Section 2 boundaries"
}

Write-Host ""
Write-Host "=== Plain-text sig check ===" -ForegroundColor Cyan
if ($html.Contains("Ravi Jain<br>CEO")) {
    Write-Host "PLAIN TEXT SIG STILL PRESENT" -ForegroundColor Red
} else {
    Write-Host "Plain-text sig: not found (good)" -ForegroundColor Green
}
if ($html.Contains("ravi-jain.jpg")) {
    Write-Host "Branded signature: present" -ForegroundColor Green
} else {
    Write-Host "Branded signature: NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Local/Onsite check ===" -ForegroundColor Cyan
if ($html.Contains("Local/Onsite") -or $html.Contains("flat-rate monthly")) {
    Write-Host "OLD SECTION 2 LANGUAGE STILL PRESENT" -ForegroundColor Red
} else {
    Write-Host "Old Local/Onsite / flat-rate language: not found (good)" -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
