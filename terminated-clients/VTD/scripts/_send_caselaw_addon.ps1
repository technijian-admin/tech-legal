$ErrorActionPreference = "Stop"
$senderUpn = "RJain@technijian.com"

$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null

$drafts = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$senderUpn/mailFolders/Drafts/messages?`$top=5&`$orderby=lastModifiedDateTime desc&`$select=id,subject,toRecipients"
$match = $null; foreach ($m in $drafts.value) { if ($m.subject -match "Case Law Upgrade") { $match = $m; break } }
if (-not $match) { Write-Host "Draft not found" -ForegroundColor Red; exit 1 }

Write-Host "Sending: $($match.subject)"
Write-Host "  To: $($match.toRecipients.emailAddress.address)"

Send-MgUserMessage -UserId $senderUpn -MessageId $match.id
Write-Host "SENT." -ForegroundColor Green

Disconnect-MgGraph | Out-Null
