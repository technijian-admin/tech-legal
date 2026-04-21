$ErrorActionPreference = "Stop"
$m365Keys = Get-Content "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\m365-graph.md" -Raw
$cid = [regex]::Match($m365Keys, 'App Client ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$tid = [regex]::Match($m365Keys, 'Tenant ID[^:]*:\*\*\s*(\S+)').Groups[1].Value
$sec = [regex]::Match($m365Keys, 'Client Secret[^:]*:\*\*\s*(\S+)').Groups[1].Value
$cred = New-Object System.Management.Automation.PSCredential($cid, (ConvertTo-SecureString $sec -AsPlainText -Force))
Connect-MgGraph -TenantId $tid -ClientSecretCredential $cred -NoWelcome | Out-Null
$uri = "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/mailFolders/Drafts/messages?`$top=10&`$orderby=lastModifiedDateTime desc&`$select=id,subject,lastModifiedDateTime"
$resp = Invoke-MgGraphRequest -Method GET -Uri $uri
foreach ($m in $resp.value) { Write-Host "$($m.lastModifiedDateTime) | $($m.subject)" }
Write-Host ""
Write-Host "Checking Sent Items for VTD..."
$uri2 = "https://graph.microsoft.com/v1.0/users/RJain@technijian.com/mailFolders/SentItems/messages?`$top=5&`$orderby=sentDateTime desc&`$select=id,subject,sentDateTime"
$resp2 = Invoke-MgGraphRequest -Method GET -Uri $uri2
foreach ($m in $resp2.value) { Write-Host "$($m.sentDateTime) | $($m.subject)" }
Disconnect-MgGraph | Out-Null
